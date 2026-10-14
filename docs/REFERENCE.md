# Deckit API reference

Deckit's architecture separates **card data**, **runtime state**, **presentation**, and **optional game flow**. No component assumes a particular card game, turn order or combat system.

## Core model and rules

| Class | Purpose |
| --- | --- |
| `DeckitCardDefinition` | Reusable `Resource` with ID, artwork, tags and arbitrary attributes |
| `DeckitCardInstance` | One runtime copy: instance ID, owner, controller, orientation, counters |
| `DeckitCardZone` | Ordered collection with capacity, owner, visibility, shuffle, peek and search |
| `DeckitCardAction` | Move an instance from a source zone to a destination zone |
| `DeckitCardRule` | Custom `Resource` with `allows(action, game)` |
| `DeckitGameState` | Register zones/rules and process actions through `perform(action)` |

A zone's **top card is its last entry**. `DeckitCardZone.shuffle_with_rng(rng)` accepts a caller-owned random generator for reproducible shuffles. `game.perform()` checks source, destination, instance and capacity, applies registered rules and emits accepted/rejected signals.

Register a game-specific rule by subclassing `DeckitCardRule` and overriding `allows()`; Deckit does not automatically enforce player ownership, suit-following, timing, payment or victory.

`DeckitGameState.inspect_integrity()` can report invalid runtime cards, duplicate instance IDs and zone registry inconsistencies.

## Catalogs, deck recipes and setup

| Class | Purpose |
| --- | --- |
| `DeckitCardCatalog` | Searchable definitions, unique IDs, ID validation |
| `DeckitDeckList` / `DeckitDeckEntry` | Editable counts by card ID and section (`main`, `side`, etc.) |
| `DeckitDeckRules` / `DeckitDeckSectionRule` | Optional size, copy, section, tag and forbidden-card limits |
| `DeckitDeckRule` / `DeckitDeckValidator` / `DeckitDeckIssue` | Extend validation and report why a recipe is invalid |
| `DeckitDeckCodec` | Export/import portable deck-recipe JSON v1 |
| `DeckitDeckFactory` | Validate a recipe and build independent runtime card instances |
| `DeckitDealer` | Deal round-robin through `DeckitGameState.perform()` |

Individual definitions may also impose `deck_limit`; the stricter positive copy limit wins. **Drafts may be invalid** while being edited, but validate before starting a match.

```gdscript
var factory := DeckitDeckFactory.new()
var cards := factory.build(deck_list, catalog, &"main", &"player-1", "player1", deck_rules)
if factory.last_errors.is_empty():
    for card in cards:
        draw_zone.add_card(card)
```

Reusing an instance ID in different zones is invalid. Each factory allocates IDs within its own lifetime; manage unique prefixes/identities across factories and network peers. The dealer stops after a failed action but does **not** undo earlier moves.

## Traditional playing-card helpers

- `DeckitCardRanking.compare()` and `trick_winner()` compare configured suit/rank attributes, with optional trump and caller-provided **strongest-first** rank order.
- `DeckitCardPatterns.attribute_counts()`, `all_share()` and `is_run()` support generic rank/suit groupings and runs. `is_run()` accepts a **lowest-first** rank order.

Neither helper implements the full rules of Brisca, Tute, Poker, Blackjack or Rummy. The game decides legal plays, scoring, tie-breaking and special ranks.

## Presentation

- `DeckitCardView`: one card as a `Button`; emits `card_requested(instance_id)`.
- `DeckitZoneView`: renders one registered zone, emits `card_requested(zone_id, instance_id)` and refreshes when movements affect the zone.
- `DeckitDeckBuilderUI`: optional deck-construction interface (see [Getting started](GETTING_STARTED.md)).
- **Classic UI:** `DeckitPlayingCard`, `DeckitPlayingCardUI`, `DeckitCardHand`, `DeckitCardPile`, `DeckitDeck`, `DeckitDraggable2D`, `DeckitDeckCreator`, `DeckitDeckPreloader`.

