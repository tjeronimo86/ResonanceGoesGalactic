#!/bin/sh
# Packs the Flutter Linux bundle into an AppImage that runs without libmpv installed.
# libmpv and its dependencies are bundled (linuxdeploy skips base libraries like glibc/libGL); GTK comes from the
# system like for any other GTK app. media_kit is pointed at the bundled libmpv via LIBMPV_LIBRARY_PATH, so no
# LD_LIBRARY_PATH leaks into programs the app starts (browser, file manager).
#
# Usage: scripts/package-linux-appimage.sh <flutter bundle dir> <output .AppImage>
# Build on the oldest distro you want to support (CI: Ubuntu 22.04); needs libmpv-dev, curl, file.
set -eu
BUNDLE=$(readlink -f "$1")
OUT=$(readlink -f "$(dirname "$2")")/$(basename "$2")
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TOOLS=${APPIMAGE_TOOLS:-$HOME/.cache/appimage-tools}
export APPIMAGE_EXTRACT_AND_RUN=1 # no FUSE needed in containers/CI

mkdir -p "$TOOLS"
fetch() {
  [ -x "$TOOLS/$1" ] || { curl -fsSL -o "$TOOLS/$1" "$2" && chmod +x "$TOOLS/$1"; }
}
fetch linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
fetch appimagetool https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage

MPV=$(ldconfig -p | awk '/libmpv\.so\.[0-9]+ .*x86-64/ {print $NF; exit}')
[ -n "$MPV" ] || { echo "libmpv not found (install libmpv-dev)" >&2; exit 1; }

WORK=$(mktemp -d)
APPDIR=$WORK/AppDir
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/icons/hicolor/512x512/apps"
cp -a "$BUNDLE/." "$APPDIR/usr/bin/"
# Only libmpv's dependency closure: linuxdeploy run on the whole bundle would also pull in GTK. Libraries the app
# already loaded from the system (glib, …) are matched by soname, so bundled duplicates stay unused.
"$TOOLS/linuxdeploy" --appdir "$WORK/mpv" --library "$MPV" >/dev/null
cp -a "$WORK/mpv/usr/lib/." "$APPDIR/usr/lib/"

cat >"$APPDIR/usr/share/applications/de.knode.resonance.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Resonance
GenericName=Music player
Comment=Your self-hosted music library
Exec=resonance %U
Icon=de.knode.resonance
Categories=AudioVideo;Audio;Player;
StartupWMClass=de.knode.resonance
Terminal=false
EOF
cp "$ROOT/app/linux/runner/resources/resonance.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/de.knode.resonance.png"
ln -s usr/share/applications/de.knode.resonance.desktop "$APPDIR/de.knode.resonance.desktop"
ln -s usr/share/icons/hicolor/512x512/apps/de.knode.resonance.png "$APPDIR/de.knode.resonance.png"
ln -s de.knode.resonance.png "$APPDIR/.DirIcon"

cat >"$APPDIR/AppRun" <<EOF
#!/bin/sh
HERE=\$(dirname "\$(readlink -f "\$0")")
export LIBMPV_LIBRARY_PATH="\$HERE/usr/lib/$(basename "$MPV")"
# Steam's Gaming Mode (gamescope) runs the app through XWayland, where NVIDIA's EGL gives Flutter no GPU context and
# Mesa falls back to drawing on the CPU (5-9 fps). Mesa's OpenGL on Vulkan (Zink) runs on the NVIDIA GPU there.
# RESONANCE_NO_ZINK=1 turns this off; an EGL vendor chosen by the user is left alone.
if [ -z "\${RESONANCE_NO_ZINK:-}" ] && [ -z "\${__EGL_VENDOR_LIBRARY_FILENAMES:-}" ] && [ -d /proc/driver/nvidia ] &&
  { [ "\${XDG_CURRENT_DESKTOP:-}" = gamescope ] || [ -n "\${GAMESCOPE_WAYLAND_DISPLAY:-}" ]; }; then
  for MESA_EGL in /usr/share/glvnd/egl_vendor.d/50_mesa.json /etc/glvnd/egl_vendor.d/50_mesa.json; do
    if [ -f "\$MESA_EGL" ]; then
      export __EGL_VENDOR_LIBRARY_FILENAMES="\$MESA_EGL" MESA_LOADER_DRIVER_OVERRIDE=zink
      break
    fi
  done
fi
exec "\$HERE/usr/bin/resonance" "\$@"
EOF
chmod +x "$APPDIR/AppRun"

ARCH=x86_64 "$TOOLS/appimagetool" --no-appstream "$APPDIR" "$OUT" >/dev/null
rm -rf "$WORK"
echo "Built $OUT"
