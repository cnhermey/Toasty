-- Toasty: warnings before a buff runs out, and when one drops.
--
-- In the last minute of Well-Rested, Camp Benefits or the XP food buff, the
-- icon pulses (UI_Bar's B:SetWarning) and a quiet chat line says so, once
-- per buff. When one of them drops, another chat line (Well Fed also drops
-- when you die). No sounds: these are nudges, not alarms.
-- Times come from Toasty's own reading (Status.lua, Food.lua): exact out of
-- combat, the last known end time in combat. A drop is only reported from
-- a readable scan, so it never fires because combat hid a buff.
-- Settings > Alerts > Warnings (warnings). The demo shows the pulse only.
local _, ns = ...

local A = { warned = {}, had = {}, primed = false, seen = { warned = 0, dropped = 0 } }
ns.Alerts = A

A.WINDOW = 60

-- The buffs watched: key, icon index, name, and where its aura is.
local function Watched(useDemo)
  local S, F = ns.Status, ns.Food
  local s = useDemo and ns.Demo.s or S.s
  local food = useDemo and ns.Demo.s.food or F.s
  local all = {
    { key = "wellRested", slot = 1, name = S:Name("wellRested"), a = s.wellRested },
    { key = "benefits",   slot = 2, name = S:Name("benefits"),   a = s.benefits },
    { key = "food",       slot = 4, name = F:Name() .. " (XP)",  a = food },
  }
  -- Only icons that show (Settings > Show icons; the XP ones go at level 60).
  local list = {}
  for _, w in ipairs(all) do
    if ns.Bar:Allowed(w.slot) then list[#list + 1] = w else ns.Bar:SetWarning(w.slot, false) end
  end
  return list
end

local function Say(text)
  if ns.db.warnings then ns.Print(text) end
end

function A:Tick()
  if not ns.db or not ns.Bar.frame then return end
  local demo = ns.Demo.active
  local inCombat = InCombatLockdown and InCombatLockdown() and true or false
  for _, w in ipairs(Watched(demo)) do
    local a = w.a
    local left = a and ns.Status:Left(a)
    local ending = left and left > 0 and left <= A.WINDOW
    ns.Bar:SetWarning(w.slot, ns.db.warnings and ending or false)

    if not demo then
      if ending and A.warned[w.key] ~= a.expires then
        A.warned[w.key] = a.expires
        if A.primed then
          A.seen.warned = A.seen.warned + 1
          Say(w.name .. " runs out in " .. (ns.BuffTime(left) or "a minute") .. ".")
        end
      end
      -- Dropped: had it, a readable scan says it's gone (not kept in combat).
      if a then
        A.had[w.key] = true
      elseif A.had[w.key] and not inCombat then
        A.had[w.key] = nil
        if A.primed then
          A.seen.dropped = A.seen.dropped + 1
          local dead = UnitIsDeadOrGhost and ns.Clean(UnitIsDeadOrGhost("player"))
          Say(w.name .. (dead and " is gone (you died)." or " ran out."))
        end
      end
    end
  end
  A.primed = true   -- nothing is reported for what you had at login
end

ns.Listen("LOGIN", function()
  C_Timer.After(3, function()
    A:Tick()
    C_Timer.NewTicker(1, function() A:Tick() end)
  end)
end)

ns.Listen("SETTINGS_CHANGED", function(key)
  if key == "warnings" or key == "demo" or key == "hideXPAtMax"
    or key == "showBag" or key == "showBuffs" or key == "showFood" then A:Tick() end
end)
