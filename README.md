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

### Rclone
- Backblaze personal backups at 01:00 on Tue, Thu, and Sat
- Onedrive personal backups at 01:00 on Mon, Wed, and Fri
- Backblaze photo backups at 02:00 on Sun
- Onedrive photo backups at 01:00 on Sun

### Rsync
- Backup to sg2 runs at 03:00 on Tue, Thu, and Sat
- Backup to sg3 runs at 03:00 on Mon, Wed, and Fri

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

Backup logs live under ~/rclone_logs and ~/rsync_logs, and there's a different file for each backup type

## Rclone to cloud as regular user bblasco

### To Backblaze

Photos:
`rclone sync /var/mnt/sg1/media/photos/ backblaze:eraser215-photos/photos/ --log-file ~/rclone_logs/eraser215-photos.log --log-level=INFO --stats=0`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ backblaze:eraser215-personal/personal/ --log-file ~/rclone_logs/eraser215-personal.log --log-level=INFO --stats=0`

### To Onedrive

Photos:
`rclone sync /var/mnt/sg1/media/photos/ onedrive:rclone_backup/photos/ --log-file ~/rclone_logs/onedrive-photos.log --log-level=INFO --stats=0`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ onedrive:rclone_backup/personal/ --log-file ~/rclone_logs/onedrive-personal.log --log-level=INFO --stats=0 `

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





