import 'package:flutter/widgets.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';

/// Draws nothing: when the app's language changes it hands the tracking
/// service the sharing notification's texts in the new language, which the
/// service otherwise keeps from the moment it started.
class SharingNotificationRefresher extends StatefulWidget {
  const SharingNotificationRefresher({super.key, required this.tracking});

  final TrackingViewModel tracking;

  @override
  State<SharingNotificationRefresher> createState() =>
      _SharingNotificationRefresherState();
}

class _SharingNotificationRefresherState
    extends State<SharingNotificationRefresher> {
  /// The language the service last got its texts in (the first one it
  /// started with, from the screen that turned sharing on).
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final changed = _locale != null && _locale != locale;
    _locale = locale;
    if (!changed) return;
    final l10n = AppLocalizations.of(context);
    final notification = SharingNotification(
      title: l10n.sharingNotificationTitle,
      content: l10n.sharingNotificationContent,
    );
    // After the frame: the command notifies when it starts, which must not
    // happen while this widget is building.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.tracking.refreshNotification.execute(notification),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
