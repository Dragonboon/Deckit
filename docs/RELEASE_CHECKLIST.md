# Release-readiness checklist

This checklist is for maintainers reviewing Deckit before calling an iteration verified. It is **not** a claim that all checks have already passed.

- [ ] Import the repository in Godot 4.7 and inspect the editor's Errors/Warnings.
- [ ] Verify enabling and disabling the add-on under Project Settings → Plugins.
- [ ] Run every headless test listed in [Integration validation](INTEGRATION_VALIDATION.md).
- [ ] Open `res://examples/labs/lab_hub.tscn` and exercise the nine labs and three microgames.
- [ ] Verify deck-editor add/remove, multi-copy selection, validation, save, load and duplicate.
- [ ] Verify classic hand/pile dragging, orientation, capacity and resource creation with real textures.
- [ ] Copy **only** `addons/deckit/` into a clean Godot 4.7 project, enable the plugin and instantiate both classic UI nodes and headless classes.
- [ ] Confirm file paths and resource references are valid after import.
- [ ] Reconcile any regenerated `.uid` files; keep generated `.import` files untracked.
- [ ] Confirm current documentation describes only features actually implemented.
- [ ] Check keyboard focus (Tab / Shift+Tab / Enter / Space), controls, error messages and 960×600 window dimensions.
- [ ] Compare before/after performance for a large catalog and repeated zone refreshes; no benchmark numbers are claimed without measurements.

No CI is required; all checks can run locally. Core/card-builder scripts are designed to work without the example project.
