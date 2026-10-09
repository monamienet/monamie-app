# AGENTS.md

## Project Overview

This white-label application is maintained by the company MonAmieNet and provides clients services for tracking, coordination and comunication of teams.

## Business Archictecture

MonAmie has a single Google Developer Account, where every instance of this app is published.

Each instance of this app:
- belongs to one client $c$
- has its own and unique identity, which includes:
    - name (must be "MonAmie <instance_name>")
    - Application ID (Android) `android/app/build.gradle[.kts]`
    - Bundle Identifier (iOS) `ios/Runner.xcodeproj/project.pbxproj`
    - icons
    - theme
    - etc
- has its own separated Firebase Project which is associated to $c$'s billing account


## Frontend & Architectural Best Practices

### Asynchronous Actions & Visual Feedback
- **Immediate Visual Feedback**: Any interactive trigger initiating an asynchronous operation (background services, location hardware, authentication, remote queries) must immediately render a visible pending/loading state (e.g., progress spinner, transitional colors).
- **Debouncing & Reentrancy Guards**: Disable interactive triggers (`onPressed: null`) and protect controllers with reentrancy guard clauses (`if (isLoading.value) return;`) while operations are in flight to prevent concurrent executions and race conditions.
- **Guaranteed State Reset**: Always wrap asynchronous processes in `try ... finally` blocks to guarantee the loading state is reset on early returns or exceptions, preventing UI freezes.

### Contract & Interface Segregation (SOLID)
- **Dedicated Contract Files**: When creating abstract interfaces/contracts for widgets or controllers (e.g., to support dependency injection and testability), place the interface in its own dedicated file rather than inside the concrete implementation file.
- **Avoid Transitive Bloat**: Pure UI components and widget tests must only depend on lightweight contracts, avoiding transitive dependencies on heavy concrete controllers that import background services, map rendering, or native hardware plugins.

### Hardware & Sensor Operations UX
- **User-Facing Transparency**: Never silently swallow hardware or sensor timeouts (e.g., GPS satellite fix) with developer-only `debugPrint`. When a service starts but sensor calibration is pending, provide transparent, non-blocking user feedback (e.g., an informative SnackBar or status banner) clarifying that the service is running while satellites/hardware sync.
- **Defensive Timeouts**: Guard platform hardware and sensor calls (e.g., `Geolocator.getCurrentPosition()`) with sensible timeouts (e.g., 5 seconds) and `try/catch` blocks to prevent freezing or unhandled crashes during cold starts or weak-signal environments.


## Security & Guardrails

- Never commit or log API keys, access tokens, or secrets.
- Never alter database schemas or run destructive migrations automatically.
- Do not edit generated folders directly (`/generated`, `/dist`, lockfiles etc).