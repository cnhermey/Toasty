# Toasty (v0.5.0)

Your camping status in WoW: Forever, as three icons that look like your buff bar, plus tooltips that explain camp objects when you hover them in the world.

- **Icon 1: Well-Rested.** The Cozy Sleeping Bag buff, with Blizzard's icon, its stacks and its time left.
  - **No Well-Rested?** The icon becomes your **Cozy Sleeping Bag**: click it to use the bag. It shows the bag's cooldown, and how many you have when it's more than one.
  - **No bag?** A gray bag icon that says "No bag".
- **Icon 2: Camp Benefits.** The camp buffs, with their time left.
  - **No camp buffs, but by a campfire?** The **Campfire Nearby** icon. Sit for 1 minute to get the camp buffs.
  - **Neither?** A gray Camp Benefits icon.
- **Icon 3: Boosted Rest.** The Camp Tent's rested XP cooldown (a debuff), with its time left.
  - **Gray?** You don't have Boosted Rest, so a Camp Tent can give you more rested XP again.
- **Camp object tooltips.** Hover a camp object or campfire in the world, and its tooltip says what it does: the profession and tier, the buff or service, what it includes from the tier below, and which class buff it doesn't stack with.
- **Settings** in Esc → Options → AddOns → Toasty (or `/toasty`).

