import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/initials.dart';

void main() {
  group('initialsOf - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      ('Happy Path: first and last word', 'Ana Souza', 'AS'),
      ('Happy Path: middle words are skipped', 'ana maria de souza', 'AS'),
      ('Happy Path: e-mail local part split on dot', 'joao.silva@x.org', 'JS'),
      ('Edge Case: e-mail split on underscore', 'joao_silva@x.org', 'JS'),
      ('Edge Case: e-mail split on hyphen', 'joao-silva@x.org', 'JS'),
      ('Edge Case: e-mail first and last of three', 'a.b.c@x.org', 'AC'),
      ('Edge Case: a single word gives one letter', 'ana', 'A'),
      (
        'Edge Case: an e-mail with one word gives one letter',
        'joao@x.org',
        'J',
      ),
      ('Edge Case: lowercase becomes uppercase', 'ana souza', 'AS'),
      ('Edge Case: accents are kept and uppercased', 'álvaro ébano', 'ÁÉ'),
      ('Edge Case: extra whitespace is ignored', '  ana   souza ', 'AS'),
      ('Sad Path: empty gives a question mark', '', '?'),
      ('Sad Path: only whitespace gives a question mark', '   ', '?'),
      ('Sad Path: only separators give a question mark', '._-', '?'),
      (
        'Sad Path: an e-mail without local part gives a question mark',
        '@x.org',
        '?',
      ),
    ];
    for (final (label, input, expected) in cases) {
      test('$label ("$input" -> "$expected")', () {
        // 1. Arrange
        final name = input;

        // 2. Act
        final initials = initialsOf(name);

        // 3. Assert
        expect(initials, expected);
      });
    }
  });
}
