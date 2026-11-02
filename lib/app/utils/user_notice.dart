/// A message for the person using the app that is not the result of the
/// action they just took: a warning raised by a background change, or a
/// remark on an action that succeeded (e.g. sharing started while the GPS has
/// no fix yet). [message] and the optional [title] are in pt-BR.
class UserNotice {
  const UserNotice(this.message, {this.title});

  final String message;
  final String? title;

  @override
  bool operator ==(Object other) =>
      other is UserNotice && other.message == message && other.title == title;

  @override
  int get hashCode => Object.hash(message, title);

  @override
  String toString() => 'UserNotice(${title == null ? '' : '$title: '}$message)';
}
