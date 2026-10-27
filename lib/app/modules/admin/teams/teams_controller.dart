import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'team.dart';
import 'teams_backend.dart';

/// State of the owner's team screens (*Equipes*, *Criar equipe*,
/// *Equipe*). One operation at a time: [isWorking] guards reentrancy and
/// drives the pending states; it always resets in `finally`.
class TeamsController extends GetxController {
  TeamsController({required this.partnerId, required TeamsBackend backend})
    : _backend = backend;

  final String partnerId;
  final TeamsBackend _backend;

  final RxList<Team> teams = <Team>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isWorking = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// "12 de 99".
  String get countLabel => '${teams.length} de 99';

  Team? byNumber(String number) =>
      teams.firstWhereOrNull((t) => t.number == number);

  /// Why [name] cannot be a new team (or the new name of [renaming]).
  String? nameProblem(String name, {String? renaming}) => teamNameProblem(
    name,
    teams.where((t) => t.number != renaming).map((t) => t.name),
  );

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      teams.assignAll(await _backend.list(partnerId));
    } on TeamsException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('[Teams] Could not load: $e');
      errorMessage.value = 'Não foi possível carregar as equipes.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Runs [operation] guarded; returns its result, or `null` when it did
  /// not run or failed (the message is in [errorMessage]).
  Future<T?> _guarded<T>(Future<T> Function() operation) async {
    if (isWorking.value) return null;
    isWorking.value = true;
    errorMessage.value = '';
    try {
      return await operation();
    } on TeamsException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      debugPrint('[Teams] Operation failed: $e');
      errorMessage.value =
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.';
      return null;
    } finally {
      isWorking.value = false;
    }
  }

  /// Creates a team; returns it, or `null` on failure.
  Future<Team?> create(String name) => _guarded(() async {
    final team = await _backend.create(partnerId, name.trim());
    teams.add(team);
    return team;
  });

  Future<bool> rename(String number, String name) async =>
      await _guarded(() async {
        await _backend.rename(partnerId, number, name.trim());
        await load();
        return true;
      }) ??
      false;

  Future<({List<String> loses, List<String> stays})?> deletionImpact(
    String number,
  ) => _guarded(() => _backend.deletionImpact(partnerId, number));

  Future<bool> delete(String number) async =>
      await _guarded(() async {
        await _backend.delete(partnerId, number);
        teams.removeWhere((t) => t.number == number);
        return true;
      }) ??
      false;

  /// Sets [email]'s roles in team [number]; never none.
  Future<bool> setRoles(
    String number,
    String email,
    Set<TeamRole> roles,
  ) async {
    if (roles.isEmpty) {
      errorMessage.value = 'Escolha pelo menos um papel.';
      return false;
    }
    return await _guarded(() async {
          await _backend.setRoles(partnerId, number, email, roles);
          await load();
          return true;
        }) ??
        false;
  }

  Future<bool> remove(String number, String email) async =>
      await _guarded(() async {
        await _backend.remove(partnerId, number, email);
        await load();
        return true;
      }) ??
      false;
}
