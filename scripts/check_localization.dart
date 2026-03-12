#!/usr/bin/env dart
// Script to find potentially missing localizations in the Flutter app.
// Run from project root: dart run scripts/check_localization.dart
// Or: dart scripts/check_localization.dart

import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('Error: lib/ directory not found. Run from project root.');
    exit(1);
  }

  final patterns = [
    // Text('...') or Text("...")
    RegExp(r'''Text\s*\(\s*['"]([^'"]{4,})['"]'''),
    // toast('...')
    RegExp(r'''toast\s*\(\s*['"]([^'"]{4,})['"]'''),
    // title: '...'
    RegExp(r'''title:\s*['"]([^'"]{4,})['"]'''),
    // hintText: '...'
    RegExp(r'''hintText:\s*['"]([^'"]{4,})['"]'''),
    // labelText: '...'
    RegExp(r'''labelText:\s*['"]([^'"]{4,})['"]'''),
    // appBarTitle: '...'
    RegExp(r'''appBarTitle:\s*['"]([^'"]{4,})['"]'''),
    // subTitle: '...' or subtitle: '...'
    RegExp(r'''sub[Tt]itle:\s*['"]([^'"]{4,})['"]'''),
    // hint: Text('...')
    RegExp(r'''hint:\s*Text\s*\(\s*['"]([^'"]{4,})['"]'''),
    // return '...' (validation messages)
    RegExp(r'''return\s+['"]([^'"]{4,})['"]\s*;'''),
    // buttonText: '...'
    RegExp(r'''buttonText:\s*['"]([^'"]{4,})['"]'''),
    // positiveText: '...' / negativeText: '...'
    RegExp(r'''(?:positive|negative)Text:\s*['"]([^'"]{4,})['"]'''),
    // emptyWidget title etc
    RegExp(r'''emptyWidget:\s*\w+\([^)]*title:\s*['"]([^'"]{4,})['"]'''),
  ];

  // Strings that are OK (not user-facing or already interpolated)
  final skipPatterns = [
    RegExp(r'^[\s\-\.\,\:\;\|\*\#\>\<\=\+\/\\]+$'), // punctuation only
    RegExp(r'^\d+$'), // numbers only
    RegExp(r'^[a-z_]+\.[a-z_]+$'), // e.g. path.to.asset
    RegExp(r'^assets/'), // asset paths
    RegExp(r'^https?://'), // URLs
    RegExp(r'^[\w\.]+@[\w\.]+$'), // emails
    RegExp(r'^\$\s*'), // currency
    RegExp(r'^[A-Z][a-zA-Z]+Exception'), // exception names
    RegExp(r'^[A-Z][a-zA-Z]*Error$'), // error class names
    RegExp(r'^[a-z]+://'), // scheme
    RegExp(r'^[A-Z_]{2,}$'), // CONSTANTS
    RegExp(r'^[a-z]+\.[a-z]+$'), // key.path
    RegExp(r'^[A-Z][a-z]+\.'), // Class.
    RegExp(r'^[a-z]+\(\)$'), // method()
    RegExp(r'^[#\$].*'), // #id or $var
    RegExp(r'^[\%]\w'), // format
    RegExp(r'^[\d\.]+$'), // version numbers
    RegExp(r'^[a-z_]+$', caseSensitive: false), // single word (might be key)
    RegExp(r'^[HhMmSsZzadAy\:\s\.\-]+$'), // date/time format patterns e.g. HH:mm:ss, h:mm a
  ];

  final excludePaths = [
    'lib/locale/', // language files themselves
    'lib/generated/',
    '.g.dart',
    '.freezed.dart',
    'l10n',
    'gen/',
    'test/',
    '/Pods/',
  ];

  final found = <String, List<_Occurrence>>{};
  int totalFiles = 0;
  int totalMatches = 0;

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart')) continue;
    if (excludePaths.any((p) => path.contains(p))) continue;

    final content = await entity.readAsString();
    // Skip if line contains language. - already localized
    final lines = content.split('\n');
    totalFiles++;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      if (line.contains('language.') &&
          !line.contains("'") &&
          !line.contains('"')) continue;
      // Skip lines that are clearly already using language.xxx for this string
      if (RegExp(r'language\.\w+').hasMatch(line) &&
          !RegExp(r'''Text\s*\(\s*['"][^'"]+['"]''').hasMatch(line) &&
          !RegExp(r'''toast\s*\(\s*['"][^'"]+['"]''').hasMatch(line)) continue;

      for (final re in patterns) {
        for (final m in re.allMatches(line)) {
          final str = m.group(1) ?? '';
          if (str.length < 4) continue;
          // Skip if string is only placeholder or variable-like
          if (skipPatterns.any((s) => s.hasMatch(str))) continue;
          if (str.startsWith(r'$') || str.contains(r'${') || str.contains(r'$'))
            continue;
          if (str.contains('Exception') || str.contains('Error')) continue;
          if (str.length > 120) continue; // likely template

          final key = '$path:${i + 1}';
          found
              .putIfAbsent(str, () => [])
              .add(_Occurrence(path, i + 1, line.trim()));
          totalMatches++;
        }
      }
    }
  }

  // Load known language getters from BaseLanguage
  final knownGetters = <String>{};
  final langFile = File('lib/locale/languages.dart');
  if (await langFile.exists()) {
    final langContent = await langFile.readAsString();
    for (final m in RegExp(r'String get (\w+)').allMatches(langContent)) {
      knownGetters.add(m.group(1)!);
    }
  }

  // Output report
  final out = StringBuffer();
  out.writeln('=== Localization check report ===');
  out.writeln('Scanned $totalFiles Dart files under lib/');
  out.writeln('');

  final byString = found.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  var missingCount = 0;
  out.writeln(
      '--- Potentially hardcoded user-facing strings (candidates for localization) ---');
  out.writeln('');

  for (final e in byString) {
    final str = e.key;
    final occurrences = e.value;
    if (occurrences.isEmpty) continue;
    // Heuristic: if string looks like English sentence or phrase, flag it
    final looksLikeEnglish = str.contains(' ') ||
        (str.length > 10 && RegExp(r'^[A-Z]').hasMatch(str));
    if (!looksLikeEnglish && str.length < 8) continue; // skip short tokens
    missingCount++;
    out.writeln(
        'String: "${str.length > 60 ? '${str.substring(0, 57)}...' : str}"');
    for (final o in occurrences.take(3)) {
      out.writeln('  ${o.path}:${o.line}');
      out.writeln('    ${o.snippet}');
    }
    if (occurrences.length > 3) {
      out.writeln('  ... and ${occurrences.length - 3} more');
    }
    out.writeln('');
  }

  out.writeln('--- Summary ---');
  out.writeln('Total unique hardcoded string candidates: $missingCount');
  out.writeln('Known language getters in BaseLanguage: ${knownGetters.length}');

  print(out.toString());

  // Also write to file
  final reportFile = File('scripts/localization_report.txt');
  await reportFile.writeAsString(out.toString());
  print('Report written to ${reportFile.path}');
}

class _Occurrence {
  final String path;
  final int line;
  final String snippet;
  _Occurrence(this.path, this.line, this.snippet);
}
