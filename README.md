# Health check
Project URL: https://github.com/Dishaman8/health-check.git
`server-stats.sh` prints a Linux server performance summary:
CPU, memory and disk usage, the top five processes by CPU and memory, plus OS, uptime, load average, 
and logged-in user details.

Run it directly from the project directory:

```bash
chmod +x server-stats.sh
./server-stats.sh
```

The script uses standard Linux utilities (`awk`, `ps`, `df`, and `free`) and
does not require root privileges.

