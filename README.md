# backups-personal

Backups of my personal data between hosts in my home network, and to the cloud.

## Deploying

The systemd units are deployed via Ansible using the `linux-system-roles.systemd` role. Install the required collection before running the playbook:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.yml playbook.yml
```

## Documentation

- [Rclone to cloud](README.rclone-to-cloud.md) — cloud backups to Backblaze and OneDrive
- [Rsync to local destinations](README.rsync-local.md) — local network and disk sync between sg1, sg2, and sg3
- [Signal notifications](README.signal-notifications.md) — post-backup alerts via signal-cli REST API
- [Android FolderSync app configuration](README.foldersync.md) — LAN permissions for FolderSync on Android
- [Podman volume backup](README.podman-volume-backup.md) — export Podman volumes to timestamped tar archives
