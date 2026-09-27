# Rclone mount as a replacement for sshfs

## Previous SSHFS setup

I have been using SSHFS to mount a disk on my home server for years, using this command as a regular user:

```
sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p <server port> <server host>:/mnt/sg1 /mnt/sg1
```

However SSHFS is no longer maintained, as per the project [git page](https://github.com/libfuse/sshfs) does not have a proper maintainer.

So, time to find a new solution.

## New rclone mount setup

First, we configure a new rclone remote as follows:

name: home
Storage: 55 (SSH SFTP)
host: <server host>
user: bblasco
port: <server port>
Password: blank (so it uses keys)
key_pem: blank
key_file: ~/.ssh/id_rsa
key_file_pass: blank
pubkey: blank
pubkey_file: blank
key_use_agent: default (false)
use_insecure_cipher: false
disable_hashcheck: false
ssh: default (blank)

```
❯ more ~/.config/rclone/rclone.conf 
[home]
type = sftp
host = <server host>
port = <server port>
key_file = ~/.ssh/id_rsa
#known_hosts_file = ~/.ssh/known_hosts
shell_type = unix
md5sum_command = md5sum
sha1sum_command = sha1sum
```
## rclone mount command

As per some help from a google search with AI.

To make rclone act like sshfs but with high fault tolerance, configure your SFTP remote using rclone config, and then run the following optimized mount command:

```
rclone mount home:/var/mnt/sg1 /var/mnt/sg1 \
  --vfs-cache-mode full \
  --vfs-cache-max-age 2h \
  --vfs-cache-max-size 10G \
  --low-level-retries 10 \
  --contimeout 10s \
  --timeout 10m \
  --vfs-refresh \
  --daemon
```

Key Flags for Graceful Reconnections

- **`--vfs-cache-mode full`**
    - *The Savior:* This is what prevents your apps from freezing. It buffers reads and writes locally, keeping your system smooth during drops.

- **`--low-level-retries 10`
    - *The Router:* Tells `rclone` to aggressively try to re-establish broken network sockets before giving up.

- **`--contimeout 10s`**
    - *The Timer:* Reduces the connection timeout. If a network switch happens, it forces `rclone` to declare a timeout quickly and start reconnecting immediately rather than waiting for minutes.

- **`--vfs-refresh`**
    - *The Renewer:* Pre-loads the directory structure in the background on startup, making initial file browsing instant.









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
