// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter_test/flutter_test.dart';
import 'package:rxdata/rxdata.dart';

void main() {
  test('Data properly overrides equality', () {
    final data1 = Data(value: ['a', 'b']);
    final data2 = Data(value: ['a', 'b']);
    expect(data1 == data2, equals(true));
  });

  test('Data properly overrides hashCode', () {
    final data1 = Data(value: ['a', 'b']);
    final data2 = Data(value: ['a', 'b']);
    expect(data1.hashCode == data2.hashCode, equals(true));
  });
}
