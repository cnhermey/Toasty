# Changelog

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
