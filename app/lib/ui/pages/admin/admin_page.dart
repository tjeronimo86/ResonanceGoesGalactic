import '../../../l10n/l10n.dart';

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/audiobooks.dart';
import '../../../core/books.dart';
import '../../../core/models.dart';
import '../../../core/session.dart';
import '../../../integrations/discord_presence.dart';
import '../../../core/theme.dart';
import '../../widgets/collection.dart';
import '../../widgets/common.dart';
import 'import_tab.dart';
import 'metadata_editor.dart';

/// Jellyfin-style dashboard; only routed to for admins (and the API enforces it).
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 6,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.l10n.adminDashboard, style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: Icon(Icons.dashboard_outlined), text: context.l10n.adminTabOverview),
            Tab(icon: Icon(Icons.people_outline), text: context.l10n.adminTabUsers),
            Tab(icon: Icon(Icons.link), text: context.l10n.adminTabInvites),
            Tab(icon: Icon(Icons.move_to_inbox), text: context.l10n.adminTabImport),
            Tab(icon: Icon(Icons.rule), text: context.l10n.adminTabReview),
            Tab(icon: Icon(Icons.tune), text: context.l10n.adminTabServer),
          ],
        ),
      ),
      body: const TabBarView(
        children: [_OverviewTab(), _UsersTab(), _InvitesTab(), ImportTab(), ReviewTab(), _ServerTab()],
      ),
    ),
  );
}

// --- overview ----------------------------------------------------------------

final _statsProvider = FutureProvider.autoDispose<LibraryStats>((ref) => ref.watch(apiProvider).libraryStats());
final _jobsProvider = FutureProvider.autoDispose<List<Job>>((ref) => ref.watch(apiProvider).jobs());
final _mixAnalysisStatusProvider = FutureProvider.autoDispose<({int total, int analyzed, int failed})>(
  (ref) => ref.watch(apiProvider).mixAnalysisStatus(),
);
final _lyricsStatusProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).lyricsStatus());
final _vocalAnalysisStatusProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).vocalAnalysisStatus());

