import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/connections/google_service.dart';
import 'package:monamie_app/app/data/provider/google_groups_provider.dart';
import 'package:monamie_app/app/data/repository/google_groups_repository.dart';

class FakeService extends GoogleService {
  List<Map<String, dynamic>> result = [];
  Object? error;
  int entitiesCalls = 0;
  int userGroupsCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> getGroupEntities(String token, String groupEmail) async {
    entitiesCalls++;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserGroups(String token, String userEmail) async {
    userGroupsCalls++;
    if (error != null) throw error!;
    return result;
  }
}

class FakeProvider extends GoogleGroupsProvider {
  final Map<String, List<Map<String, dynamic>>> store = {};
  final List<String> saved = [];

  @override
  Future<void> saveGroupEntities(String groupEmail, List<Map<String, dynamic>> entities) async {
    saved.add(groupEmail);
    store[groupEmail] = entities;
  }

  @override
  Future<List<Map<String, dynamic>>?> getGroupEntities(String groupEmail) async => store[groupEmail];
}

void main() {
  late FakeService service;
  late FakeProvider provider;
  late GoogleGroupsRepository repo;
  final data = [
    {'email': 'a@x.com'}
  ];
  final cachedData = [
    {'email': 'cached@x.com'}
  ];

  setUp(() {
    service = FakeService();
    provider = FakeProvider();
    repo = GoogleGroupsRepository(googleService: service, provider: provider);
  });

  group('GoogleGroupsRepository.userGroupsKey', () {
    test('Edge Case: normaliza caixa e espaços com prefixo', () {
      // 1. Arrange
      const email = '  User@X.com ';

      // 2. Act
      final key = GoogleGroupsRepository.userGroupsKey(email);

      // 3. Assert
      expect(key, 'user-groups:user@x.com');
    });
  });

  group('GoogleGroupsRepository.getGroupEntities', () {
    test('Happy Path: grava no cache após sucesso', () async {
      // 1. Arrange
      service.result = data;

      // 2. Act
      final result = await repo.getGroupEntities('t', 'g@x.com');

      // 3. Assert
      expect(result, data);
      expect(provider.store['g@x.com'], data);
    });

    test('Happy Path: retorna cache não vazio sem chamar o serviço', () async {
      // 1. Arrange
      provider.store['g@x.com'] = cachedData;

      // 2. Act
      final result = await repo.getGroupEntities('t', 'g@x.com');

      // 3. Assert
      expect(result, cachedData);
      expect(service.entitiesCalls, 0);
    });

    test('Edge Case: cache vazio é tratado como ausente', () async {
      // 1. Arrange
      provider.store['g@x.com'] = [];
      service.result = data;

      // 2. Act
      final result = await repo.getGroupEntities('t', 'g@x.com');

      // 3. Assert
      expect(result, data);
      expect(service.entitiesCalls, 1);
    });

    test('Edge Case: forceRefresh ignora o cache', () async {
      // 1. Arrange
      provider.store['g@x.com'] = cachedData;
      service.result = data;

      // 2. Act
      final result = await repo.getGroupEntities('t', 'g@x.com', forceRefresh: true);

      // 3. Assert
      expect(result, data);
      expect(service.entitiesCalls, 1);
    });

    test('Sad Path: exceção propaga e não grava cache', () async {
      // 1. Arrange
      service.error = Exception('boom');

      // 2. Act
      action() => repo.getGroupEntities('t', 'g@x.com');

      // 3. Assert
      await expectLater(action(), throwsA(isA<Exception>()));
      expect(provider.saved, isEmpty);
    });
  });

  group('GoogleGroupsRepository.getUserGroups', () {
    final key = GoogleGroupsRepository.userGroupsKey('U@x.com');

    test('Happy Path: grava no cache com a chave do usuário após sucesso', () async {
      // 1. Arrange
      service.result = data;

      // 2. Act
      final result = await repo.getUserGroups('t', 'U@x.com');

      // 3. Assert
      expect(result, data);
      expect(provider.store[key], data);
    });

    test('Happy Path: retorna cache não vazio sem chamar o serviço', () async {
      // 1. Arrange
      provider.store[key] = cachedData;

      // 2. Act
      final result = await repo.getUserGroups('t', ' u@X.com');

      // 3. Assert
      expect(result, cachedData);
      expect(service.userGroupsCalls, 0);
    });

    test('Edge Case: cache vazio é tratado como ausente', () async {
      // 1. Arrange
      provider.store[key] = [];
      service.result = data;

      // 2. Act
      final result = await repo.getUserGroups('t', 'U@x.com');

      // 3. Assert
      expect(result, data);
      expect(service.userGroupsCalls, 1);
    });

    test('Edge Case: forceRefresh ignora o cache', () async {
      // 1. Arrange
      provider.store[key] = cachedData;
      service.result = data;

      // 2. Act
      final result = await repo.getUserGroups('t', 'U@x.com', forceRefresh: true);

      // 3. Assert
      expect(result, data);
      expect(service.userGroupsCalls, 1);
    });

    test('Sad Path: exceção propaga e não grava cache', () async {
      // 1. Arrange
      service.error = Exception('boom');

      // 2. Act
      action() => repo.getUserGroups('t', 'U@x.com');

      // 3. Assert
      await expectLater(action(), throwsA(isA<Exception>()));
      expect(provider.saved, isEmpty);
    });
  });
}

