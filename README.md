# Shields Up Forever

The shield display from Mage Tools Forever, on its own, for any class in World
of Warcraft: Forever (beta). Settings are in **Options → AddOns → Shields Up
Forever**, or type `/suf`. They are saved per character.

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
- **Display size** shrinks or grows it (50-150%). The number can be turned
  off, and a sound can play when a shield ends or breaks, also in combat.
- Locked (the default), it never blocks clicks on the world. **Unlock to move
  it** (or `/suf unlock`) shows a full sample of every part to drag; `/suf
  lock` locks it again and `/suf reset` puts it back.

## With Mage Tools Forever or Warlock Tools Forever

Both ship the same display. Installed together, you still see one ring: the
newest version among the AddOns running on your character draws it, and on
the same version the first AddOn loaded does (the game loads them in folder
order, so Mage Tools Forever before Shields Up Forever before Warlock Tools
Forever). MTF runs only on a Mage and WTF only on a Warlock, so on any other
class SUF draws it. When another AddOn draws it, SUF says so once at login,
and its settings and commands point you to that AddOn's settings.

## Commands

| Command | What it does |
|---|---|
| `/suf`, `/suf options` | Opens the settings |
| `/suf unlock`, `/suf lock` | Unlocks the display to drag it, and locks it again |
| `/suf reset` | Moves the display back to its default place |
| `/suf debug_shield` | Diagnostics: the absorb APIs, which AddOn draws the ring, each shield, and the icon row |

`/shieldsup` works the same, in case another AddOn uses `/suf`.

## Compatibility

Beta, for the Forever beta client 1.60.1 (Interface 16001). SUF keeps working
on later beta builds; if a client update removes an API it needs, it says so
in chat and the display stays off.

**Verified in client:** Shields Up Forever loads and works on a Paladin, and
Forever uses Classic's spell IDs for the Paladin bubbles (Divine Shield,
Divine Protection, Blessing of Protection), which draw the gold innermost
crescent. With Mage Tools Forever and Warlock Tools Forever, which run this same shield
display: the crescent tracks the absorb total and its number, the icon row
shows each shield up, Mana Shield's inner crescent drains with time and
empties as the buff ends, and Forever uses Classic's spell IDs for Mana
Shield, Fire Ward, and Power Word: Shield (a Priest's shield on a Mage showed
correctly).

**Not yet verified in client:** a Priest casting Power Word: Shield on
themself, Warlock shields (Shadow Ward, Sacrifice), the break sound, the
ring dropping at zero absorb in combat, and only one ring showing with MTF or
WTF also installed. [TESTING.md](TESTING.md) has the checklist.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases
carry the Forever metadata WowUp needs.

## License

MIT. See [LICENSE](LICENSE).
