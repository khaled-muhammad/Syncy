import 'package:flutter_test/flutter_test.dart';
import 'package:syncy/services/lan/lan_host_service.dart';

void main() {
  const total = 1000;

  test('open-ended range serves from start to EOF', () {
    final r = computeByteRange('bytes=0-', total);
    expect(r, isNotNull);
    expect(r!.start, 0);
    expect(r.end, 999);
    expect(r.length, 1000);
  });

  test('closed range is inclusive of both ends', () {
    final r = computeByteRange('bytes=100-199', total)!;
    expect(r.start, 100);
    expect(r.end, 199);
    expect(r.length, 100);
  });

  test('a seek requests a mid-file open-ended range', () {
    final r = computeByteRange('bytes=500-', total)!;
    expect(r.start, 500);
    expect(r.end, 999);
  });

  test('suffix range returns the last N bytes', () {
    final r = computeByteRange('bytes=-200', total)!;
    expect(r.start, 800);
    expect(r.end, 999);
    expect(r.length, 200);
  });

  test('suffix larger than the file clamps to the whole file', () {
    final r = computeByteRange('bytes=-5000', total)!;
    expect(r.start, 0);
    expect(r.end, 999);
  });

  test('range past EOF is unsatisfiable', () {
    expect(computeByteRange('bytes=1000-1200', total), isNull);
    expect(computeByteRange('bytes=2000-', total), isNull);
  });

  test('inverted and malformed ranges are rejected', () {
    expect(computeByteRange('bytes=500-100', total), isNull);
    expect(computeByteRange('bytes=-', total), isNull);
    expect(computeByteRange('nonsense', total), isNull);
  });

  test('an empty file has no satisfiable range', () {
    expect(computeByteRange('bytes=0-', 0), isNull);
  });
}
