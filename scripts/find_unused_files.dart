// scripts/find_unused_files.dart
// Dart script to find Dart files in `lib/` that are not imported by other files.

import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('No lib/ directory found. Run from repo root.');
    exit(1);
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll('\\', '/'))
      .toList();

  final importsMap = <String, Set<String>>{};
  for (final file in dartFiles) {
    importsMap[file] = {};
  }

  for (final file in dartFiles) {
    final content = File(file).readAsStringSync();
    final regex = RegExp(r"import\s+['\"]([^'\"]+)['\"];?");
    for (final m in regex.allMatches(content)) {
      final imp = m.group(1)!;
      // normalize relative imports
      if (imp.startsWith('package:') || imp.startsWith('dart:')) continue;
      final candidate = Uri.file(File(file).parent.path + '/' + imp).normalizePath();
      final candidatePath = candidate.toFilePath();
      final normalized = candidatePath.replaceAll('\\', '/');
      if (importsMap.containsKey(normalized)) {
        importsMap[normalized]!.add(file);
      }
    }
  }

  // Files with zero inbound imports (excluding main.dart, app.dart, routes, and test helpers)
  final excluded = [
    'lib/main.dart',
    'lib/app.dart',
    'lib/routes/app_routes.dart',
  ];

  final unused = importsMap.entries
      .where((e) => e.value.isEmpty && !excluded.contains(e.key.replaceAll('\\','/')))
      .map((e) => e.key)
      .toList();

  if (unused.isEmpty) {
    print('No obviously-unused Dart files found (by import analysis).');
  } else {
    print('Potentially unused Dart files (no inbound imports detected):');
    for (final f in unused) {
      print(' - $f');
    }
    print('\nReview before deleting. Some files may be used via reflection, route strings, or assets.');
  }
}
