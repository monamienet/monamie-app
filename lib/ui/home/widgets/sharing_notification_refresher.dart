import 'package:flutter/widgets.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';

/// Draws nothing: when the app's language changes it hands the tracking
/// service the sharing notification's texts in the new language, which the
/// service otherwise keeps from the moment it started.
///
/// It also stores, from the first frame on and at each change of language,
/// the texts the device shows when sharing resumes without the screen
/// ([SharingResumeTexts]).
class SharingNotificationRefresher extends StatefulWidget {
  const SharingNotificationRefresher({
    super.key,
    required this.tracking,
    required this.resumeOnRestart,
  });

  final TrackingViewModel tracking;
  final ResumeOnRestartViewModel resumeOnRestart;

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
    if (_locale == locale) return;
    final first = _locale == null;
    _locale = locale;
    final l10n = AppLocalizations.of(context);
    final notification = SharingNotification(
      title: l10n.sharingNotificationTitle,
      content: l10n.sharingNotificationContent,
    );
    final texts = SharingResumeTexts(
      notificationTitle: notification.title,
      notificationContent: notification.content,
      waitingForGps: l10n.resumeWaitingForGps,
      failureChannel: l10n.resumeFailureChannel,
      failureTitle: l10n.resumeFailureTitle,
      failures: {
        ResumeFailure.backgroundLocation: l10n.resumeFailureBackgroundLocation,
        ResumeFailure.batteryRestricted: l10n.resumeFailureBatteryRestricted,
        ResumeFailure.signedOut: l10n.resumeFailureSignedOut,
        ResumeFailure.noGroup: l10n.resumeFailureNoGroup,
      },
    );
    // After the frame: the command notifies when it starts, which must not
    // happen while this widget is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.resumeOnRestart.storeTexts(texts);
      if (!first) widget.tracking.refreshNotification.execute(notification);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
