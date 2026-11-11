import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'desktop.dart';
import 'session.dart';

/// Desktop builds are attached to the GitHub releases by .github/workflows/desktop-release.yml.
const githubRepo = 'Sky0405-coder/Resonance';

/// Resonance Galactic (fork tjeronimo86/ResonanceGoesGalactic): its own Android app next to the original.
/// GitHub Actions builds the APK on every push and publishes it as release `galactic-<build>`.
const androidApplicationId = 'de.knode.resonance.galactic';
const galacticRepo = 'tjeronimo86/ResonanceGoesGalactic';

/// The Galactic APK of a release, e.g. `ResonanceGalactic-1007-android.apk`; its build number orders updates.
AppUpdate galacticUpdateFrom(Map<String, dynamic> release, PackageInfo info) {
  final tag = release['tag_name'] as String? ?? '';
  final build = int.tryParse(tag.replaceFirst('galactic-', ''));
  final url = [
    for (final a in (release['assets'] as List? ?? const []))
      if (a is Map && (a['name'] as String? ?? '').endsWith('-android.apk')) a['browser_download_url'] as String?,
  ].firstOrNull;
  return AppUpdate(
    installed: '${info.version} · Build ${info.buildNumber}',
    installedCode: int.tryParse(info.buildNumber) ?? 0,
    availableName: url == null || build == null ? null : 'Galactic Build $build',
    availableCode: url == null ? null : build,
    downloadUrl: url,
    releaseUrl: release['html_url'] as String?,
  );
}

/// Installed version and, if there is a newer release, that release.
/// Android: the APK on the Resonance server. Linux/Windows/iOS: the GitHub release's AppImage / installer / .ipa.
class AppUpdate {
  const AppUpdate({
    required this.installed,
    required this.installedCode,
    this.availableName,
    this.availableCode,
    this.downloadUrl,
    this.releaseUrl,
  });
  final String installed;
  final int installedCode;
  final String? availableName;
  final int? availableCode;

  /// Desktop: the file for this platform (null when the build is not attached to the release yet).
  final String? downloadUrl;
  final String? releaseUrl;

  bool get available => availableCode != null && availableCode! > installedCode;
}

/// The asset of a release that updates this installation, e.g. `Resonance-v1.0.18-windows-setup.exe`.
String desktopAssetName(String tag, TargetPlatform platform) => switch (platform) {
  TargetPlatform.windows => 'Resonance-$tag-windows-setup.exe',
  TargetPlatform.iOS => 'Resonance-$tag-ios.ipa',
  _ => 'Resonance-$tag-linux-x86_64.AppImage',
};

/// Comparable number of a version or tag: 1.1.0 / v1.1.0 → 1001000 (major.minor.patch, build suffix ignored).
int? versionCode(String version) {
  final parts = version.replaceFirst('v', '').split('+').first.split('.').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return parts[0]! * 1000000 + parts[1]! * 1000 + parts[2]!;
}

/// Parses GitHub's `releases/latest` answer into the update offered to this platform.
AppUpdate desktopUpdateFrom(Map<String, dynamic> release, PackageInfo info, TargetPlatform platform) {
  final tag = release['tag_name'] as String? ?? '';
  final asset = desktopAssetName(tag, platform);
  final url = [
    for (final a in (release['assets'] as List? ?? const []))
      if (a is Map && a['name'] == asset) a['browser_download_url'] as String?,
  ].firstOrNull;
  return AppUpdate(
    installed: info.version,
    installedCode: versionCode(info.version) ?? 0,
    // Only offer releases whose build for this platform is already uploaded.
    availableName: url == null ? null : tag.replaceFirst('v', ''),
    availableCode: url == null ? null : versionCode(tag),
    downloadUrl: url,
    releaseUrl: release['html_url'] as String?,
  );
}

final appUpdateProvider = FutureProvider<AppUpdate?>((ref) async {
  if (kIsWeb) return null;
  final api = ref.watch(apiProvider);
  if (api.token == null) return null;
  final info = await PackageInfo.fromPlatform();
  // Desktop and iOS (sideloaded .ipa) get their builds from the GitHub release.
  if (isDesktop || defaultTargetPlatform == TargetPlatform.iOS) {
    final response = await Dio().get<Map<String, dynamic>>(
      'https://api.github.com/repos/$githubRepo/releases/latest',
      options: Options(headers: {'Accept': 'application/vnd.github+json'}),
    );
    return desktopUpdateFrom(response.data ?? const {}, info, defaultTargetPlatform);
  }
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  // Galactic: updates come from the fork's GitHub releases, not from the Resonance server (that APK is the
  // original app with another signature).
  final galactic = await Dio().get<Map<String, dynamic>>(
    'https://api.github.com/repos/$galacticRepo/releases/latest',
    options: Options(headers: {'Accept': 'application/vnd.github+json'}),
  );
  return galacticUpdateFrom(galactic.data ?? const {}, info);
});

/// Path of the running AppImage (set by the AppImage runtime), null for other Linux installs.
String? get runningAppImage => Platform.environment['APPIMAGE'];

/// Downloads the update and hands over to it: Windows runs the installer (which restarts the app), an AppImage
/// replaces itself and restarts. Returns false when this installation cannot update itself (Linux tarball).
Future<bool> installDesktopUpdate(AppUpdate update, void Function(double progress) onProgress) async {
  final url = update.downloadUrl;
  if (url == null) return false;
  final appImage = runningAppImage;
  if (defaultTargetPlatform == TargetPlatform.linux && appImage == null) return false;
  final target = defaultTargetPlatform == TargetPlatform.windows
      ? '${Directory.systemTemp.path}${Platform.pathSeparator}Resonance-setup.exe'
      : '$appImage.update';
  await Dio().download(
    url,
    target,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress(received / total);
    },
  );
  if (defaultTargetPlatform == TargetPlatform.windows) {
    // Inno Setup (app/windows/installer/resonance.iss): updates silently and starts the app again.
    await Process.start(target, const [
      '/SILENT',
      '/SUPPRESSMSGBOXES',
      '/CLOSEAPPLICATIONS',
    ], mode: ProcessStartMode.detached);
  } else {
    await Process.run('chmod', ['755', target]);
    // Replacing the file of a running program is fine on Linux; the old inode stays until we exit.
    await File(target).rename(appImage!);
    await Process.start(appImage, const [], mode: ProcessStartMode.detached);
  }
  exit(0);
}
