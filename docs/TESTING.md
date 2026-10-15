# Testing and troubleshooting

Target engine: **Godot 4.7.x**. You can use the repository as an example project, or copy only `addons/deckit/` into a clean Godot project.

## First-run checklist

1. Open the Deckit project and let Godot scan/import files.
2. Enable the add-on in **Project → Project Settings → Plugins**.
3. Open `res://examples/labs/lab_hub.tscn` and try the three guided labs; optional microgames are in the expandable section.
4. For a clean-install check, copy **only** `addons/deckit/` into a new Godot 4.7.x project; confirm editor custom nodes and `DeckitCardDefinition.new()` are available.
5. Run the headless suite below after the import finishes.

## Full local test suite

From the project root:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_core.gd
godot --headless --path . --script res://tests/headless/test_actions.gd
godot --headless --path . --script res://tests/headless/test_presentation.gd
godot --headless --path . --script res://tests/headless/test_lab_visuals.gd
godot --headless --path . --script res://tests/headless/test_drag_drop.gd
godot --headless --path . --script res://tests/headless/test_native_drag.gd
godot --headless --path . --script res://tests/headless/test_lab_workflows.gd
godot --headless --path . --script res://tests/headless/test_events.gd
godot --headless --path . --script res://tests/headless/test_resolution.gd
godot --headless --path . --script res://tests/headless/test_turns.gd
godot --headless --path . --script res://tests/headless/test_priority.gd
godot --headless --path . --script res://tests/headless/test_turn_signal_order.gd
godot --headless --path . --script res://tests/headless/test_integration.gd
godot --headless --path . --script res://tests/headless/test_deck_builder.gd
godot --headless --path . --script res://tests/headless/test_game_families.gd
godot --headless --path . --script res://tests/headless/test_common_services.gd
godot --headless --path . --script res://tests/headless/test_microgames.gd
godot --headless --path . --script res://tests/headless/test_maintenance.gd
godot --headless --path . --script res://tests/headless/test_editor_bootstrap.gd
```

No GitHub Actions workflow is necessary. Running a test script without errors is different from checking graphical drag-and-drop, keyboard focus and resizing: inspect the labs in the editor as well.

## Common issues

**Editor plugin cannot load SVG icons (Godot 4.7.x).** Make sure you have the current `addons/deckit/plugin.gd`. It reads the SVG source files with `FileAccess` and creates editor textures without relying on `.godot/imported` cache resources.

**GDScript constant constructor error in Spanish Tricks.** The rank order is a literal `STRENGTH` array and converts to `PackedInt32Array` at the point of use. Update the example files if you are running an older checkout.

**A card view does not show a changed counter or face.** When editing an instance directly, call `DeckitZoneView.refresh()`. Normal `GameState.perform()` actions notify bound views.

**Card faces appear hidden.** Check `DeckitCardZone.Visibility`, `viewer_id` and `face_up` in [API reference](REFERENCE.md). This is only a visual display policy, not permission enforcement.

**Deck builder reports errors.** Check duplicate/unknown IDs, copy limits, size/section limits and tags. Invalid draft decks can be saved, but should be validated before play.

**Godot does not recognize a class.** Keep `addons/deckit/` intact, let the editor rescan, check the Output panel for a preceding parse error, and verify the Godot version.

## Supported behavior and limits

- Actions and event sequences are not transactional: successful steps cannot be rolled back automatically.
- Ownership and action legality require game-specific `DeckitCardRule` implementations.
- Networking, complete saved games, hidden-information security and game-specific combat/scoring rules are not built in.
- Classic visual controls and the newer headless state model remain separate APIs.

To report a reproducible error, use the [GitHub issue templates](https://github.com/Dragonboon/Deckit/issues/new/choose) with your engine version and the affected example or component.


## Drag/drop acceptance checks

`test_drag_drop.gd` covers pure hover checks, capacities, rules, foreign payloads,
stale/reset instances, cancellation, hidden faces, selection and bounded placement.
`test_native_drag.gd` pushes real mouse events into the viewport to exercise
Control's drag threshold, release routing, empty surface drops and cancellation.
`test_lab_workflows.gd` plays the guided draw/flip, LIFO/FIFO/reaction and deck
materialization flows, including reset and invalid recipes.

For graphical QA, check at 1120×820 and a narrower window: cards must have distinct
FRONT/BACK badges, readable captions, visible selection/focus and accessible buttons.
Draw/hand/discard panels wrap; the free surface stays inside its allotted area.
No gameplay tests require network access or GitHub Actions.
