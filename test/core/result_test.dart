import 'package:flutter_test/flutter_test.dart';
import 'package:nutrease_flutter/core/error/domain_error.dart';
import 'package:nutrease_flutter/core/error/result.dart';

void main() {
  group('Result.fold', () {
    test('Ok routes to the ok branch', () {
      const Result<int> result = Ok(42);
      final folded = result.fold(ok: (v) => 'ok:$v', err: (e) => 'err');
      expect(folded, 'ok:42');
    });

    test('Err routes to the err branch', () {
      const Result<int> result = Err(NetworkError());
      final folded =
          result.fold(ok: (v) => 'ok', err: (e) => 'err:${e.message}');
      expect(folded, startsWith('err:'));
    });
  });
}
