import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resonance/ui/tv/tv_settings_controls.dart';

FocusNode _node({required bool inSwitch}) => FocusManager.instance.rootScope.descendants.firstWhere((node) {
  final context = node.context;
  return context != null &&
      node.canRequestFocus &&
      node.skipTraversal != inSwitch &&
      context.findAncestorWidgetOfExactType<TvSettingsTile>() != null &&
      (context.findAncestorWidgetOfExactType<SwitchListTile>() != null) == inSwitch;
});

void main() {
  testWidgets('activating a settings tile that has the focus itself does not recurse', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TvSettingsTile(child: Text('Info'))),
      ),
    );
    final node = _node(inSwitch: false)..requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, node);

    Actions.invoke(FocusManager.instance.primaryFocus!.context!, const ActivateIntent());
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('activating a settings tile still reaches the focused control inside it', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TvSettingsTile(
              child: SwitchListTile(
                title: const Text('Switch'),
                value: toggled,
                onChanged: (value) => setState(() => toggled = value),
              ),
            ),
          ),
        ),
      ),
    );
    _node(inSwitch: true).requestFocus();
    await tester.pump();
    Actions.invoke(FocusManager.instance.primaryFocus!.context!, const ActivateIntent());
    await tester.pump();

    expect(toggled, isTrue);
  });
}
