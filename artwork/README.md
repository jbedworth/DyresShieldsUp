# Dyre's Shields Up logo

Original vector artwork: a gold-edged heater shield with a deep blue face, a
radiant gold star and orb at its heart, beside a segmented crescent of shield
light that drains from the top, as the display does, with a thinner timed
crescent inside it, on a rich dark-brown background. It shares its frame and
colors with the Mage Tools Forever, Warlock Tools Forever, Weapon Sets
Forever, and Weapon Skills Forever logos. The design has no font or
external-image dependencies.

- `dyres-shields-up-logo.svg`: editable, resolution-independent source.
- `dyres-shields-up-logo.png`: 1024 x 1024 PNG master.
- `dyres-shields-up-logo-512.png`: 512 x 512 PNG for square project images.

The PNGs are rendered from the SVG with headless Chrome, for example:

```sh
chrome --headless=new --hide-scrollbars --window-size=1024,1024 --force-device-scale-factor=0.5 --screenshot=dyres-shields-up-logo-512.png dyres-shields-up-logo.svg
```

Use these files for project pages and distribution branding. Keep this directory
out of the runtime release ZIP; the TOC uses a built-in client icon
(Spell_Holy_PowerWordShield).

## Screenshots

- `screenshots/shield-display.png`: the shield display with its crescents,
  absorb amount, and shield icons (captured by the author on the Forever beta
  client with Mage Tools Forever, which draws the same display).

Retake a screenshot when the feature it shows changes visibly.

This artwork is covered by the repository's MIT License. Copyright (c) 2026
John Bedworth. Include the applicable license notice with distributed copies.
