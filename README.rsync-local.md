# Rsync to local destinations

Local rsync backups run as systemd system units as `root`. Each job ensures that `sg1`, `sg2`, and `sg3` are all mounted before running.

## Schedule

| Job | Destination | Schedule |
|-----|-------------|----------|
| sg1 → sg2 (NUC) | Local network | 03:00 on Tue, Thu, Sat |
| sg1 → sg3 (local disk) | Local disk | 03:00 on Mon, Wed, Fri |

## Running a backup manually

To trigger a backup immediately without waiting for its timer, start the `.service` unit directly (as `root`):

```bash
sudo systemctl start rsync-sg2.service
```

Follow live output:

```bash
sudo journalctl -fu rsync-sg2.service
```

## Backup logging

Rsync backups log to the systemd journal. View logs with:

```bash
journalctl -u rsync-sg2.service
journalctl -u rsync-sg3.service
```

## Signal notifications

See [Signal notifications](README.signal-notifications.md#rsync) for setup, message format, and manual testing.

## SELinux requirements

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

## Rsync commands

Run as `root`.

### From 2TB Seagate disk on micro to NFS mounted 2TB Seagate disk on nuc

`rsync -avh --delete-before /var/mnt/sg1/ /var/mnt/sg2/ --log-file=/var/home/bblasco/rsync_logs/20260320.txt`

### From 2TB Seagate disk to 12TB WD disk on micro

`rsync -avh --delete-before /var/mnt/sg1/ /var/mnt/sg3/ --log-file=/var/home/bblasco/rsync_logs/20260320.txt`
