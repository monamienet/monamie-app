/// The text rule run by `dart run tool/check_layers.dart`: the screens'
/// text lives in the ARB files (`lib/l10n/`), so a hand-written file under
/// `lib/ui/` holds no string literal with a letter in it, except where the
/// literal is not text the person reads.
///
/// The rule is deny by default: every literal with a letter is reported
/// unless it sits in one of the contexts below, which carry identifiers,
/// paths and developer messages, it is an asset path, a web address or one
/// lowercase ASCII word (an id or a `select` case), or it is made only of
/// [brandNames]. A
/// literal that is not text for people and fits no context (a list of file
/// extensions, say) takes the [notUiTextMarker] at the end of its line or
/// on the line above.
///
/// Limits: it reads literals only, so text built elsewhere (a view model's
/// message, a domain model's label) and reaching a widget as a value is not
/// seen; view models and state contracts (see `isStateFile`) are left out,
/// because their messages become typed failures in a later step; a literal
/// without letters ("·", "—", "%") passes; and so does a single lowercase
/// ASCII word, so a lone word such as 'agora' would slip through (accented
/// words, capitals and sentences are still caught).
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

import 'state_layer_imports.dart' show isStateFile;

/// The rule's name, printed with each violation.
const String uiHardCodedText = 'ui_hard_coded_text';

/// The comment that allows the literals of its line, or of the line below
/// when it stands on a line of its own.
const String notUiTextMarker = '// check_layers: not_ui_text';

/// Names shown as they are in every language. A literal made only of these
/// (and of characters that are not letters) passes.
const List<String> brandNames = [
  // Longest first: "Google Meet" before "Google".
  'Google Meet',
  'OpenStreetMap',
  'MonAmie',
  'Google',
];

/// Invocations whose arguments are never text for people: developer logs
/// and errors, patterns, keys, URIs and asset paths. Matched by the
/// invoked name (`RegExp(...)`, `Uri.parse(...)`, `Image.asset(...)`).
const Set<String> nonTextInvocations = {
  'debugPrint',
  'print',
  'log',
  'RegExp',
  'Key',
  'ValueKey',
  'ObjectKey',
  'PageStorageKey',
  'GlobalKey',
  'Locale',
  'parse',
  'tryParse',
  'asset',
  'AssetImage',
  'ArgumentError',
  'StateError',
  'FormatException',
  'UnsupportedError',
  'UnimplementedError',
  'Exception',
};

/// Named arguments that take identifiers or configuration, never text.
const Set<String> nonTextArguments = {
  'fontFamily',
  'heroTag',
  'urlTemplate',
  'userAgentPackageName',
  'restorationId',
  'debugLabel',
  'package',
  'allowedExtensions',
};

/// A hard-coded text found under `lib/ui/`.
class TextViolation {
  const TextViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.text,
  });

  final String path;

  /// 1-based line and column of the literal's opening quote.
  final int line;
  final int column;

  /// The literal as written, shortened to its first line.
  final String text;

  @override
  String toString() =>
      '$path:$line:$column - Text for people in lib/ui/ goes in the ARB '
      'files (lib/l10n/app_pt.arb and app_en.arb) and is read with '
      'AppLocalizations.of(context): $text. If it is not text for people, '
      "end the line with '$notUiTextMarker'. - $uiHardCodedText";
}

final _letter = RegExp(r'\p{L}', unicode: true);

/// Asset paths and web addresses, which are never translated.
final _pathOrUrl = RegExp(r'^(assets/|https?://)');

/// One lowercase ASCII word, such as `community`, `both` or `svg`: an id, a
/// stored value or an ICU `select` case, never a sentence.
final _identifier = RegExp(r'^[a-z][a-zA-Z0-9_]*$');

/// The hard-coded texts of the Dart file at [path] (relative to the package
/// root, `/` or `\` separated) with [content]: none outside `lib/ui/`, in
/// generated files or in state files.
List<TextViolation> findHardCodedTexts(String path, String content) {
  final segments = path.split(RegExp(r'[/\\]'));
  final name = segments.last;
  if (segments.length < 3 || segments[0] != 'lib' || segments[1] != 'ui') {
    return const [];
  }
  if (!name.endsWith('.dart') ||
      name.endsWith('.g.dart') ||
      name.endsWith('.freezed.dart') ||
      name.endsWith('.mocks.dart')) {
    return const [];
  }
  if (isStateFile(path, content)) return const [];
  final unit = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  ).unit;
  final lines = content.split('\n');
  final visitor = _TextVisitor(path, unit.lineInfo, lines);
  unit.accept(visitor);
  return visitor.found;
}

