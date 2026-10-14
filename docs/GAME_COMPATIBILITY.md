# Deckit capability audit — October 2026

**Baseline:** `main` at commit `7580287`, Godot 4.7 target. This document assesses the **mechanics implemented in source**, not completed games. The headless runtime was unavailable during this assessment. The companion representative test `tests/headless/test_game_families.gd` must be executed locally in Godot 4.7.

## Interpretation

- **Core support:** the game can be implemented using existing generic objects, with its own rule scripts.
- **Partial:** several building blocks exist but an essential reusable helper or integration is missing.
- **Not built in:** implement in the consuming game's code; no automatic solution exists in Deckit.

| Mechanic | Current status | Implementation |
| --- | --- | --- |
| French / Spanish suits, values, textures | Core support | `DeckitPlayingCard`, `DeckitDeckCreator` (classic API), or custom attributes in `DeckitCardDefinition` |
| Fixed deck sizes, custom variants and jokers | Core support | Catalog, deck list, configurable validation rules |
| Draw, deal, move, discard, shuffle, card order | Core support | `DeckitCardZone`, `DeckitCardAction`, seeded shuffle |
| Multiple players, phases and rounds | Core support | Optional `DeckitTurnManager` |
| Selection, cards face up/down, counters | Core support | Instances, target selection, generic effects |
| Hand/pile visuals and interactions | Partial | Classic UI and newer presentation API are separate |
| Scorekeeping and end-of-game detection | Not built in | No score/goal rule engine or standard game result model |
| Trick taking (follow suit, trump, winning trick) | Not built in | A consuming game must implement comparison and legal-play rules |
| Betting, pots, raises, chips and side pots | Not built in | No betting or settlement subsystem |
| Blackjack totals, ace flexibility, dealer policy | Not built in | Host rules; card ranks available as custom data |
| Solitaire tableau rules, stock recycling, automated setup | Partial | Zones and movement exist; layouts and tableau rules are host-owned |
| Game-specific combinations (poker hands, melds, runs) | Not built in | No reusable combination evaluator |
| TCG/LCG deck-building caps, card bans, section rules | Core support | `DeckitDeckRules`/`DeckitDeckValidator`, custom rule hooks |
| Card resources, costs, payments, attack/defense, health | Partial | Arbitrary attributes/counters/effects exist; no accounting or combat services |
| Triggers, reactions, action order, interruption windows | Partial | Events, conditions, responders and priority windows; no full timing/ability language |
| Statuses, keywords, continuous/modifying effects | Partial | Generic tags and mutable state; no duration/layer/replacement system |
| Scenario decks, encounter zones, cooperative objectives | Partial | Arbitrary zones and deck sections; no encounter/scenario controller |
| Campaign progression, rewards, persistent player state | Not built in | Deck JSON is a **recipe**, not a saved game |
| Card ownership and concealed information | Partial | Identity and UI visibility hints; host must enforce permissions and filter hidden data |
| Runtime deck materialization and unique ID assignment | Partial | Manual instance creation required; no shared factory |
| Persistence, undo/replay and atomic rollback | Not built in | Only deck recipe import/export, nontransactional actions |
| Deterministic multiplayer synchronization and authoritative server | Not built in | IDs/RNG patterns help, but there is no transport/state reconciliation |
| AI opponents and tutorial/automation helpers | Not built in | External game logic required |

## Representative genres and completion outlook

| Family | Examples to evaluate | Viability with current Deckit | Missing gameplay rules |
| --- | --- | --- | --- |
| Spanish 40/48-card games | Brisca, Tute, Mus, Escoba, Cinquillo | **Foundation ready, not plug-and-play** | Following suits/trumps, scores, betting, card combinations and legal-move checks |
| French classic games | Poker, Blackjack, Rummy, Hearts, Bridge | **Foundation ready, not plug-and-play** | Hand evaluators, dealer/bets, melds, trick resolution, bidding and scoring |
| Solitaire/patience | Klondike, FreeCell | **Partially ready** | Specialized tableau moves, cascades, automatic setups and win checks |
| TCG | Configurable resource/combat deck duel | **Partially ready** | Cost payment, trigger ordering, attack/combat, duration effects, victory state |
| LCG/cooperative | Scenario encounter and hero/deck systems | **Partially ready** | Encounter AI, objectives, campaigns, game-state saves and scenario rules |

These labels **do not claim complete gameplay support**. They describe whether a developer has suitable reusable primitives. Rule implementations are intentionally not part of the generic plug-in.

## Representative regression

The companion headless test builds 40 Spanish and 52 French definitions, deck recipes, runtime card instances, shuffle/deal/table workflows, a four-participant phase cycle, basic TCG/LCG deck constraints and effects, and duplicate instance-ID diagnostics.

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_game_families.gd
```

**Required additional checks:** launch a clean project containing only `addons/deckit/`, run the nine interactive labs in this repository, and confirm the test script exits with code 0. These were not executed in this audit environment.

## Priority gaps for broad game coverage

1. **Declarative rule helpers:** card rank/suit comparison, combinations, score tables and victory/round outcome checks as optional utilities.
2. **Runtime factories and lifecycle:** turn deck recipes into unique instances, deal hands and reset hands/matches with stable IDs.
3. **Reusable state services:** typed resources/costs, game counters, score trackers and configurable action restrictions.
4. **Advanced timing and effects:** layered modifiers, duration, automatic trigger registration and replacement rules.
5. **Game persistence and visibility:** save authoritative state, implement viewer-safe projections, network authority.
6. **Demonstrable reference scenarios:** runnable, original, noncopyright-specific microgames for each family.

The design principle remains: **a generic Deckit primitive should be demonstrably useful in more than one card game**. Avoid embedding named-game rules in `addons/deckit/`.
