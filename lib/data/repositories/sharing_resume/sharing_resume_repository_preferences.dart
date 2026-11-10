import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository.dart';
import 'package:monamie_app/data/services/sharing_resume_preferences_service.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/utils/result.dart';

/// [SharingResumeRepository] over [SharingResumePreferencesService].
class SharingResumeRepositoryPreferences implements SharingResumeRepository {
  SharingResumeRepositoryPreferences({required this._service});

  final SharingResumePreferencesService _service;

  final _resumeOnRestart = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get resumeOnRestart => _resumeOnRestart;

  @override
  Future<void> restore() async {
    try {
      _resumeOnRestart.value = await _service.readOption();
    } catch (error) {
      debugPrint('Ignoring an unreadable resume option: $error');
    }
  }

  @override
  Future<Result<void>> setResumeOnRestart(bool resume) async {
    try {
      await _service.writeOption(resume);
    } catch (error, stackTrace) {
      return Err(
        const Failure.resumeOptionNotSaved(),
        error: error,
        stackTrace: stackTrace,
      );
    }
    _resumeOnRestart.value = resume;
    return const Ok(null);
  }

  @override
  Future<void> saveIntent(SharingIntent intent) =>
      _service.writeIntent(email: intent.email, name: intent.name);

  @override
  Future<void> clearIntent() => _service.clearIntent();

  @override
  Future<void> saveTexts(SharingResumeTexts texts) => _service.writeTexts({
    'notificationTitle': texts.notificationTitle,
    'notificationContent': texts.notificationContent,
    'waitingForGps': texts.waitingForGps,
    'failureChannel': texts.failureChannel,
    'failureTitle': texts.failureTitle,
    'failures': {
      for (final MapEntry(:key, :value) in texts.failures.entries)
        key.name: value,
    },
  });
}
