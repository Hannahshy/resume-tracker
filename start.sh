#!/bin/zsh
# ============================================================
# 简历投递管理 — 启动脚本
# 双击此文件即可启动服务并打开浏览器
# ============================================================

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PORT=3000
APP_URL="http://127.0.0.1:${APP_PORT}"
APP_VERSION="2.1-ocr"
APP_LOG="${APP_DIR}/.resume-tracker.log"
cd "$APP_DIR" || exit 1

# 首次运行或 OCR 源码更新后，构建 macOS 本地文字识别组件
OCR_BINARY="${APP_DIR}/.build/ResumeTrackerOCR"
OCR_SOURCE="${APP_DIR}/ocr.swift"
if [[ -f "$OCR_SOURCE" && ( ! -x "$OCR_BINARY" || "$OCR_SOURCE" -nt "$OCR_BINARY" ) ]]; then
  /bin/mkdir -p "${APP_DIR}/.build/clang-cache" "${APP_DIR}/.build/swift-cache"
  CLANG_MODULE_CACHE_PATH="${APP_DIR}/.build/clang-cache" \
  SWIFT_MODULE_CACHE_PATH="${APP_DIR}/.build/swift-cache" \
  /usr/bin/xcrun swiftc "$OCR_SOURCE" -O -o "$OCR_BINARY" >>"$APP_LOG" 2>&1
fi

# 检查 Node.js 是否安装
if [[ -x "/opt/homebrew/bin/node" ]]; then
  APP_NODE="/opt/homebrew/bin/node"
elif [[ -x "/usr/local/bin/node" ]]; then
  APP_NODE="/usr/local/bin/node"
elif command -v node >/dev/null 2>&1; then
  APP_NODE="$(command -v node)"
else
  /usr/bin/osascript -e 'display alert "无法启动简历投递管理" message "未检测到 Node.js，请先安装 Node.js 后重试。" as critical' >/dev/null 2>&1 || true
  exit 1
fi

# 已经启动时直接打开，不重复创建服务
APP_HEALTH="$(/usr/bin/curl -fsS "${APP_URL}/api/health" 2>/dev/null || true)"
if [[ "$APP_HEALTH" == *"\"version\":\"${APP_VERSION}\""* ]]; then
  /usr/bin/open "$APP_URL"
  exit 0
fi

# 只替换本项目的旧版本服务，不影响其他应用
if [[ -n "$APP_HEALTH" ]]; then
  APP_OLD_PID="$(/usr/sbin/lsof -tiTCP:${APP_PORT} -sTCP:LISTEN 2>/dev/null | /usr/bin/head -n 1)"
  APP_OLD_COMMAND="$(/bin/ps -p "$APP_OLD_PID" -o command= 2>/dev/null || true)"
  if [[ "$APP_OLD_COMMAND" == *"${APP_DIR}/server.js"* || "$APP_OLD_COMMAND" == *"node server.js"* ]]; then
    /bin/kill "$APP_OLD_PID" 2>/dev/null || true
    /bin/sleep 0.5
  fi
fi

# 不占用或终止其他应用的进程
if /usr/sbin/lsof -tiTCP:${APP_PORT} -sTCP:LISTEN >/dev/null 2>&1; then
  /usr/bin/osascript -e 'display alert "无法启动简历投递管理" message "本机 3000 端口正在被其他应用使用，请关闭该应用后重试。" as warning' >/dev/null 2>&1 || true
  exit 1
fi

/usr/bin/nohup "$APP_NODE" "${APP_DIR}/server.js" >"$APP_LOG" 2>&1 &

# 最多等待约 5 秒，服务就绪后打开浏览器
for APP_ATTEMPT in {1..20}; do
  if /usr/bin/curl -fsS "${APP_URL}/api/health" >/dev/null 2>&1; then
    /usr/bin/open "$APP_URL"
    exit 0
  fi
  /bin/sleep 0.25
done

/usr/bin/osascript -e 'display alert "简历投递管理启动失败" message "请检查项目目录中的 .resume-tracker.log 文件。" as critical' >/dev/null 2>&1 || true
exit 1
