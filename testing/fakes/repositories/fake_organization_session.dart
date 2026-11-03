import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';

import 'fake_organization_binding_store.dart';
import 'fake_outcomes.dart';

/// [OrganizationSession] (and so `OrganizationBinder`) without Firebase:
/// binding sets [Organization.current], as the real one does, and keeps
/// the binding in [store]; forgetting clears both. No Firebase app is
/// created, so nothing reaches the organization's project.
///
/// [Organization.current] is global: a test that binds or forgets through
/// this fake restores it afterwards.
class FakeOrganizationSession with FakeOutcomes implements OrganizationSession {
  FakeOrganizationSession({FakeOrganizationBindingStore? store})
    : store = store ?? FakeOrganizationBindingStore();

  /// Where the binding is remembered.
  final FakeOrganizationBindingStore store;

  /// The binding bound in this "isolate", or `null`.
  OrganizationBinding? bound;

  @override
  Future<void> bind(OrganizationBinding binding, {bool remember = true}) =>
      run('bind', [binding, remember], () async {
        bound = binding;
        Organization.bind(binding.organization);
        if (remember) await store.write(binding);
      });

  @override
  Future<OrganizationBinding?> restore() => run('restore', const [], () async {
    final binding = await store.read();
    if (binding != null) {
      bound = binding;
      Organization.bind(binding.organization);
    }
    return binding;
  });

  @override
  Future<void> storeBranding(OrganizationConfig organization) =>
      run('storeBranding', [organization], () async {
        final binding = await store.read();
        if (binding == null || binding.organization.id != organization.id) {
          return;
        }
        await store.write(binding.copyWith(organization: organization));
      });

  @override
  Future<void> forget() => run('forget', const [], () async {
    bound = null;
    await store.clear();
    Organization.unbind();
  });
}
