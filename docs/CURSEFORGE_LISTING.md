# CurseForge listing

Copy-ready text for the CurseForge project form. Keep it aligned with README.md
and the tested client; do not advertise clients or versions that have not been
tested.

## Project fields

| Field | Value |
| --- | --- |
| Name | Shields Up Forever |
| Class | Addons |
| Main category | Buffs & Debuffs. Keep it identical to the TOC `## Category`, which groups the AddOn in the in-game AddOn list. |
| Additional categories | Combat (CurseForge allows up to 4; unrelated ones can send the project back for changes). |
| Author shown | Dyre, set through the CurseForge account's username |
| License | MIT License |
| Logo | artwork/shields-up-forever-logo.png (1024 x 1024) |
| Source | https://github.com/jbedworth/ShieldsUpForever |
| Issues | https://github.com/jbedworth/ShieldsUpForever/issues |

## Summary

A crescent beside your character that shows your remaining shield, for any class in World of Warcraft: Forever: Power Word: Shield, Ice Barrier, wards, and any other absorb, also in combat.

## Screenshots

Upload these from `artwork/screenshots/`, with these captions:

| File | Caption |
| --- | --- |
| shield-display.png | The shield display: your remaining absorb, with an icon for each shield that is up. |

## Description

Paste this with the description editor in Markdown mode. Pasted into the rich
text editor, the headings, bullets, and bold show as raw, escaped markdown.

Per-file changelogs need no manual text: each CI upload uses the version's
`CHANGELOG.md` section, through `release-notes.md`.

```markdown
**Shields Up Forever** shows your remaining shield as a crescent beside your character, for any class. It is the shield display from Mage Tools Forever, on its own.

### Shield display
- Fills when a shield lands and drains as it absorbs, with the amount below, also in combat. Drops away the moment the shield is used up.
- Power Word: Shield in white, Ice Barrier blue, the wards in fire and frost, Warlock shields in purple, and any other absorb in gold.
- Several shields at once? The crescent shows the total, and a row of icons shows which are up: your own class's shields, then Power Word: Shield and Blessing of Protection.
- Mana Shield and Paladin bubbles drain with their time left in their own inner crescents.
- Size 50-150%, an optional number, and an optional sound when a shield ends.

### With Mage Tools Forever or Warlock Tools Forever
They ship the same display. Installed together, you still see one ring, and Shields Up Forever tells you which AddOn draws it.

### Commands
- `/suf` or `/suf options` opens the settings (Options > AddOns).
- `/suf unlock`, `/suf lock`, and `/suf reset` move the display.
- `/shieldsup` works the same, in case another AddOn uses `/suf`.

### Compatibility
Beta, for the Forever beta client 1.60.1. If a client update removes an API it needs, it says so in chat and the display stays off.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases carry the Forever metadata WowUp needs.

Source, issues, and license (MIT): https://github.com/jbedworth/ShieldsUpForever
```
