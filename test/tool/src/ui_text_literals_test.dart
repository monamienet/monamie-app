import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/ui_text_literals.dart';

const screenPath = 'lib/ui/x/widgets/x_screen.dart';

/// [body] as the content of a screen file, after the imports a screen has.
String screen(String body) =>
    "import 'package:flutter/material.dart';\n"
    "import 'package:monamie_app/l10n/app_localizations.dart';\n"
    '\n'
    '$body\n';

/// The literals reported in [body], as written.
List<String> reported(String body, {String path = screenPath}) => [
  for (final violation in findHardCodedTexts(path, screen(body)))
    violation.text,
];

void main() {
  group('findHardCodedTexts - reported', () {
    final cases = <(String, String, String)>[
      ('a Text widget', "Widget f() => const Text('Olá');", "'Olá'"),
      (
        'an interpolation with words around the value',
        r"Widget f(String n) => Text('Olá, $n!');",
        r"'Olá, $n!'",
      ),
      (
        'a Tooltip message',
        "Widget f() => const Tooltip(message: 'Abrir o menu');",
        "'Abrir o menu'",
      ),
      (
        'a switch expression result',
        "String f(int n) => switch (n) { 0 => 'Nenhum', _ => '' };",
        "'Nenhum'",
      ),
      ('a lone capitalized word', "const String title = 'Grupos';", "'Grupos'"),
      ('a lone accented lowercase word', "const String word = 'não';", "'não'"),
      (
        'a brand followed by other words',
        "Widget f() => const Text('Entrar com Google');",
        "'Entrar com Google'",
      ),
      (
        'an argument of a function of the app',
        "AppBar f() => adminAppBar('Administradores');",
        "'Administradores'",
      ),
      (
        'a text in a list',
        "const List<String> labels = ['Em campo', '·'];",
        "'Em campo'",
      ),
      (
        'a branch of a conditional',
        "String f(bool on) => on ? 'Ligado' : '';",
        "'Ligado'",
      ),
    ];
    for (final (label, body, expected) in cases) {
      test(label, () {
        // 1. Arrange
        final source = body;

        // 2. Act
        final texts = reported(source);

        // 3. Assert
        expect(texts, [expected]);
      });
    }

    test('adjacent strings are one report for the whole sentence', () {
      // 1. Arrange
      const source =
          'Widget f() => const Text(\n'
          "  'Uma frase longa '\n"
          "  'em duas partes',\n"
          ');';

      // 2. Act
      final violations = findHardCodedTexts(screenPath, screen(source));

      // 3. Assert
      expect(violations, hasLength(1));
      expect(violations.single.text, startsWith("'Uma frase longa '"));
    });

    test('an interpolated value inside adjacent strings is checked too', () {
      // 1. Arrange
      const source =
          'Widget f(bool b) => Text(\n'
          r"  '${b ? 'Sim' : ''} '"
          '\n'
          "  '·',\n"
          ');';

      // 2. Act
      final texts = reported(source);

      // 3. Assert
      expect(texts, hasLength(1));
      expect(texts.single, "'Sim'");
    });

    test('the violation gives the line and column of the opening quote', () {
      // 1. Arrange
      const source = "Widget f() => const Text('Olá');";

      // 2. Act
      final violation = findHardCodedTexts(screenPath, screen(source)).single;

      // 3. Assert
      expect(
        (violation.path, violation.line, violation.column),
        (screenPath, 4, 26),
      );
      expect(
        violation.toString(),
        allOf(
          contains('$screenPath:4:26'),
          contains("'Olá'"),
          contains(notUiTextMarker),
          endsWith(uiHardCodedText),
        ),
      );
    });

    test('a long literal is shortened to 80 characters', () {
      // 1. Arrange
      final long = 'Palavra ' * 20;
      final source = "Widget f() => const Text('$long');";

      // 2. Act
      final text = findHardCodedTexts(screenPath, screen(source)).single.text;

      // 3. Assert
      expect(text, hasLength(80));
      expect(text, endsWith('...'));
    });

    test('a file under a nested folder of lib/ui/ is checked', () {
      // 1. Arrange
      const path = 'lib/ui/a/b/c/widgets/c_tile.dart';

      // 2. Act
      final texts = reported("const String t = 'Olá';", path: path);

      // 3. Assert
      expect(texts, ["'Olá'"]);
    });

    test('a Windows path is read the same way', () {
      // 1. Arrange
      const path = r'lib\ui\x\widgets\x_screen.dart';

      // 2. Act
      final texts = reported("const String t = 'Olá';", path: path);

      // 3. Assert
      expect(texts, ["'Olá'"]);
    });
  });

  group('findHardCodedTexts - not reported (contexts that are never text)', () {
    final cases = <(String, String)>[
      ('a directive', "export 'package:flutter/widgets.dart' show Text;"),
      ('an annotation', "@Deprecated('Use outro')\nconst int a = 1;"),
      (
        'toString',
        "class A {\n  @override\n  String toString() => 'A de exemplo';\n}",
      ),
      ('an assert', "void f(int n) {\n  assert(n > 0, 'Precisa ser > 0');\n}"),
      ('debugPrint', "void f() => debugPrint('Falhou ao ler');"),
      ('print', "void f() => print('Falhou ao ler');"),
      ('log', "void f() => developer.log('Falhou ao ler');"),
      ('a RegExp', r"final r = RegExp(r'^[A-Z]\w+ Olá$');"),
      ('a Key', "Widget f() => SizedBox(key: Key('Botão Entrar'));"),
      ('a ValueKey', "const k = ValueKey('Lista de Grupos');"),
      ('a GlobalKey debug label', "final k = GlobalKey(debugLabel: 'Mapa');"),
      ('a Locale', "const l = Locale('pt', 'BR');"),
      ('Uri.parse', "final u = Uri.parse('mailto:Ana@x.com');"),
      ('DateTime.tryParse', "final d = DateTime.tryParse('Hoje');"),
      ('Image.asset', "Widget f() => Image.asset('Logo Grande.png');"),
      ('an asset path', "const p = 'assets/images/Logo.png';"),
      ('a web address', "const u = 'https://example.com/Ajuda';"),
      ('a fontFamily', "const s = TextStyle(fontFamily: 'Plus Jakarta Sans');"),
      ('a heroTag', "Widget f() => FloatingActionButton(heroTag: 'Botão');"),
      (
        'an urlTemplate and userAgentPackageName',
        "Widget f() => TileLayer(urlTemplate: 'X', "
            "userAgentPackageName: 'Org App');",
      ),
      (
        'allowedExtensions',
        "final e = pick(allowedExtensions: ['PNG', 'JPEG']);",
      ),
      ('an Exception', "void f() => throw Exception('Algo deu errado');"),
      ('a StateError', "void f() => throw StateError('Estado ruim');"),
      ('an ArgumentError', "void f() => throw ArgumentError('Valor ruim');"),
      (
        'a prefix compared with startsWith',
        "bool f(String s) => s.startsWith('Equipe ');",
      ),
      (
        'a suffix compared with endsWith',
        "bool f(String s) => s.endsWith(' Ltda.');",
      ),
      ('a comparison with ==', "bool f(String s) => s == 'Administrador';"),
      ('a comparison with !=', "bool f(String s) => s != 'Membro';"),
      (
        'a constant pattern in a switch statement',
        "void f(String s) {\n  switch (s) {\n    case 'Ação':\n      break;\n"
            '  }\n}',
      ),
      (
        'a constant pattern in a switch expression',
        "int f(String s) => switch (s) { 'Ação' => 1, _ => 0 };",
      ),
      ('a map key', "const m = {'Chave Grande': 1};"),
      ('an index', "int f(Map<String, int> m) => m['Chave Grande']!;"),
      ('one lowercase ASCII word', "const id = 'community';"),
      ('one camelCase identifier', "const id = 'groupMemberships';"),
      ('a literal without letters', "const s = ' · ';"),
      (
        'an interpolation of values only',
        r"String f(int a, int b) => '$a/$b';",
      ),
      ('a brand alone', "const s = 'MonAmie';"),
      ('Google Meet', "Widget f() => const Text('Google Meet');"),
      ('OpenStreetMap', "const s = 'OpenStreetMap';"),
      ('brands and punctuation', "const s = 'Google · MonAmie';"),
      ('the marker at the end of the line', "const s = 'AB'; $notUiTextMarker"),
      ('the marker on the line above', "$notUiTextMarker\nconst s = 'AB';"),
    ];
    for (final (label, body) in cases) {
      test(label, () {
        // 1. Arrange
        final source = body;

        // 2. Act
        final texts = reported(source);

        // 3. Assert
        expect(texts, isEmpty);
      });
    }

    test('the marker above a line does not reach the line after it', () {
      // 1. Arrange
      final source =
          "$notUiTextMarker\nconst a = 'AB';\nconst b = 'Texto de verdade';";

      // 2. Act
      final texts = reported(source);

      // 3. Assert
      expect(texts, ["'Texto de verdade'"]);
    });

    test('a text argument next to a key is still reported', () {
      // 1. Arrange
      const source = "Widget f() => Text('Olá', key: Key('Saudação'));";

      // 2. Act
      final texts = reported(source);

      // 3. Assert
      expect(texts, ["'Olá'"]);
    });
  });

  group('findHardCodedTexts - view models and their states', () {
    const viewModelPath = 'lib/ui/x/view_models/x_view_model.dart';
    const statePath = 'lib/ui/x/view_models/x_state.dart';
    const stateContractPath = 'lib/ui/x/x_toggle_view_model.dart';

    final reportedCases = <(String, String, String, String)>[
      (
        'a message kept by a view model',
        viewModelPath,
        "const String m = 'Não foi possível salvar.';",
        "'Não foi possível salvar.'",
      ),
      (
        'a title handed by a view model',
        viewModelPath,
        "String f(bool ok) => ok ? '' : 'Erro ao sair';",
        "'Erro ao sair'",
      ),
      (
        'a default text in a state file',
        statePath,
        "class S {\n  const S({this.m = 'Mínimo 3 letras'});\n"
            '  final String m;\n}',
        "'Mínimo 3 letras'",
      ),
      (
        'a text in a state contract',
        stateContractPath,
        "// check_layers: state_contract\n"
            "const String m = 'Compartilhamento';",
        "'Compartilhamento'",
      ),
    ];
    for (final (label, path, body, expected) in reportedCases) {
      test('$label is reported', () {
        // 1. Arrange
        final source = body;

        // 2. Act
        final texts = reported(source, path: path);

        // 3. Assert
        expect(texts, [expected]);
      });
    }

    final exemptCases = <(String, String, String)>[
      (
        'a debugPrint in a view model',
        viewModelPath,
        "void f(Object e) => debugPrint('[XViewModel] Falhou ao ler: \$e');",
      ),
      (
        'a startsWith in a view model',
        viewModelPath,
        "bool f(String n) => n.startsWith('Equipe ');",
      ),
      (
        'an endsWith in a view model',
        viewModelPath,
        "bool f(String n) => n.endsWith('.PNG');",
      ),
      (
        'a toString in a state file',
        statePath,
        "class S {\n  @override\n  String toString() => 'S de exemplo';\n}",
      ),
      (
        'an id compared in a state contract',
        stateContractPath,
        "// check_layers: state_contract\n"
            "bool f(String s) => s == 'Administrador';",
      ),
    ];
    for (final (label, path, body) in exemptCases) {
      test('$label is not reported', () {
        // 1. Arrange
        final source = body;

        // 2. Act
        final texts = reported(source, path: path);

        // 3. Assert
        expect(texts, isEmpty);
      });
    }

    test('a startsWith next to a text keeps reporting the text', () {
      // 1. Arrange
      const source =
          "String f(String n) => n.startsWith('Equipe ') ? 'Nome reservado' "
          ": '';";

      // 2. Act
      final texts = reported(source, path: viewModelPath);

      // 3. Assert
      expect(texts, ["'Nome reservado'"]);
    });
  });

  group('findHardCodedTexts - files outside the rule', () {
    final cases = <(String, String, String)>[
      (
        'a generated freezed file',
        'lib/ui/x/x_state.freezed.dart',
        "const String m = 'Não foi possível';",
      ),
      (
        'a generated .g.dart file',
        'lib/ui/x/x.g.dart',
        "const String m = 'Não foi possível';",
      ),
      (
        'a generated mocks file',
        'lib/ui/x/x.mocks.dart',
        "const String m = 'Não foi possível';",
      ),
      (
        'the generated localizations',
        'lib/l10n/app_localizations_pt.dart',
        "const String m = 'Não foi possível';",
      ),
      (
        'a repository',
        'lib/data/repositories/x/x_repository.dart',
        "const String m = 'Não foi possível';",
      ),
      (
        'a domain model',
        'lib/domain/models/x.dart',
        "const String m = 'Grupo sem nome';",
      ),
      (
        'a test of a screen',
        'test/ui/x/widgets/x_screen_test.dart',
        "const String m = 'Olá';",
      ),
      (
        'a file that is not Dart',
        'lib/ui/x/notes.txt',
        "const String m = 'Olá';",
      ),
      ('a file at the root of lib/', 'lib/ui.dart', "const String m = 'Olá';"),
    ];
    for (final (label, path, body) in cases) {
      test('$label is not checked', () {
        // 1. Arrange
        final content = screen(body);

        // 2. Act
        final violations = findHardCodedTexts(path, content);

        // 3. Assert
        expect(violations, isEmpty);
      });
    }
  });
}