```gdscript
var zone_view := DeckitZoneView.new()
add_child(zone_view)
zone_view.bind(game, &"hand", &"player-1")
zone_view.card_requested.connect(
    func(source_id: StringName, card_id: StringName) -> void:
        game.perform(DeckitCardAction.new(source_id, &"table", card_id, &"player-1"))
)
```

`DeckitCardZone.Visibility` supports `PUBLIC`, `OWNER_ONLY` and `HIDDEN` display hints. Public cards reveal faces when `face_up` is true; owned-zone display depends on matching viewer/owner ID. **This is display policy, not multiplayer secrecy:** filter unauthorized card data before transmission. Direct changes to card counters/faces require `view.refresh()`; successfully performed actions notify bound zone views.

The classic visual nodes and the headless state API are **not automatically synchronized**.

## Targets, actions and effects

| Class | Purpose |
| --- | --- |
| `DeckitCardTarget` / `DeckitTargetSelection` | Address a card by zone/instance and select a bounded set |
| `DeckitCardCondition` / `DeckitTagCondition` | Extend eligibility predicates |
| `DeckitCardEffect` / `DeckitCounterEffect` / `DeckitFaceEffect` | Apply game-neutral or custom state changes |
| `DeckitEffectAction` | Execute a targeted effect through the standard action/rule gateway |
| `DeckitActionSequence` | Execute a bounded list of actions in order |

```gdscript
var effect := DeckitCounterEffect.new()
effect.counter_key = &"charge"
effect.delta = 1
var target := DeckitCardTarget.new(&"table", &"unit-01")
game.perform(DeckitEffectAction.new().configure(effect, target, &"player-1"))
```

Selections check existence; **game permission is still the responsibility of registered rules**. Sequences are **nontransactional**: successful early steps remain if a later step fails.

## Events and resolution

`DeckitGameEvent` describes a notification. `DeckitEventResponder` is a `Resource` you subclass to propose actions. `DeckitEventQueue` records `action.applied` / `action.rejected` when bound, and can receive custom events.

```gdscript
var queue := DeckitEventQueue.new()
queue.bind(game)
queue.register_responder(my_responder)
game.perform(an_action)
queue.drain()  # Explicit, not automatic.
```

Higher-priority events and responders resolve first, FIFO within equal priorities. The queue offers limits for pending events, actions per event, causal depth and repeated signatures, as well as cancellation and a bounded trace via `get_trace()`. Rejection policies `CONTINUE`, `STOP_EVENT` and `STOP_DRAIN` determine whether processing continues after a response fails. Events and actions cannot be rolled back by the queue.

## Turn phases and player priority

```gdscript
var turns := DeckitTurnManager.new()
turns.configure([&"alice", &"bob"], [&"setup", &"action", &"cleanup"])
turns.start()
turns.next_phase()
turns.end_turn()
```

`DeckitTurnManager` optionally supports pause/resume, round tracking and `DeckitTurnTransitionRule` for vetoing transitions. `DeckitTurnEventBridge` optionally publishes phase/turn notifications.

`DeckitPriorityWindow` is separate: stage proposals, rotate between priority holders, pass and resolve one action after everyone passes. It supports LIFO (default) and FIFO response ordering. `DeckitPriorityTurnGate` optionally blocks turn advances during a window; `DeckitPriorityEventBridge` publishes window notifications. The game decides **when** to open these windows and which actions are legal.

## Scores, resources and win predicates

`DeckitValueLedger` stores signed numeric tracks (points, energy, health, money, etc.) by participant; `grant()` and `pay()` operate on integer dictionaries, and payment succeeds only if **all** costs are affordable.

`DeckitThresholdGoal` checks a configured numeric threshold (at least, at most, equals); it does not start or end a game automatically.

## Boundaries

Deckit is a toolkit, **not a complete Spanish/French card-game, TCG or LCG engine**. Rules for betting, combat, scenarios, network authority, hidden-information transport, persistent campaigns and match saves belong to your game. Only deck *recipes* currently have portable JSON support. The included example rules live under `examples/`, not `addons/deckit/`.

See [Examples](EXAMPLES.md) to inspect each module in isolation or in a small playable flow.
