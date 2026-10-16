# Agent guide — Deckit

Scope: entire repository. **Deckit is a modular Godot 4.7 card-game addon, not a complete game or a mandatory TCG ruleset.** The portable deliverable is `addons/deckit/`; `examples/` and `tests/` are development aids.

## 60-second orientation

1. Check the current `main` HEAD and relevant files before making changes; never assume a previous agent's plan still matches the code. Read `README.md` and the appropriate section of `docs/REFERENCE.md` before touching an API.
2. Locate the existing owner, caller and nearest test with targeted search. Do not copy an entire demo into the runtime plugin or create a parallel system when an existing module suffices.
3. Preserve public classes, signals, serialized Resources and stable card identities. Make a small, testable modification rather than broad unrelated cleanup.

| Task | Start in `addons/deckit/src/` | Evidence |
| --- | --- | --- |
| Definitions, instances, decks, zones | `core/`, `decks/` | `test_core.gd`, `test_actions.gd` |
| Legality, state transitions, targeting | `actions/`, `state/` | `test_actions.gd`, `test_resolution.gd`, `test_integration.gd` |
| Deck construction and formats | `building/` | `test_deck_builder.gd` |
| Signals, effects, responses, priority | `events/`, `priority/`, `turns/` | `test_events.gd`, `test_priority.gd`, `test_turns.gd`, `test_turn_signal_order.gd` |
| Drag/drop, fronts/backs, focus, zone UI | `presentation/`, `components/`, `traditional/` | `test_presentation.gd`, `test_drag_drop.gd`, `test_native_drag.gd`, `test_lab_visuals.gd` |
| Practical workflows and integration | `examples/labs/`, `docs/RECIPES.md` | `test_lab_workflows.gd`, `test_microgames.gd` |
| Editor installation | `plugin.gd`, `plugin.cfg` | `test_editor_bootstrap.gd`, clean addon-only import |

Test paths in the table are under `tests/headless/`. Look up exact API names rather than inferring contracts from folder names.

## Critical invariants

- A `DeckitCardDefinition` is a card type; a `DeckitCardInstance` is a specific physical/logical copy with a stable instance ID. DeckitCardZone stores ordered instances. Rule-checked transitions must go through the appropriate `DeckitGameState.perform()` path rather than bypassing its validation.
- **Classic visual controls and the newer headless state model are independent APIs.** Never imply they automatically synchronize. Add an explicit adapter only if requested and ensure backward compatibility.
- Hidden-card presentation is **not secrecy or authorization**. Do not expose hidden data under a claim of security, invent networking guarantees or treat UI visibility as permission enforcement.
- Actions and event sequences are **not transactional** and do not guarantee rollback. Do not document partial success as atomic; preserve event and turn ordering.
- Game-specific combat, deck limits, action legality, scoring, ownership and network trust stay in the consuming game or optional rules. Modules should remain separately useful.
- UI interactions must work for mouse and keyboard; preserve cancel/no-op semantics, correct visible fronts versus backs, meaningful focus, bounded table placement and accessible controls. The three focused labs are the primary hands-on examples; avoid proliferating labs.
- Do not introduce runtime references to repository-only demos, unnecessary autoloads, new third-party packages or generated import-cache dependencies.

## Efficient proof, not blanket execution

Use **Godot 4.7.x**. For a source change, import once, then run only the impacted regression scripts from `docs/TESTING.md`:

```sh
godot --version
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_actions.gd
```

Replace `test_actions.gd` with the test matching the change. On wider changes, run the complete enumerated suite in `docs/TESTING.md`; do not invent a CI workflow (this repository documents manual tests). For presentation, drag/drop, card visibility, focus or resizing, also launch `res://examples/labs/lab_hub.tscn`, check the three labs and a narrow viewport: headless pass alone is not a graphical acceptance test. For packaging changes, test a fresh project containing **only** `addons/deckit/`.

## Delivery

Update matching docs or examples and add focused regression coverage for behavior changes. When the user authorizes direct `main` commits, preserve unrelated work, do not force-push, and record exactly what was modified and tested. Do not claim execution or visual quality that you did not observe.
