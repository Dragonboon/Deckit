# Maintainability, accessibility and performance

This pass preserves exported class names, node paths, signals and public APIs. It is a **source audit**, not a verified Godot performance benchmark.

## Cleanup decisions

- Updated residual error strings from previous templates to `DeckitUtils`.
- Kept the historical `center_texture_rect_pivot()` helper as an API-compatible alias to `center_pivot()`, rather than removing an externally callable function.
- Kept Godot script `.uid` files, the editor plugin icons and both empty French/Spanish deck-folder templates.
- Removed only the empty `.gitkeep` markers at the *parent* template directory level: nested directory markers already preserve those folders.
- Preserved the classic `DeckitPlayingCard`, `DeckitDeck` and related components rather than treating them as dead code. Their APIs are separate from the newer headless runtime.

## Optimizations

- Deck validation builds a temporary ID → definition lookup once per run instead of repeatedly scanning the entire catalog for each entry and copy-limit check.
- Searching the deck catalog no longer recalculates validation or rebuilds the deck-entry list on every character typed.
- The zone presenter reuses card buttons with stable instance IDs. This avoids freeing and allocating all views after each action, and retains keyboard focus on surviving cards.
- Recursive file discovery ends the directory listing and returns sorted filenames for reproducible tools.
- Drag interpolation clamps its weight to [0, 1] so a long frame does not overshoot its target.

These improvements reduce avoidable work, but **no measured speedup is claimed**. If profiling reveals unusually large catalogs, consider a cache with explicit invalidation rather than a permanent index that can become stale when Resources are edited in Godot's Inspector.

## Accessibility

- Interactive lab and deck-editor buttons have consistent minimum heights, keyboard focus and tooltips.
- The presentation view keeps the same card button when the card remains in a zone, preserving focus on refreshes.
- Card counters are described with their names and values rather than only a count.
- The French example has one clearly labeled submit action instead of two buttons performing the same operation.
- Use Tab/Shift+Tab to reach buttons, Enter/Space to activate, and arrow keys to navigate `ItemList` selections where supported by Godot.
- Text and list-based laboratory UI still depend on the game's theme for color contrast and full screen-reader support; this pass does **not** claim certified WCAG conformance.

## Validation

From the project root:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_maintenance.gd
```

Also run the full list in [Integration validation](INTEGRATION_VALIDATION.md), exercise the nine labs and three microgames, and install `addons/deckit/` into a clean Godot 4.7 project.

**Limit:** The working environment did not have Godot installed; tests were added for local verification rather than reported as executed.
