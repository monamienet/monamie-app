# AGENTS.md

## Project Overview

This white-label application is maintained by the company MonAmieNet and provides clients services for tracking, coordination and comunication of teams.

## Business Archictecture

MonAmie has a single Google Developer Account, where every instance of this app is published.

Each instance of this app:
- belongs to one client $c$
- has its own and unique identity, which includes:
    - name (must be "MonAmie <instance_name>")
    - applicationId
    - bundleId
    - icons
    - theme
    - etc
- has its own separated Firebase Project which is associated to $c$'s billing account


## Security & Guardrails

- Never commit or log API keys, access tokens, or secrets.
- Never alter database schemas or run destructive migrations automatically.
- Do not edit generated folders directly (`/generated`, `/dist`, lockfiles etc).