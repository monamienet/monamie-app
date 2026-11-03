/// The words of the notification the tracking service shows while it runs.
/// The screen that turns sharing on builds it from its `AppLocalizations`,
/// so the notification follows the device's language.
class SharingNotification {
  const SharingNotification({required this.title, required this.content});

  final String title;
  final String content;

  @override
  bool operator ==(Object other) =>
      other is SharingNotification &&
      other.title == title &&
      other.content == content;

  @override
  int get hashCode => Object.hash(title, content);

  @override
  String toString() => 'SharingNotification($title)';
}
