# Contributing

This repository is a personal fork / hobby project. Contributions are welcome, but the goal is practicality and fun over strict process.

If you’re here to experiment, mod, or patch things locally—cool. If you want to upstream anything to the original project, do not assume compatibility with their standards or roadmap.

## Project Rules (Community)

- Speaking style: informal/formal speech is both allowed.
- NSFW: allowed.
- Politics: not allowed (no political discussion in issues/PRs/comments).
- Keep discussions focused on the game, mods, and implementation.

For more detail, see the Code of Conduct/Rules document in this repository.

## What’s in scope

Good targets:
- Gameplay tweaks, balance experiments, and quality-of-life changes
- Mod content (JSON), new items/recipes, and feature prototypes
- Build improvements for Windows (MSVC workflow, packaging, resources)
- Performance fixes (crafting UI, caching/indexing, etc.)

Out of scope (likely to be rejected):
- Long arguments about design philosophy
- “Big refactor for elegance” without a clear payoff
- Political content or politics-adjacent debates

## Quick Start Workflow

1) Fork the repo (or create a branch if you have access).
2) Make changes in small chunks.
3) Test your change in-game.
4) Open a PR with:
   - what changed
   - why it changed
   - how to test it

If you’re not sure, open a draft PR early.

## Build & Packaging Notes (Windows / MSVC)

This repo may include a Release `.exe` in versioned form for convenience.

- The Release build may rename the executable to include a date identifier.
- Debug builds should stay stable and are intended for local debugging only.

If your changes touch build scripts:
- Keep generated files out of commits (logs, temp files, build outputs).
- Only include the intended Release binary if requested/expected for a release commit.

## Assets & Large Files

- Do not commit large source assets (e.g., `.psd`).
- Prefer lightweight formats for distribution (e.g., `.png`, `.webp`, `.json`).
- If an asset is necessary, keep it minimal and clearly document its purpose.

## Mod / JSON Guidelines

- Keep IDs stable. Renaming IDs can break existing saves/mod setups.
- Prefer additive changes over destructive changes.
- If you add replacement/substitution systems, consider:
  - save/load behavior
  - crafting UI performance
  - stacking/charge-count behavior for substitute items

## Code Style

Try to match the existing code style in the surrounding files.
- Keep changes readable and localized.
- Avoid mixing formatting-only changes with behavior changes unless necessary.
- If you add logging/debug code, remove it before final PR unless it’s explicitly intended.

## Reporting Bugs

When opening an issue, include:
- what you expected
- what happened instead
- minimal steps to reproduce
- your build version string (from the game/version output)
- whether you used a clean world or an existing save

Screenshots/log snippets help.

## License & Attribution

This project is a derivative work. Keep original license notices intact where applicable, and don’t remove attribution blocks from upstream files unless you know exactly what you’re doing.

If you add new code/content, you agree it can be redistributed under this repository’s license terms.
