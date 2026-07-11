# Rclone to cloud

Cloud backups run as systemd user units for `bblasco`. Each job ensures that `sg1` is mounted before running.

## Schedule

| Job | Destination | Schedule |
|-----|-------------|----------|
| Personal documents | Backblaze | 01:00 on Tue, Thu, Sat |
| Personal documents | OneDrive | 01:00 on Mon, Wed, Fri |
| Photos | Backblaze | 02:00 on Sun |
| Photos | OneDrive | 01:00 on Sun |

## Running a backup manually

To trigger a backup immediately without waiting for its timer, start the `.service` unit directly (as `bblasco`):

```bash
systemctl --user start rclone-backblaze-personal.service
```

Follow live output:

```bash
journalctl --user -fu rclone-backblaze-personal.service
```

## Backup logging

Rclone backup logs live under `~/rclone_logs`, with a separate file for each backup type.

## Signal notifications

See [Signal notifications](README.signal-notifications.md#rclone) for setup, message format, and manual testing.

## Rclone commands

Run as regular user `bblasco`.

### To Backblaze

Photos:
`rclone sync /var/mnt/sg1/media/photos/ backblaze:eraser215-photos/photos/ --log-file ~/rclone_logs/backblaze-photos.log --log-level=INFO --stats-log-level NOTICE`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ backblaze:eraser215-personal/personal/ --log-file ~/rclone_logs/backblaze-personal.log --log-level=INFO --stats-log-level NOTICE`

### To OneDrive

Photos:
`rclone sync /var/mnt/sg1/media/photos/ onedrive:rclone_backup/photos/ --log-file ~/rclone_logs/onedrive-photos.log --log-level=INFO --stats-log-level NOTICE`

Documents:
`rclone sync /var/mnt/sg1/eblaben_backup/personal/ onedrive:rclone_backup/personal/ --log-file ~/rclone_logs/onedrive-personal.log --log-level=INFO --stats-log-level NOTICE`
