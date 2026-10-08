import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Serviço centralizado para sincronização e validação dos Custom Claims
/// do MonAmie (`group_roles`).
///
/// Substitui as implementações duplicadas em `AuthGoogleController` e
/// `GoogleGroupsController`.
class MonAmieClaimsService {
  MonAmieClaimsService._();

  /// Sincroniza os Custom Claims chamando a Cloud Function `syncClaims`.
  ///
  /// 1. Obtém um token fresco para repassar à Cloud Function.
  /// 2. Chama a Cloud Function que computa os roles via Google Groups.
  /// 3. Força refresh do token para que os novos claims fiquem disponíveis.
  ///
  /// Retorna o mapa de roles retornado pela Cloud Function, ou `null` em
  /// caso de erro.
  static Future<Map<String, dynamic>?> syncClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[MonAmieClaimsService] Usuário não autenticado.');
        return null;
      }

      // 1. Token fresco para a Cloud Function repassar ao backend
      final rawToken = await user.getIdToken(true);
      if (rawToken == null) {
        debugPrint('[MonAmieClaimsService] Token nulo.');
        return null;
      }

      // 2. Chamar a Cloud Function
      final callable =
          FirebaseFunctions.instance.httpsCallable('syncClaims');
      final result = await callable.call({'idToken': rawToken});

      // 3. Forçar refresh para incorporar os claims recém-escritos
      await user.getIdToken(true);

      final data = result.data as Map<String, dynamic>?;
      final roles = data?['group_roles'];
      debugPrint('[MonAmieClaimsService] Claims sincronizados: $roles');
      return roles is Map<String, dynamic> ? roles : null;
    } catch (e) {
      debugPrint('[MonAmieClaimsService] Erro ao sincronizar claims: $e');
      return null;
    }
  }

  /// Lê os custom claims `group_roles` do token atual SEM forçar
  /// sincronização com a Cloud Function.
  ///
  /// Retorna o mapa de roles ou `null` se ausente.
  static Future<Map<String, dynamic>?> readClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;
      if (claims == null) {
        debugPrint('[MonAmieClaimsService] Token sem claims.');
        return null;
      }

      final groupRoles = claims['group_roles'];
      debugPrint('[MonAmieClaimsService] Claims lidos do token: $groupRoles');

      if (groupRoles == null || groupRoles is! Map) return null;
      return Map<String, dynamic>.from(groupRoles);
    } catch (e) {
      debugPrint('[MonAmieClaimsService] Erro ao ler claims: $e');
      return null;
    }
  }

  /// Verifica se o token atual contém claims de observável (MEMBER ou
  /// MANAGER em pelo menos um grupo).
  static Future<bool> isObservavel() async {
    final roles = await readClaims();
    if (roles == null || roles.isEmpty) return false;
    return roles.values.any(
      (role) => role == 'MEMBER' || role == 'MANAGER',
    );
  }

  /// Garante que os custom claims estejam presentes e válidos.
  ///
  /// 1. Lê os claims atuais.
  /// 2. Se estiverem presentes e válidos (contêm MEMBER/MANAGER), retorna `true`.
  /// 3. Se não, tenta sincronizar via Cloud Function.
  /// 4. Após sincronização, valida novamente.
  ///
  /// Retorna `true` se os claims estão válidos, `false` caso contrário.
  static Future<bool> ensureClaims() async {
    // Primeiro tenta ler os claims existentes
    final existingRoles = await readClaims();
    if (existingRoles != null && existingRoles.isNotEmpty) {
      final hasObservableRole = existingRoles.values.any(
        (role) => role == 'MEMBER' || role == 'MANAGER',
      );
      if (hasObservableRole) {
        debugPrint(
          '[MonAmieClaimsService] Claims já válidos: $existingRoles',
        );
        return true;
      }
    }

    // Claims ausentes ou inválidos — tentar sincronizar
    debugPrint(
      '[MonAmieClaimsService] Claims ausentes/inválidos. '
      'Tentando sincronizar...',
    );
    final syncedRoles = await syncClaims();

    if (syncedRoles == null || syncedRoles.isEmpty) {
      debugPrint('[MonAmieClaimsService] Sincronização retornou vazio.');
      return false;
    }

    final hasObservableRole = syncedRoles.values.any(
      (role) => role == 'MEMBER' || role == 'MANAGER',
    );

    if (!hasObservableRole) {
      debugPrint(
        '[MonAmieClaimsService] Nenhum role observável encontrado '
        'após sincronização: $syncedRoles',
      );
    }

    return hasObservableRole;
  }
}

