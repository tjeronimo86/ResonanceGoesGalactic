import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/ui/widgets/common.dart';

void main() {
  Widget shell({required bool inPlayerArea}) {
    final button = Builder(
      builder: (context) => TextButton(onPressed: () => showInfo(context, 'Saved'), child: const Text('save')),
    );
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: inPlayerArea ? PlayerArea(child: button) : button),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: MeasureHeight(
                height: playerAreaHeight,
                child: const SizedBox(key: Key('player'), height: 70),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SizedBox(height: 64),
      ),
    );
  }

  testWidgets('messages from the shell\'s pages float above the player instead of covering it', (tester) async {
    await tester.pumpWidget(shell(inPlayerArea: true));
    expect(playerAreaHeight.value, 70);
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    final message = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
    final player = tester.getRect(find.byKey(const Key('player')));
    expect(message.bottom, lessThanOrEqualTo(player.top));
  });

  testWidgets('messages from outside the shell keep their usual place', (tester) async {
    await tester.pumpWidget(shell(inPlayerArea: false));
    await tester.tap(find.text('save'));
    await tester.pumpAndSettle();
    final message = tester.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
    final player = tester.getRect(find.byKey(const Key('player')));
    expect(message.bottom, greaterThan(player.top));
  });

  testWidgets('the player height drops to 0 when the player is gone', (tester) async {
    await tester.pumpWidget(shell(inPlayerArea: true));
    expect(playerAreaHeight.value, 70);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(playerAreaHeight.value, 0);
  });
}
