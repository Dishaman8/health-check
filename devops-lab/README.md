# DevOps Lab Scripts

This repository contains a system health check, a backup script, and a shared
logging library.

## Requirements

No third-party libraries need to be downloaded. The scripts use Bash and
standard Linux command-line tools:

- `top` and `free` (usually provided by the `procps` package)
- `df`, `date`, and `cp` (usually provided by `coreutils`)
- `grep`, `awk`, and `tar`

Install any missing tools with your Linux distribution's package manager. For
example, on Debian or Ubuntu:

```bash
sudo apt update
sudo apt install procps coreutils grep gawk tar
```

The scripts append log entries to `/var/log/devops-toolkit.log`. Run them with
`sudo` so they can write to that file.

## Health check

Run the CPU, memory, and disk checks:

```bash
sudo ./health-check.sh
```

The script sources `lib.sh`, then runs `check_cpu`, `check_memory`, and
`check_disk` in that order. It logs CPU warnings above 80%, memory warnings
above 85%, and disk warnings above 90%. The CPU and memory thresholds are set
near the top of `health-check.sh`; the disk check currently uses a fixed 90%
cutoff.

## Back up a directory

Make an uncompressed copy:

```bash
sudo ./backup.sh -s /path/to/source -d /path/to/backup-directory
```

Create a gzip-compressed tar archive instead:

```bash
sudo ./backup.sh -s /path/to/source -d /path/to/backup-directory -c
```

The destination directory must already exist. Each run adds a timestamp to the
backup name. Without `-c`, the source is copied recursively to a directory
named `backup-TIMESTAMP`. With `-c`, it creates
`backup-TIMESTAMP.tar.gz`. The script logs the result through `lib.sh`.

Options:

- `-s <source>`: file or directory to back up (required)
- `-d <destination>`: existing directory where the backup is written (required)
- `-c`: create a compressed `.tar.gz` archive
- `-h`: print the usage line

## Shared functions (`lib.sh`)

Both scripts load `lib.sh` from the same directory. It defines:

- `log_info`: append an `[INFO]` message to the log
- `log_warn`: append a `[WARN]` message to the log
- `log_error`: append an `[ERROR]` message to the log and print it to stderr
- `check_root`: report an error and exit when the caller is not root
- `command_exists`: return success if a command is available

Log lines use this format:

```text
[YYYY-MM-DD HH:MM:SS] [INFO] message
```