String formatBytes(int b, {String? locale, bool megabytes = false}) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  if (megabytes) return '${NumberFormat('0.0', locale).format(b / (1024 * 1024))} MB';
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final value = locale == null
      ? v.toStringAsFixed(i == 0 ? 0 : 1)
      : NumberFormat(i == 0 ? '0' : '0.0', locale).format(v);
  return '$value ${units[i]}';
}

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab();

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  Timer? _poll;
  Timer? _mixPoll;

  @override
  void initState() {
    super.initState();
    _mixPoll = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(_mixAnalysisStatusProvider);
      ref.invalidate(_lyricsStatusProvider);
      ref.invalidate(_vocalAnalysisStatusProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _mixPoll?.cancel();
    super.dispose();
  }

  void _ensurePolling(List<Job> jobs) {
    final active = jobs.any((j) => j.isActive);
    if (active && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) {
        ref.invalidate(_jobsProvider);
        ref.invalidate(_statsProvider);
      });
    } else if (!active && _poll != null) {
      _poll!.cancel();
      _poll = null;
    }
  }

  Future<void> _scan(bool full) async {
    try {
      await ref.read(apiProvider).startScan(full: full);
      ref.invalidate(_jobsProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(_statsProvider);
    final jobs = ref.watch(_jobsProvider);
    final mixStatus = ref.watch(_mixAnalysisStatusProvider);
    final lyricsStatus = ref.watch(_lyricsStatusProvider);
    final numbers = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    jobs.whenData(_ensurePolling);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomInset),
      children: [
        stats.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (s) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(context.l10n.commonSongsTitle, '${s.tracks}', Icons.music_note),
              _StatCard(context.l10n.commonAlbums, '${s.albums}', Icons.album),
              _StatCard(context.l10n.commonArtists, '${s.artists}', Icons.person),
              _StatCard(context.l10n.adminStorage, formatBytes(s.totalBytes), Icons.storage),
              _StatCard(
                context.l10n.adminPlaytime,
                context.l10n.commonDurationHours(((s.totalSeconds / 3600).toStringAsFixed(0)).toString()),
                Icons.schedule,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Palette.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.adminMixAnalysis, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                mixStatus.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  // Failed songs (damaged files) are done too: otherwise the bar never reaches its end.
                  data: (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: s.total == 0 ? 0 : ((s.analyzed + s.failed) / s.total).clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (s.total > 0 && s.analyzed + s.failed >= s.total
                                ? context.l10n.adminMixAnalysisDone(numbers.format(s.total))
                                : context.l10n.adminMixAnalysisProgress(
                                    numbers.format(s.analyzed),
                                    numbers.format(s.total),
                                  )) +
                            (s.failed > 0 ? context.l10n.adminMixAnalysisFailed(numbers.format(s.failed)) : ''),
                      ),
                    ],
                  ),
                ),
                const _VocalAnalysisStatus(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          color: Palette.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.adminLyrics, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                lyricsStatus.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: s.total == 0 ? 0 : ((s.total - s.missing) / s.total).clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.adminLyricsProgress(
                          numbers.format(s.synced),
                          numbers.format(s.plainOnly),
                          numbers.format(s.none),
                          numbers.format(s.missing),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.adminLibrary, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(context.l10n.adminScanHint, style: TextStyle(color: Palette.textMuted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _scan(false),
              icon: const Icon(Icons.sync),
              label: Text(context.l10n.adminQuickScan),
            ),
            OutlinedButton.icon(
              onPressed: () => _scan(true),
              icon: const Icon(Icons.manage_search),
              label: Text(context.l10n.adminFullScan),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/admin/duplicates'),
              icon: const Icon(Icons.copy_all),
              label: Text(context.l10n.adminDuplicates),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(context.l10n.adminJobs, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        jobs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
              ? Text(context.l10n.adminNoJobs, style: TextStyle(color: Palette.textMuted))
              : Column(
                  children: [
                    for (final j in list.take(20))
                      Card(
                        color: Palette.card,
                        child: ListTile(
                          leading: Icon(switch (j.status) {
                            'done' => Icons.check_circle,
                            'failed' => Icons.error,
                            'running' => Icons.autorenew,
                            _ => Icons.hourglass_empty,
                          }, color: j.status == 'failed' ? Theme.of(context).colorScheme.error : null),
                          title: Text(j.kind == 'library_scan' ? context.l10n.adminLibraryScan : j.kind),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (j.message != null) Text(j.message!),
                              if (j.isActive) ...[
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: j.status == 'running' && j.progress > 0 ? j.progress : null,
                                ),
                              ],
                            ],
                          ),
                          trailing: Text(
                            _dateTime(context, j.createdAt),
                            style: const TextStyle(color: Palette.textMuted, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _dateTime(BuildContext context, DateTime d) {
  final l = d.toLocal();
  return '${MaterialLocalizations.of(context).formatShortDate(l)} ${TimeOfDay.fromDateTime(l).format(context)}';
}

/// Progress of the optional vocal detection, below the AutoMix analysis; nothing while it is off.
class _VocalAnalysisStatus extends ConsumerWidget {
  const _VocalAnalysisStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(_vocalAnalysisStatusProvider).value;
    if (s == null || s['enabled'] != true) return const SizedBox.shrink();
    final numbers = NumberFormat.decimalPattern(context.l10n.localeName);
    final total = s['total'] as int;
    final analyzed = s['analyzed'] as int;
    // Servers before 1.7.9 count failed songs as analyzed and send no failed count.
    final failed = (s['failed'] as int?) ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          switch (s['state']) {
            'installing' => const LinearProgressIndicator(),
            'failed' => const SizedBox.shrink(),
            _ => LinearProgressIndicator(value: total == 0 ? 0 : ((analyzed + failed) / total).clamp(0.0, 1.0)),
          },
          const SizedBox(height: 8),
          Text(switch (s['state']) {
            'installing' => context.l10n.adminVocalAnalysisInstalling,
            'failed' => context.l10n.adminVocalAnalysisFailed('${s['message'] ?? ''}'),
            _ =>
              context.l10n.adminVocalAnalysisProgress(numbers.format(analyzed), numbers.format(total)) +
                  (failed > 0 ? context.l10n.adminMixAnalysisFailed(numbers.format(failed)) : ''),
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(8)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Palette.textMuted)),
      ],
    ),
  );
}

// --- users -------------------------------------------------------------------

final _usersProvider = FutureProvider.autoDispose<List<User>>((ref) => ref.watch(apiProvider).users());

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(_usersProvider);
    final me = ref.watch(currentUserIdProvider);
    final api = ref.read(apiProvider);

    Future<void> run(Future<void> Function() fn) async {
      try {
        await fn();
        ref.invalidate(_usersProvider);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return AsyncBody(
      value: users,
      builder: (list) => ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, kBottomInset),
        children: [
          for (final u in list)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: parseHexColor(u.accentColor),
                child: Text(
                  u.displayName.characters.first.toUpperCase(),
                  style: TextStyle(color: onColor(parseHexColor(u.accentColor))),
                ),
              ),
              title: Text('${u.displayName}${u.id == me ? context.l10n.adminUserYouSuffix : ''}'),
              subtitle: Text(
                '@${u.username} • ${u.isAdmin ? context.l10n.navAdmin : context.l10n.adminUserRole}${u.isDisabled ? context.l10n.adminUserDisabledSuffix : ''}${u.lastSeenAt != null ? context.l10n.adminUserLastSeenSuffix((_dateTime(context, u.lastSeenAt!)).toString()) : ''}',
              ),
              trailing: PopupMenuButton<String>(
                useRootNavigator: true,
                onSelected: (v) async {
                  switch (v) {
                    case 'role':
                      await run(() => api.updateUser(u.id, {'role': u.isAdmin ? 'user' : 'admin'}));
                    case 'disable':
                      await run(() => api.updateUser(u.id, {'is_disabled': !u.isDisabled}));
                    case 'password':
                      final pw = await _ask(context, context.l10n.adminNewPasswordFor((u.username).toString()));
                      if (pw != null && pw.length >= 8) {
                        await run(() => api.updateUser(u.id, {'new_password': pw}));
                        if (context.mounted) showInfo(context, context.l10n.adminPasswordSet);
                      }
                    case 'delete':
                      final ok = await _confirm(
                        context,
                        context.l10n.adminDeleteUserTitle((u.username).toString()),
                        context.l10n.adminDeleteUserHint,
                      );
                      if (ok) await run(() => api.deleteUser(u.id));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'role',
                    child: Text(u.isAdmin ? context.l10n.adminRemoveAdmin : context.l10n.adminMakeAdmin),
                  ),
                  PopupMenuItem(
                    value: 'disable',
                    child: Text(u.isDisabled ? context.l10n.adminEnableUser : context.l10n.adminDisableUser),
                  ),
                  PopupMenuItem(value: 'password', child: Text(context.l10n.adminResetPassword)),
                  if (u.id != me) PopupMenuItem(value: 'delete', child: Text(context.l10n.commonDelete)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<String?> _ask(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        obscureText: true,
        decoration: InputDecoration(labelText: context.l10n.adminPasswordMinimum),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: Text(context.l10n.commonSave)),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(context.l10n.commonDelete)),
        ],
      ),
    ) ??
    false;

// --- invites -----------------------------------------------------------------

final _invitesProvider = FutureProvider.autoDispose<List<Invite>>((ref) => ref.watch(apiProvider).invites());

class _InvitesTab extends ConsumerWidget {
  const _InvitesTab();

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final note = TextEditingController();
    var role = 'user';
    int? hours = 72;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(context.l10n.adminCreateInviteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: note,
                decoration: InputDecoration(labelText: context.l10n.adminInviteNote),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: hours,
                decoration: InputDecoration(labelText: context.l10n.adminInviteValidity),
                items: [
                  DropdownMenuItem(value: 24, child: Text(context.l10n.adminInviteOneDay)),
                  DropdownMenuItem(value: 72, child: Text(context.l10n.adminInviteThreeDays)),
                  DropdownMenuItem(value: 168, child: Text(context.l10n.adminInviteSevenDays)),
                  DropdownMenuItem(value: 720, child: Text(context.l10n.adminInviteThirtyDays)),
                  DropdownMenuItem(value: null, child: Text(context.l10n.adminInviteUnlimited)),
                ],
                onChanged: (v) => setState(() => hours = v),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.adminInviteAsAdmin),
                value: role == 'admin',
                onChanged: (v) => setState(() => role = v ? 'admin' : 'user'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(context.l10n.commonCreate)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final invite = await ref
          .read(apiProvider)
          .createInvite(note: note.text.trim().isEmpty ? null : note.text.trim(), role: role, expiresInHours: hours);
      ref.invalidate(_invitesProvider);
      final link = '${ref.read(sessionProvider).serverUrl}/register?invite=${invite.token}';
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(context.l10n.adminInviteLink),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.adminInviteLinkHint, style: TextStyle(color: Palette.textMuted)),
              const SizedBox(height: 12),
              SelectableText(link),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                showInfo(context, context.l10n.adminLinkCopied);
              },
              child: Text(context.l10n.commonCopy),
            ),
            FilledButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonDone)),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(_invitesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: isWide(context) ? 0 : 72),
        child: FloatingActionButton.extended(
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add_link),
          label: Text(context.l10n.adminNewInvite),
        ),
      ),
      body: AsyncBody(
        value: invites,
        builder: (list) => list.isEmpty
            ? Center(
                child: Text(
                  context.l10n.adminNoInvites,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.textMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, kBottomInset + 72),
                children: [
                  for (final i in list)
                    ListTile(
                      leading: Icon(
                        i.isUsed ? Icons.how_to_reg : (i.isExpired ? Icons.timer_off : Icons.link),
                        color: i.isUsed || i.isExpired ? Palette.textMuted : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(i.note ?? context.l10n.adminInvitation),
                      subtitle: Text(
                        i.isUsed
                            ? context.l10n.adminInviteUsed(
                                (i.usedBy ?? '?').toString(),
                                (_dateTime(context, i.usedAt!)).toString(),
                              )
                            : i.isExpired
                            ? context.l10n.adminInviteExpired
                            : context.l10n.adminInviteOpen(
                                (i.expiresAt == null
                                        ? context.l10n.adminInviteNoExpiry
                                        : context.l10n.adminInviteExpires(
                                            (_dateTime(context, i.expiresAt!)).toString(),
                                          ))
                                    .toString(),
                                (i.role == 'admin' ? context.l10n.adminInviteAdminSuffix : '').toString(),
                              ),
                      ),
                      trailing: IconButton(
                        tooltip: context.l10n.commonDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(apiProvider).deleteInvite(i.id);
                          ref.invalidate(_invitesProvider);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// --- server settings ---------------------------------------------------------

final _configProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) => ref.watch(apiProvider).adminConfig());

class _ServerTab extends ConsumerWidget {
  const _ServerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(_configProvider);

    Future<void> patch(Map<String, dynamic> p) async {
      try {
        await ref.read(apiProvider).patchAdminConfig(p);
        ref.invalidate(_configProvider);
      } catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return AsyncBody(
      value: config,
      builder: (c) {
        final reg = c['registration'] as Map;
        final radio = c['radio'] as Map;
        final mixes = (c['mixes'] ?? const {}) as Map;
        final dl = c['downloads'] as Map;
        final lib = (c['library'] ?? const {}) as Map;
        final lyrics = (c['lyrics'] ?? const {}) as Map;
        final abs = (c['audiobookshelf'] ?? const {}) as Map;
        final books = (c['books'] ?? const {}) as Map;
        final spotify = (c['spotify'] ?? const {}) as Map;
        final integrations = (c['integrations'] ?? const {}) as Map;
        return ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, kBottomInset),
          children: [
            ListTile(
              title: Text(context.l10n.adminServerName),
              subtitle: Text(c['server_name']),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final ctrl = TextEditingController(text: c['server_name']);
                final name = await showDialog<String>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(context.l10n.adminServerName),
                    content: TextField(controller: ctrl, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, ctrl.text.trim()),
                        child: Text(context.l10n.commonSave),
                      ),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty) await patch({'server_name': name});
              },
            ),
            _Group(context.l10n.adminRegistration),
            RadioGroup<String>(
              groupValue: reg['mode'],
              onChanged: (v) => patch({
                'registration': {'mode': v},
              }),
              child: Column(
                children: [
                  RadioListTile(
                    value: 'invite',
                    title: Text(context.l10n.adminRegistrationInviteOnly),
                    subtitle: Text(context.l10n.adminRegistrationInviteHint),
                  ),
                  RadioListTile(
                    value: 'public',
                    title: Text(context.l10n.adminRegistrationPublic),
                    subtitle: Text(context.l10n.adminRegistrationPublicHint),
                  ),
                ],
              ),
            ),
            _Group(context.l10n.adminLibraryImport),
            ListTile(
              title: Text(context.l10n.adminAcoustIdKey),
              subtitle: Text(
                (lib['acoustid_api_key'] ?? '').isEmpty
                    ? context.l10n.adminAcoustIdNotSet
                    : context.l10n.adminConfigured,
              ),
              trailing: _EditTrailing(check: (lib['acoustid_api_key'] ?? '').isEmpty ? null : 'acoustid'),
              onTap: () async {
                final ctrl = TextEditingController(text: lib['acoustid_api_key'] ?? '');
                final key = await showDialog<String>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(context.l10n.adminAcoustIdKey),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: InputDecoration(helperText: context.l10n.adminAcoustIdHint),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
                      FilledButton(
                        onPressed: () => Navigator.pop(d, ctrl.text.trim()),
                        child: Text(context.l10n.commonSave),
                      ),
                    ],
                  ),
                );
                if (key != null) {
                  await patch({
                    'library': {'acoustid_api_key': key},
                  });
                }
              },
            ),
            _LibraryKeyTile(
              field: 'discogs_token',
              check: 'discogs',
              title: context.l10n.adminDiscogsToken,
              helper: context.l10n.adminDiscogsHint,
              value: lib['discogs_token'] ?? '',
              patch: patch,
            ),
            _LibraryKeyTile(
              field: 'lastfm_api_key',
              check: 'lastfm',
              title: context.l10n.adminLastfmKey,
              helper: context.l10n.adminLastfmHint,
              value: lib['lastfm_api_key'] ?? '',
              patch: patch,
            ),
            _LibraryKeyTile(
              field: 'fanarttv_api_key',
              check: 'fanarttv',
              title: context.l10n.adminFanartKey,
              value: lib['fanarttv_api_key'] ?? '',
              patch: patch,
            ),
            _GenreFill(configured: (lib['lastfm_api_key'] ?? '').isNotEmpty),
            RadioGroup<String>(
              groupValue: lib['import_mode'] ?? 'move',
              onChanged: (v) => patch({
                'library': {'import_mode': v},
              }),
              child: Column(
                children: [
                  RadioListTile(
                    value: 'move',
                    title: Text(context.l10n.adminMoveImportedFiles),
                    subtitle: Text(context.l10n.adminMoveImportedFilesHint),
                  ),
                  RadioListTile(
                    value: 'copy',
                    title: Text(context.l10n.adminCopyImportedFiles),
                    subtitle: Text(context.l10n.adminCopyImportedFilesHint),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminImportUnidentifiedFiles),
              subtitle: Text(context.l10n.adminImportUnidentifiedFilesHint),
              value: lib['import_unidentified'] ?? true,
              onChanged: (v) => patch({
                'library': {'import_unidentified': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminAutoImport),
              subtitle: Text(context.l10n.adminAutoImportHint),
              value: lib['auto_import'] ?? true,
              onChanged: (v) => patch({
                'library': {'auto_import': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminVocalAnalysis),
              subtitle: Text(context.l10n.adminVocalAnalysisHint),
              isThreeLine: true,
              value: lib['vocal_analysis'] ?? false,
              onChanged: (v) async {
                await patch({
                  'library': {'vocal_analysis': v},
                });
                ref.invalidate(_vocalAnalysisStatusProvider);
              },
            ),
            SwitchListTile(
              title: Text(context.l10n.adminLyricsOnline),
              subtitle: Text(context.l10n.adminLyricsOnlineHint),
              value: lib['lyrics_online'] ?? true,
              onChanged: (v) => patch({
                'library': {'lyrics_online': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminLyricsBackgroundFetch),
              value: lyrics['background_fetch'] ?? true,
              onChanged: (v) => patch({
                'lyrics': {'background_fetch': v},
              }),
            ),
            _Group(context.l10n.adminMixes),
            SwitchListTile(
              title: Text(context.l10n.discoverWeekly),
              subtitle: Text(context.l10n.adminDiscoverWeeklyHint),
              value: mixes['discover_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'discover_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminDiscoverSize,
              value: mixes['discover_size'] ?? 50,
              enabled: mixes['discover_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'discover_size': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminDiscoverDownloads,
              value: mixes['discover_downloads'] ?? 20,
              enabled: mixes['discover_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'discover_downloads': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.releaseRadar),
              subtitle: Text(context.l10n.adminReleaseRadarHint),
              value: mixes['release_radar_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'release_radar_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminReleaseRadarSize,
              value: mixes['release_radar_size'] ?? 30,
              enabled: mixes['release_radar_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'release_radar_size': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminDiscoverDownloads,
              value: mixes['release_radar_downloads'] ?? 20,
              enabled: mixes['release_radar_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'release_radar_downloads': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminChartsEnabled),
              subtitle: Text(context.l10n.adminChartsEnabledHint),
              value: mixes['charts_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'charts_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminChartsDownloads,
              value: mixes['charts_downloads'] ?? 100,
              enabled: mixes['charts_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'charts_downloads': v.clamp(0, 100)},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminEditorialEnabled),
              value: mixes['editorial_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'editorial_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminEditorialDownloads,
              value: mixes['editorial_downloads'] ?? 20,
              enabled: mixes['editorial_enabled'] ?? true,
              onChanged: (v) => patch({
                'mixes': {'editorial_downloads': v.clamp(0, 100)},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminEditorialYears),
              value: mixes['editorial_years'] ?? true,
              onChanged: (mixes['editorial_enabled'] ?? true)
                  ? (v) => patch({
                      'mixes': {'editorial_years': v},
                    })
                  : null,
            ),
            _Group(context.l10n.adminSongRadio),
            SwitchListTile(
              title: Text(context.l10n.adminRadioAutoDownload),
              subtitle: Text(context.l10n.adminRadioAutoDownloadHint),
              value: radio['auto_download_enabled'],
              onChanged: (v) => patch({
                'radio': {'auto_download_enabled': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminRadioTemporary),
              subtitle: Text(context.l10n.adminRadioTemporaryHint(radio['temporary_retention_days'])),
              value: radio['temporary_tracks_enabled'],
              onChanged: (v) => patch({
                'radio': {'temporary_tracks_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminRadioRetention,
              value: radio['temporary_retention_days'],
              enabled: radio['temporary_tracks_enabled'],
              onChanged: (v) => patch({
                'radio': {'temporary_retention_days': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminRadioMaxDownloads,
              value: radio['max_downloads_per_radio'] ?? 10,
              enabled: radio['auto_download_enabled'],
              onChanged: (v) => patch({
                'radio': {'max_downloads_per_radio': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminRadioPlaylistRetention,
              value: radio['playlist_retention_days'] ?? 30,
              onChanged: (v) => patch({
                'radio': {'playlist_retention_days': v},
              }),
            ),
            _Group(context.l10n.navAudiobooks),
            SwitchListTile(
              title: Text(context.l10n.adminEnableAudiobookshelf),
              subtitle: Text(context.l10n.adminEnableAudiobookshelfHint),
              value: abs['enabled'] ?? false,
              onChanged: (v) async {
                await patch({
                  'audiobookshelf': {'enabled': v},
                });
                ref.invalidate(absStatusProvider);
              },
            ),
            if (abs['enabled'] ?? false) ...[
              _TextTile(
                title: context.l10n.adminAudiobookshelfAddress,
                value: abs['url'] ?? '',
                hint: context.l10n.adminAudiobookshelfAddressHint,
                onChanged: (v) async {
                  await patch({
                    'audiobookshelf': {'url': v},
                  });
                  ref.invalidate(absStatusProvider);
                },
              ),
              const _AbsCheckTile(),
            ],
            _Group(context.l10n.booksEbooks),
            SwitchListTile(
              title: Text(context.l10n.adminBooksEnable),
              subtitle: Text(context.l10n.adminBooksEnableHint),
              value: books['enabled'] ?? false,
              onChanged: (v) async {
                await patch({
                  'books': {'enabled': v},
                });
                ref.invalidate(booksStatusProvider);
              },
            ),
            if (books['enabled'] ?? false) ...[
              ListTile(
                title: Text(context.l10n.adminBooksLanguage),
                subtitle: Text(context.l10n.adminBooksTorrentsHint),
                trailing: DropdownButton<String>(
                  value: books['default_language'] ?? 'de',
                  items: [
                    DropdownMenuItem(value: 'de', child: Text(context.l10n.booksLanguageDe)),
                    DropdownMenuItem(value: 'en', child: Text(context.l10n.booksLanguageEn)),
                    DropdownMenuItem(value: 'any', child: Text(context.l10n.booksLanguageAny)),
                  ],
                  onChanged: (v) async {
                    await patch({
                      'books': {'default_language': v},
                    });
                    ref.invalidate(booksStatusProvider);
                  },
                ),
              ),
              _NumberTile(
                title: context.l10n.adminBooksDailyLimit,
                value: books['daily_limit_per_user'] ?? 10,
                onChanged: (v) => patch({
                  'books': {'daily_limit_per_user': v},
                }),
              ),
              _TextTile(
                title: context.l10n.adminBooksGoogleKey,
                value: books['google_books_api_key'] ?? '',
                secret: true,
                hint: context.l10n.adminBooksGoogleKeyHint,
                onChanged: (v) => patch({
                  'books': {'google_books_api_key': v},
                }),
              ),
              const _BooksCheckTile(),
            ],
            _Group(context.l10n.adminIntegrations),
            _TextTile(
              title: context.l10n.adminDiscordClientId,
              value: integrations['discord_client_id'] ?? '',
              check: (integrations['discord_client_id'] ?? '').isEmpty ? null : 'discord',
              hint: context.l10n.adminDiscordClientIdHint,
              onChanged: (v) async {
                await patch({
                  'integrations': {'discord_client_id': v},
                });
                if (isDiscordDesktop) ref.invalidate(discordClientIdProvider);
              },
            ),
            _Group(context.l10n.adminSpotifyGroup),
            _TextTile(
              title: context.l10n.adminSpotifyClientId,
              value: spotify['client_id'] ?? '',
              hint: context.l10n.adminSpotifyHint('${ref.read(sessionProvider).serverUrl}/api/spotify/callback'),
              onChanged: (v) => patch({
                'spotify': {'client_id': v},
              }),
            ),
            _TextTile(
              title: context.l10n.adminSpotifyClientSecret,
              value: spotify['client_secret'] ?? '',
              check: (spotify['client_secret'] ?? '').isEmpty ? null : 'spotify',
              secret: true,
              onChanged: (v) => patch({
                'spotify': {'client_secret': v},
              }),
            ),
            _Group(context.l10n.navDownloads),
            SwitchListTile(
              title: Text(context.l10n.adminAlbumTorrents),
              subtitle: Text(context.l10n.adminAlbumTorrentsHint),
              value: dl['torrent_enabled'] ?? false,
              onChanged: (v) => patch({
                'downloads': {'torrent_enabled': v},
              }),
            ),
            if (dl['torrent_enabled'] ?? false) ...[
              _TextTile(
                title: context.l10n.adminProwlarrApiKey,
                value: dl['prowlarr_api_key'] ?? '',
                secret: true,
                hint: context.l10n.adminProwlarrApiKeyHint,
                onChanged: (v) => patch({
                  'downloads': {'prowlarr_api_key': v},
                }),
              ),
              _TextTile(
                title: context.l10n.adminQbittorrentUsername,
                value: dl['qbittorrent_username'] ?? '',
                onChanged: (v) => patch({
                  'downloads': {'qbittorrent_username': v},
                }),
              ),
              _TextTile(
                title: context.l10n.adminQbittorrentPassword,
                value: dl['qbittorrent_password'] ?? '',
                secret: true,
                onChanged: (v) => patch({
                  'downloads': {'qbittorrent_password': v},
                }),
              ),
              _NumberTile(
                title: context.l10n.adminMinimumSeeders,
                value: dl['torrent_min_seeders'] ?? 1,
                onChanged: (v) => patch({
                  'downloads': {'torrent_min_seeders': v},
                }),
              ),
              _NumberTile(
                title: context.l10n.adminTorrentTimeout,
                value: dl['torrent_timeout_minutes'] ?? 60,
                onChanged: (v) => patch({
                  'downloads': {'torrent_timeout_minutes': v},
                }),
              ),
              _NumberTile(
                title: context.l10n.adminTorrentSeedDays,
                subtitle: context.l10n.adminTorrentSeedDaysHint,
                value: dl['torrent_seed_days'] ?? 7,
                onChanged: (v) => patch({
                  'downloads': {'torrent_seed_days': v},
                }),
              ),
              const _TorrentCheckTile(),
            ],
            SwitchListTile(
              title: Text(context.l10n.adminYouTubeSource),
              subtitle: Text(context.l10n.adminYouTubeSourceHint),
              value: dl['youtube_enabled'] ?? true,
              onChanged: (v) => patch({
                'downloads': {'youtube_enabled': v},
              }),
            ),
            if (dl['youtube_enabled'] ?? true) const _YouTubeCookiesTile(),
            SwitchListTile(
              title: Text(context.l10n.adminSoundCloudSource),
              subtitle: Text(context.l10n.adminSoundCloudSourceHint),
              value: dl['soundcloud_enabled'] ?? true,
              onChanged: (v) => patch({
                'downloads': {'soundcloud_enabled': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminBandcampSource),
              subtitle: Text(context.l10n.adminBandcampSourceHint),
              value: dl['bandcamp_enabled'] ?? true,
              onChanged: (v) => patch({
                'downloads': {'bandcamp_enabled': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminQualityUpgrades),
              subtitle: Text(context.l10n.adminQualityUpgradesHint),
              value: dl['quality_upgrade_enabled'],
              onChanged: (v) => patch({
                'downloads': {'quality_upgrade_enabled': v},
              }),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  try {
                    await ref.read(apiProvider).runQualityUpgrades();
                    if (context.mounted) showInfo(context, context.l10n.adminQualityUpgradeStarted);
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                },
                child: Text(context.l10n.adminQualityUpgradeSearchNow),
              ),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminAutoApprove),
              subtitle: Text(context.l10n.adminAutoApproveHint),
              value: dl['auto_approve_requests'],
              onChanged: (v) => patch({
                'downloads': {'auto_approve_requests': v},
              }),
            ),
            SwitchListTile(
              title: Text(context.l10n.adminDailyLimit),
              subtitle: Text(context.l10n.adminDailyLimitHint(dl['daily_limit_per_user'])),
              value: dl['daily_limit_enabled'],
              onChanged: (v) => patch({
                'downloads': {'daily_limit_enabled': v},
              }),
            ),
            _NumberTile(
              title: context.l10n.adminDownloadsPerDay,
              value: dl['daily_limit_per_user'],
              enabled: dl['daily_limit_enabled'],
              onChanged: (v) => patch({
                'downloads': {'daily_limit_per_user': v},
              }),
            ),
          ],
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });
  final String title;
  final String? subtitle;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: Text('$value', style: Theme.of(context).textTheme.titleMedium),
    onTap: () async {
      final ctrl = TextEditingController(text: '$value');
      final result = await showDialog<int>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
            FilledButton(
              onPressed: () => Navigator.pop(d, int.tryParse(ctrl.text)),
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      );
      if (result != null) onChanged(result);
    },
  );
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.secret = false,
    this.hint,
    this.check,
  });
  final String title;
  final String value;
  final bool secret;
  final String? hint;
  final ValueChanged<String> onChanged;

  /// Service whose key [ApiClient.checkKey] can test, shown as a button next to the edit icon.
  final String? check;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(value.isEmpty ? context.l10n.adminNotConfigured : (secret ? '••••••••' : value)),
    trailing: _EditTrailing(check: check),
    onTap: () async {
      final ctrl = TextEditingController(text: value);
      final result = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: secret,
            decoration: InputDecoration(helperText: hint, helperMaxLines: 5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: Text(context.l10n.commonSave)),
          ],
        ),
      );
      if (result != null) onChanged(result);
    },
  );
}

/// The edit icon of a settings tile, with a button that tests the saved key when [check] names its service.
class _EditTrailing extends ConsumerStatefulWidget {
  const _EditTrailing({this.check});
  final String? check;

  @override
  ConsumerState<_EditTrailing> createState() => _EditTrailingState();
}

class _EditTrailingState extends ConsumerState<_EditTrailing> {
  bool _busy = false;
  bool? _ok;

  @override
  void didUpdateWidget(_EditTrailing old) {
    super.didUpdateWidget(old);
    // A new key has not been tested yet.
    if (old.check != widget.check) _ok = null;
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).checkKey(widget.check!);
      if (!mounted) return;
      setState(() => _ok = r['ok'] == true);
      showInfo(context, '${r['message'] ?? ''}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.check == null) return const Icon(Icons.edit);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.adminTestKey,
          onPressed: _busy ? null : _check,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : switch (_ok) {
                  true => Icon(Icons.check_circle, color: scheme.primary),
                  false => Icon(Icons.error_outline, color: scheme.error),
                  null => const Icon(Icons.network_check),
                },
        ),
        const SizedBox(width: 4),
        const Icon(Icons.edit),
      ],
    );
  }
}

/// Checks the Prowlarr / qBittorrent connection with the saved credentials.
class _AbsCheckTile extends ConsumerStatefulWidget {
  const _AbsCheckTile();

  @override
  ConsumerState<_AbsCheckTile> createState() => _AbsCheckTileState();
}

class _AbsCheckTileState extends ConsumerState<_AbsCheckTile> {
  Map<String, dynamic>? _result;
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).absAdminStatus();
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _result?['ok'] == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check),
            label: Text(context.l10n.adminTestConnection),
          ),
          if (_result != null) ...[
            const SizedBox(width: 12),
            Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              size: 18,
              color: ok ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('${_result!['message'] ?? ''}')),
          ],
        ],
      ),
    );
  }
}

class _YouTubeCookiesTile extends ConsumerStatefulWidget {
  const _YouTubeCookiesTile();

  @override
  ConsumerState<_YouTubeCookiesTile> createState() => _YouTubeCookiesTileState();
}

class _YouTubeCookiesTileState extends ConsumerState<_YouTubeCookiesTile> {
  Map<String, dynamic>? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _run(() => ref.read(apiProvider).youtubeCookies());
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      final status = await action();
      if (!mounted) return;
      setState(() => _status = status);
      if (done != null) showInfo(context, done);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['txt']);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _run(() => ref.read(apiProvider).uploadYoutubeCookies(bytes), done: context.l10n.adminYouTubeCookiesSaved);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final uploaded = DateTime.tryParse(status?['uploaded_at'] ?? '')?.toLocal();
    final fromEnv = status?['from_env'] == true;
    final expired = status?['expired'] == true;
    final configured = status?['configured'] == true && !expired;
    final state = expired
        ? context.l10n.adminYouTubeCookiesExpired
        : fromEnv
        ? context.l10n.adminYouTubeCookiesFromEnv
        : uploaded != null
        ? context.l10n.adminYouTubeCookiesActive(MaterialLocalizations.of(context).formatMediumDate(uploaded))
        : context.l10n.adminYouTubeCookiesNone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.adminYouTubeCookies, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(context.l10n.adminYouTubeCookiesHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (status != null)
            Row(
              children: [
                Icon(
                  expired
                      ? Icons.error_outline
                      : configured
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 18,
                  color: expired
                      ? Theme.of(context).colorScheme.error
                      : configured
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(state)),
              ],
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || fromEnv ? null : _upload,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: Text(context.l10n.adminYouTubeCookiesUpload),
              ),
              if (uploaded != null && !fromEnv)
                TextButton(
                  onPressed: _busy ? null : () => _run(() => ref.read(apiProvider).deleteYoutubeCookies()),
                  child: Text(context.l10n.adminYouTubeCookiesRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TorrentCheckTile extends ConsumerStatefulWidget {
  const _TorrentCheckTile();

  @override
  ConsumerState<_TorrentCheckTile> createState() => _TorrentCheckTileState();
}

class _TorrentCheckTileState extends ConsumerState<_TorrentCheckTile> {
  Map<String, dynamic>? _result;
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).torrentStatus();
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget line(String name, Map? r) {
      final ok = r?['ok'] == true;
      return Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: ok ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$name: ${r?['message'] ?? ''}')),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check),
            label: Text(context.l10n.adminTestConnection),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            line(context.l10n.adminProwlarr, _result!['prowlarr'] as Map?),
            const SizedBox(height: 4),
            line(context.l10n.adminQbittorrent, _result!['qbittorrent'] as Map?),
          ],
        ],
      ),
    );
  }
}

/// Checks the metadata sources and the library folder.
class _BooksCheckTile extends ConsumerStatefulWidget {
  const _BooksCheckTile();

  @override
  ConsumerState<_BooksCheckTile> createState() => _BooksCheckTileState();
}

class _BooksCheckTileState extends ConsumerState<_BooksCheckTile> {
  Map<String, dynamic>? _result;
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).booksAdminStatus();
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _check,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check),
            label: Text(context.l10n.adminTestConnection),
          ),
          for (final entry in (_result ?? const {}).entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    entry.value['ok'] == true ? Icons.check_circle : Icons.error_outline,
                    size: 18,
                    color: entry.value['ok'] == true ? theme.colorScheme.primary : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${switch (entry.key) {
                        'google' => 'Google Books',
                        'audible' => 'Audible',
                        _ => context.l10n.booksEbooks,
                      }}: ${entry.value['message'] ?? ''}',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryKeyTile extends StatelessWidget {
  const _LibraryKeyTile({
    required this.field,
    required this.title,
    required this.value,
    required this.patch,
    this.helper,
    this.check,
  });
  final String field;
  final String title;
  final String value;
  final String? helper;
  final String? check;
  final Future<void> Function(Map<String, dynamic>) patch;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Text(value.isEmpty ? (helper ?? context.l10n.adminAcoustIdNotSet) : context.l10n.adminConfigured),
    trailing: _EditTrailing(check: value.isEmpty ? null : check),
    onTap: () async {
      final ctrl = TextEditingController(text: value);
      final key = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(helperText: helper, helperMaxLines: 2),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(context.l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(d, ctrl.text.trim()), child: Text(context.l10n.commonSave)),
          ],
        ),
      );
      if (key != null) {
        await patch({
          'library': {field: key},
        });
      }
    },
  );
}

class _GenreFill extends ConsumerStatefulWidget {
  const _GenreFill({required this.configured});
  final bool configured;

  @override
  ConsumerState<_GenreFill> createState() => _GenreFillState();
}

class _GenreFillState extends ConsumerState<_GenreFill> {
  Job? _job;
  Timer? _timer;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _poll() {
    _timer?.cancel();
    if (_job?.isActive ?? false) _timer = Timer(const Duration(seconds: 1), _refresh);
  }

  Future<void> _refresh() async {
    try {
      final job = await ref.read(apiProvider).genreFillStatus();
      if (!mounted) return;
      setState(() => _job = job);
      _poll();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final job = await ref.read(apiProvider).fillGenres();
      if (!mounted) return;
      setState(() => _job = job);
      _poll();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(context.l10n.adminFillGenres),
    subtitle: _job == null ? null : Text(_job!.message ?? ''),
    trailing: _starting || (_job?.isActive ?? false)
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.auto_fix_high),
    enabled: widget.configured && !_starting && !(_job?.isActive ?? false),
    onTap: _start,
  );
}
