# monish

Lightweight Bash server monitoring dashboard.

## Features
- Single-screen terminal dashboard
- CPU load, RAM%, disk%, uptime
- Parallel SSH checks with minimal dependencies
- Color thresholds for load, RAM%, and disk%
- JSON output for automation

## Requirements
- Bash
- OpenSSH client
- Common GNU utilities: awk, sed, grep, df, free, ping, tput

## Quick start
```bash
git clone <repo>
cd monish
cp monish.conf.example monish.conf  # copy example to local config

# edit the new config file
$EDITOR monish.conf

./monish.sh -c monish.conf
```

One-shot and JSON:
```bash
./monish.sh --once
./monish.sh --json --once > out.json
```

## Disk usage collection
monish gathers disk usage by executing `df -h /` on each server over SSH and
parsing the used percentage. Ensure the `df` utility is available on the remote
host; the root filesystem `/` is checked by default.

## RAM usage collection
monish calculates memory usage by running `free -m` on each remote host and
deriving the used/total percentage from the `Mem` line. Ensure the `free`
utility is installed on the server.

## Config reference
All keys and defaults are shown in `monish.conf.example`. Define servers with sections:
```
[server "name"]
host=1.2.3.4
user=ubuntu
```

For password-based SSH (requires `sshpass`), add the authentication method and password:
```
[server "name"]
host=1.2.3.4
user=ubuntu
auth=password
password=s3cr3t
```

The refresh interval is configured via `refresh_sec` (default 3 seconds). `monish.sh` automatically reads server names from all `[server "..."]` sections in the config, so no environment variables are required.

## Color thresholds
| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Load1  | <1    | 1-2    | >2  |
| RAM%   | <70   | 70-85  | >85 |
| Disk%  | <70   | 70-85  | >85 |

Disk% and RAM% values displayed in the table are wrapped in green/yellow/red
colors based on these thresholds.

## Security
Use key-based auth or SSH agent. Password auth requires `sshpass` and is not recommended.

## Troubleshooting
- Ensure SSH connectivity and permissions.
- Timeouts or ERR status indicate unreachable hosts.

## License
MIT
