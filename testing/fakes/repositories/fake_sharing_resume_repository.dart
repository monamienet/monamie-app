import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [SharingResumeRepository] in memory: [storedOption], [intent] and
/// [texts] stand for what the device keeps. A failure asked for with
/// `fail('setResumeOnRestart', …)` changes nothing, as the real one.
class FakeSharingResumeRepository
    with FakeOutcomes
    implements SharingResumeRepository {
  /// Starts with [storedOption] kept on the device (off when omitted).
  FakeSharingResumeRepository({this.storedOption = false});

  /// The option the device keeps between launches.
  bool storedOption;

  /// Who is sharing, `null` while nobody is.
  SharingIntent? intent;

  /// The texts last stored.
  SharingResumeTexts? texts;

  final _resumeOnRestart = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get resumeOnRestart => _resumeOnRestart;

  @override
  Future<void> restore() => run('restore', const [], () {
    _resumeOnRestart.value = storedOption;
  });

  @override
  Future<Result<void>> setResumeOnRestart(bool resume) =>
      answer('setResumeOnRestart', [resume], () {
        storedOption = resume;
        _resumeOnRestart.value = resume;
      });

  @override
  Future<void> saveIntent(SharingIntent intent) =>
      run('saveIntent', [intent], () => this.intent = intent);

  @override
  Future<void> clearIntent() =>
      run('clearIntent', const [], () => intent = null);

  @override
  Future<void> saveTexts(SharingResumeTexts texts) =>
      run('saveTexts', [texts], () => this.texts = texts);
}
