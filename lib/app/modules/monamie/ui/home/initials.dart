/// Up to two capital letters for an avatar: the first letters of the first
/// and last word of [name], or of the part of an e-mail before the `@`.
///
/// Returns `?` when there is nothing to take letters from.
String initialsOf(String name) {
  final base = name.contains('@') ? name.split('@').first : name;
  final words = base
      .split(RegExp(r'[\s._-]+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  final first = _firstLetter(words.first);
  if (words.length == 1) return first.toUpperCase();
  return (first + _firstLetter(words.last)).toUpperCase();
}

String _firstLetter(String word) => String.fromCharCode(word.runes.first);
