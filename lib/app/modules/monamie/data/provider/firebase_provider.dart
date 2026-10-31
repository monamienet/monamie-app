import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/modules/monamie/history/history_month.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:monamie_app/app/utils/group_email.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

class FirebaseProvider {
  CollectionReference get collectionRef => CurrentOrganizationFirebase
      .instance
      .organizationData
      .collection(FirestorePaths.positions);

  Future<void> adicionarDados(UserModel userLocation) async {
    try {
      await collectionRef.doc(userLocation.email).set({
        PositionFields.email: userLocation.email,
        PositionFields.lat: userLocation.lat,
        PositionFields.lng: userLocation.lng,
        PositionFields.capturedAt: userLocation.capturedAt,
        PositionFields.name: userLocation.name,
        PositionFields.isPublishing: userLocation.isPublishing,
      });
      if (kDebugMode) {
        print("Dados adicionados com sucesso!");
      }
    } catch (e) {
      throw Exception("Erro ao adicionar dados: $e");
    }
  }

  Future<void> setUser(UserModel user) async {
    try {
      await collectionRef.doc(user.email).set(user.toMap());
      debugPrint("Usuário criado com sucesso!");
    } catch (e) {
      throw Exception("Erro ao criar usuário!");
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    return collectionRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Every person's live document that points at [groupEmail], sharing or
  /// not, so the team list can say who turned the location off. The map keeps
  /// only the live ones (see `liveUsers`).
  Stream<List<UserModel>> streamUsersOfGroup(String groupEmail) {
    try {
      return collectionRef
          .where(
            PositionFields.groupId,
            isEqualTo: normalizeGroupEmail(groupEmail),
          )
          .snapshots()
          .map(
            (QuerySnapshot query) => [
              for (final doc in query.docs)
                UserModel.fromMap(doc.data() as Map<String, dynamic>),
            ],
          );
    } catch (e) {
      throw Exception("Erro ao buscar usuários do grupo: $e");
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    try {
      return collectionRef.snapshots().map((QuerySnapshot query) {
        List<UserModel> users = [];
        for (var doc in query.docs) {
          final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          if (user.capturedAt == null) continue;
          users.add(user);
        }
        return users;
      });
    } catch (e) {
      throw Exception("Erro ao buscar todos os usuários: $e");
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final DocumentSnapshot doc = await collectionRef.doc(email).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        //throw Exception("Documento não encontrado para o email: $email");
        return null;
      }
    } catch (e) {
      throw Exception(
        "Erro ao buscar localização do usuário por id do dispositivo: $e",
      );
    }
  }

  Future<void> updateIsPublishing(
    String email,
    bool isPublishing, {
    String? groupId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        PositionFields.isPublishing: isPublishing,
      };
      if (groupId != null) {
        data[PositionFields.groupId] = normalizeGroupEmail(groupId);
      }
      await collectionRef.doc(email).update(data);
      debugPrint("Campo isPublishing atualizado com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar isPublishing: $e");
      rethrow;
    }
  }

  Future<void> updateHeartbeat(String email) async {
    try {
      await collectionRef.doc(email).update({
        PositionFields.capturedAt: DateTime.now(),
      });
      debugPrint("Heartbeat atualizado com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar heartbeat: $e");
    }
  }

  Future<void> updateLocationAndTimestamp({
    required String email,
    required String name,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    String? groupId,
  }) async {
    try {
      // The position and its trail point go in one batch, both stamped
      // with the server's time: the rules limit how often a position may
      // change (Community plan) and only accept a point written together
      // with the position it records.
      final userDoc = collectionRef.doc(email);
      final Map<String, dynamic> userUpdates = {
        PositionFields.email: email,
        PositionFields.name: name,
        PositionFields.lat: lat,
        PositionFields.lng: lng,
        PositionFields.capturedAt: capturedAt,
        PositionFields.receivedAt: FieldValue.serverTimestamp(),
      };
      final Map<String, dynamic> pointData = {
        TrailPointFields.lat: lat,
        TrailPointFields.lng: lng,
        TrailPointFields.receivedAt: FieldValue.serverTimestamp(),
      };
      if (groupId != null) {
        userUpdates[PositionFields.groupId] = normalizeGroupEmail(groupId);
        pointData[TrailPointFields.groupId] = normalizeGroupEmail(groupId);
      }

      // The day summary marks the day in the history calendar, so a month
      // costs one read per person and day instead of every point.
      final daySummary = <String, dynamic>{
        TrailDayFields.lastAt: FieldValue.serverTimestamp(),
        TrailDayFields.pointCount: FieldValue.increment(1),
        TrailDayFields.groupId: ?pointData[TrailPointFields.groupId],
      };
      final batch = CurrentOrganizationFirebase.instance.firestore.batch()
        ..update(userDoc, userUpdates)
        ..set(userDoc.collection(FirestorePaths.trail).doc(), pointData)
        ..set(
          userDoc
              .collection(FirestorePaths.trailDays)
              .doc(dayKey(DateTime.now())),
          daySummary,
          SetOptions(merge: true),
        );
      await batch.commit();

      if (kDebugMode) print("Dados atualizados no firestore com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar coordenadas e timestamp: $e");
      rethrow;
    }
  }

  /// The days of [month] when any of [emails] shared their location, read
  /// from the day summaries (at most one read per person and day).
  Future<Set<String>> trailDays(
    Iterable<String> emails,
    HistoryMonth month,
  ) async {
    final (first, last) = month.keyRange;
    final days = <String>{};
    await Future.wait([
      for (final email in emails)
        collectionRef
            .doc(email)
            .collection(FirestorePaths.trailDays)
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: first)
            .where(FieldPath.documentId, isLessThanOrEqualTo: last)
            .get()
            .then((snapshot) => days.addAll(snapshot.docs.map((d) => d.id)))
            .catchError((Object e) {
              debugPrint('Could not read the days of $email: $e');
            }),
    ]);
    return days;
  }

