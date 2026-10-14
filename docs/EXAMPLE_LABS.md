# Deckit example labs

Start **`res://examples/labs/lab_hub.tscn`** from Godot 4.7. No external assets or additional packages are required.

| Scene | Try | Layer |
|---|---|---|
| `zone_flow_lab.tscn` | Draw, move, discard, recycle, seeded shuffle, orientation and counters; see rejected moves at hand capacity 5 | New headless core |
| `rule_gate_lab.tscn` | Tagged cards, actor restrictions, optional rule toggling, capacity 2 and rejected actions with unchanged zones | New headless core + example-only custom rule |
| `legacy_ui_lab.tscn` | Hand horizontal/fan/arc layouts, card creation and presentation, face toggling and visual piles | Existing legacy UI |
| `presenter_lab.tscn` | State-driven card views, authoritative transfers, per-viewer disclosure, counters, rejection feedback | Optional presenter + core |
| `actions_lab.tscn` | Target selection, tag conditions, counter/face effects, move + effect sequences | Optional actions + core |

## Boundaries

- **All labs are outside `addons/deckit/`.** A consuming project installs only the plugin directory; the labs are optional.
- The new core intentionally does not enforce any particular card-game rules. `sample_access_rule.gd` is an **illustrative local policy**, not part of the plugin.
- The visual lab uses original UI nodes separately from the new state engine.
- The new presenter lab uses `DeckitCardView`/`DeckitZoneView` and requests game actions rather than changing state in UI callbacks. Its visual controls are deliberately simple and do not replace the legacy drag-and-drop implementation.
- Visibility flags are presentation hints, **not data security**: authoritative network code must avoid sending concealed definitions to unauthorized clients. A UI-to-core adapter is future work, not implemented implicitly in these demos.
- Card images in the visual lab are existing vector icons reused as development placeholders rather than commercial artwork.
- Tests are not substitutes for interactive editor validation. Confirm scene imports, clicks, layout changes and drag interactions on Godot 4.7.

## Runtime verification

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_core.gd
```

Open each lab in the graphical editor for user-interface interaction checks.
