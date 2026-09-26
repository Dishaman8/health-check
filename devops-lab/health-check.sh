#! /usr/bin/env bash
# health-check.sh - checks CPU, memory, disk, and network connectivity
#Author: Mustafa Ismail | Date: 25-sep-2025
source "$(dirname "$0")/lib.sh"
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90
TAILSCALE_GATEWAY=${TAILSCALE_GATEWAY:-gateway}
TAILSCALE_TIMEOUT=${TAILSCALE_TIMEOUT:-5s}
INTERNET_TARGET=${INTERNET_TARGET:-1.1.1.1}
INTERNET_PROBE_COUNT=${INTERNET_PROBE_COUNT:-3}
INTERNET_TIMEOUT=${INTERNET_TIMEOUT:-2}

check_cpu() {
  CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2)}')
  [ $CPU -gt $CPU_THRESHOLD ] && log_warn "CPU at ${CPU}%" || log_info "CPU OK: ${CPU}%"
}

check_memory() {
  MEM=$(free | awk 'NR==2{printf "%d", $3*100/$2}')
  [ $MEM -gt $MEM_THRESHOLD ] && log_warn "Memory at ${MEM}%" || log_info "Memory OK: ${MEM}%"
}

check_disk() {
  df -h | awk 'NR>1 {gsub("%","",$5); if($5+0 > 90) print "WARN: "$6" at "$5"%"}' | while read l; do log_warn "$l"; done
  log_info 'Disk check complete'
}

check_tailscale_gateway() {
  if ! command_exists tailscale; then
    log_warn "Tailscale gateway ping unavailable: tailscale command not found (target: ${TAILSCALE_GATEWAY})"
  elif tailscale ping --c=1 --timeout="${TAILSCALE_TIMEOUT}" "$TAILSCALE_GATEWAY" >/dev/null 2>&1; then
    log_info "Tailscale gateway ping successful: ${TAILSCALE_GATEWAY}"
  else
    log_warn "Tailscale gateway ping failed: ${TAILSCALE_GATEWAY}"
  fi
  return 0
}

check_internet() {
  local probe successes=0 failures=0

  if ! command_exists ping; then
    log_warn "Internet reachability unavailable: ping command not found (target: ${INTERNET_TARGET})"
    log_warn "Internet connection stability unavailable: ping command not found"
    return 0
  fi

  if [[ ! $INTERNET_PROBE_COUNT =~ ^[1-9][0-9]*$ ]]; then
    log_warn "Internet reachability unavailable: INTERNET_PROBE_COUNT must be a positive integer (got: ${INTERNET_PROBE_COUNT})"
    log_warn "Internet connection stability unavailable: invalid probe count"
    return 0
  fi

  if [[ ! $INTERNET_TIMEOUT =~ ^[1-9][0-9]*$ ]]; then
    log_warn "Internet reachability unavailable: INTERNET_TIMEOUT must be a positive integer (got: ${INTERNET_TIMEOUT})"
    log_warn "Internet connection stability unavailable: invalid timeout"
    return 0
  fi

  for ((probe = 1; probe <= INTERNET_PROBE_COUNT; probe++)); do
    if ping -n -c 1 -W "$INTERNET_TIMEOUT" "$INTERNET_TARGET" >/dev/null 2>&1; then
      ((successes += 1))
    else
      ((failures += 1))
    fi
  done

  if (( successes > 0 )); then
    log_info "Internet reachable: ${INTERNET_TARGET} (${successes}/${INTERNET_PROBE_COUNT} probes succeeded)"
  else
    log_warn "Internet unreachable: ${INTERNET_TARGET} (0/${INTERNET_PROBE_COUNT} probes succeeded)"
  fi

  if (( failures == 0 )); then
    log_info "Internet connection stable: ${INTERNET_TARGET} (${successes}/${INTERNET_PROBE_COUNT} probes succeeded)"
  else
    log_warn "Internet connection unstable: ${INTERNET_TARGET} (${successes}/${INTERNET_PROBE_COUNT} probes succeeded, ${failures} failed)"
  fi
  return 0
}

check_cpu && check_memory && check_disk && check_tailscale_gateway && check_internet

