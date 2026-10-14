# Godot 4.7.2 editor bootstrap

## SVG custom-type icons

Godot enables installed EditorPlugins during project opening, sometimes
before resource imports have populated the `.godot/imported/` cache.

Deckit previously used `preload("...svg")` for its five custom editor-node
icons. In affected Godot 4.7.2 projects, this raised a parse error saying
an SVG path has no registered resource loader.

`addons/deckit/plugin.gd` now reads the existing SVG files as bytes with
`FileAccess`, then uses `Image.load_svg_from_buffer()` and
`ImageTexture.create_from_image()` to create its editor icons. These
operations do not rely on Godot's texture import cache. If an optional
icon cannot be opened or rendered, Deckit uses a null icon and logs a warning
instead of preventing the plugin from parsing.

The SVG assets remain in the repository and still serve as the source artwork.
Do **not** commit generated `.godot/` folders or `.import` cache files.

## Spanish sample

`examples/microgames/spanish_tricks.gd` previously declared a typed constant
using a `PackedInt32Array()` constructor. GDScript 4.7.2 does not permit
calling that constructor in a constant expression. The array is now a plain
literal constant and is converted to `PackedInt32Array` where the ranking
API needs it.

## Verify

1. Update the `main` branch and reopen the project in Godot 4.7.2.
2. Check the **Output** panel. There should be no parse errors related to
   `plugin.gd` SVG preloads or the `STRENGTH` constant.
3. Enable Deckit at **Project Settings → Plugins**, if necessary.
4. Run `res://examples/microgames/spanish_tricks.tscn` and the lab hub.
5. From a terminal in the project root, run:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_editor_bootstrap.gd
godot --headless --path . --script res://tests/headless/test_microgames.gd
```

The tests and import step are local verification instructions, not a claim
that Godot was executed in the automated editing environment.
