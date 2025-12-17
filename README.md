# ntfy_nmap_watcher

A simple script to monitor externally visible ports on your servers and get notified when the configuration changes. Designed to catch UFW misconfigurations, especially outdated [ufw-docker](https://github.com/chaifeng/ufw-docker) rules that may expose services unintentionally.

## Problem

When using Docker with UFW, the Docker daemon can bypass UFW rules and expose ports directly to the internet. The [ufw-docker](https://github.com/chaifeng/ufw-docker) project helps manage this, but rules can become outdated when containers are removed or reconfigured. This script helps detect these misconfigurations by scanning your server from the outside and notifying you of any open ports.

## How It Works

The script uses `nmap` to scan all TCP ports on a target host from an external perspective, then sends the results via [ntfy](https://ntfy.sh/) using `apprise`. This gives you a complete picture of what's actually exposed to the internet, regardless of what your local UFW rules say.

## Installation

Requirements:
- `nmap` - Network scanner
- `apprise` - Notification library

```bash
# On Ubuntu/Debian
sudo apt install nmap
pip install apprise

# Or using uv
uv tool install apprise
```

## Usage

Basic usage:

```bash
./ntfy_nmap_watcher.sh --host yourserver.com --ntfy your-topic
```

The script will scan all 65535 TCP ports and send results to `ntfys://your-topic`.

## Automation with Cron

To automatically detect configuration drift, run the script periodically using cron:

```bash
# Edit crontab
crontab -e

# Run daily at 3 AM to check for exposed ports
0 3 * * * /path/to/ntfy_nmap_watcher.sh --host yourserver.com --ntfy your-topic

# Or run every 6 hours for more frequent monitoring
0 */6 * * * /path/to/ntfy_nmap_watcher.sh --host yourserver.com --ntfy your-topic
```

You'll receive a notification whenever the scan completes, showing all open ports. Compare consecutive notifications to detect when new ports appear unexpectedly.

## Example Notification

```
Title: Port Scan: yourserver.com
Body:
Scan duration: 127 seconds

Starting Nmap 7.80 ( https://nmap.org )
Nmap scan report for yourserver.com (192.0.2.1)
Host is up (0.012s latency).
Not shown: 65532 filtered ports
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
443/tcp  open  https
```

If you see unexpected ports (e.g., database ports, internal services), you've found a UFW misconfiguration that needs attention.

## Tips

- Start with manual runs to establish a baseline of expected open ports
- Consider scanning from multiple external locations to catch geo-restricted misconfigurations
- The full port scan takes time (typically 2-5 minutes); adjust cron frequency based on your security requirements
- Subscribe to your ntfy topic on your phone for instant alerts

## Credits

Created with assistance from [aider.chat](https://github.com/Aider-AI/aider/).
