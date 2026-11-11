import '../../l10n/l10n.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/desktop.dart';
import '../../core/session.dart';
import '../../core/updates.dart';
import 'common.dart';

/// Downloads the APK from the server with progress and hands it to the Android installer.
/// Desktop: downloads the installer / AppImage from GitHub (Linux tarball installs get the release page).
Future<void> installAppUpdate(BuildContext context, WidgetRef ref) async {
  if (isDesktop || defaultTargetPlatform == TargetPlatform.iOS) {
    final update = ref.read(appUpdateProvider).value;
    if (update == null) return;
    // iOS: the .ipa is installed with a sideloading tool; Linux tarball: no self-update.
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        (defaultTargetPlatform == TargetPlatform.linux && runningAppImage == null)) {
      final page = update.releaseUrl;
      if (page != null) await launchUrl(Uri.parse(page), mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DesktopUpdateDialog(update: update),
    );
    return;
  }
  // Galactic: the APK of the fork's latest GitHub release.
  final url = ref.read(appUpdateProvider).value?.downloadUrl ?? ref.read(apiProvider).androidApkUrl;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(url: url),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.url});
  final String url;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    OtaUpdate()
        .execute(widget.url, destinationFilename: 'Resonance.apk')
        .listen(
          (event) {
            if (!mounted) return;
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                setState(() => _progress = (double.tryParse(event.value ?? '') ?? 0) / 100);
              case OtaStatus.INSTALLING || OtaStatus.INSTALLATION_DONE:
                // The system installer takes over from here.
                Navigator.pop(context);
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                setState(() => _error = context.l10n.updateAllowInstall);
              case OtaStatus.CANCELED:
                Navigator.pop(context);
              default:
                setState(() => _error = context.l10n.updateFailedCode((event.status.name).toString()));
            }
          },
          onError: (Object e) {
            if (mounted) setState(() => _error = context.l10n.updateFailedMessage((e).toString()));
          },
        );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.updateInProgress),
    content: _error != null
        ? Text(_error!)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                _progress == null
                    ? context.l10n.updateDownloadStarting
                    : context.l10n.updateDownloadProgress((_progress! * 100).round()),
              ),
            ],
          ),
    actions: [
      if (_error != null) TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonClose)),
    ],
  );
}

class _DesktopUpdateDialog extends StatefulWidget {
  const _DesktopUpdateDialog({required this.update});
  final AppUpdate update;

  @override
  State<_DesktopUpdateDialog> createState() => _DesktopUpdateDialogState();
}

class _DesktopUpdateDialogState extends State<_DesktopUpdateDialog> {
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    installDesktopUpdate(widget.update, (value) {
      if (mounted) setState(() => _progress = value);
    }).then(
      (_) {},
      onError: (Object e) {
        if (mounted) setState(() => _error = context.l10n.updateFailedMessage(e.toString()));
      },
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.updateInProgress),
    content: _error != null
        ? Text(_error!)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                _progress == null
                    ? context.l10n.updateDownloadStarting
                    : _progress! >= 1
                    ? context.l10n.updateRestarting
                    : context.l10n.updateDownloadProgress((_progress! * 100).round()),
              ),
            ],
          ),
    actions: [
      if (_error != null) TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonClose)),
    ],
  );
}

/// Shows a one-time hint per app start when the server has a newer APK.
class UpdateNotifier extends ConsumerStatefulWidget {
  const UpdateNotifier({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdateNotifier> createState() => _UpdateNotifierState();
}

class _UpdateNotifierState extends ConsumerState<UpdateNotifier> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(appUpdateProvider, (_, next) {
      final update = next.value;
      if (_shown || update == null || !update.available) return;
      _shown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(context.l10n.updateAvailableTitle((update.availableName).toString())),
          action: SnackBarAction(label: context.l10n.updateInstall, onPressed: () => installAppUpdate(context, ref)),
        ),
      );
    });
    return widget.child;
  }
}

/// Settings tile: installed version and update button.
class AppVersionTile extends ConsumerWidget {
  const AppVersionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(appUpdateProvider);
    final u = update.value;
    if (u == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.system_update),
      title: Text(context.l10n.updateInstalledVersion(u.installed)),
      subtitle: Text(
        u.available ? context.l10n.updateAvailableVersion((u.availableName).toString()) : context.l10n.updateCurrent,
      ),
      trailing: u.available
          ? FilledButton(onPressed: () => installAppUpdate(context, ref), child: Text(context.l10n.updateAction))
          : IconButton(
              tooltip: context.l10n.updateCheck,
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                ref.invalidate(appUpdateProvider);
                try {
                  final next = await ref.read(appUpdateProvider.future);
                  if (context.mounted && !(next?.available ?? false)) {
                    showInfo(context, context.l10n.updateAlreadyCurrent);
                  }
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
    );
  }
}
