-- Toasty: Demo icons. Cycles the icon bar through every state (both buffs
-- with stacks, the sleeping bag button, "No bag", Campfire Nearby, no camp
-- buffs, Boosted Rest on and ready) so you can see them without camping. Only the look changes: the
-- bag button still uses your real bag (or nothing), never the demo's.
-- Always off after a reload. Settings > Testing > Demo icons, or /toasty demo.
local _, ns = ...

local D = { s = {}, bags = 0 }
ns.Demo = D

local SECONDS_PER_SCENE = 5

local function Buff(key, left, duration, stacks)
  return {
    icon = ns.Status:Icon(key), stacks = stacks, duration = duration,
    expires = left and (GetTime() + left) or nil,
  }
end

local SCENES = {
  { text = "Well-Rested (3 stacks), camp buffs and Boosted Rest", build = function()
      return { wellRested = Buff("wellRested", 1450, 1800, 3), benefits = Buff("benefits", 1740, 1800),
        boosted = Buff("boosted", 2280, 3600) }, 1
    end },
  { text = "No Well-Rested: sleeping bag button; by a campfire; tent ready", build = function()
      return { nearby = Buff("nearby") }, 2
    end },
  { text = "No sleeping bag; no camp buffs", build = function()
      return {}, 0
    end },
  { text = "Buffs running out (white under a minute)", build = function()
      return { wellRested = Buff("wellRested", 42, 1800, 1), benefits = Buff("benefits", 25, 1800),
        boosted = Buff("boosted", 50, 3600) }, 1
    end },
}

local scene, ticker

local function Apply(i)
  local sc = SCENES[i]
  D.s, D.bags = sc.build()
  ns.Print("Demo " .. i .. "/" .. #SCENES .. ": " .. sc.text .. ".")
  ns.Fire("STATUS_CHANGED")
end

function D:Start()
  if self.active then return end
  self.active = true
  scene = 1
  Apply(scene)
  ticker = C_Timer.NewTicker(SECONDS_PER_SCENE, function()
    scene = scene % #SCENES + 1
    Apply(scene)
  end)
end

function D:Stop()
  if not self.active then return end
  self.active = false
  if ticker then ticker:Cancel(); ticker = nil end
  D.s, D.bags = {}, 0
  ns.Print("Demo off.")
  ns.Fire("STATUS_CHANGED")
end

ns.Listen("SETTINGS_CHANGED", function(key)
  if key ~= "demo" then return end
  if ns.db.demo then D:Start() else D:Stop() end
end)
