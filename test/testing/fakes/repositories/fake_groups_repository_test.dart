import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../../testing/fakes/repositories/fake_groups_repository.dart';

GroupPerson _person(String email) =>
    GroupPerson(email: email, roles: const {GroupRole.publisher});

void main() {
  group('FakeGroupsRepository - Unit Test Suite', () {
    test('Happy Path: a created group is listed with a new id', () async {
      // 1. Arrange
      final fake = FakeGroupsRepository();

      // 2. Act
      final created = await fake.create('rotasul', 'Guias');
      final listed = await fake.list('rotasul');

      // 3. Assert
      final group = (created as Ok<Group>).value;
      expect(group.id, 'g1');
      expect((listed as Ok<List<Group>>).value, [group]);
    });

    test('Happy Path: setting roles adds a person or replaces their roles, '
        'and removing takes them out', () async {
      // 1. Arrange
      final fake = FakeGroupsRepository(
        groups: {
          'rotasul': [
            Group(id: 'g1', name: 'Guias', people: [_person('bia@x.com')]),
          ],
        },
      );

      // 2. Act
      await fake.setRoles('rotasul', 'g1', 'bia@x.com', {GroupRole.subscriber});
      await fake.setRoles('rotasul', 'g1', 'caio@x.com', {GroupRole.publisher});
      await fake.remove('rotasul', 'g1', 'bia@x.com');

      // 3. Assert
      expect(fake.groups['rotasul']!.single.people, [_person('caio@x.com')]);
    });

    test('Edge Case: deleting a group would cost access only to whoever is '
        'in no other group', () async {
      // 1. Arrange
      final fake = FakeGroupsRepository(
        groups: {
          'rotasul': [
            Group(
              id: 'g1',
              name: 'Guias',
              people: [_person('bia@x.com'), _person('caio@x.com')],
            ),
            Group(id: 'g2', name: 'Recepção', people: [_person('caio@x.com')]),
          ],
        },
      );

      // 2. Act
      final impact = await fake.deletionImpact('rotasul', 'g1');

      // 3. Assert
      final value =
          (impact as Ok<({List<String> loses, List<String> stays})>).value;
      expect(value.loses, ['bia@x.com']);
      expect(value.stays, ['caio@x.com']);
    });

    test('Sad Path: a failing create adds no group', () async {
      // 1. Arrange
      final fake = FakeGroupsRepository()
        ..fail('create', const Failure.groupNameTaken('Guias'));

      // 2. Act
      final created = await fake.create('rotasul', 'Guias');

      // 3. Assert
      expect(
        (created as Err<Group>).failure,
        const Failure.groupNameTaken('Guias'),
      );
      expect(fake.groups['rotasul'] ?? const [], isEmpty);
    });
  });
}