class _TextVisitor extends RecursiveAstVisitor<void> {
  _TextVisitor(this.path, this.lineInfo, this.lines);

  final String path;
  final LineInfo lineInfo;
  final List<String> lines;
  final found = <TextViolation>[];

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    // One report for the whole sentence; its parts are not visited.
    _check(node, node.strings.map(_ownText).join());
    for (final part in node.strings) {
      if (part is StringInterpolation) {
        for (final element in part.elements) {
          if (element is InterpolationExpression) element.accept(this);
        }
      }
    }
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.parent is! AdjacentStrings) _check(node, node.value);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.parent is! AdjacentStrings) _check(node, _ownText(node));
    super.visitStringInterpolation(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitPartDirective(PartDirective node) {}

  @override
  void visitAnnotation(Annotation node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // toString() describes the object to developers.
    if (node.name.lexeme != 'toString') super.visitMethodDeclaration(node);
  }

  @override
  void visitAssertStatement(AssertStatement node) {}

  /// The literal's own characters: interpolated expressions left out.
  static String _ownText(StringLiteral literal) => switch (literal) {
    SimpleStringLiteral(:final value) => value,
    StringInterpolation(:final elements) => [
      for (final element in elements)
        if (element is InterpolationString) element.value,
    ].join(),
    AdjacentStrings(:final strings) => strings.map(_ownText).join(),
  };

  void _check(StringLiteral node, String text) {
    var rest = text;
    for (final brand in brandNames) {
      rest = rest.replaceAll(brand, '');
    }
    if (!_letter.hasMatch(rest) ||
        _pathOrUrl.hasMatch(text) ||
        _identifier.hasMatch(text)) {
      return;
    }
    if (_inNonTextContext(node) || _marked(node)) return;
    final location = lineInfo.getLocation(node.offset);
    final source = node.toSource().split('\n').first;
    found.add(
      TextViolation(
        path: path,
        line: location.lineNumber,
        column: location.columnNumber,
        text: source.length > 80 ? '${source.substring(0, 77)}...' : source,
      ),
    );
  }

  /// Whether the line of [node], or the line above, carries the marker.
  bool _marked(AstNode node) {
    final line = lineInfo.getLocation(node.offset).lineNumber - 1;
    if (lines[line].trimRight().endsWith(notUiTextMarker)) return true;
    return line > 0 && lines[line - 1].trim() == notUiTextMarker;
  }

  /// Whether [node] is an identifier rather than text: an argument of a
  /// [nonTextInvocations] call or a [nonTextArguments] argument, a value
  /// compared with `==` / `!=`, a constant pattern, a map key or an index.
  static bool _inNonTextContext(StringLiteral node) {
    AstNode child = node;
    for (var parent = node.parent; parent != null; parent = parent.parent) {
      switch (parent) {
        case NamedArgument(:final name)
            when nonTextArguments.contains(name.lexeme):
          return true;
        case MethodInvocation(:final methodName)
            when child is ArgumentList &&
                nonTextInvocations.contains(methodName.name):
          return true;
        case InstanceCreationExpression(:final constructorName)
            when child is ArgumentList &&
                (nonTextInvocations.contains(
                      constructorName.type.name.lexeme,
                    ) ||
                    nonTextInvocations.contains(constructorName.name?.name)):
          return true;
        case BinaryExpression(:final operator)
            when operator.lexeme == '==' || operator.lexeme == '!=':
          return true;
        case ConstantPattern():
        case IndexExpression():
          return true;
        case MapLiteralEntry(:final key) when key == child:
          return true;
        // Text reaches a widget through an argument, a list, a condition
        // or a record; any other parent ends the climb.
        case ArgumentList():
        case NamedArgument():
        case ListLiteral():
        case ConditionalExpression():
        case ParenthesizedExpression():
        case RecordLiteral():
          child = parent;
          continue;
        default:
          return false;
      }
    }
    return false;
  }
}
