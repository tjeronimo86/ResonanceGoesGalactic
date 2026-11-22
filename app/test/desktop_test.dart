import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:resonance/core/desktop.dart';
import 'package:resonance/core/updates.dart';

void main() {
  final info = PackageInfo(appName: 'Resonance', packageName: 'resonance', version: '1.0.17', buildNumber: '17');

  Map<String, dynamic> release(String tag, List<String> assets) => {
    'tag_name': tag,
    'html_url': 'https://github.com/$githubRepo/releases/tag/$tag',
    'assets': [
      for (final name in assets)
        {'name': name, 'browser_download_url': 'https://github.com/$githubRepo/releases/download/$tag/$name'},
    ],
  };

  test('desktop update: newer release with this platform\'s build', () {
    final u = desktopUpdateFrom(
      release('v1.0.18', ['Resonance-v1.0.18-android.apk', 'Resonance-v1.0.18-windows-setup.exe']),
      info,
      TargetPlatform.windows,
    );
    expect(u.available, isTrue);
    expect(u.availableName, '1.0.18');
    expect(u.downloadUrl, endsWith('/v1.0.18/Resonance-v1.0.18-windows-setup.exe'));
  });

  test('desktop update: not offered before the build is attached', () {
    final u = desktopUpdateFrom(release('v1.0.18', ['Resonance-v1.0.18-android.apk']), info, TargetPlatform.linux);
    expect(u.available, isFalse);
    expect(u.releaseUrl, contains('v1.0.18'));
  });

  test('desktop update: same version is current', () {
    final u = desktopUpdateFrom(
      release('v1.0.17', ['Resonance-v1.0.17-linux-x86_64.AppImage']),
      info,
      TargetPlatform.linux,
    );
    expect(u.downloadUrl, isNotNull);
    expect(u.available, isFalse);
  });

  test('versions compare across minor releases', () {
    expect(versionCode('1.1.0')! > versionCode('1.0.21')!, isTrue);
    expect(versionCode('v1.0.9')! < versionCode('v1.0.10')!, isTrue);
    expect(versionCode('1.1.0+22'), versionCode('1.1.0'));
    expect(versionCode('main'), isNull);
    final u = desktopUpdateFrom(release('v1.1.0', ['Resonance-v1.1.0-ios.ipa']), info, TargetPlatform.iOS);
    expect(u.available, isTrue);
  });

  test('window bounds round trip and validation', () {
    const rect = Rect.fromLTWH(100, 50, 1280, 800);
    expect(parseBounds(formatBounds(rect)), rect);
    expect(parseBounds(null), isNull);
    expect(parseBounds('1,2,3'), isNull);
    expect(parseBounds('a,b,c,d'), isNull);
    expect(parseBounds('0,0,300,200'), isNull); // smaller than the minimum window
  });

  test('AppImage menu entry quotes the path', () {
    final entry = appImageDesktopEntry(r'/home/a b/Res"onance$.AppImage', '/i/r.png');
    expect(entry, contains(r'Exec="/home/a b/Res\\"onance\\$.AppImage" %U'));
    expect(entry, contains('StartupWMClass=de.knode.resonance'));
    expect(entry, contains('Icon=/i/r.png'));
    expect(entry, isNot(contains('NoDisplay')));
  });
}
