# Dyre's Shields Up

A shield display for any class in World of Warcraft: Forever, and the one
shield display for all of Dyre's AddOns: Mage Tools Forever and Warlock Tools
Forever use it too. Settings are in **Options → AddOns → Dyre's AddOns →
Shields Up**, or type `/dsu`. They are saved per character. Needs **Dyre's
Toolkit** 2.0 or later, which the CurseForge app installs with it. Formerly
Shields Up Forever (`/suf`).

## Shield display

A segmented crescent beside your character that fills with your remaining
shield, full when it lands and draining as it absorbs, with the amount as a
number below. It tracks live, also in combat, and drops away the moment the
shield is used up.

- Any absorb on you counts: a Priest's **Power Word: Shield** (white), a
  Mage's **Ice Barrier** (blue), **Fire Ward** (orange), and **Frost Ward**
  (pale blue), a Warlock's **Shadow Ward** and Voidwalker **Sacrifice**
  (purples), and any other absorb (a trinket, a potion, or one Forever adds)
  in a neutral gold.
- With several shields up, the crescent shows their combined total, refilled
  as each one lands, and a row of icons under the number shows which are up,
  each in its own spot. Each icon drops the moment its shield breaks or ends,
  also in combat.
- The icon row holds your own class's shields first, then the ones anyone can
  put on you: Power Word: Shield and Blessing of Protection. A Priest sees
  those two; a Mage sees Ice Barrier, Mana Shield, Fire Ward, and Frost Ward
  first; a Warlock Shadow Ward and Sacrifice; a Paladin Divine Shield and
  Divine Protection.
- Shields with no absorb amount drain with their time left instead: a Mage's
  **Mana Shield** in a thinner purple crescent nested inside, and Paladin
  bubbles (**Divine Shield**, **Divine Protection**, **Blessing of
  Protection**) in a gold crescent innermost of all.
- **Display size** shrinks or grows the crescents from their center
  (50-150%). The number and the icons keep their size; **Text size** and
  **Icon size** set them (50-150% each), and **Reset size** puts all three
  back to 100%. The number can be turned off, and a sound can play when a
  shield ends or breaks, also in combat. The sounds come from **Dyre's
  Sounds**, which the CurseForge app installs with DSU; otherwise get it from
  CurseForge or github.com/jbedworth/DyresSounds. Without it, DSU works but
  plays no sound.
- Tiny absorbs (under 25 points or 5% of your health, whichever is larger,
  such as a Paladin's Seal of Righteousness) never show.
- Locked (the default), it never blocks clicks on the world. Unlocked, it
  shows a full sample of every part, outlined, to drag; `/dsu reset` puts it
  back.

## With Dyre's Toolkit

**Dyre's Toolkit** gives all of Dyre's AddOns one layout mode and one
settings home, and DSU needs it (2.0 or later): the shield display is one of
its widgets, placed, dragged, sized, and saved by the toolkit. The CurseForge
app installs it with DSU; without it, DSU stays off and says once at login to
install it from CurseForge.

- Unlocking (`/dsu unlock`, `/dyre unlock`, the toolkit's minimap button, or
  **Unlock frames** on the Dyre's AddOns page) unlocks every Dyre's AddOn's
  frames at once, and locking locks them all. Frames always start locked at
  login.
- Dropped near another Dyre's AddOn's frame, the shield display snaps beside
  it; Shift-drag moves a snapped group; with the toolkit's "Snap to the grid"
  on, it snaps to the grid.
- DSU's settings page sits under **Dyre's AddOns**, and DSU is listed under
  Dyre's Toolkit in the in-game AddOn list.

## With Mage Tools Forever or Warlock Tools Forever

Mage Tools Forever (1.2.0 and later) and Warlock Tools Forever (1.3.0 and
later) leave the shield to Dyre's Shields Up and require it, so the
CurseForge app installs it with them. The first time Dyre's Shields Up runs
on a character, a Mage's shield settings from Mage Tools Forever (or a
Warlock's from Warlock Tools Forever) are copied once: place, sizes, the
number, and the sound. DSU says so in chat. A character that already has DSU
settings keeps them, and the other AddOn's own settings are left as they are.

Older versions of Mage Tools Forever and Warlock Tools Forever ship the same
display. Installed together, you still see one ring: the newest version
among the AddOns running on your character draws it, and on the same version
the first AddOn loaded does (Dyre's Shields Up, by folder order). When
another AddOn draws it, DSU says so once at login, and its settings and
commands point you to that AddOn's settings.

## Commands

| Command | What it does |
|---|---|
| `/dsu`, `/dsu options` | Opens the settings |
| `/dsu unlock`, `/dsu lock` | Unlocks every Dyre's AddOn's frames to drag them, and locks them again |
| `/dsu reset` | Moves the display back to its default place |
| `/dsu debug_shield` | Diagnostics: the absorb APIs, which AddOn draws the ring, each shield, and the icon row |

`/shieldsup` works the same, in case another AddOn uses `/dsu`.

## Compatibility

For World of Warcraft: Forever 1.60.1 (tested on build 70450, Interface
16001) and World of Warcraft Classic Era 1.15.9 (tested on build 70003). If
a client update removes an API it needs, it says so in chat and the display
stays off.

On Classic Era the game gives AddOns no absorb amount, so the crescent's
number starts from the shield's base absorb for its rank (without spell
power, so a little under the real one) and goes down with what the combat
log says each hit absorbed; a shield of a rank it doesn't know drains with
its time left, with no number. The sound when a shield ends doesn't play
there yet: Classic Era has no way for an AddOn to ask for it.

**Verified in client:** Dyre's Shields Up loads and works on a Paladin, and
Forever uses Classic's spell IDs for the Paladin bubbles (Divine Shield,
Divine Protection, Blessing of Protection), which draw the gold innermost
crescent. With Mage Tools Forever and Warlock Tools Forever, which run this same shield
display: the crescent tracks the absorb total and its number, the icon row
shows each shield up, Mana Shield's inner crescent drains with time and
empties as the buff ends, and Forever uses Classic's spell IDs for Mana
Shield, Fire Ward, and Power Word: Shield (a Priest's shield on a Mage showed
correctly).

**Not yet verified in client:** a Priest casting Power Word: Shield on
themself, Warlock shields (Shadow Ward, Sacrifice), the break sound, and the
ring dropping at zero absorb in combat. [TESTING.md](TESTING.md) has the
checklist.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases
carry the Forever metadata WowUp needs.

## Support

Dyre's AddOns are free. If you enjoy them, you can support them on Ko-fi: https://ko-fi.com/dyre_janelle

## License

MIT. See [LICENSE](LICENSE).
