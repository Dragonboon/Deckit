# Contributing to Deckit

Thanks for helping make Deckit approachable and reusable.

## Report a problem

Use the [bug report template](https://github.com/sempitern0/Deckit/issues/new/choose). Please search for an existing issue first and describe **one problem per report**.

Include your Godot version, operating system, relevant errors and a minimal reproduction. Where possible, name the affected lab or script.

## Suggest an improvement

Use the [issue templates](https://github.com/sempitern0/Deckit/issues/new/choose). Describe the use case, expected behavior and how the change could stay independent of a particular card game.

## Working on the code

- Keep reusable scripts inside `addons/deckit/`; put example rules and demonstrations in `examples/labs/`.
- Prefer small APIs with explicit responsibilities and document any changed behavior.
- Add or update a `tests/headless/` script for logic changes. See [local validation](docs/INTEGRATION_VALIDATION.md).
- Do not add required external services or GitHub Actions workflows.
- Check the editor and the affected labs in Godot 4.7 before proposing a change.
- Preserve existing `.uid` files and include new ones created by Godot.

The project uses the [MIT License](LICENSE) and the [Code of Conduct](CODE_OF_CONDUCT.md).
