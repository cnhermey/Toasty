# Toasty Buffs (v0.12.2)

Your camping status in WoW: Forever, as four icons that look like your buff bar, plus tooltips that explain camp objects when you hover them in the world.

- **Sleeping bag countdown.** After you lay out your Cozy Sleeping Bag, the Bag icon counts down the minute to your next Well-Rested stack (one a minute, up to 3 for +3% XP), and the label reads "Bag 1/3", "Bag 2/3" until it's full. Moving pauses it ("still"): stay put on the bag.
- **Icon 1: Well-Rested.** The Cozy Sleeping Bag buff, with Blizzard's icon, its stacks and its time left.
  - **No Well-Rested?** The icon becomes your **Cozy Sleeping Bag**: click it to use the bag. It shows the bag's cooldown, and how many you have when it's more than one.
  - **No bag?** A gray bag icon that says "No bag".
- **Icon 2: Camp Benefits.** The camp buffs, with their time left.
  - **No camp buffs, but by a campfire?** The **Campfire Nearby** icon. Sit for 1 minute to get the camp buffs.
  - **Neither?** A gray Camp Benefits icon.
- **Icon 3: Rest.** Your rested XP, as a percent of your level under the icon. Lit at 5% or more (a Camp Tent only tops you up to 5%, so it would add nothing), or while the tent's cooldown (Boosted Rest) runs.
  - **Gray?** Under 5% rested and no cooldown: rest at a camp with a Camp Tent to top up.
- **Icon 4: XP food.** Well Fed from **Nutritious** food (+5% experience from kills, 15 minutes), with its time left. Well Fed from food without the XP bonus doesn't count.
  - **No XP food buff?** The icon becomes your best Nutritious food (the highest level you can eat): click it to eat. It shows how many you have.
  - **No Nutritious food?** A gray Well Fed icon that says "No food".
