# Security and hidden-card information

Deckit is a local Godot toolkit, **not** a network server or an anti-cheat system.

- `DeckitCardZone.Visibility` and the optional visual components control what is **displayed**, not which card data a peer can access.
- Multiplayer and online games must filter concealed card definitions and state **before** sending data to other players, and validate actions on the authoritative side.
- The current project target is Godot 4.7.x. Refer to [Testing and troubleshooting](docs/TESTING.md) for installation checks and known boundaries.

If you find a security-sensitive issue, use [GitHub private vulnerability reporting](https://github.com/sempitern0/Deckit/security/advisories/new) if available, rather than publishing exploitable details in a public issue.
