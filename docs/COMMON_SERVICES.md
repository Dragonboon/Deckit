# Common card-game services

These optional utilities are **game-neutral**: they do not decide whose turn it is, which suit wins, which resources exist, or when a match is over.

## Build runtime cards from a deck recipe

`DeckitDeckFactory` validates a `DeckitDeckList` against its catalog and optional deck-building rules, then generates independent `DeckitCardInstance` objects with stable, incrementing IDs **within that factory instance**.

```gdscript
var factory := DeckitDeckFactory.new()
var copies := factory.build(deck_list, card_catalog, &"main", &"player-1", "player1", deck_rules)
assert(factory.last_errors.is_empty())
for card in copies:
    draw_zone.add_card(card)
```

Select `section_id = &""` to include every section, or pass a named section such as `&"main"`. Reuse the same factory to avoid reissuing IDs; distinct factories and peers still require globally unique prefixes or an authoritative ID allocator. Failed validation returns an empty array and reports errors without advancing its serial. The factory does **not** register zones, deal cards or save runtime state automatically.

## Deal cards through the action gateway

`DeckitDealer.deal_round_robin(game_state, source_id, destination_ids, cards_each, actor_id)` uses ordinary `DeckitCardAction` transfers. It respects zone capacity and registered rules. A denied action stops dealing; **successful earlier transfers are not rolled back**.

## Traditional rank and pattern utilities

`DeckitCardRanking` compares configurable suit/rank attributes, optional trump and caller-provided descending rank order. `trick_winner()` gives a candidate winner index; it does not decide if a card was legally played. When there is no lead/trump and suits differ, the comparison yields a tie.

`DeckitCardPatterns` counts shared attributes, checks whether all cards share a value and detects contiguous rank sequences. `is_run()` accepts an optional **ascending** rank order (unlike the ranking utility, which uses descending strength). There are no hardcoded Ace exceptions, meld scoring or poker classifications.

## Scores, resources and objectives

`DeckitValueLedger` stores signed numeric tracks per participant, such as `score`, `energy`, `coins`, or `health`. `grant()` and `pay()` accept dictionaries of integer amounts; `pay()` only applies when **all** requested balances are sufficient.

```gdscript
var ledger := DeckitValueLedger.new()
ledger.grant(&"player-1", {&"energy": 3, &"coins": 2})
assert(ledger.pay(&"player-1", {&"energy": 2, &"coins": 1}))
var goal := DeckitThresholdGoal.new()
goal.track_id = &"coins"
goal.threshold = 1
assert(goal.is_met(ledger, &"player-1"))
```

`DeckitThresholdGoal` is a simple predicate (at least, at most, equals). The game decides when to check it, whether the score is public and what outcome follows. This is **not** a combat, betting, scenario or end-of-match engine.

## Test

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_common_services.gd
```

This test and the feature descriptions document intended behavior; only a local Godot 4.7 run can validate runtime execution.
