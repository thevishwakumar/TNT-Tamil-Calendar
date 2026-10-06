import 'dart:io';

void main() {
  final file = File('analyze_errors_4.txt');
  final lines = file.readAsLinesSync();
  final counts = <String, int>{};

  for (final line in lines) {
    if (line.trim().startsWith('error -')) {
      final parts = line.split(' - ');
      if (parts.length >= 3) {
        final errorMsg = parts[1].trim();
        // Just extract the general error type (e.g. before the dash)
        counts[errorMsg] = (counts[errorMsg] ?? 0) + 1;
      }
    }
  }

  final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted.take(20)) {
    print('${entry.value}: ${entry.key}');
  }
}
