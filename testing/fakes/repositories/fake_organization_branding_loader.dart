import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';

import 'fake_outcomes.dart';

/// [OrganizationBrandingLoader] over [brandings], by organization id: an
/// organization without one gets the fallback branding (its capitalized id
/// as name, MonAmie's colors), as when the real document cannot be read.
/// Nothing is read from Firestore or downloaded.
class FakeOrganizationBrandingLoader
    with FakeOutcomes
    implements OrganizationBrandingLoader {
  FakeOrganizationBrandingLoader({Map<String, OrganizationConfig>? brandings})
    : brandings = {...?brandings};

  final Map<String, OrganizationConfig> brandings;

  @override
  Future<OrganizationBinding> load(OrganizationCandidate candidate) =>
      run('load', [candidate], () {
        return OrganizationBinding(
          organization:
              brandings[candidate.id] ??
              OrganizationConfig.fromBranding(candidate.id, null),
          options: candidate.options,
        );
      });

  @override
  Future<OrganizationConfig> readBranding(OrganizationBinding binding) => run(
    'readBranding',
    [binding],
    () => brandings[binding.organization.id] ?? binding.organization,
  );
}
