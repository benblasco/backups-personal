# Signal notifications

After each backup job completes, a notification is sent to a Signal group via a locally hosted [signal-cli REST API](https://github.com/bbernhard/signal-cli-rest-api) instance running on `micro.lan:9922`. Notifications are sent regardless of whether the job succeeded or failed, and include the systemd result (`success`, `exit-code`, etc.) alongside a summary of the backup output.

The `signal_number` variable is the registered sender account; `signal_group_id` is the destination group. Both are configured in `group_vars/all/backups-config.yml` (see `backups-config.yml.example`).

To find your group ID, use the list groups endpoint:

```bash
curl -X GET -H "Content-Type: application/json" 'http://micro.lan:9922/v1/groups/<signal_number>'
```

For full signal-cli REST API usage examples see the [official examples](https://github.com/bbernhard/signal-cli-rest-api/blob/master/doc/EXAMPLES.md).

## Rclone

The rclone notification script (`/var/usrlocal/bin/rclone-notify.sh`) reads the last 4 lines of the rclone log file — the stats summary block written at job completion — and sends them as the message body. Example message:

```
rclone-backblaze-personal: success | 2026/03/31 15:23:35 NOTICE:  Transferred: 0 B / 0 B, -, 0 B/s, ETA - Checks: 5314 / 5314, 100%, Listed 11387 Elapsed time: 40.9s
```

Test manually (as `bblasco`, since rclone services run as a user unit):

```bash
SERVICE_RESULT=test /var/usrlocal/bin/rclone-notify.sh rclone-backblaze-personal ~/rclone_logs/backblaze-personal.log
```

## Rsync

The rsync notification script (`/var/usrlocal/bin/rsync-notify.sh`) reads the last 2 lines of the service's journal output for the current invocation — the rsync transfer summary — and sends them as the message body. Example message:

```
rsync-sg2: success | sent 21.84M bytes  received 12 bytes  147.06K bytes/sec  total size is 1.83T  speedup is 83,727.42
```

Test manually:

```bash
sudo INVOCATION_ID=test SERVICE_RESULT=test /var/usrlocal/bin/rsync-notify.sh rsync-sg3
```
