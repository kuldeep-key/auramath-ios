import 'package:auramath/ui/core/parts/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every avatar id is one the server keeps, and none repeats', () {
    final ids = [for (final a in avatarChoices) a.id];
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(RegExp(r'^[a-z0-9_-]{1,32}$').hasMatch(id), isTrue, reason: id);
    }
  });

  testWidgets('the picker names each choice and says which is chosen', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarPicker(selected: 'key', onPick: (id) => picked = id),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Key')),
      isSemantics(isButton: true, isSelected: true),
    );
    await tester.tap(find.bySemanticsLabel('Compass'));
    expect(picked, 'map');
  });
}
