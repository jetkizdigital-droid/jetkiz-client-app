import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('network images keep quality rules for static and scrolling surfaces', () {
    final violations = <String>[];
    final scrollOptimizedPaths = <String>{
      'lib/features/home/presentation/homePage.dart',
      'lib/features/menu/presentation/categoryProductsPage.dart',
      'lib/features/menu/presentation/restaurantMenuPage.dart',
    };
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final normalizedPath = file.path.replaceAll(r'\', '/');
      final source = file.readAsStringSync();
      final calls = _extractImageNetworkCalls(source);
      final isScrollOptimized = scrollOptimizedPaths.contains(normalizedPath);

      for (var index = 0; index < calls.length; index += 1) {
        final call = calls[index];
        final label = '${file.path}: Image.network #${index + 1}';

        if (isScrollOptimized) {
          if (!call.contains('filterQuality: FilterQuality.low')) {
            violations.add(
              '$label must use FilterQuality.low on scrolling surfaces',
            );
          }

          if (!call.contains('cacheWidth:')) {
            violations.add(
              '$label must use bounded cacheWidth on scrolling surfaces',
            );
          }
        } else if (!call.contains('filterQuality: FilterQuality.high')) {
          violations.add('$label must use FilterQuality.high');
        }

        if (call.contains('cacheHeight:')) {
          violations.add(
            '$label must preserve source aspect ratio and not force cacheHeight',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.join('\n'),
    );
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
