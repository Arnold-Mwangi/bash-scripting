#!/usr/bin/env bash
#
# system_health.sh — system health report (terminal + /var/log/system_health.log)
#

set -uo pipefail

LOGFILE="/var/log/system_health.log"
REPORT=""
SEP="================================"

append() { REPORT+="$1"$'\n'; }

# --- System info ---
HOSTNAME="$(hostname)"
KERNEL="$(uname -r)"
UPTIME_RAW="$(uptime -p 2>/dev/null || uptime | sed 's/.*up *//; s/, *[0-9]* user.*//')"

if command -v lsb_release >/dev/null 2>&1; then
	OS_INFO="$(lsb_release -a 2>/dev/null | tr '\n' '; ')"
else
	OS_INFO="$(grep -E '^(NAME|VERSION)=' /etc/os-release 2>/dev/null | tr '\n' ' ' || echo 'N/A')"
fi

# --- CPU usage (from /proc/stat; idle+iowait treated as idle) ---
CPU_PCT="$(
	awk '/^cpu / {
		t=0
		for (i=2;i<=NF;i++) t+=$i
		idle=$5+$6
		if (t>0) printf "%d", int(100*(t-idle)/t); else print 0
	}' /proc/stat
)"

# --- top: one-shot header + first tasks (requirement: top) ---
TOP_HEAD="$(LC_ALL=C top -bn1 2>/dev/null | head -n 12 || echo '(top unavailable)')"

# --- Memory (free -h) ---
if command -v free >/dev/null 2>&1; then
	MEM_LINE="$(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
else
	MEM_LINE="N/A"
fi

# --- Top CPU processes (ps) ---
TOP_PROCS="$(ps -eo user:12,pid,%cpu,cmd --sort=-%cpu 2>/dev/null | head -6 || true)"

# --- Disk (df -h); warn if use > 80% ---
DISK_LINES=""
WARN_DISK=()
DISK_SUMMARY=""
while read -r fs size used avail pct mount; do
	[[ "$fs" == "Filesystem" ]] && continue
	[[ "$fs" =~ ^(tmpfs|devtmpfs|overlay) ]] && continue
	[[ "$fs" == "dev" && "$mount" == "/dev" ]] && continue
	pct_num="${pct%\%}"
	if [[ "$pct_num" =~ ^[0-9]+$ ]] && [[ "$pct_num" -gt 80 ]]; then
		WARN_DISK+=("$mount ($pct used — WARNING: >80%)")
	fi
	DISK_LINES+="${fs}  ${mount}  ${pct} used"$'\n'
	if [[ -z "$DISK_SUMMARY" ]] && [[ "$fs" =~ ^/dev/ ]]; then
		DISK_SUMMARY="${fs} ${pct} used"
	fi
done < <(df -hP 2>/dev/null | tail -n +2)

[[ -z "$DISK_SUMMARY" ]] && DISK_SUMMARY="N/A"

# --- Network: ip a; ping ---
IP_ADDR="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)"
[[ -z "$IP_ADDR" ]] && IP_ADDR="$(hostname -I 2>/dev/null | awk '{print $1}')"
[[ -z "$IP_ADDR" ]] && IP_ADDR="N/A"

if ping -c 2 -W 3 google.com >/dev/null 2>&1; then
	PING_MSG="OK (ping success)"
else
	PING_MSG="FAIL (ping failed)"
fi

IP_A_SNIP="$(ip -4 a show scope global 2>/dev/null | sed 's/^/  /' | head -n 12)"
[[ -z "$IP_A_SNIP" ]] && IP_A_SNIP="  (no global IPv4 or ip unavailable)"

# --- Services: sshd, apache2 (and common alternates) ---
SERVICES_LINE=""
for svc in sshd ssh apache2 httpd; do
	unit="${svc}.service"
	if systemctl list-unit-files "$unit" 2>/dev/null | grep -q "^${unit}"; then
		if systemctl is-active --quiet "$unit" 2>/dev/null; then
			SERVICES_LINE+="${svc} active, "
		else
			SERVICES_LINE+="${svc} inactive, "
		fi
	fi
done
SERVICES_LINE="${SERVICES_LINE%, }"
[[ -z "$SERVICES_LINE" ]] && SERVICES_LINE="(no ssh/apache service units found)"

TS="$(date)"
append "$SEP"
append "===== SYSTEM HEALTH REPORT ====="
append ""
append "Date: $TS"
append "Hostname: $HOSTNAME"
append "OS: $OS_INFO"
append "Kernel: $KERNEL"
append "Uptime: $UPTIME_RAW"
append ""
append "CPU Usage: ${CPU_PCT}%"
append "Memory Usage: $MEM_LINE"
append "Disk: $DISK_SUMMARY"
append ""
append "--- top (batch, first lines) ---"
append "$TOP_HEAD"
append ""
append "Top CPU processes (ps):"
append "${TOP_PROCS:-(none)}"
append ""
append "Disk usage (df -h):"
append "${DISK_LINES:-N/A}"
if [[ ${#WARN_DISK[@]} -gt 0 ]]; then
	append "WARNINGS — partitions over 80%:"
	for w in "${WARN_DISK[@]}"; do
		append "  * $w"
	done
fi
append ""
append "--- ip a (IPv4, global) ---"
append "$IP_A_SNIP"
append "Network: $IP_ADDR — $PING_MSG"
append "Services: $SERVICES_LINE"
append ""
append "Report saved to $LOGFILE"
append "$SEP"

printf '%s' "$REPORT"

# --- Append to log (sudo if needed); each run is one timestamped entry ---
write_log() {
	local target="$1"
	if ( umask 022; printf '%s\n' "$REPORT" >>"$target" ) 2>/dev/null; then
		return 0
	fi
	if command -v sudo >/dev/null 2>&1; then
		if printf '%s\n' "$REPORT" | sudo tee -a "$target" >/dev/null 2>&1; then
			return 0
		fi
	fi
	echo "Warning: could not write to $target (run this script with sudo to log there)." >&2
}

write_log "$LOGFILE"
