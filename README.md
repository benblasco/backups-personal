# backups-personal
Backups of my personal data between hosts in my home network, and to the cloud

## Deploying

The systemd units are deployed via Ansible using the `linux-system-roles.systemd` role. Install the required collection before running the playbook:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.yml playbook.yml
```

## How the backups run

All backups run as systemd timers. Cloud rclone-based backups ensure that sg1 is mounted before running the backup. Local rsync based backups ensure that sg1, sg2, and sg3 are all mounted before running the backup.

| Job | Type | Destination | Schedule |
|-----|------|-------------|----------|
| Personal documents | rclone | Backblaze | 01:00 on Tue, Thu, Sat |
| Personal documents | rclone | OneDrive | 01:00 on Mon, Wed, Fri |
| Photos | rclone | Backblaze | 02:00 on Sun |
| Photos | rclone | OneDrive | 01:00 on Sun |
| sg1 → sg2 (NUC) | rsync | Local network | 03:00 on Tue, Thu, Sat |
| sg1 → sg3 (local disk) | rsync | Local disk | 03:00 on Mon, Wed, Fri |

## Running a backup manually

To trigger a backup immediately without waiting for its timer, start the `.service` unit directly.

Rclone user units (as `bblasco`):

```bash
systemctl --user start rclone-backblaze-personal.service
```

Rsync system units (as `root`):

```bash
sudo systemctl start rsync-sg2.service
```

Follow live output:

```bash
# User unit
journalctl --user -fu rclone-backblaze-personal.service

# System unit
sudo journalctl -fu rsync-sg2.service
```

## Backup logging

Rclone backup logs live under `~/rclone_logs`, with a separate file for each backup type.

Rsync backups log to the systemd journal. View logs with:

```bash
journalctl -u rsync-sg2.service
journalctl -u rsync-sg3.service
```

## Signal notifications

After each backup job completes, a notification is sent to a Signal group via a locally hosted [signal-cli REST API](https://github.com/bbernhard/signal-cli-rest-api) instance running on `micro.lan:9922`. Notifications are sent regardless of whether the job succeeded or failed, and include the systemd result (`success`, `exit-code`, etc.) alongside a summary of the backup output.

The `signal_number` variable is the registered sender account; `signal_group_id` is the destination group. Both are configured in `group_vars/all/backups-config.yml` (see `backups-config.yml.example`).

To find your group ID, use the list groups endpoint:

```bash
curl -X GET -H "Content-Type: application/json" 'http://micro.lan:9922/v1/groups/<signal_number>'
```

### Rsync notifications

The rsync notification script (`/var/usrlocal/bin/rsync-notify.sh`) reads the last 2 lines of the service's journal output for the current invocation — the rsync transfer summary — and sends them as the message body. Example message:

```
rsync-sg2: success | sent 21.84M bytes  received 12 bytes  147.06K bytes/sec  total size is 1.83T  speedup is 83,727.42
```

Test manually:

```bash
sudo INVOCATION_ID=test SERVICE_RESULT=test /var/usrlocal/bin/rsync-notify.sh rsync-sg3
```

### Rclone notifications

The rclone notification script (`/var/usrlocal/bin/rclone-notify.sh`) reads the last 4 lines of the rclone log file — the stats summary block written at job completion — and sends them as the message body. Example message:

```
rclone-backblaze-personal: success | 2026/03/31 15:23:35 NOTICE:  Transferred: 0 B / 0 B, -, 0 B/s, ETA - Checks: 5314 / 5314, 100%, Listed 11387 Elapsed time: 40.9s
```

Test manually (as `bblasco`, since rclone services run as a user unit):

```bash
SERVICE_RESULT=test /var/usrlocal/bin/rclone-notify.sh rclone-backblaze-personal ~/rclone_logs/backblaze-personal.log
```

For full signal-cli REST API usage examples see the [official examples](https://github.com/bbernhard/signal-cli-rest-api/blob/master/doc/EXAMPLES.md).

## Rclone to cloud as regular user bblasco

### To Backblaze

Photos:
`rclone sync /var/mnt/sg1/media/photos/ backblaze:eraser215-photos/photos/ --log-file ~/rclone_logs/backblaze-photos.log --log-level=INFO --stats-log-level NOTICE`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ backblaze:eraser215-personal/personal/ --log-file ~/rclone_logs/backblaze-personal.log --log-level=INFO --stats-log-level NOTICE`

### To Onedrive

Photos:
`rclone sync /var/mnt/sg1/media/photos/ onedrive:rclone_backup/photos/ --log-file ~/rclone_logs/onedrive-photos.log --log-level=INFO --stats-log-level NOTICE`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ onedrive:rclone_backup/personal/ --log-file ~/rclone_logs/onedrive-personal.log --log-level=INFO --stats-log-level NOTICE`

## SELinux requirements for rsync jobs

The rsync services run as root in the `rsync_t` SELinux domain. Two SELinux configurations are required and are applied automatically by the playbook.

### Boolean: `rsync_full_access`

The rsync services access NFS-mounted paths (`/var/mnt/sg2/`) and files in a user home directory. Without this boolean, SELinux denies rsync the ability to access NFS mounts and traverse the home directory tree.

```bash
setsebool -P rsync_full_access 1
```

### Custom policy module: `rsync-dac-override`

The source files on sg1 are owned by `bblasco`. When rsync (running as root in `rsync_t`) creates matching directories on the destination it must bypass DAC (Discretionary Access Control) ownership checks, which requires the `dac_override` capability. This is not covered by any boolean and requires a custom SELinux policy module.

The module source lives at `files/rsync-dac-override.te` and is compiled and loaded by the playbook using `checkmodule` and `semodule_package` from the `checkpolicy` and `policycoreutils` packages. Both packages must be present on the system before running the playbook — on a bootc image they should be baked in, as they cannot be installed at runtime.

To inspect or rebuild the module manually:

```bash
checkmodule -M -m -o rsync-dac-override.mod rsync-dac-override.te
semodule_package -o rsync-dac-override.pp -m rsync-dac-override.mod
semodule -i rsync-dac-override.pp
```

## Rsync between drives in my home network as root

### From 2TB Seagate disk on micro to NFS mounted 2TB Seagate disk on nuc
`rsync -avh --delete-before /var/mnt/sg1/ /var/mnt/sg2/ --log-file=/var/home/bblasco/rsync_logs/20260320.txt`

### From 2TB Seagate disk to 12TB WD disk on micro
`rsync -avh --delete-before /var/mnt/sg1/ /var/mnt/sg3/ --log-file=/var/home/bblasco/rsync_logs/20260320.txt`





