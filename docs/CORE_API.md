# Deckit core API (first iteration)

The core classes live in `addons/deckit/src/core/`. They have no dependency on the visual hand, pile or deck nodes. They are **initial building blocks**, not a complete TCG/LCG rules engine.

## Ownership

| Class | Role |
| --- | --- |
| `DeckitCardDefinition` | Editable, reusable Resource with ID, presentation, tags and arbitrary game-specific attributes |
| `DeckitCardInstance` | Runtime copy with a host-assigned unique ID, ownership, controller, orientation, counters and state |
| `DeckitCardZone` | Ordered collection (top = last entry), optional capacity, owner, visibility metadata and seeded shuffle |
| `DeckitCardAction` | Validated transfer of a specific card instance between registered zones |
| `DeckitCardRule` | Overridable Resource hook for game-owned restrictions |
| `DeckitGameState` | Zone/rule registry and action execution with accepted/rejected signals |

## Example: draw into a hand

```gdscript
var definition := DeckitCardDefinition.new()
definition.card_id = &"spark"
definition.display_name = "Spark"
definition.attributes = {"cost": 1, "damage": 2}

var card := DeckitCardInstance.new(definition, &"player1-0001")
card.owner_id = &"player1"
card.controller_id = &"player1"

var draw_pile := DeckitCardZone.new(&"draw", &"player1")
var hand := DeckitCardZone.new(&"hand", &"player1")
hand.capacity = 7

var game := DeckitGameState.new()
game.register_zone(draw_pile)
game.register_zone(hand)
draw_pile.add_card(card)

var action := DeckitCardAction.new(&"draw", &"hand", card.instance_id, &"player1")
assert(game.perform(action))
```

A full deck uses many *instances* referencing shared *definitions*. Do not reuse an instance ID for separate copies. Give each card a stable ID from the host game's authoritative state.

## Rules and limitations

- A transfer checks **both zones**, the card's instance ID and the destination capacity, then applies rules **before** moving the card. Rejected transfers do not alter either zone.
- Subclass `DeckitCardRule`, override `allows(action, game)`, and register it with `game.register_rule(rule)` for game-specific constraints. The default rule permits transfers; **ownership, turn order, costs, visibility, combat and effects are not automatically enforced**.
- `DeckitCardZone.Visibility` describes intended visibility only. A networked game must filter concealed card definitions and instance state on the authoritative side.
- `DeckitCardZone.shuffle_with_rng(rng)` uses the provided `RandomNumberGenerator`; store/manage its seed and state if you need reproducibility.
- Direct calls to a zone bypass game rules. For game actions, use `DeckitGameState.perform()`.
- Visual nodes in `src/components/ui/` remain the legacy interface. Binding them to the headless state is a **separate future step**, not an implicit promise of integration in this iteration.
- No built-in persistence or networking protocol has been introduced yet.

## Tests

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_core.gd
```

Use Godot 4.7.x. The smoke test covers shared definitions, independent instance state, zone capacity and ordering, transfer failure safety, rule vetoes, and draw/shuffle basics.
