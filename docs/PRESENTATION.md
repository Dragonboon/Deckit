# Optional presentation layer

The `addons/deckit/src/presentation/` folder offers two optional, independent `Control` types.

- **`DeckitCardView`** displays one `DeckitCardInstance` using definition artwork and labels when authorized; pressing it emits `card_requested(instance_id)` rather than changing state.
- **`DeckitZoneView`** displays one `DeckitCardZone` and emits `card_requested(zone_id, instance_id)`. It refreshes when `DeckitGameState.action_applied` changes the source or destination zone.

```gdscript
var view := DeckitZoneView.new()
add_child(view)
view.bind(game_state, &"hand", &"player-1")
view.card_requested.connect(
    func(source: StringName, card_id: StringName) -> void:
        # Your game decides the destination and performs its own rules.
        game_state.perform(DeckitCardAction.new(source, &"table", card_id, &"player-1"))
)
```

## Display policy

- Public zones reveal a card only when its `face_up` flag is set.
- OWNER_ONLY zones reveal their cards only when `viewer_id == zone.owner_id` and `reveal_owned_cards` is true.
- HIDDEN zones never display a card's face in this renderer.
- The view does not grant permission to perform an action. The host must enforce all gameplay permissions through rules.
- **Security:** hidden cards still exist in client memory if the full game state is sent to a client. Filter secret data *before transmission* when implementing networking.
- Direct edits to card counters, face state, or visibility are not action signals: call `view.refresh()` after these edits.
- `DeckitCardView` does not manage focus/selection for game logic, mouse dragging or layout animation.

The legacy `DeckitCardHand`, `DeckitCardPile` and `DeckitPlayingCardUI` are not replaced or silently synchronized. They remain available independently until a separate, deliberate adapter refactor.

**Try it:** `res://examples/labs/presenter_lab.tscn`.
