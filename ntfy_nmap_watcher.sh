#!/usr/bin/env zsh

# ntfy_nmap_watcher.sh - Monitor open ports on a host and send notifications
# This script scans a host using nmap and sends the results via apprise/ntfy
# Goal: Detect ufw configuration errors by monitoring externally visible ports
# Created with assistance from aider.chat (https://github.com/Aider-AI/aider/)

VERSION="1.0.0"

# Function to display help and version
show_help() {
    cat << EOF
ntfy_nmap_watcher.sh v${VERSION}

Usage: $0 --host <hostname|ip> [--ntfy <ntfy_topic>] [-h|--help]

Monitor open ports on a host using nmap and optionally send results via ntfy.
Designed to detect ufw misconfiguration by showing externally visible ports.

Arguments:
  --host <hostname|ip>  Target host to scan (required)
  --ntfy <ntfy_topic>   Ntfy topic for notifications (optional)
  -h, --help           Show this help message and version

Example:
  $0 --host example.com --ntfy mytopic

This script was created with assistance from aider.chat
EOF
    exit 0
}

# Check for required commands upfront to fail fast
# nmap is required to perform the port scan
if ! command -v nmap &> /dev/null; then
    echo "Error: nmap is not installed or not in PATH" >&2
    exit 1
fi


# Parse command line arguments
HOST=""
NTFY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --ntfy)
            NTFY="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown argument: $1" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$HOST" ]]; then
    echo "Error: --host argument is required" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

# If --ntfy is specified, check that apprise is available
# Otherwise we'll just print results to stdout
if [[ -n "$NTFY" ]] && ! command -v apprise &> /dev/null; then
    echo "Error: apprise is not installed or not in PATH" >&2
    echo "apprise is required when using --ntfy option" >&2
    exit 1
fi

# Run nmap scan
# Using -p- to scan all 65535 TCP ports for comprehensive coverage
# This ensures we catch any misconfigured ports, not just common ones
# -Pn skips host discovery to work with hosts that block ping
# Note: This will be slower than scanning just top ports but more thorough
START_TIME=$(date +%s)
SCAN_RESULTS=$(nmap -Pn -p- "$HOST" 2>&1)
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [[ $? -ne 0 ]]; then
    echo "Error: nmap scan failed" >&2
    echo "$SCAN_RESULTS" >&2
    exit 1
fi

# If --ntfy was provided, send notification via apprise
# Otherwise, just print the results to stdout
if [[ -n "$NTFY" ]]; then
    # Send results via apprise to ntfy
    # Title includes the hostname for easy identification
    # Body contains the full nmap output to show which ports are open
    # Duration is included to help understand scan performance
    NOTIFICATION_BODY="Scan duration: ${DURATION} seconds

$SCAN_RESULTS"

    apprise --title "Port Scan: $HOST" --body "$NOTIFICATION_BODY" "ntfys://$NTFY"

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to send notification via apprise" >&2
        exit 1
    fi

    echo "Scan completed and notification sent successfully"
else
    # Print results to stdout when no ntfy topic is specified
    echo "Port Scan: $HOST"
    echo "Scan duration: ${DURATION} seconds"
    echo ""
    echo "$SCAN_RESULTS"
fi
