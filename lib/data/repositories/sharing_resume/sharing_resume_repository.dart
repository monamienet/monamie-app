import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/utils/result.dart';

/// Whether sharing resumes by itself after the device restarts or the app
/// is updated, and what that needs: who was sharing and the texts the
/// device shows meanwhile. Kept on the device (Android only).
///
/// It belongs to the app scope: the option is the device's, kept across
/// sign-outs and organizations, and `SignOut` clears the intent.
abstract class SharingResumeRepository {
  /// Whether the person chose to resume sharing; `false` until [restore]
  /// reads it.
  ValueListenable<bool> get resumeOnRestart;

  /// Reads the stored option. An unreadable storage leaves it off.
  Future<void> restore();

  /// Uses and stores [resume]. Fails when it could not be stored; the option
  /// is then unchanged.
  Future<Result<void>> setResumeOnRestart(bool resume);

  /// Records that [intent]'s person is sharing. Throws when it could not be
  /// stored.
  Future<void> saveIntent(SharingIntent intent);

  /// Records that nobody is sharing. Throws when it could not be stored.
  Future<void> clearIntent();

  /// Stores the texts shown without the screen. Throws when they could not
  /// be stored.
  Future<void> saveTexts(SharingResumeTexts texts);
}
