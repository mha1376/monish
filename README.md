# monish

Lightweight Bash server monitoring dashboard.

## Features
- Single-screen terminal dashboard
- CPU load, RAM%, disk%, uptime, ping
- Parallel SSH checks with minimal dependencies
- Color thresholds
- JSON output for automation

## Requirements
- Bash
- OpenSSH client
- Common GNU utilities: awk, sed, grep, df, free, ping, tput

## Quick start
```bash
git clone <repo>
cd monish
cp monish.conf.example monish.conf
# edit monish.conf
./monish.sh -c monish.conf
```

One-shot and JSON:
```bash
./monish.sh --once
./monish.sh --json --once > out.json
```

## Config reference
All keys and defaults are shown in `monish.conf.example`. Define servers with sections:
```
[server "name"]
host=1.2.3.4
user=ubuntu
```

## Required variables
`monish.sh` expects a few shell variables to be defined. They may be placed in
the config file or exported in the environment.

- `SERVER_NAME` – space‑separated list of servers to display.
- `REFRESH_SEC` – refresh interval in seconds.

### Minimal example
Create a config file with the required variables:

```
SERVER_NAME="local"
REFRESH_SEC=3
```

Run the script with:

```
./monish.sh -c monish.conf
```

Or provide the values via environment variables:

```
SERVER_NAME="local" REFRESH_SEC=3 ./monish.sh --once

## Environment variables
The collectors module reads server names from the `SERVER_NAME` environment variable. It must contain a space-separated list of servers before running `collect_servers` or `collect_all` directly:
```bash
export SERVER_NAME="web1 db1"

```

## Color thresholds
| Metric | Green | Yellow | Red |
|--------|-------|--------|-----|
| Load1  | <1    | 1-2    | >2  |
| RAM%   | <70   | 70-85  | >85 |
| Disk%  | <70   | 70-85  | >85 |
| Ping ms| <50   | 50-150 | >150 |

## Security
Use key-based auth or SSH agent. Password auth requires `sshpass` and is not recommended.

## Troubleshooting
- Ensure SSH connectivity and permissions.
- Timeouts or ERR status indicate unreachable hosts.

## License
MIT
