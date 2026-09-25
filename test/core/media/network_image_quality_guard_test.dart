import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all network images use production rendering quality', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      final calls = _extractImageNetworkCalls(source);

      for (var index = 0; index < calls.length; index += 1) {
        final call = calls[index];

        expect(
          call.contains('filterQuality: FilterQuality.high'),
          isTrue,
          reason:
              '${file.path}: Image.network #${index + 1} must use FilterQuality.high',
        );

        expect(
          call.contains('cacheHeight:'),
          isFalse,
          reason:
              '${file.path}: Image.network #${index + 1} must preserve source aspect ratio and not force cacheHeight',
        );
      }
    }
  });
}

List<String> _extractImageNetworkCalls(String source) {
  const marker = 'Image.network(';
  final calls = <String>[];
  var searchFrom = 0;

  while (true) {
    final start = source.indexOf(marker, searchFrom);
    if (start < 0) break;

    var depth = 1;
    var index = start + marker.length;
    String? quote;
    var escaped = false;

    while (index < source.length && depth > 0) {
      final char = source[index];

      if (quote != null) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == quote) {
          quote = null;
        }

        index += 1;
        continue;
      }

      if (char == "'" || char == '"') {
        quote = char;
      } else if (char == '(') {
        depth += 1;
      } else if (char == ')') {
        depth -= 1;
      }

      index += 1;
    }

    calls.add(source.substring(start, index));
    searchFrom = index;
  }

  return calls;
}