### Looks like Blizzard's UI
- The icons sit in a tooltip-style panel (Blizzard's tooltip background and border) with "Toasty" in gold above them. Settings → **Name and border** turns the panel off for bare icons.
- The icons are drawn like the buff bar: 30 px icons, the stack count in Blizzard's number font at the bottom right, and the time left under the icon in the buff bar's font, written the same way ("12 m", "45 s"), turning white under a minute.
- Hovering an icon shows Blizzard's own buff, debuff, item or spell tooltip.
- The sleeping bag button uses Blizzard's button highlight, pressed look and cooldown swipe.
- Object descriptions are added to the game's own tooltip in Blizzard's tooltip colors.
- The settings page uses Blizzard's checkboxes, slider and buttons.

### Combat and secret values
- Using an item needs a secure button, so the icon bar is protected: moving it, resizing it, showing or hiding it and switching icon 1 between "buff" and "use bag" wait until you leave combat. The icons and times still update in combat.
- In combat, Forever hides which buff is which from addons. So the buffs themselves are drawn by the game: icons 1 and 2 each have an engine aura slot (the 12.1 aura containers, as EllesmereUI uses them) that the game fills with the matching buff, with its icon, stacks and countdown, in or out of combat. Toasty only draws what lies under it: the sleeping bag button, "No bag", and the gray icons.
- Boosted Rest (icon 3) is a debuff, which the game-drawn slots don't show, so Toasty draws it itself. In combat it stays lit and counts down from the end time it read before the fight.
- Hovering a lit icon shows the game's own buff tooltip. Clicks and Shift-drag go through to Toasty's icon underneath.
- Settings → Testing → **Game-drawn buffs** turns this off, so Toasty draws the buffs itself (exact out of combat, best effort in combat).
- On a client without aura containers, Toasty reads the buffs itself: it asks for each by spell ID, and if it can't tell in combat it keeps the last known state and counts down from the time it knew.

## Install
1. Copy the `Toasty` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
   **Copy the folder; don't symlink it.** On Forever, a symlinked addon folder silently resets its SavedVariables.
2. Restart the game, or `/reload` if it's already running, and enable the addon on the character screen.
3. The TOC says `## Interface: 16001`. If the addon shows as out of date, check the real number with
   `/run print(select(4, GetBuildInfo()))` and update the TOC line.
4. Updating from 0.1.0: delete `Camp.lua` and `UI_HUD.lua` from the folder (0.2.0 no longer loads them).

## First in-game test (solo)
1. Type `/toasty demo`. The two icons cycle through every state, 5 seconds each. Shift-drag the panel where you want it. Type `/toasty demo` again to stop.
2. With a Cozy Sleeping Bag and no Well-Rested, click icon 1: the bag should be used and the icon should turn into Well-Rested with its time.
3. Stand by a campfire: icon 2 shows Campfire Nearby. `/sit` for a minute: it becomes Camp Benefits with its time.
   With a Camp Tent at the camp, icon 3 lights up as Boosted Rest with its time; without the debuff it stays gray.
4. Hover a camp object or campfire in the world: the tooltip should explain it. Type `/toasty tip Camp Chair` to see one without a camp.
5. Type `/toasty probe` and send the output.

## Commands
- `/toasty` or `/toast`: open the settings
- `/toasty show`, `/toasty hide`: show or hide the icons
- `/toasty demo`: cycle the icons through every state (again to stop)
- `/toasty tip <object>`: show a camp object's tooltip at the cursor, e.g. `/toasty tip Camp Chair`
- `/toasty reset`: move the icons back to their first spot
- `/toasty probe`: developer report

## How it works
| File | Role |
|---|---|
| `Util.lua` | Helpers: secret-value guards, safe API calls, chat output, timers, combat queue, buff-bar time format |
| `Core.lua` | Event frame, internal message bus, SavedVariables (`ToastyDB`), runs queued changes after combat |
| `UI_Common.lua` | Blizzard colors, icons and sounds |
| `Status.lua` | Reads your buffs and debuffs on `UNIT_AURA` (Well-Rested 429959, Camp Benefits 1229741, Campfire Nearby 1283391, Boosted Rest 1229451) by spell ID and by name, learning new IDs; counts your Cozy Sleeping Bags (item 211527) and reads its cooldown |
| `Objects.lua` | What every camp object and campfire does; adds it to the game tooltip for world objects (`TooltipDataProcessor` for objects when the client has it, else `GameTooltip` `OnShow` when the tooltip belongs to the world) |
| `Engine.lua` | Game-drawn buff layers: an `AuraContainer` (`CustomAuraContainerTemplate`) per buff with one aura slot limited to its spell IDs (`candidateFilters.includeSpellIDs`), set up in the slot's `initializeFrame` |
| `UI_Bar.lua` | The three icons; icon 1 is a `SecureActionButtonTemplate` that uses the bag |
| `Options.lua` | Settings page in Esc → Options → AddOns, through one setter (`ns.Options:Set`) |
| `Demo.lua` | The demo icons (`/toasty demo`) |
| `Commands.lua` | `/toasty`, `/toast` and the `/toasty probe` report |

Camp object descriptions come from Wowhead's Camping Overview guide (patch 1.60.1). Edit `DATA` at the top of `Objects.lua` to change them.

## Needs in-game verification
- That the four buff and debuff IDs are right on the live client. `/toasty probe` "Buffs" lines show each ID, any learned ID, and red "(name not from client)" if the client didn't know it.
- That Well-Rested has stacks (probe "stacks").
- That the game-drawn layers work: probe "Game-drawn buffs: built", with 3 layers and 3 buttons made, no errors; the buffs show on the icons, in and out of combat. If they don't, turn off Game-drawn buffs and send the probe.
- That icon 3 lights up with Boosted Rest's time out of combat, and stays lit through a fight.
- That the countdown under the game-drawn icons reads like the buff bar ("12 m"). It stays gold under a minute (the white warning color is Toasty's own and not on these).
- Fallback only: that `C_UnitAuras.GetPlayerAuraBySpellID` finds the buffs in combat: run `/toasty probe` during a fight. "by-ID lookup worked in combat yes" means icons stay exact in combat; "not yet" with "kept" buffs means Toasty is holding the last known state.
- That Boosted Rest is a debuff with a timer, and that you can get rested XP from a tent again once it's gone (icon 3 gray).
- That clicking the bag icon uses the bag once, not twice or never. Probe shows "button uses bag" and your "cast on key down" setting.
- That camp objects show a tooltip when hovered at all (some world objects don't), and that the tooltip's first line is the object's plain name. Probe "Object tooltips" shows how many were explained, and the title of the last world tooltip that wasn't a known object, so a different name can be added.
- What the Faction Banner is called in game, and the First Aid Kit's Stamina amount (the guide gives no number).
