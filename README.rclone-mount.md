# Rclone mount as a replacement for sshfs

## Previous SSHFS setup

I have been using SSHFS to mount a disk on my home server for years, using this command as a regular user:

```
sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 -p <server port> <server host>:/mnt/sg1 /mnt/sg1
```

However SSHFS is no longer maintained, as per the project [git page](https://github.com/libfuse/sshfs) does not have a proper maintainer.

So, time to find a new solution.

## New rclone mount setup (with thanks to Google search with AI)

**`rclone mount` is an excellent, modern replacement for `sshfs`** and handles network disconnections far more gracefully.

Because `sshfs` operates as a direct network filesystem, any brief drop in internet connectivity usually causes the entire mount to freeze, hang your terminal, or throw hard "Input/output errors."

`rclone` solves this by using an abstract **Virtual File System (VFS) layer with local caching**. If your internet drops, `rclone` keeps the local file system structure alive, queues your operations, and silently retries the connection in the background without crashing your application.

### Why `rclone` Handles Disconnections Better

- **VFS Cache Mode:** With caching enabled, apps read and write to your local disk first. If you lose connection while editing a file, you can keep saving it locally. `rclone` will upload it automatically once the network returns.
- **Aggressive Retries:** `rclone` features built-in, low-level retry logic that constantly attempts to reconnect to the SFTP server without dropping the mount point.
- **No Frozen Terminals:** Unlike `sshfs`, which often requires a forced lazy unmount (`umount -l`) after a network drop, `rclone` stays responsive.

### Implementation

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

### rclone mount command

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

- **`--daemon`**
    - Tells rclone to launch the mount, hand control of the terminal back to you, and run quietly in the background.
