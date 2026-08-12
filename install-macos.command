#!/bin/zsh
set -u

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${HOME}/Library/Application Support/ResumeTracker"
APP_DIR="${HOME}/Applications/简历投递管理.app"
DESKTOP_ALIAS="${HOME}/Desktop/简历投递管理.app"
APP_LOG="${INSTALL_DIR}/.resume-tracker.log"

show_error() {
  /usr/bin/osascript -e "display alert \"安装失败\" message \"$1\" as critical" >/dev/null 2>&1 || true
  print "安装失败：$1"
  read "?按回车键退出..."
  exit 1
}

if [[ "$(/usr/bin/uname -s)" != "Darwin" ]]; then
  show_error "当前安装程序仅支持 macOS。"
fi

if [[ -x "/opt/homebrew/bin/node" ]]; then
  APP_NODE="/opt/homebrew/bin/node"
elif [[ -x "/usr/local/bin/node" ]]; then
  APP_NODE="/usr/local/bin/node"
elif command -v node >/dev/null 2>&1; then
  APP_NODE="$(command -v node)"
else
  show_error "未检测到 Node.js 18 或更高版本。请先访问 https://nodejs.org 安装 Node.js。"
fi

NODE_MAJOR="$($APP_NODE -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || print 0)"
if (( NODE_MAJOR < 18 )); then
  show_error "Node.js 版本过低，请升级到 Node.js 18 或更高版本。"
fi

/bin/mkdir -p "$INSTALL_DIR" "${HOME}/Applications" || show_error "无法创建安装目录。"

# 更新程序文件，但永远不覆盖已有的个人 data.json。
for APP_FILE in package.json resume-tracker.html server.js start.sh ocr.swift LICENSE; do
  [[ -f "${SOURCE_DIR}/${APP_FILE}" ]] || show_error "安装包缺少 ${APP_FILE}。"
  /usr/bin/ditto "${SOURCE_DIR}/${APP_FILE}" "${INSTALL_DIR}/${APP_FILE}" || show_error "复制 ${APP_FILE} 失败。"
done

if [[ ! -f "${INSTALL_DIR}/data.json" ]]; then
  print '[]' > "${INSTALL_DIR}/data.json" || show_error "无法创建数据文件。"
fi

/bin/chmod +x "${INSTALL_DIR}/start.sh"
/bin/mkdir -p "${INSTALL_DIR}/.build/clang-cache" "${INSTALL_DIR}/.build/swift-cache"
CLANG_MODULE_CACHE_PATH="${INSTALL_DIR}/.build/clang-cache" \
SWIFT_MODULE_CACHE_PATH="${INSTALL_DIR}/.build/swift-cache" \
/usr/bin/xcrun swiftc "${INSTALL_DIR}/ocr.swift" -O -o "${INSTALL_DIR}/.build/ResumeTrackerOCR" >>"$APP_LOG" 2>&1 \
  || show_error "本机 OCR 组件编译失败。请确认已安装 macOS Command Line Tools。"

/bin/mkdir -p "${APP_DIR}/Contents/MacOS"

/bin/cat > "${APP_DIR}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key><string>简历投递管理</string>
  <key>CFBundleExecutable</key><string>ResumeTrackerLauncher</string>
  <key>CFBundleIdentifier</key><string>local.resume-tracker.app</string>
  <key>CFBundleName</key><string>简历投递管理</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

/bin/cat > "${APP_DIR}/Contents/MacOS/ResumeTrackerLauncher" <<LAUNCHER
#!/bin/zsh
exec "${INSTALL_DIR}/start.sh"
LAUNCHER

/bin/chmod +x "${APP_DIR}/Contents/MacOS/ResumeTrackerLauncher"
/usr/bin/codesign --force --deep --sign - "$APP_DIR" >>"$APP_LOG" 2>&1 || show_error "无法签名桌面应用。"

# 桌面放置应用副本；程序和数据仍保存在用户资料目录中。
if [[ -L "$DESKTOP_ALIAS" ]]; then
  /bin/rm -f "$DESKTOP_ALIAS" || show_error "无法更新桌面快捷方式。"
elif [[ -d "$DESKTOP_ALIAS" && -f "$DESKTOP_ALIAS/Contents/Info.plist" ]]; then
  /bin/mv "$DESKTOP_ALIAS" "${DESKTOP_ALIAS}.backup-$(/bin/date +%Y%m%d-%H%M%S)" || show_error "无法备份已有桌面应用。"
elif [[ -e "$DESKTOP_ALIAS" ]]; then
  show_error "桌面已存在同名文件，请先将其改名后重试。"
fi
/usr/bin/ditto "$APP_DIR" "$DESKTOP_ALIAS" || show_error "无法创建桌面快捷方式。"

if [[ "${RESUME_TRACKER_INSTALL_TEST:-0}" != "1" ]]; then
  /usr/bin/open "$APP_DIR"
  /usr/bin/osascript -e 'display notification "桌面快捷方式已创建，个人数据会保存在本机。" with title "简历投递管理安装完成"' >/dev/null 2>&1 || true
fi
print ""
print "安装完成。"
print "应用位置：${APP_DIR}"
print "数据位置：${INSTALL_DIR}/data.json"
print ""
if [[ "${RESUME_TRACKER_INSTALL_TEST:-0}" != "1" ]]; then
  read "?按回车键关闭此窗口..."
fi
