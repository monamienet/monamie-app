import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/l10n/app_localizations.dart';

Map<String, Object?> _readArb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

/// The message keys of [arb]: every key but the `@` attributes.
Set<String> _messageKeys(Map<String, Object?> arb) => {
  for (final key in arb.keys)
    if (!key.startsWith('@')) key,
};

/// How [message] uses each of [names]: `plain` for `{name}`, or the ICU
/// kind (`plural`, `select`) for `{name, kind, …}`.
Map<String, Set<String>> _uses(String message, Iterable<String> names) => {
  for (final name in names)
    name: {
      for (final match in RegExp(
        r'\{\s*' + RegExp.escape(name) + r'\s*(?:,\s*(\w+)\s*,|\})',
      ).allMatches(message))
        match.group(1) ?? 'plain',
    },
};

/// The names declared under `placeholders` of the `@key` entry in [arb].
Set<String> _declared(Map<String, Object?> arb, String key) {
  final attributes = arb['@$key'] as Map<String, Object?>?;
  final placeholders = attributes?['placeholders'] as Map<String, Object?>?;
  return {...?placeholders?.keys};
}

void main() {
  final pt = _readArb('app_pt.arb');
  final en = _readArb('app_en.arb');
  final ptKeys = _messageKeys(pt);
  final enKeys = _messageKeys(en);

  group('ARB files - Unit Test Suite', () {
    test('Happy Path: every Portuguese key has an English translation', () {
      // 1. Arrange / 2. Act
      final missing = ptKeys.difference(enKeys);

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Sad Path: the English file has no key the template lacks', () {
      // 1. Arrange / 2. Act
      final extra = enKeys.difference(ptKeys);

      // 3. Assert
      expect(extra, isEmpty);
    });

    test('Happy Path: every template key has a description', () {
      // 1. Arrange / 2. Act
      final undescribed = [
        for (final key in ptKeys)
          if ((pt['@$key'] as Map?)?['description'] is! String) key,
      ];

      // 3. Assert
      expect(undescribed, isEmpty);
    });

    test('Happy Path: every translation is a non-empty text', () {
      // 1. Arrange / 2. Act
      final empty = [
        for (final key in enKeys)
          if (en[key] is! String || (en[key] as String).trim().isEmpty) key,
      ];

      // 3. Assert
      expect(empty, isEmpty);
    });

    test('Happy Path: the English messages use the same placeholders, the '
        'same way', () {
      // 1. Arrange
      final differences = <String>[];
      var checked = 0;

      // 2. Act
      for (final key in ptKeys.intersection(enKeys)) {
        final names = _declared(pt, key);
        checked += names.length;
        final ptUses = _uses(pt[key]! as String, names);
        final enUses = _uses(en[key]! as String, names);
        for (final name in names) {
          if (ptUses[name]!.isEmpty) differences.add('$key: pt lacks {$name}');
          if (!_sameSet(ptUses[name]!, enUses[name]!)) {
            differences.add(
              '$key: {$name} is ${ptUses[name]} in pt, ${enUses[name]} in en',
            );
          }
        }
      }

      // 3. Assert
      expect(checked, greaterThan(50), reason: 'placeholders were read');
      expect(differences, isEmpty);
    });

    test('Edge Case: every plural writes its zero case in both languages', () {
      // 1. Arrange
      final plurals = [
        for (final key in ptKeys)
          if ((pt[key]! as String).contains(RegExp(r',\s*plural\s*,'))) key,
      ];
      final missing = <String>[];

      // 2. Act
      for (final key in plurals) {
        if (!(pt[key]! as String).contains('=0{')) missing.add('pt $key');
        if (!(en[key]! as String).contains('=0{')) missing.add('en $key');
      }

      // 3. Assert
      expect(plurals, isNotEmpty);
      expect(missing, isEmpty);
    });

    test('Edge Case: the English file only marks its locale', () {
      // 1. Arrange / 2. Act
      final attributes = [
        for (final key in en.keys)
          if (key.startsWith('@')) key,
      ];

      // 3. Assert
      expect(attributes, ['@@locale']);
      expect(en['@@locale'], 'en');
    });
  });

  // In Portuguese CLDR's `one` category takes 0 too, so without `=0{…}`
  // these would read "1 pessoa" for nobody.
  group('Portuguese plurals at zero - Unit Test Suite', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final cases = <(String, String Function(), String)>[
      ('memberCount', () => l10n.memberCount(0), '0 pessoas'),
      ('peopleCount', () => l10n.peopleCount(0), 'Ninguém ainda'),
      ('pendingInvites', () => l10n.pendingInvites(0), '0 convites pendentes'),
      ('inviteSend', () => l10n.inviteSend(0), 'Enviar convite'),
      ('inviteSent', () => l10n.inviteSent(0), '0 convites enviados'),
      (
        'deletionPendingAccountTitle',
        () => l10n.deletionPendingAccountTitle(0),
        'Sua conta será excluída hoje',
      ),
      (
        'groupDeletedLost',
        () => l10n.groupDeletedLost(0, 'Rota Sul'),
        '0 pessoas perderam o acesso à Rota Sul.',
      ),
    ];
    for (final (key, message, expected) in cases) {
      test('Edge Case: $key(0) reads "$expected"', () {
        // 1. Arrange / 2. Act
        final text = message();

        // 3. Assert
        expect(text, expected);
      });
    }

    test('Happy Path: one and many keep their own wording', () {
      // 1. Arrange / 2. Act
      final texts = [l10n.memberCount(1), l10n.memberCount(2)];

      // 3. Assert
      expect(texts, ['1 pessoa', '2 pessoas']);
    });
  });
}

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
