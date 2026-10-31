# MonAmie

Team tracking, coordination and communication. One app (`org.monamienet.app`) serves every partner organization: each partner keeps its own Firebase project, data and billing, and the app binds the user's partner (project, root group and branding) after Google sign-in.

- How partners, groups and users fit together, and how to onboard a partner without releasing the app: [docs/en-us/white-label.md](docs/en-us/white-label.md) ([pt-BR](docs/pt-br/white-label.md))
- Release to Play internal testing and the CI pipeline: [docs/en-us/publish-internal-testing.md](docs/en-us/publish-internal-testing.md), [docs/en-us/understanding-ci.md](docs/en-us/understanding-ci.md)
- Run the web app locally: [docs/en-us/run-web-locally.md](docs/en-us/run-web-locally.md)
- Plan to move groups and roles from Google Groups to Firestore (in progress, pt-BR): [docs/pt-br/migracao-grupos-firestore.md](docs/pt-br/migracao-grupos-firestore.md)
- Rules for contributors and coding agents: [AGENTS.md](AGENTS.md)

## Quick start

```sh
firebase login                       # reads the central project's config
flutter run                          # Android: fetches google-services.json on first build
dart run tool/partner.dart web       # web: stages web/central/firebase.json first
nice -n 15 flutter test test/unit -j 2
```
