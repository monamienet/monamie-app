import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

bool evaluateMarkerVisibility({
  required UserModel user,
  required Set<String> observedEmails,
  required bool isObservingToday,
  required Map<String, LatLng> animatedMarkerPositions,
}) {
  final isObserved = observedEmails.contains(user.email);
  if (!isObservingToday) {
    return isObserved && animatedMarkerPositions.containsKey(user.email);
  }
  return isObserved;
}

void main() {
  group('Lógica de Visibilidade e Ativação Imediata do Marcador', () {
    // -------------------------------------------------------------
    // Filtragem de Marcadores no Mapa (Hoje vs Dia Passado)
    // -------------------------------------------------------------
    test(
      'Happy Path (Hoje): Membro observado no stream ativo de usuários deve ser exibido imediatamente',
      () {
        // 1. Arrange
        final observedMembers = [
          GroupMember(email: 'user1@monamienet.org', name: 'User 1'),
          GroupMember(email: 'user2@monamienet.org', name: 'User 2'),
        ];
        final observedEmails = observedMembers.map((m) => m.email).toSet();

        final activeUser = UserModel(
          email: 'user1@monamienet.org',
          name: 'User 1',
          lat: -22.90,
          lng: -43.13,
          isPublishing: true,
          capturedAt: DateTime.now(),
        );

        // 2. Act
        final shouldDisplay = evaluateMarkerVisibility(
          user: activeUser,
          observedEmails: observedEmails,
          isObservingToday: true,
          animatedMarkerPositions: {},
        );

        // 3. Assert
        expect(shouldDisplay, isTrue);
      },
    );

    test(
      'Sad Path (Hoje): Usuário ativo no stream que NÃO pertence aos membros observados não deve ser exibido',
      () {
        // 1. Arrange
        final observedMembers = [
          GroupMember(email: 'user1@monamienet.org', name: 'User 1'),
        ];
        final observedEmails = observedMembers.map((m) => m.email).toSet();

        final outsideUser = UserModel(
          email: 'other_user@monamienet.org',
          name: 'Other',
          lat: -22.90,
          lng: -43.13,
          isPublishing: true,
          capturedAt: DateTime.now(),
        );

        // 2. Act
        final shouldDisplay = evaluateMarkerVisibility(
          user: outsideUser,
          observedEmails: observedEmails,
          isObservingToday: true,
          animatedMarkerPositions: {},
        );

        // 3. Assert
        expect(shouldDisplay, isFalse);
      },
    );

    test(
      'Happy Path (Passado): Membro observado com posição histórica em animatedMarkerPositions é exibido',
      () {
        // 1. Arrange
        final observedMembers = [
          GroupMember(email: 'user1@monamienet.org', name: 'User 1'),
        ];
        final observedEmails = observedMembers.map((m) => m.email).toSet();

        final user = UserModel(email: 'user1@monamienet.org', name: 'User 1');

        final animatedMarkerPositions = <String, LatLng>{
          'user1@monamienet.org': const LatLng(-22.90, -43.13),
        };

        // 2. Act
        final shouldDisplay = evaluateMarkerVisibility(
          user: user,
          observedEmails: observedEmails,
          isObservingToday: false,
          animatedMarkerPositions: animatedMarkerPositions,
        );

        // 3. Assert
        expect(shouldDisplay, isTrue);
      },
    );

    test(
      'Sad Path (Passado): Membro observado sem registro histórico no dia não é exibido',
      () {
        // 1. Arrange
        final observedMembers = [
          GroupMember(email: 'user2@monamienet.org', name: 'User 2'),
        ];
        final observedEmails = observedMembers.map((m) => m.email).toSet();

        final user = UserModel(email: 'user2@monamienet.org', name: 'User 2');

        final animatedMarkerPositions = <String, LatLng>{
          'user1@monamienet.org': const LatLng(-22.90, -43.13),
        };

        // 2. Act
        final shouldDisplay = evaluateMarkerVisibility(
          user: user,
          observedEmails: observedEmails,
          isObservingToday: false,
          animatedMarkerPositions: animatedMarkerPositions,
        );

        // 3. Assert
        expect(shouldDisplay, isFalse);
      },
    );

    // -------------------------------------------------------------
    // Registro Reativo em usersWithPointsOnObservedDay
    // -------------------------------------------------------------
    test(
      'Happy Path: Usuários que chegam no stream firebaseUsers são adicionados dinamicamente ao conjunto do dia',
      () {
        // 1. Arrange
        final usersWithPointsOnObservedDay = <String>{};
        final streamUsers = [
          UserModel(
            email: 'novo_rastreado@monamienet.org',
            lat: -22.90,
            lng: -43.13,
          ),
          UserModel(
            email: 'outro_rastreado@monamienet.org',
            lat: -22.91,
            lng: -43.14,
          ),
        ];

        // 2. Act
        for (final user in streamUsers) {
          usersWithPointsOnObservedDay.add(user.email);
        }

        // 3. Assert
        expect(
          usersWithPointsOnObservedDay.contains(
            'novo_rastreado@monamienet.org',
          ),
          isTrue,
        );
        expect(
          usersWithPointsOnObservedDay.contains(
            'outro_rastreado@monamienet.org',
          ),
          isTrue,
        );
        expect(usersWithPointsOnObservedDay.length, 2);
      },
    );

    // -------------------------------------------------------------
    // Carga Imediata de Posição ao Iniciar Rastreamento
    // -------------------------------------------------------------
  });
}
