import 'package:finansy/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseAmount', () {
    expect(parseAmount('1 234,5'), 1234.5);
    expect(parseAmount(''), null);
  });

  test('week range starts on Monday by default', () {
    final r = rangeFor(PeriodKind.week, DateTime(2026, 11, 4));
    expect(r.start, DateTime(2026, 11, 2));
    expect(r.end, DateTime(2026, 11, 9));
  });

  test('custom month start', () {
    PeriodCfg.monthStartDay = 10;
    final r = rangeFor(PeriodKind.month, DateTime(2026, 11, 4));
    expect(r.start, DateTime(2026, 10, 10));
    PeriodCfg.monthStartDay = 1;
  });
}
