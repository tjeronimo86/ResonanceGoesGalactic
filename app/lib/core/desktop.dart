import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Linux and Windows apps (not the web build).
bool get isDesktop =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows);

/// Steam's Gaming Mode (gamescope, e.g. Bazzite or SteamOS on a TV): the app is the only window on the screen.
bool get isGamescope =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.linux &&
    (Platform.environment['XDG_CURRENT_DESKTOP'] == 'gamescope' ||
        Platform.environment['GAMESCOPE_WAYLAND_DISPLAY'] != null);

/// Android on a desktop screen (Samsung DeX, Android's desktop mode, Chromebooks): behaves like the desktop app.
final androidDesktopProvider = NotifierProvider<AndroidDesktop, bool>(AndroidDesktop.new);

/// The desktop app, or Android on a desktop screen.
final desktopUiProvider = Provider<bool>((ref) => isDesktop || ref.watch(androidDesktopProvider));

const _device = MethodChannel('resonance/device');

/// Resolved before runApp so the desktop look does not flip in after the first frame.
Future<bool> detectAndroidDesktop() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  try {
    return await _device.invokeMethod<bool>('isDesktop') ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

class AndroidDesktop extends Notifier<bool> {
  AndroidDesktop([this._initial = false]);
  final bool _initial;

  @override
  bool build() => _initial;

  /// Follows DeX being switched on or off while the app runs.
  void listen() => _device.setMethodCallHandler((call) async {
    if (call.method == 'desktopMode') state = call.arguments == true;
  });
}

const _boundsKey = 'window_bounds';
const _maximizedKey = 'window_maximized';
const minWindowSize = Size(800, 560);

/// "x,y,w,h" → Rect; null for missing or broken values and windows smaller than the minimum.
Rect? parseBounds(String? value) {
  final parts = value?.split(',').map(double.tryParse).toList();
  if (parts == null || parts.length != 4 || parts.contains(null)) return null;
  final rect = Rect.fromLTWH(parts[0]!, parts[1]!, parts[2]!, parts[3]!);
  return rect.width < minWindowSize.width || rect.height < minWindowSize.height ? null : rect;
}

String formatBounds(Rect r) => [r.left, r.top, r.width, r.height].map((v) => v.round()).join(',');

/// Title, minimum size, and the size/position from the last session.
Future<void> initDesktopWindow(SharedPreferences prefs) async {
  await windowManager.ensureInitialized();
  if (isGamescope) {
    // gamescope scales a smaller window up to the screen and keeps its aspect ratio: a 1280x800 window ends up
    // blurry with black bars. Fullscreen gets the real resolution.
    await windowManager.waitUntilReadyToShow(const WindowOptions(title: 'Resonance', fullScreen: true), () async {
      await windowManager.show();
      await windowManager.focus();
    });
    return;
  }
  final bounds = parseBounds(prefs.getString(_boundsKey));
  await windowManager.waitUntilReadyToShow(
    WindowOptions(title: 'Resonance', minimumSize: minWindowSize, size: bounds?.size ?? const Size(1280, 800)),
    () async {
      // Wayland does not let apps place windows; the position only applies on X11 and Windows.
      if (bounds != null) await windowManager.setPosition(bounds.topLeft);
      if (prefs.getBool(_maximizedKey) ?? false) await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    },
  );
  windowManager.addListener(_WindowSaver(prefs));
}

class _WindowSaver extends WindowListener {
  _WindowSaver(this.prefs);
  final SharedPreferences prefs;
  Timer? _debounce;

  void _save() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (await windowManager.isMaximized() || await windowManager.isMinimized()) return;
      await prefs.setString(_boundsKey, formatBounds(await windowManager.getBounds()));
    });
  }

  @override
  void onWindowResized() => _save();

  @override
  void onWindowMoved() => _save();

  @override
  void onWindowMaximize() => prefs.setBool(_maximizedKey, true);

  @override
  void onWindowUnmaximize() => prefs.setBool(_maximizedKey, false);
}

/// Menu entry for an AppImage started directly (Exec = the AppImage's path). Wayland desktops look up the taskbar
/// icon by app id (de.knode.resonance) in the .desktop files, so without it KDE/GNOME show a generic icon.
/// The icon is an absolute path: icon theme caches would hide a freshly added theme icon.
String appImageDesktopEntry(String appImage, String icon) {
  final exec = appImage.replaceAllMapped(RegExp(r'["`$\\]'), (m) => '\\${m[0]}').replaceAll('\\', '\\\\');
  return """[Desktop Entry]
Type=Application
Name=Resonance
GenericName=Music player
Comment=Your self-hosted music library
Exec="$exec" %U
Icon=$icon
Categories=AudioVideo;Audio;Player;
StartupWMClass=de.knode.resonance
Terminal=false
""";
}

/// Installs/updates the taskbar entry and icon of the running AppImage in ~/.local/share (also after it was moved).
/// When another tool (Gear Lever, AppImageLauncher) already added an entry for this AppImage, ours is removed: it
/// copies the AppImage's own entry with StartupWMClass=de.knode.resonance, so the taskbar still finds the icon, and
/// Plasma's search lists even NoDisplay entries, which showed Resonance twice.
Future<void> registerAppImage() async {
  final appImage = Platform.environment['APPIMAGE'];
  final home = Platform.environment['HOME'];
  if (defaultTargetPlatform != TargetPlatform.linux || appImage == null || home == null) return;
  final dataHome = Platform.environment['XDG_DATA_HOME'] ?? '$home/.local/share';
  try {
    final icon = File('${File(Platform.resolvedExecutable).parent.path}/data/resonance.png');
    final iconTarget = File('$dataHome/icons/hicolor/512x512/apps/de.knode.resonance.png');
    if (!await iconTarget.exists() || await iconTarget.length() != await icon.length()) {
      await iconTarget.parent.create(recursive: true);
      await icon.copy(iconTarget.path);
    }
    final applications = Directory('$dataHome/applications');
    final entry = File('${applications.path}/de.knode.resonance.desktop');
    var integrated = false;
    if (await applications.exists()) {
      await for (final file in applications.list()) {
        if (file is! File || file.path == entry.path || !file.path.endsWith('.desktop')) continue;
        if ((await file.readAsString()).contains(appImage)) integrated = true;
      }
    }
    if (integrated) {
      if (await entry.exists()) await entry.delete();
      return;
    }
    final content = appImageDesktopEntry(appImage, iconTarget.path);
    if (await entry.exists() && await entry.readAsString() == content) return;
    await applications.create(recursive: true);
    await entry.writeAsString(content);
  } on FileSystemException catch (e) {
    debugPrint('AppImage desktop integration failed: $e');
  }
}
