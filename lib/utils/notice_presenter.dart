// check_layers: state_contract

import 'package:monamie_app/utils/user_notice.dart';

/// Shows a [UserNotice] that no screen is waiting for (a warning raised by a
/// background change, or one that outlives the screen that started the
/// action). View models and use cases receive it through their
/// constructor; the widget layer implements it (`ScaffoldNoticePresenter`).
abstract class NoticePresenter {
  void show(UserNotice notice);
}