- **Fully toasty.** When all four icons are lit (a full 3/3 Well-Rested, Camp Benefits, Boosted Rest and XP food), "Toasty" turns red with a little campfire on each side.
- **Warnings.** In the last minute of Well-Rested, Camp Benefits or the XP food buff, its icon pulses and a quiet chat line says so. Another line tells you when one runs out (Well Fed also drops when you die).
- **Only show what's missing.** Settings → **Only show what's missing** hides an icon while you have its buff (a full 3/3 Well-Rested, Camp Benefits, Boosted Rest, XP food), so a showing icon is your cue to go get it. The others close up, and with everything up the whole panel hides. An icon comes back in its buff's last minute. Off by default.
- **Level 60.** XP buffs do nothing at max level, so the Rest and 5% XP icons hide themselves there (Settings → Hide XP icons at level 60).
- **Camp object tooltips.** Hover a camp object or campfire in the world, and its tooltip says what it does: the profession and tier, the buff or service, what it includes from the tier below, and which class buff it doesn't stack with. Buffs that add a number (mana, Strength, Stamina, Intellect, Spirit, Attack Power, the Lute's armor) show **what you get at your level**, and the level where it goes up next. It also tells you about you: when you already have that class buff (so the camp buff won't add to it), your Camp Tent cooldown, and when you can place your own next camp object.
- **Settings** in Esc → Options → AddOns → Toasty Buffs (or `/toasty`).

### Looks like WoW Forever's UI
- The icons sit in a panel drawn with WoW Forever's own art: by default the **bronze rim of Forever's windows**, with "Toasty" in its title bar, and Forever's bronze **action button ring** around each icon. Settings → **Border style** switches to **Forever slim** (Forever's thin bronze line) or **Tooltip** (Blizzard's tooltip border). **Name and border** turns the panel off for bare icons.
- Forever repaints several stock Blizzard art pieces in bronze; Toasty draws those pieces, following EllesmereUI's measurements. A style whose art is missing falls back to Tooltip.
- A short label over each icon says what it is: **Bag**, **Buffs**, **Rest**, **5% XP** (Settings → **Icon labels**).
- The icons are drawn like the buff bar: 30 px icons, the stack count in Blizzard's number font at the bottom right, and the time left under the icon in the buff bar's font, written the same way ("12 m", "45 s"), turning white under a minute.
- Hovering an icon shows Blizzard's own buff, debuff, item or spell tooltip.
- The sleeping bag button uses Blizzard's button highlight, pressed look and cooldown swipe.
- Object descriptions are added to the game's own tooltip in Blizzard's tooltip colors.
- The settings page uses Blizzard's checkboxes, slider and buttons.

### Camp buffs grow with your level
- The number on a camp buff depends on the level of the player who gets it (your level), not on the builder's profession skill. Skill 20, 140 and 300 only unlock the tier 1, 2 and 3 objects.
- The percentage buffs (Fish Bowl 8%, Camp Chair 2%) and the Camp Tent are the same at every level.
- Toasty starts from the level table in the game client's tooltip data (as published by endgametools.com). Out of combat, it also reads your own camp buffs' tooltips and saves each number with your level, so the tooltip uses what you really got (it then says "from your own buff"). Saved numbers are shared by all your characters.
- A buff you had before you levelled up isn't read, in case it still carries the old number. Learning reads English tooltips only; other languages use the table.

### Combat and secret values
- Using an item needs a secure button, so the icon bar is protected: moving it, resizing it, showing or hiding it (Only show what's missing too) and switching icon 1 between "buff" and "use bag" wait until you leave combat. The icons and times still update in combat.
- In combat, Forever hides which buff is which from addons. So the buffs themselves are drawn by the game: icons 1 and 2 each have an engine aura slot (the 12.1 aura containers, as EllesmereUI uses them) that the game fills with the matching buff, with its icon, stacks and countdown, in or out of combat. Toasty only draws what lies under it: the sleeping bag button, "No bag", and the gray icons.
- XP food (icon 4): each food has its own Well Fed spell, and the XP bonus is only in its tooltip. Out of combat, Toasty reads a Well Fed buff's tooltip for "experience" and remembers whether that spell gives XP. From then on that food is game-drawn too, so it works in combat. The very first time you eat a new food, if you go straight into combat, the icon counts down from the time it read.
- Boosted Rest (icon 3) is a debuff, which the game-drawn slots don't show, so Toasty draws it itself. In combat it stays lit and counts down from the end time it read before the fight.
- Hovering a lit icon shows the game's own buff tooltip. Clicks and Shift-drag go through to Toasty's icon underneath.
- Settings → Testing → **Game-drawn buffs** turns this off, so Toasty draws the buffs itself (exact out of combat, best effort in combat).
- On a client without aura containers, Toasty reads the buffs itself: it asks for each by spell ID, and if it can't tell in combat it keeps the last known state and counts down from the time it knew.

## Install
1. Copy the `ToastyBuffs` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
   **Copy the folder; don't symlink it.** On Forever, a symlinked addon folder silently resets its SavedVariables.
2. Restart the game, or `/reload` if it's already running, and enable the addon on the character screen.
3. The TOC says `## Interface: 16001`. If the addon shows as out of date, check the real number with
   `/run print(select(4, GetBuildInfo()))` and update the TOC line.
4. Updating from 0.7.x or older: the folder is now `ToastyBuffs`. Delete the old `Toasty` folder. To keep your settings, copy `WTF\Account\<account>\SavedVariables\Toasty.lua` to `ToastyBuffs.lua` in the same folder (game closed) and change `ToastyDB` to `ToastyBuffsDB` inside it.

## First in-game test (solo)
1. Type `/toasty demo`. The two icons cycle through every state, 5 seconds each. Shift-drag the panel where you want it. Type `/toasty demo` again to stop.
2. With a Cozy Sleeping Bag and no Well-Rested, click icon 1: the bag should be used and the icon should turn into Well-Rested with its time.
3. Stand by a campfire: icon 2 shows Campfire Nearby. `/sit` for a minute: it becomes Camp Benefits with its time.
   With a Camp Tent at the camp, icon 3 lights up as Boosted Rest with its time; without the debuff it stays gray.
4. Hover a camp object or campfire in the world: the tooltip should explain it, with the buff's value at your level. Type `/toasty tip Camp Chair` to see one without a camp, or `/toasty tip Mana Well 30` to see it as a level 30.
5. Sit at a camp with a stat object (Mana Well, Sharpening Wheel, First Aid Kit...) until you have Camp Benefits, out of combat.
6. Type `/toasty probe` and send the output.

## Commands
- `/toasty buffs`: list your buffs with their spell IDs and your rested XP (for bug reports)
- `/toasty`, `/toast` or `/toastybuffs`: open the settings
- `/toasty show`, `/toasty hide`: show or hide the icons
- `/toasty demo`: cycle the icons through every state (again to stop)
- `/toasty tip <object> [level]`: show a camp object's tooltip at the cursor, e.g. `/toasty tip Camp Chair`, or `/toasty tip Mana Well 30` to see it at level 30
- `/toasty reset`: move the icons back to their first spot
- `/toasty probe`: developer report

## How it works
| File | Role |
|---|---|
| `Util.lua` | Helpers: secret-value guards, safe API calls, chat output, timers, combat queue, buff-bar time format |
| `Core.lua` | Event frame, internal message bus, SavedVariables (`ToastyBuffsDB`), runs queued changes after combat |
| `UI_Common.lua` | Blizzard colors, icons and sounds |
| `Status.lua` | Reads your buffs and debuffs on `UNIT_AURA` (Well-Rested 429959, Camp Benefits 1229741, Campfire Nearby 1283391, Boosted Rest 1229451) by spell ID and by name, learning new IDs; counts your Cozy Sleeping Bags (item 211527) and reads its cooldown |
| `Sleep.lua` | The sleeping bag countdown: your cast of the bag's use spell starts a minute to the next Well-Rested stack; each new stack restarts it, 3 ends it; moving pauses it |
| `Alerts.lua` | Last-minute pulse and chat line for Well-Rested, Camp Benefits and XP food, and a line when one drops |
| `Food.lua` | The XP food buff: Well Fed (by name, icon 136000, or the food buffs not named Well Fed) whose tooltip mentions experience, learned per spell ID; the best Nutritious food in your bags (items whose use spell is Nutritious Food, 1248377, as EllesmereUI finds them) |
| `Scaling.lua` | Camp buff values by your level: the client's level table, plus numbers read from your own Camp Benefits (and object-named) buff tooltips out of combat, saved per level in `ToastyBuffsDB.scaling` |
| `Objects.lua` | What every camp object and campfire does; adds it to the game tooltip for world objects (`TooltipDataProcessor` for objects when the client has it, else `GameTooltip` `OnShow` when the tooltip belongs to the world) |
| `Engine.lua` | Game-drawn buff layers: an `AuraContainer` (`CustomAuraContainerTemplate`) per buff with one aura slot limited to its spell IDs (`candidateFilters.includeSpellIDs`), set up in the slot's `initializeFrame` |
| `UI_Frame.lua` | The panel border per Border style: Forever's window rim (`UI-Frame-Metal` pieces, title bar included, at 75% size), Forever's slim line (`UI-HUD-ActionBar-Frame` cut into corners and edges) or the tooltip border |
| `UI_Bar.lua` | The four icons; icons 1 and 4 are `SecureActionButtonTemplate`s that use the bag or eat the food |
| `Options.lua` | Settings page in Esc → Options → AddOns, through one setter (`ns.Options:Set`) |
| `Demo.lua` | The demo icons (`/toasty demo`) |
| `Commands.lua` | `/toasty`, `/toast` and the `/toasty probe` report |

Camp object descriptions come from Wowhead's Camping Overview guide (patch 1.60.1). Edit `DATA` at the top of `Objects.lua` to change them.

## Needs in-game verification
- The bronze border: that it lines up (no gaps at the corners, the title bar behind "Toasty"), and the slim style too. Probe "Border" shows which style is drawn and which art exists.
- The bronze ring on each icon (Forever's action button frame) fits the 30 px icons.
- The sleeping bag countdown: that using the bag is seen (probe "Sleeping bag": "bag uses seen 1"), that a stack arrives about when the countdown hits 0, and whether moving off the bag and back really restarts the minute.
- That a single Well-Rested stack reads as 1 (or 0) stacks, so "Bag 1/3" is right.
- Camp object tooltips: "You have Arcane Intellect..." when you do, and "Your next camp object" after you place one (probe: "next camp object").
- XP food in other languages: the words in `Food.lua` (XP_WORDS) are WoW's usual ones, unconfirmed on Forever.
- That a Nutritious food's Well Fed tooltip says "experience" (probe "XP food": "tooltips checked ... XP 1" after eating one, and its ID under "XP Well Fed IDs"). Non-English clients won't match yet.
- That Nutritious food in bags is found (probe "Nutritious food": the name in quotes, and the food under "in bags"), and that clicking icon 4 eats it once.
- That the food's game-drawn layer shows in combat (probe "game-drawn layer yes" once an XP food has been learned).
- That the four buff and debuff IDs are right on the live client. `/toasty probe` "Buffs" lines show each ID, any learned ID, and red "(name not from client)" if the client didn't know it.
- That Well-Rested has stacks (probe "stacks").
- That the game-drawn layers work: probe "Game-drawn buffs: built", with 3 layers and 3 buttons made, no errors; the buffs show on the icons, in and out of combat. If they don't, turn off Game-drawn buffs and send the probe.
- That icon 3 lights up with Boosted Rest's time out of combat, and stays lit through a fight.
- That the countdown under the game-drawn icons reads like the buff bar ("12 m"). It stays gold under a minute (the white warning color is Toasty's own and not on these).
- Fallback only: that `C_UnitAuras.GetPlayerAuraBySpellID` finds the buffs in combat: run `/toasty probe` during a fight. "by-ID lookup worked in combat yes" means icons stay exact in combat; "not yet" with "kept" buffs means Toasty is holding the last known state.
- That Boosted Rest is a debuff with a timer, and that you can get rested XP from a tent again once it's gone (icon 3 gray).
- That clicking the bag icon uses the bag once, not twice or never. Probe shows "button uses bag" and your "cast on key down" setting.
- Only show what's missing: icons hide as their buffs arrive and come back in the last minute, the row closes up without gaps, and the panel hides when nothing is missing. Probe "Icons shown": "only missing on, showing ..." should match "laid out ..." out of combat.
- That hovering an icon with an active buff shows only one tooltip, in and out of combat. Probe "tooltips left to the game" should go up each time you hover one.
- That camp objects show a tooltip when hovered at all (some world objects don't), and that the tooltip's first line is the object's plain name. Probe "Object tooltips" shows how many were explained, and the title of the last world tooltip that wasn't a known object, so a different name can be added.
- What the Faction Banner is called in game.
- Camp buff scaling: that the Camp Benefits tooltip lists the numbers (probe "Camp buff scaling": "tooltips read" goes up and "last read" shows e.g. "str 34 at level 60"), and that they match the level table (probe "Differs from the level table: nothing"). If the buff tooltip has no numbers, each object may have its own buff: "read 0" with Camp Benefits on means Toasty needs the buff's name.
- Whether a camp buff picked up before a level-up updates to the new level's number (Toasty assumes it may not).
