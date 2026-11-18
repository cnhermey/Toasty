# Changelog

## 0.12.1 (2026-11-18)
- Fixed `/toasty tip` and the Test tooltip button showing the camp object's description twice. Hovering real camp objects wasn't affected.

## 0.12.0 (2026-11-18)
- New setting: **Only show what's missing** (Settings → Icons). An icon hides while you have its buff (a full 3/3 Well-Rested, Camp Benefits, Boosted Rest, XP food), so an icon on screen means "go get this". The other icons close up, and when you have everything the panel hides. An icon comes back in its buff's last minute. Off by default.
- In combat, icons wait until the fight ends to hide or come back.

## 0.11.0 (2026-11-18)
- Camp object tooltips now show what a buff gives **at your level**, and the level where it goes up next (for example "+11 Strength", "More at level 38: +20 Strength"). Before, they always showed the level 60 number.
- This covers the Mana Well, Sharpening Wheel, First Aid Kit, Lodestone, Incense Candle, Faction Banner and Enchanted Lute. The Fish Bowl, Camp Chair and Camp Tent are the same at every level.
- Toasty learns: out of combat it reads your own camp buffs and remembers the real numbers for each level, for all your characters. Learned numbers show as "from your own buff".
- The First Aid Kit tooltip now gives its Stamina amount.
- `/toasty tip Mana Well 30` shows a tooltip as if you were level 30.

## 0.10.1 (2026-11-18)
- Fixed two tooltips drawing over each other when you hover an icon with an active buff. Now you see only the game's buff tooltip. If a buff starts or ends while you hover, the tooltip switches over.
- Fixed an error at login that could stop the game-drawn icons from hiding in demo mode.

## 0.10.0 (2026-11-17)
- New look: the panel now wears WoW Forever's bronze window frame, with "Toasty" in its title bar, and each icon gets Forever's bronze action button ring.
- Settings → Border style: Forever bronze (new default), Forever slim (a thinner bronze line) or Tooltip (the old look).
- Gray icons are dimmer, like an unusable action button, and the last-minute pulse is warm bronze.

## 0.9.0 (2026-11-17)
- Sleeping bag countdown: after you lay out your Cozy Sleeping Bag, the Bag icon counts down the minute to each Well-Rested stack, and the label shows "Bag 1/3", "Bag 2/3" until it's full. Moving pauses it.
- "Toasty" only turns red with a full 3/3 Well-Rested.
- Warnings: an icon pulses in its buff's last minute, with a quiet chat line, and another line when Well-Rested, Camp Benefits or your XP food runs out. Turn off in Settings → Warnings.
- At level 60 the Rest and 5% XP icons hide themselves (they do nothing there). Settings → Hide XP icons at level 60.
- Camp object tooltips now also say when you already have the class buff a camp buff doesn't stack with, your Camp Tent cooldown, and when you can place your next camp object.
- XP food is recognized on German, French, Spanish, Italian, Portuguese, Russian, Korean and Chinese clients too.
- Fixed: thin light lines at the side of the Bag icon.

## 0.8.0 (2026-11-17)
- Toasty's folder is now **ToastyBuffs** (it shows as "Toasty Buffs" in your addon list and options), so it can't clash with the other Forever addon called Toasty.
- Updating by hand: delete the old **Toasty** folder from Interface\AddOns. Addon managers handle it for you. Your settings start fresh unless you copy them over (see the README).
- `/toasty` and `/toast` still work, and `/toastybuffs` is new.

## 0.7.2 (2026-11-17)
- Toasty is now on CurseForge. No changes in game.

## 0.7.1 (2026-11-17)
- New picture for Toasty in WoWUp, showing all four icons and a camp object tooltip. No changes in game.

## 0.7.0 (2026-11-17)
- When all four icons are lit, "Toasty" turns red with a little campfire on each side. The demo's first step shows it.

## 0.6.3 (2026-11-17)
- Labels are now Bag, Buffs, Rest and 5% XP, and the icons are back to their closer spacing.

## 0.6.2 (2026-11-17)
- Labels renamed: "Rested" is now "Rest XP" and "XP" is now "5% XP". The icons are a little further apart so the longer labels fit.

## 0.6.1 (2026-11-17)
- Short labels over the icons: Bag, Fire, Rested and XP. Turn them off in Settings → Icon labels.

## 0.6.0 (2026-11-17)
- New fourth icon: XP food. It shows Well Fed from Nutritious food (+5% experience from kills) with its time left. Food without the XP bonus doesn't count.
- Without the buff, click the icon to eat your best Nutritious food. With none in your bags, it says "No food".
- The demo shows the food icon too.

## 0.5.0 (2026-11-17)
- The icons now sit in a bordered panel with "Toasty" centered above them. Turn it off in Settings → Name and border.
- Shift-drag the panel itself to move it, not only the icons.

## 0.4.2 (2026-11-17)
- Fixed: the Boosted Rest icon didn't light up. Toasty now draws it itself, and it stays lit with its time through combat.

## 0.4.1 (2026-11-17)
- Fixed: buffs didn't show at all in 0.4.0. The game-drawn icons now sit on Toasty's icons.
- New setting: Testing → Game-drawn buffs. Turn it off to have Toasty draw the buffs itself.

## 0.4.0 (2026-11-17)
- The buff icons are now drawn by the game itself, the way EllesmereUI draws buffs, so they stay accurate in combat: they light up, count down and go gray exactly as the buffs come and go, even mid-fight.
- Hovering a lit icon shows the game's own buff tooltip.
- "No bag" now sits on the gray bag icon.

## 0.3.1 (2026-11-17)
- Fixed: the icons no longer turn gray in combat. Your buffs stay lit and keep counting down during a fight.

## 0.3.0 (2026-11-17)
- New third icon: Boosted Rest, the Camp Tent's cooldown, with its time left. Gray when you don't have it, meaning a Camp Tent can give you more rested XP.

## 0.2.0 (2026-11-17)
- Toasty is now two icons that look like your buff bar, instead of the campfire panel.
- Icon 1: Well-Rested with its stacks and time. Without it, click the icon to use your Cozy Sleeping Bag; without a bag, it says "No bag".
- Icon 2: Camp Benefits with its time. Without it, Campfire Nearby when you're by a fire, else a gray Camp Benefits icon.
- Hover a camp object or campfire in the world to see what it does.
- New: `/toasty tip <object>` to preview an object's tooltip.
- Removed: the campfire panel, its alerts and its fire and cooldown timers.

## 0.1.0 (2026-11-17)
- First version: a campfire panel with a sit timer, camp buffs, your fire's time and camp cooldowns, with alerts.
