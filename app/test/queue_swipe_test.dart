import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/ui/widgets/track_list.dart';

class _Player extends PlayerController {
  final queued = <String>[];
  @override
  PlayerView build() => const PlayerView();
  @override
  Future<void> addToQueue(Track t) async => queued.add(t.id);
}

void main() {
  testWidgets('swiping a song to the right queues it and the row springs back', (tester) async {
    const track = Track(
      id: 'one',
      title: 'Song one',
      artist: NamedRef('a', 'Artist'),
      artistCredit: 'Artist',
      album: NamedRef('b', 'Album'),
      duration: 200,
    );
    final player = _Player();
    var removed = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerProvider.overrideWith(() => player)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QueueSwipe(
              track: track,
              onRemove: () => removed++,
              child: const SizedBox(height: 60, width: 400, child: Text('row')),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.text('row'), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(player.queued, isEmpty, reason: 'a short drag does nothing');
    await tester.drag(find.text('row'), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(player.queued, ['one']);
    expect(find.text('row'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing, reason: 'queueing a song needs no message');
    expect(removed, 0);
    await tester.drag(find.text('row'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(removed, 1, reason: 'swiping to the left takes the song out of the queue');
    expect(player.queued, ['one']);
    expect(find.text('row'), findsOneWidget);
  });
}
