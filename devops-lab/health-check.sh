#! /usr/bin/env bash
# health-check.sh - checks CPU, memory, and disk usage
#Author: Mustafa Ismail | Date: 25-sep-2025
source $(dirname $0)/lib.sh
CPU_THRESHOLD=80
MEM_THRESHOLD=85
DISK_THRESHOLD=90

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

check_cpu && check_memory && check_disk


