import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/domain/models/creation.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [CreationRepository] over [takenIds] and [creations]: an id in
/// [takenIds] is not available; creating an organization takes its id and
/// lists it among [creations], `active` on Community and
/// `awaiting_billing` on Standard.
class FakeCreationRepository with FakeOutcomes implements CreationRepository {
  FakeCreationRepository({Set<String>? takenIds, List<Creation>? creations})
    : takenIds = {...?takenIds},
      creations = [...?creations];

  /// Why a taken id cannot be used, as [idProblem] says it.
  static const takenMessage = 'Este identificador já está em uso.';

  final Set<String> takenIds;

  /// The signed-in account's organizations being created.
  final List<Creation> creations;

  @override
  Future<Result<String?>> idProblem(String id) => answer('idProblem', [
    id,
  ], () => takenIds.contains(id) ? takenMessage : null);

  @override
  Future<Result<String>> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) => answer('create', [id, name, themeId, plan], () {
    final status = plan == 'community' ? 'active' : 'awaiting_billing';
    takenIds.add(id);
    creations.add(Creation(id: id, name: name, plan: plan, status: status));
    return status;
  });

  @override
  Future<Result<List<Creation>>> mine() =>
      answer('mine', const [], () => [...creations]);
}
