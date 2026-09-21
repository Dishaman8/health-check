#! /usr/bin/env bash
# health-check.sh  | This script used to analyse PC Status
# Author:Dishaman8 | Date: Sep-21 2026

set -o errexit
set -o nounset
set -o pipefail

command -v awk >/dev/null 2>&1 || {
  printf 'Error: awk is required.\n' >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Error: required command not found: %s\n' "$1" >&2
    exit 1
  }
}

require_command ps
require_command df
require_command free

separator() {
  printf '\n%s\n' '------------------------------------------------------------'
}

heading() {
  separator
  printf '%s\n' "$1"
  printf '%s\n' '------------------------------------------------------------'
}

cpu_usage() {
  # /proc/stat provides cumulative CPU time. Sampling twice gives real usage.
  local first total1 idle1 second total2 idle2 total_delta idle_delta
  first=$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
  idle1=$(awk '/^cpu / {print $5+$6}' /proc/stat)
  sleep 1
  second=$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
  idle2=$(awk '/^cpu / {print $5+$6}' /proc/stat)

  total1=$first
  total2=$second
  total_delta=$((total2 - total1))
  idle_delta=$((idle2 - idle1))

  if (( total_delta > 0 )); then
    awk -v total="$total_delta" -v idle="$idle_delta" \
      'BEGIN { printf "%.1f%%", (total - idle) * 100 / total }'
  else
    printf 'N/A'
  fi
}

memory_usage() {
  # "available" better reflects reclaimable cache than free memory alone.
  free -b | awk '
    /^Mem:/ {
      total = $2; used = $3; available = $7
      printf "Used: %.2f GiB / %.2f GiB (%.1f%%) | Available: %.2f GiB\n", \
        used / 1024^3, total / 1024^3, used * 100 / total, available / 1024^3
    }'
}

disk_usage() {
  df -hP -x tmpfs -x devtmpfs --output=target,size,used,avail,pcent 2>/dev/null \
    || df -hP -x tmpfs -x devtmpfs
}

processes_by_cpu() {
  ps -eo pid,user,comm,%cpu,%mem --sort=-%cpu | head -n 6
}

processes_by_memory() {
  ps -eo pid,user,comm,%mem,%cpu --sort=-%mem | head -n 6
}

printf 'Server performance report — %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"

heading 'CPU usage'
printf 'Total CPU usage: %s\n' "$(cpu_usage)"
printf 'Logical CPUs: %s\n' "$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf 'N/A')"

heading 'Memory usage'
memory_usage

heading 'Disk usage (local filesystems)'
disk_usage

heading 'Top 5 processes by CPU usage'
processes_by_cpu

heading 'Top 5 processes by memory usage'
processes_by_memory

heading 'Additional server details'
printf 'OS: '
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf '%s\n' "${PRETTY_NAME:-Linux}"
else
  uname -sr
fi
printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime)"
printf 'Load average: %s\n' "$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || printf 'N/A')"
printf 'Logged-in users: %s\n' "$(who 2>/dev/null | awk '!seen[$1]++ {count++} END {print count + 0}')"
separator
