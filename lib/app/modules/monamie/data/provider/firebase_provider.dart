import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

class FirebaseProvider {
  CollectionReference get collectionRef => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
  ).collection('usuarios');

  Future<void> adicionarDados(UserModel userLocation) async {
    // 1. Instanciar o Firestore com o app específico e banco de dados
    FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
    );

    // 2. Referenciar a coleção e adicionar dados
    try {
      await firestore.collection('usuarios').doc(userLocation.email).set({
        'email': userLocation.email,
        'lat': userLocation.lat,
        'lng': userLocation.lng,
        'timestamp': userLocation.timestamp,
        'nome': userLocation.nome,
        'isTracked': userLocation.isTracked,
      });
      if (kDebugMode) {
        print("Dados adicionados com sucesso!");
      }
    } catch (e) {
      throw Exception("Erro ao adicionar dados: $e");
    }
  }

  Future<void> setUser(UserModel user) async {
    FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      //app: Firebase.app(firebaseAppName),
      app: Firebase.app(),
      //databaseId: firestoreDatabaseId,
    );

    try {
      await firestore.collection('usuarios').doc(user.email).set(user.toMap());
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

  Stream<List<UserModel>> streamUsersByGroup(String groupEmail) {
    try {
      return collectionRef
          .where('grupo_ativo', isEqualTo: groupEmail)
          .where('isTracked', isEqualTo: true)
          .snapshots()
          .map((QuerySnapshot query) {
        List<UserModel> users = [];
        final limit = DateTime.now().subtract(const Duration(minutes: 5));
        for (var doc in query.docs) {
          final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          if (user.timestamp != null && user.timestamp!.isAfter(limit)) {
            users.add(user);
          }
        }
        return users;
      });
    } catch (e) {
      throw Exception("Erro ao buscar usuários do grupo: $e");
    }
  }

  Stream<List<UserModel>> getAllTrackedUsers() {
    try {
      return collectionRef.where('isTracked', isEqualTo: true).snapshots().map((
        QuerySnapshot query,
      ) {
        List<UserModel> users = [];
        final limit = DateTime.now().subtract(const Duration(minutes: 2));
        for (var doc in query.docs) {
          final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          if (user.timestamp != null && user.timestamp!.isAfter(limit)) {
            users.add(user);
          }
        }
        return users;
      });
    } catch (e) {
      throw Exception("Erro ao buscar usuários: $e");
    }
  }

  Stream<List<UserModel>> getAllUsers() {
    try {
      return collectionRef.snapshots().map((QuerySnapshot query) {
        List<UserModel> users = [];
        for (var doc in query.docs) {
          final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          if (user.timestamp == null) continue;
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

  Future<void> updateIsTracked(
    String email,
    bool isTracked, {
    String? grupoAtivo,
  }) async {
    try {
      final Map<String, dynamic> data = {'isTracked': isTracked};
      if (grupoAtivo != null) {
        data['grupo_ativo'] = grupoAtivo;
      }
      await collectionRef.doc(email).update(data);
      debugPrint("Campo isTracked atualizado com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar isTracked: $e");
      rethrow;
    }
  }

  Future<void> updateHeartbeat(String email) async {
    try {
      await collectionRef.doc(email).update({'timestamp': DateTime.now()});
      debugPrint("Heartbeat atualizado com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar heartbeat: $e");
    }
  }

  Future<void> updateLocationAndTimestamp({
    required String email,
    required String nome,
    required double lat,
    required double lng,
    required DateTime timestamp,
    String? grupoAtivo,
  }) async {
    try {
      final Map<String, dynamic> userUpdates = {
        'email': email,
        'nome': nome,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
      };
      if (grupoAtivo != null) {
        userUpdates['grupo_ativo'] = grupoAtivo;
      }

      await collectionRef.doc(email).update(userUpdates);

      // Salva o ponto na subcoleção permanente de histórico de posições.
      final Map<String, dynamic> pointData = {
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp,
      };
      if (grupoAtivo != null) {
        pointData['grupo_ativo'] = grupoAtivo;
      }

      await collectionRef.doc(email).collection('historico_posicoes').add(pointData);

      if (kDebugMode) print("Dados atualizados no firestore com sucesso!");
    } catch (e) {
      debugPrint("Erro ao atualizar coordenadas e timestamp: $e");
      rethrow;
    }
  }

  /// Retorna um Stream com os últimos [limit] pontos da trajetória de um
  /// usuário, das últimas 24 horas.
  Stream<List<LocationPoint>> getRecentTrajectory(
    String email, {
    int limit = 100,
  }) {
    final twentyFourHoursAgo =
        DateTime.now().subtract(const Duration(hours: 24));

    return collectionRef
        .doc(email)
        .collection('historico_posicoes')
        .where('timestamp', isGreaterThanOrEqualTo: twentyFourHoursAgo)
        .orderBy('timestamp', descending: true)
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
        .collection('historico_posicoes')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
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
        .collection('historico_posicoes')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
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
        .collection('historico_posicoes')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
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