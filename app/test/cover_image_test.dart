import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/core/models.dart';
import 'package:resonance/ui/widgets/common.dart';

void main() {
  testWidgets('an empty album id shows the placeholder without loading a cover', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SizedBox(width: 48, child: CoverImage(albumId: '')),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  testWidgets('an album the server lists without a cover shows the placeholder without requesting one', (tester) async {
    noteCoverKey({'id': 'coverless', 'title': 'Album', 'cover_key': null});
    addTearDown(albumsWithoutCover.clear);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SizedBox(width: 48, child: CoverImage(albumId: 'coverless')),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.music_note), findsOneWidget);

    // A later listing with a cover clears the mark.
    noteCoverKey({'id': 'coverless', 'title': 'Album', 'cover_key': 'abc123'});
    expect(albumsWithoutCover, isEmpty);
  });
}
