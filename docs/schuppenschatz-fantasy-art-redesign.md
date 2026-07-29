# Schuppenschatz Fantasy-Art-Redesign

**Goal:** Replace the abstract dark UI with an original fantasy-tabletop presentation based on Günther's visual reference, while preserving every game interaction and accessibility contract.

## Assets

- `assets/images/schuppenschatz/parchment_board.png`: original generated parchment/wood background with quiet readable centre.
- `assets/images/schuppenschatz/stone_dragon_card.png`: original generated carved-stone/gold card frame.

## UI plan

1. Render the parchment board as the full-screen background beneath the game list and the result list.
2. Use warm ink, wood, parchment and gold tokens for app bar, status, message, player and action surfaces.
3. Place the existing interactive normal and boss card contents inside the stone frame; do not replace any field widget or callback.
4. Keep all existing keys, semantics, localized copy, retry behavior, block/digital mode routing and action-bar layout untouched.
5. Validate English localization, 360×800 at 200% text scale, analyzer and complete test suite before release.