  /// Retorna um Stream com os últimos [limit] pontos da trajetória de um
  /// usuário, das últimas 24 horas.
  Stream<List<LocationPoint>> getRecentTrajectory(
    String email, {
    int limit = 100,
  }) {
    final twentyFourHoursAgo = DateTime.now().subtract(
      const Duration(hours: 24),
    );

    return collectionRef
        .doc(email)
        .collection(FirestorePaths.trail)
        .where(
          TrailPointFields.receivedAt,
          isGreaterThanOrEqualTo: twentyFourHoursAgo,
        )
        .orderBy(TrailPointFields.receivedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final points = snapshot.docs
              .map((doc) => LocationPoint.fromMap(doc.data()))
              .toList();
          // Inverte para que a ordem dos pontos no mapa seja consistente cronologicamente
          return points.reversed.toList();
        });
  }

  /// Retorna o último ponto conhecido de um usuário em um dia específico.
  ///
  /// Útil para posicionar marcadores quando se observa um dia passado.
  /// Retorna `null` quando não há registros para o dia informado.
  Future<LocationPoint?> getLastKnownPositionForDate(
    String email, {
    required DateTime day,
  }) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await collectionRef
        .doc(email)
        .collection(FirestorePaths.trail)
        .where(TrailPointFields.receivedAt, isGreaterThanOrEqualTo: startOfDay)
        .where(TrailPointFields.receivedAt, isLessThan: endOfDay)
        .orderBy(TrailPointFields.receivedAt, descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return LocationPoint.fromMap(snapshot.docs.first.data());
  }

  /// Verifica se um usuário tem pelo menos um ponto registrado no dia informado.
  Future<bool> hasPointsOnDate(String email, DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await collectionRef
        .doc(email)
        .collection(FirestorePaths.trail)
        .where(TrailPointFields.receivedAt, isGreaterThanOrEqualTo: startOfDay)
        .where(TrailPointFields.receivedAt, isLessThan: endOfDay)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Retorna um Stream com os últimos [limit] pontos da trajetória de um
  /// usuário para um dia específico.
  Stream<List<LocationPoint>> getTrajectoryForDate(
    String email, {
    required DateTime day,
    int limit = 100,
  }) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return collectionRef
        .doc(email)
        .collection(FirestorePaths.trail)
        .where(TrailPointFields.receivedAt, isGreaterThanOrEqualTo: startOfDay)
        .where(TrailPointFields.receivedAt, isLessThan: endOfDay)
        .orderBy(TrailPointFields.receivedAt, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final points = snapshot.docs
              .map((doc) => LocationPoint.fromMap(doc.data()))
              .toList();
          return points.reversed.toList();
        });
  }

  Future<bool> doesDocumentExist(String email) async {
    try {
      final DocumentSnapshot doc = await collectionRef.doc(email).get();
      return doc.exists;
    } catch (e) {
      throw Exception("Erro ao verificar existência do documento: $e");
    }
  }

  Future<void> deleteUserByEmail(String email) async {
    try {
      await collectionRef.doc(email).delete();
      if (kDebugMode) {
        print("Usuário deletado com sucesso!");
      }
    } catch (e) {
      throw Exception("Erro ao deletar usuário: $e");
    }
  }
}
