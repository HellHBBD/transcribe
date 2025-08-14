#!/usr/bin/env bash
set -u

# 使用方式:
# ./build.sh [--jobs N] [--cpulimit PERCENT] [--arch "86"]
# 範例: ./build.sh --jobs 6 --cpulimit 50 --arch "86"

# 預設值
JOBS=""
CPULIMIT=""
ARCH="86"
LOGDIR="./whisper.cpp/build-logs"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOGFILE="${LOGDIR}/build-${TIMESTAMP}.log"
PIDFILE="${LOGDIR}/build-${TIMESTAMP}.pid"

# 解析簡單參數
while [[ $# -gt 0 ]]; do
	case "$1" in
	--jobs)
		JOBS="$2"
		shift 2
		;;
	--cpulimit)
		CPULIMIT="$2"
		shift 2
		;;
	--arch)
		ARCH="$2"
		shift 2
		;;
	-h | --help)
		cat <<EOF
Usage: $0 [--jobs N] [--cpulimit PERCENT] [--arch ARCH]
  --jobs N         : 指定 cmake --build -j N (預設為 nproc-1)
  --cpulimit P     : (選擇) 使用 cpulimit 限制整體 CPU 使用百分比 (e.g. 50)
  --arch ARCH      : CMAKE_CUDA_ARCHITECTURES 的值 (預設 "86")
EOF
		exit 0
		;;
	*)
		echo "Unknown arg: $1"
		exit 1
		;;
	esac
done

mkdir -p "$LOGDIR"

# 如果沒指定 jobs，預設使用 (nproc - 1) 或 1
if [[ -z "$JOBS" ]]; then
	NPROC=$(nproc)
	if [[ "$NPROC" -le 1 ]]; then
		JOBS=1
	else
		JOBS=$((NPROC - 1))
	fi
fi

echo "==== build.sh start ====" | tee -a "$LOGFILE"
echo "timestamp: $TIMESTAMP" | tee -a "$LOGFILE"
echo "jobs: $JOBS, cpulimit: ${CPULIMIT:-none}, arch: $ARCH" | tee -a "$LOGFILE"
echo "logfile: $LOGFILE" | tee -a "$LOGFILE"
echo "PIDFILE: $PIDFILE" | tee -a "$LOGFILE"

# 準備要執行的命令（configure + build）
CONFIG_CMD=(cmake -B whisper.cpp/build -DGGML_CUDA=1 -DGGML_CUDA_F16=ON -DCMAKE_CUDA_ARCHITECTURES="${ARCH}" -S whisper.cpp)
BUILD_CMD=(cmake --build whisper.cpp/build -j"${JOBS}")

run_with_nice() {
	echo "使用 nice + ionice 低優先度執行" | tee -a "$LOGFILE"

	if command -v cpulimit >/dev/null && [[ -n "$CPULIMIT" ]]; then
		echo "使用 cpulimit 限制 CPU=${CPULIMIT}%（系統需已安裝 cpulimit）" | tee -a "$LOGFILE"
		nohup bash -lc "nice -n 19 ionice -c3 ${CONFIG_CMD[*]} >>\"$LOGFILE\" 2>&1 && \
      nice -n 19 ionice -c3 cpulimit -l ${CPULIMIT} -- ${BUILD_CMD[*]} >>\"$LOGFILE\" 2>&1" >>"$LOGFILE" 2>&1 &
		echo $! >"$PIDFILE"
	else
		nohup bash -lc "nice -n 19 ionice -c3 ${CONFIG_CMD[*]} >>\"$LOGFILE\" 2>&1 && \
      nice -n 19 ionice -c3 ${BUILD_CMD[*]} >>\"$LOGFILE\" 2>&1" >>"$LOGFILE" 2>&1 &
		echo $! >"$PIDFILE"
	fi

	echo "background PID: $(cat $PIDFILE)" | tee -a "$LOGFILE"
	disown
}

# 直接使用 nice + ionice 執行
run_with_nice
