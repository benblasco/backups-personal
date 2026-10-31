# backups-personal

-  Backups of my personal data between hosts in my home network, and to the cloud
and
-  Remote mounting of a directory from my home server using rclone mount

## Deploying

The systemd units are deployed via Ansible using the `linux-system-roles.systemd` role. Install the required collection
before running the playbook:

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.yml playbook.yml
```

## Documentation

-  [Rclone mount (SSHFS replacement)](README.rclone-mount.md) — mount a path from the home server over SFTP with `rclone
mount`, VFS caching, and reconnect-friendly flags (replaces unmaintained SSHFS)
-  [Rclone to cloud](README.rclone-to-cloud.md) — cloud backups to Backblaze and OneDrive
-  [Rsync to local destinations](README.rsync-local.md) — local network and disk sync between sg1, sg2, and sg3
-  [Signal notifications](README.signal-notifications.md) — post-backup alerts via signal-cli REST API
-  [Android FolderSync app configuration](README.foldersync.md) — LAN permissions for FolderSync on Android
-  [Podman volume backup](README.podman-volume-backup.md) — export Podman volumes to timestamped tar archives

## Development

Install Python dev dependencies and Ansible collections, then enable pre-commit:

```bash
python3 -m pip install --user -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml
pre-commit install
pre-commit run --all-files
```

Pre-commit runs: YAML checks (`check-yaml`, yamllint), **ansible-lint** on the repo, **systemd-analyze verify** on
static units under `files/*.service` and `files/*.timer`, **gitleaks**, **shellcheck** (excluding Jinja `*.j2`
templates), and **markdownlint-cli2** on Markdown.

On RHEL or Fedora, confirm tooling is available:

```bash
pre-commit --version
ansible-lint --version
systemd-analyze --version
```
