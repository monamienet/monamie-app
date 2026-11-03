import 'package:monamie_app/domain/models/creation.dart';
import 'package:monamie_app/utils/result.dart';

/// Creating organizations (the central creation functions), behind a
/// contract so the screens are tested with a fake. Every method returns an
/// [Err] with a [Failure] instead of throwing.
abstract interface class CreationRepository {
  /// Whether [id] can be used: `null` when available, else why not (the
  /// server's own words as a [ServerRefusal], when it gives them).
  Future<Result<Failure?>> idProblem(String id);

  /// Creates the organization; returns its status after the call
  /// (`active` for Community, `awaiting_billing` for Standard, or
  /// `failed`).
  Future<Result<String>> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  });

  /// The signed-in account's organizations still being created.
  Future<Result<List<Creation>>> mine();
}
