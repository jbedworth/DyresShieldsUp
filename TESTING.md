# Testing

## Method

1. **Pinned source review.** Client behavior is read from Blizzard's FrameXML
   and generated API documentation at Gethe/wow-ui-source commit
   `943764493e6b16d63ded3ab304150d1f05e58b57` (`1.60.1.70338`); the client
   checks ran on build 70450, Interface 16001. Source establishes declared
   APIs, templates, and code paths, not operational behavior.
2. **Automated mock tests.** `tests/run.lua` exercises commands, saved
   settings, the shield display for each class, the settings page, and the
   election among AddOns shipping Shield.lua against a minimal mock of the
   client. Mocks model secret values as values that raise errors on
   comparison, concatenation, indexing, or printing.
   `tests/test_shield_copy.py` checks that Shield.lua and its textures match
   the copies in sibling Mage Tools Forever and Warlock Tools Forever checkouts
   (skipped where there are none, as in CI).
3. **In-client checks.** The checklist below covers everything mocks cannot.

```sh
.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/lua5.1.exe tests/run.lua
.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/luac5.1.exe -p Commands.lua Core.lua Shield.lua Options.lua tests/run.lua
.tools/python-3.13.7/python.exe -m unittest discover -s tests -p 'test_*.py'
```

Tooling: portable Lua 5.1 (LuaRocks 3.13.0 Windows bundle) and the official
python.org 3.13.7 embeddable archive under the ignored `.tools/` folder (copied
from Mage Tools Forever); CI uses ubuntu-24.04's `lua5.1` package and native
`python3`.

## Source findings

- `UnitGetTotalAbsorbs` has `SecretReturns = true` (always secret);
  `UnitHealthMax` has `SecretWhenUnitHealthMaxRestricted`.
  `UNIT_ABSORB_AMOUNT_CHANGED` carries the unit. `StatusBar:SetValue`,
  `SetMinMaxValues`, and `SetStatusBarColor`, `FontString:SetText`,
  `Region:SetAlpha`, and `AbbreviateNumbers` declare
  `SecretArguments = "AllowedWhenTainted"`, read here as accepting secrets from
  AddOn code; curve objects' `Evaluate` (`AllowedWhenUntainted`) does not.
- AuraContainer `includeSpellIDs` is a set, `{[spellID] = true}`
  (Blizzard_CustomAuraContainer.lua: "Map of permitted spell IDs").

## Found in client

With DSU, MTF, and WTF; Shield.lua is byte-identical in all three, so these
carry over:

- A list in `includeSpellIDs` matched nothing; the set shows the icons.
- Forever's shield buffs carry Classic IDs: Mana Shield 1463, Fire Ward 543,
  and Power Word: Shield (a Priest's shield on a Mage showed in its color).
  Fire Ward's aura points matched `UnitGetTotalAbsorbs`; Mana Shield's buff
  has no points and is not in the total.
- DSU on a Paladin: Forever's bubbles carry Classic IDs (Divine Shield 642,
  Divine Protection 498, Blessing of Protection 1022) and draw the gold
  innermost crescent.
- The AuraContainer icons' `IsShown` is secret to AddOn code, so each shield
  has a fixed spot in the row.
- Own cast events stay readable in combat; aura APIs error in combat for
  AddOn code.
- The minimum-absorb gate (shield display v5) works: a frame anchored to a
  StatusBar's fill texture follows a secret value, and its clipping hides the
  crescent while the fill is empty. A Paladin's Seal of Righteousness shield
  no longer flickers the ring (confirmed on a Paladin).
- The break sound: the client plays no game sound by path (RaidWarning.ogg
  stayed silent); an AddOn's own file plays, also through `AddAuraSound`
  with trigger Removed when Blessing of Protection runs out.

### Open client questions

1. Whether `SetAlpha` with the secret absorb hides the crescent at 0 in
   combat.
2. Whether the break sound plays when a shield breaks from damage in combat.
3. Which order the client loads MTF, DSU, and WTF in, which decides the ring's
   owner on equal versions.

## In-client checklist

- [ ] `/dsu` opens Options > AddOns > Dyre's Shields Up; the login banner
      shows the version and Dyre, on any class.
- [ ] As a Priest: Power Word: Shield on yourself shows the white crescent,
      empties as you take damage, also in combat, and drops the moment it is
      used up; its icon shows under the number; `/dsu debug_shield` names it.
- [ ] As a Warrior or Rogue: another player's Power Word: Shield shows; any
      other absorb shows in gold for 30 s.
- [ ] A Paladin's Blessing of Protection on you draws the gold innermost arc
      and its icon, also in combat; as a Paladin, Divine Shield and Divine
      Protection do too. `/dsu debug_shield` confirms the IDs.
- [ ] As a Paladin with Seal of Righteousness, its 10-20 point shield never
      shows the crescent, in or out of combat; a Power Word: Shield on you
      still does. `/dsu debug_shield` shows `minimumAbsorb`.
- [ ] Without Dyre's Sounds, the display works and turning the break sound on
      says once in chat to install it; with it, the sound list shows Dyre's
      Picks and the imp sounds, and the chosen sound plays when a shield ends.
- [ ] Settings: the switches, number, size slider, and break sound work;
      "Unlock to move it" and `/dsu unlock` show the full sample to drag;
      unticking or `/dsu lock` locks it, and the switch and commands stay in
      step; `/dsu reset` puts it back.
- [ ] Locked, clicks on the world pass through the display.
- [ ] With Mage Tools Forever on a Mage: one ring shows (MTF's), DSU says once
      that MTF shows it, and `/dsu unlock` points to MTF's settings. On a
      Priest with MTF installed, DSU's ring shows.
- [ ] With Warlock Tools Forever on a Warlock: one ring shows, and the other
      AddOn says which one draws it.
- [ ] The AddOn list shows DSU under Dyre's Toolkit; DSU's page is Options >
      AddOns > Dyre's AddOns > Shields Up, and `/dsu` opens it (in combat, the
      toolkit says it opens out of combat).
- [ ] After updating from 1.0.0, the shield display is where it was and the
      same size.
- [ ] Display size: dragging the slider grows and shrinks the crescents
      (Mana Shield's and the bubbles' too) from their center, without
      drifting, while the number and the icons keep their size and stay under
      the crescent's foot. Text size and Icon size change only the number and
      only the icons. Each gold mark sits at 100%, and Reset size puts all
      three back. Sizes and place are kept after `/reload`.
- [ ] A tiny absorb (Seal of Righteousness) shows neither the crescent nor
      the number, at any Text size.
- [ ] `/dsu unlock`, `/dyre unlock`, the minimap button, and "Unlock frames"
      each unlock every Dyre's AddOn's frames with one chat line from the
      toolkit and none from DSU; the shield sample and the toolkit's gold
      outline show and the display takes the mouse; locking any way hides
      them and clicks pass through again.
- [ ] The shield display dropped near another Dyre's frame snaps beside it,
      snaps to the grid with "Snap to the grid" on, moves with a
      Shift-dragged group, and keeps its place after `/reload`; `/dsu reset`
      puts it back.
- [ ] The absorb fade still works: the crescent fades out the moment a
      shield is used up, also in combat, and tiny absorbs stay hidden.
- [ ] No BugSack (or chat) errors at login, unlocking, dragging, resizing,
      in combat, or on `/dsu debug_shield`.
- [ ] With Dyre's Toolkit disabled (or older than 2.0), DSU stays off and
      says once to install it from CurseForge.
- [ ] With an MTF or WTF that ships Shield.lua v10 on a Mage or Warlock
      without DSU: changing its display size keeps the ring's center.
