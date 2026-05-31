#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/opt/chromium-widevine"
WIDEVINE_DIR="/var/lib/widevine"

echo "========================================="
echo " Chromium + Widevine Installer"
echo " aarch64 · 16K page size"
echo "========================================="
echo

if [ "$(uname -m)" != "aarch64" ]; then
  echo "ERROR: This package is for aarch64 systems only."
  exit 1
fi

if [ "$(whoami)" != "root" ]; then
  echo "ERROR: Run as root: sudo ./install.sh"
  exit 1
fi

echo "[1/4] Installing Chromium..."
mkdir -p "$INSTALL_DIR"
cp -a "$SCRIPT_DIR/chromium/"* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/chrome"

echo "[2/4] Installing Widevine CDM..."
mkdir -p "$WIDEVINE_DIR"
cp "$SCRIPT_DIR/widevine/libwidevinecdm.so" "$WIDEVINE_DIR/"
[ -f "$SCRIPT_DIR/widevine/manifest.json" ] && \
  cp "$SCRIPT_DIR/widevine/manifest.json" "$WIDEVINE_DIR/"

# WidevineCdm 目录结构
W="$WIDEVINE_DIR/WidevineCdm"
mkdir -p "$W/_platform_specific/linux_arm64"
mkdir -p "$W/_platform_specific/linux_x64"
[ -f "$WIDEVINE_DIR/manifest.json" ] && ln -sf "../manifest.json" "$W/manifest.json"
ln -sf "../../libwidevinecdm.so" "$W/_platform_specific/linux_arm64/libwidevinecdm.so"
touch "$W/_platform_specific/linux_x64/libwidevinecdm.so"

# Firefox GMP 路径
mkdir -p "$WIDEVINE_DIR/gmp-widevinecdm/system-installed"
ln -sf "../../libwidevinecdm.so" "$WIDEVINE_DIR/gmp-widevinecdm/system-installed/libwidevinecdm.so"
ln -sf "../../manifest.json" "$WIDEVINE_DIR/gmp-widevinecdm/system-installed/manifest.json"

echo "[3/4] Creating launcher..."
cat > /usr/local/bin/chromium-widevine << 'LAUNCHER'
#!/bin/bash
exec /opt/chromium-widevine/chrome "$@"
LAUNCHER
chmod +x /usr/local/bin/chromium-widevine

echo "[4/4] Configuring Firefox..."
# 环境变量
mkdir -p /usr/lib/environment.d
cat > /usr/lib/environment.d/50-gmpwidevine.conf << 'ENV'
MOZ_GMP_PATH=/var/lib/widevine/gmp-widevinecdm/system-installed
ENV

cat > /etc/profile.d/chromium-widevine.sh << 'PROFILE'
MOZ_GMP_PATH="${MOZ_GMP_PATH}${MOZ_GMP_PATH:+:}/var/lib/widevine/gmp-widevinecdm/system-installed"
export MOZ_GMP_PATH
PROFILE

# Firefox pref（自动检测 firefox-esr 或 firefox）
for dir in /usr/lib/firefox-esr /usr/lib/firefox /usr/lib64/firefox; do
  if [ -d "$dir/defaults/pref" ]; then
    cat > "$dir/defaults/pref/gmpwidevine.js" << 'FFPREF'
pref("media.gmp-widevinecdm.version", "system-installed");
pref("media.gmp-widevinecdm.visible", true);
pref("media.gmp-widevinecdm.enabled", true);
pref("media.gmp-widevinecdm.autoupdate", false);
pref("media.eme.enabled", true);
pref("media.eme.encrypted-media-encryption-scheme.enabled", true);
FFPREF
    echo "  Firefox pref: $dir/defaults/pref/gmpwidevine.js"
    break
  fi
done

# Desktop entry
cat > /usr/share/applications/chromium-widevine.desktop << 'DESKTOP'
[Desktop Entry]
Name=Chromium (Widevine)
Comment=Web Browser with Widevine DRM support
Exec=/usr/local/bin/chromium-widevine %U
Terminal=false
Type=Application
Icon=chromium
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;
DESKTOP

echo
echo "========================================="
echo " Installation complete!"
echo ""
echo "  Chromium:  /opt/chromium-widevine/chrome"
echo "  Launcher:  chromium-widevine"
echo "  Widevine:  $WIDEVINE_DIR"
echo ""
echo "  Re-login or run: source /etc/profile.d/chromium-widevine.sh"
echo "  for Firefox Widevine support."
echo "========================================="
