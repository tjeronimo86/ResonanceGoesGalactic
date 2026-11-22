import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/core/session.dart';
import 'package:resonance/l10n/l10n.dart';
import 'package:resonance/player/player.dart';
import 'package:resonance/ui/pages/browse_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _track(String id, String title) => {
  'id': id,
  'title': title,
  'artist': {'id': 'queen', 'name': 'Queen'},
  'artist_credit': 'Queen',
  'album': {'id': 'opera', 'name': 'A Night at the Opera'},
  'duration': 354,
};

class _Player extends PlayerController {
  @override
  PlayerView build() => const PlayerView();
}

void main() {
  test('search results read the lyrics hits, and older servers without them still parse', () {
    final result = SearchResult.fromJson({
      'artists': [],
      'albums': [],
      'tracks': [],
      'lyrics': [
        {'track': _track('bohemian', 'Bohemian Rhapsody'), 'line': 'Is this the real life?'},
      ],
    });
    expect(result.lyrics.single.track.title, 'Bohemian Rhapsody');
    expect(result.lyrics.single.line, 'Is this the real life?');
    expect(result.isEmpty, isFalse, reason: 'a lyrics hit alone is a result');

    final old = SearchResult.fromJson({'artists': [], 'albums': [], 'tracks': []});
    expect(old.lyrics, isEmpty);
    expect(old.isEmpty, isTrue);
  });

  testWidgets('a lyrics hit shows the song with the line it was found in', (tester) async {
    var played = 0;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hit = LyricsHit(Track.fromJson(_track('bohemian', 'Bohemian Rhapsody')), 'Is this the real life?');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [playerProvider.overrideWith(_Player.new), prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LyricsHitRow(hit: hit, onPlay: () => played++),
          ),
        ),
      ),
    );
    expect(find.text('Bohemian Rhapsody'), findsOneWidget);
    expect(find.text('„Is this the real life?“'), findsOneWidget);
    await tester.tap(find.text('Bohemian Rhapsody'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(played, 1);
  });
}
