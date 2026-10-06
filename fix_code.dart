import 'dart:io';

void main() {
  final directories = [Directory('lib'), Directory('test')];
  
  int withOpacityCount = 0;
  int fontWeightCount = 0;

  for (final dir in directories) {
    if (!dir.existsSync()) continue;
    
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = entity.readAsStringSync();
        bool changed = false;

        // Fix withOpacity
        final opacityRegex = RegExp(r'\.withOpacity\(([^)]+)\)');
        if (opacityRegex.hasMatch(content)) {
          content = content.replaceAllMapped(opacityRegex, (match) {
            withOpacityCount++;
            return '.withValues(alpha: ${match.group(1)})';
          });
          changed = true;
        }

        // Fix FontWeight.black
        if (content.contains('FontWeight.black')) {
          final fontMatches = 'FontWeight.black'.allMatches(content).length;
          fontWeightCount += fontMatches;
          content = content.replaceAll('FontWeight.black', 'FontWeight.w900');
          changed = true;
        }

        if (changed) {
          entity.writeAsStringSync(content);
        }
      }
    }
  }

  print('Replaced $withOpacityCount instances of withOpacity.');
  print('Replaced $fontWeightCount instances of FontWeight.black.');
}
