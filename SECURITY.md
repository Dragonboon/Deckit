# Security policy

Deckit is a Godot plugin, not a network authority, encryption library or anti-cheat system.

## Supported code

The current development target is **Godot 4.7** on the repository's `main` branch. Older engine versions are not the supported target for this refactor.

## Reporting concerns

For security-sensitive problems, avoid posting exploits, private tokens or personal data in a public issue. Use GitHub's [private vulnerability reporting](https://github.com/sempitern0/Deckit/security/advisories/new) if it is enabled for this repository. If it is not available, ask the repository maintainer for a private reporting channel without disclosing exploit details.

## Important limitation

Card visibility settings are presentation hints. Do not distribute secret card definitions or authoritative game state to untrusted players when implementing multiplayer. The host game is responsible for access control, transport security and input validation.
