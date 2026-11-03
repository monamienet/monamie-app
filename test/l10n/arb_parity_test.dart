import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The template every translation is compared with: Portuguese, which also
/// holds the `@key` descriptions (`l10n.yaml`).
const _templateName = 'app_pt.arb';

/// The translation whose key order every other file follows.
const _orderReferenceName = 'app_en.arb';

final _l10nDirectory = Directory('lib/l10n');

Map<String, Object?> _readArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

/// The message keys of [arb] in file order: every key but the `@` entries
/// (`@@locale` and the `@key` attributes).
List<String> _messageKeys(Map<String, Object?> arb) => [
  for (final key in arb.keys)
    if (!key.startsWith('@')) key,
];

/// The language of `app_<language>.arb`.
String _languageOf(String fileName) =>
    fileName.substring('app_'.length, fileName.length - '.arb'.length);

/// The translation files under `lib/l10n/`: every ARB file but the template,
/// so a file added later (`app_fr.arb`) is checked with no change here.
List<File> _translationFiles() {
  final files = [
    for (final entity in _l10nDirectory.listSync())
      if (entity is File &&
          RegExp(r'app_[A-Za-z_]+\.arb$').hasMatch(entity.path) &&
          !entity.path.endsWith(_templateName))
        entity,
  ]..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _nameOf(File file) => file.uri.pathSegments.last;

/// The placeholders [message] uses: `{name}` and the variable of
/// `{name, plural, …}` and `{name, select, …}`. The words inside plural and
/// select options (`=0{hoje}`, `other{…}`) are text, not placeholders.
Set<String> icuPlaceholders(String message) {
  // Turn the opening brace of each option into a parenthesis, so the words
  // that follow it are not read as `{placeholder}`.
  final stripped = message.replaceAllMapped(
    RegExp(r'(=\d+|\b[A-Za-z_][A-Za-z0-9_]*)\{'),
    (match) => '${match[1]}(',
  );
  return {
    for (final match in RegExp(
      r'\{([A-Za-z_][A-Za-z0-9_]*)\s*(?:,|\})',
    ).allMatches(stripped))
      match[1]!,
  };
}

/// The option labels of the plurals and selects in [message] (`=0`, `=1`,
/// `other`, `both`, `publisher`…), sorted.
List<String> icuOptions(String message) => [
  for (final match in RegExp(
    r'(?:^|[\s}])(=\d+|[A-Za-z_][A-Za-z0-9_]*)\{',
  ).allMatches(message))
    match[1]!,
]..sort();

/// The rules a translation follows, each with the problems found.
enum ArbRule { keys, order, empty, placeholders, options, lineBreaks, zeroCase }

/// What differs between [translation] and [template], by rule, one text per
/// problem naming [fileName] and the key. [orderReference] is the key order
/// the translation follows.
Map<ArbRule, List<String>> compareArb({
  required String fileName,
  required Map<String, Object?> template,
  required Map<String, Object?> translation,
  required List<String> orderReference,
}) {
  final problems = {for (final rule in ArbRule.values) rule: <String>[]};
  final templateKeys = _messageKeys(template);
  final keys = _messageKeys(translation);

  for (final key in templateKeys) {
    if (!translation.containsKey(key)) {
      problems[ArbRule.keys]!.add('$fileName: missing $key');
    }
  }
  for (final key in keys) {
    if (!template.containsKey(key)) {
      problems[ArbRule.keys]!.add('$fileName: $key is not in the template');
    }
  }

  final shared = keys.where(template.containsKey).toList();
  final sharedOrder = orderReference.where(shared.contains).toList();
  for (var i = 0; i < shared.length && i < sharedOrder.length; i++) {
    if (shared[i] != sharedOrder[i]) {
      problems[ArbRule.order]!.add(
        '$fileName: ${shared[i]} is out of order (the reference has '
        '${sharedOrder[i]} there)',
      );
      break;
    }
  }

  for (final key in templateKeys.where(translation.containsKey)) {
    final t = template[key];
    final o = translation[key];
    if (o is! String || t is! String) {
      problems[ArbRule.empty]!.add('$fileName: $key is not a text');
      continue;
    }
    if (o.trim().isEmpty) {
      problems[ArbRule.empty]!.add('$fileName: $key is empty');
    }
    final tPlaceholders = icuPlaceholders(t).toList()..sort();
    final oPlaceholders = icuPlaceholders(o).toList()..sort();
    if (tPlaceholders.join(',') != oPlaceholders.join(',')) {
      problems[ArbRule.placeholders]!.add(
        '$fileName: $key uses placeholders $oPlaceholders, the template '
        '$tPlaceholders',
      );
    }
    final tOptions = icuOptions(t);
    final oOptions = icuOptions(o);
    if (tOptions.join(',') != oOptions.join(',')) {
      problems[ArbRule.options]!.add(
        '$fileName: $key has plural/select options $oOptions, the template '
        '$tOptions',
      );
    }
    final tBreaks = '\n'.allMatches(t).length;
    final oBreaks = '\n'.allMatches(o).length;
    if (tBreaks != oBreaks) {
      problems[ArbRule.lineBreaks]!.add(
        '$fileName: $key has $oBreaks line breaks, the template $tBreaks',
      );
    }
    if (o.contains('plural') && !o.contains('=0{')) {
      problems[ArbRule.zeroCase]!.add(
        '$fileName: $key is a plural without its =0 case',
      );
    }
  }
  return problems;
}

void main() {
  final template = _readArb(File('lib/l10n/$_templateName'));
  final templateKeys = _messageKeys(template);
  final orderReference = _messageKeys(
    _readArb(File('lib/l10n/$_orderReferenceName')),
  );
  final translations = _translationFiles();

  group('ARB parity rules - Unit Test Suite', () {
    test('Happy Path: placeholders are read with their plural and select '
        'variables, not the option words', () {
      // 1. Arrange
      const message =
          '{inviter} chamou você para {group}, '
          '{role, select, both{em campo} other{vendo}} '
          '{count, plural, =0{hoje} =1{em 1 dia} other{em {days} dias}}';

      // 2. Act
      final placeholders = icuPlaceholders(message);

      // 3. Assert
      expect(placeholders, {'inviter', 'group', 'role', 'count', 'days'});
    });

    test('Happy Path: option labels are listed sorted, nested text '
        'ignored', () {
      // 1. Arrange
      const message =
          '{count, plural, =0{hoje} =1{em 1 dia} other{em {days} dias}}';

      // 2. Act
      final options = icuOptions(message);

      // 3. Assert
      expect(options, ['=0', '=1', 'other']);
    });

    test('Edge Case: a plain text has no placeholders and no options', () {
      // 1. Arrange / 2. Act
      const text = 'Entrar com o Google';

      // 3. Assert
      expect(icuPlaceholders(text), isEmpty);
      expect(icuOptions(text), isEmpty);
    });

    test('Happy Path: a faithful translation has no problem', () {
      // 1. Arrange
      final template = {
        '@@locale': 'pt',
        'a': 'Olá, {name}\nTchau',
        '@a': {'description': 'x'},
        'b': '{n, plural, =0{nada} =1{um} other{{n} coisas}}',
      };
      final translation = {
        '@@locale': 'es',
        'a': 'Hola, {name}\nAdiós',
        'b': '{n, plural, =0{nada} =1{uno} other{{n} cosas}}',
      };

      // 2. Act
      final problems = compareArb(
        fileName: 'app_es.arb',
        template: template,
        translation: translation,
        orderReference: ['a', 'b'],
      );

      // 3. Assert
      expect(problems.values.expand((p) => p), isEmpty);
    });

    test('Sad Path: every kind of difference is reported with the file and '
        'the key', () {
      // 1. Arrange
      final template = {
        'missing': 'x',
        'placeholder': 'Olá, {name}',
        'option': '{s, select, both{a} other{b}}',
        'breaks': 'a\nb',
        'zero': '{n, plural, =0{a} other{b}}',
        'blank': 'x',
        'first': 'x',
        'second': 'x',
      };
      final translation = {
        'extra': 'x',
        'placeholder': 'Hola, {nombre}',
        'option': '{s, select, both{a} publisher{c} other{b}}',
        'breaks': 'a b',
        'zero': '{n, plural, one{a} other{b}}',
        'blank': '  ',
        'second': 'x',
        'first': 'x',
      };

      // 2. Act
      final problems = compareArb(
        fileName: 'app_xx.arb',
        template: template,
        translation: translation,
        orderReference: template.keys.toList(),
      );

      // 3. Assert
      expect(problems[ArbRule.keys], [
        'app_xx.arb: missing missing',
        'app_xx.arb: extra is not in the template',
      ]);
      expect(problems[ArbRule.order], [
        'app_xx.arb: second is out of order (the reference has first there)',
      ]);
      expect(problems[ArbRule.empty], ['app_xx.arb: blank is empty']);
      expect(problems[ArbRule.placeholders], [
        'app_xx.arb: placeholder uses placeholders [nombre], the template '
            '[name]',
      ]);
      expect(problems[ArbRule.options], [
        'app_xx.arb: option has plural/select options '
            '[both, other, publisher], the template [both, other]',
        'app_xx.arb: zero has plural/select options [one, other], the '
            'template [=0, other]',
      ]);
      expect(problems[ArbRule.lineBreaks], [
        'app_xx.arb: breaks has 0 line breaks, the template 1',
      ]);
      expect(problems[ArbRule.zeroCase], [
        'app_xx.arb: zero is a plural without its =0 case',
      ]);
    });
  });

  group('ARB files against the template - Unit Test Suite', () {
    test('Edge Case: English is among the translations checked', () {
      // 1. Arrange / 2. Act
      final names = [for (final file in translations) _nameOf(file)];

      // 3. Assert
      expect(names, contains(_orderReferenceName));
    });

    test('Happy Path: the key order reference follows the template order', () {
      // 1. Arrange / 2. Act
      final same = orderReference.join(',') == templateKeys.join(',');

      // 3. Assert
      expect(same, isTrue, reason: '$_orderReferenceName follows the template');
    });

    for (final file in translations) {
      final name = _nameOf(file);
      final translation = _readArb(file);
      final problems = compareArb(
        fileName: name,
        template: template,
        translation: translation,
        orderReference: orderReference,
      );

      group('$name - Unit Test Suite', () {
        test('Happy Path: marks its own language in @@locale', () {
          // 1. Arrange / 2. Act
          final locale = translation['@@locale'];

          // 3. Assert
          expect(locale, _languageOf(name), reason: '$name @@locale');
        });

        test('Happy Path: has exactly the template keys', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.keys];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Happy Path: keeps the key order of $_orderReferenceName', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.order];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Sad Path: no message is empty or not a text', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.empty];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Happy Path: every message uses the placeholders of the '
            'template', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.placeholders];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Happy Path: every plural and select keeps the option labels '
            'of the template', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.options];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Edge Case: every message has the line breaks of the '
            'template', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.lineBreaks];

          // 3. Assert
          expect(found, isEmpty);
        });

        test('Edge Case: every plural spells out its =0 case', () {
          // 1. Arrange / 2. Act
          final found = problems[ArbRule.zeroCase];

          // 3. Assert
          expect(found, isEmpty);
        });
      });
    }
  });
}
