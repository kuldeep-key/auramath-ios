import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('lemon: fig tree 79, total 265', () {
    expect(lemon.bValue, 79);
    expect(lemon.total, 265);
  });

  test('shorter: fig tree 293, total 479', () {
    expect(shorter.bValue, 293);
    expect(shorter.total, 479);
  });

  test('mango: guava 84, total 236', () {
    expect(mango.bValue, 84);
    expect(mango.total, 236);
  });

  test('easier asks for the fig tree, 122', () {
    expect(easier.bValue, 122);
  });
}
