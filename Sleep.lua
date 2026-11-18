-- Toasty: the sleeping bag countdown.
--
-- The Cozy Sleeping Bag is laid on the ground; standing still on it gives a
-- Well-Rested stack every minute, up to 3 (1 min +1%, 2 min +2%, 3 min +3%,
-- per the Forever guides). The game shows nothing while you wait, so after
-- you use the bag Toasty counts down the minute to the next stack on the
-- Bag icon.
-- When the bag is used: your cast of the bag's use spell (its ID and name
-- from C_Item.GetItemSpell, learned on the first cast if it differs).
-- A stack arriving restarts the minute for the next one; 3 stacks end it.
-- Moving: the guides say you must stay still, so moving pauses the
-- countdown ("Stay still") and stopping starts a fresh minute. Whether the
-- game really restarts the minute is unverified (README).
-- Ends too after 5 minutes without a new stack (bag packed up, walked away).
local _, ns = ...

local Z = {
  session = nil,   -- { started, nextAt, moving, lastStack } while waiting for stacks
  seen = { uses = 0, stacks = 0 },
}
ns.Sleep = Z

Z.MINUTE = 60
Z.GIVE_UP = 300

local bagSpellID, bagSpellName

local function LoadBagSpell()
  if not (C_Item and C_Item.GetItemSpell) then return end
  local name, id = C_Item.GetItemSpell(ns.Status.BAG_ITEM)
  bagSpellName, bagSpellID = ns.Str(name), ns.Num(id)
  if not bagSpellName and C_Item.RequestLoadItemDataByID then
    pcall(C_Item.RequestLoadItemDataByID, ns.Status.BAG_ITEM)
  end
end

local function Stacks()
  local a = ns.Status.s.wellRested
  if not a then return 0 end
  local n = a.stacks
  if not n or n < 1 then n = 1 end   -- one stack can read as 0 applications
  return n
end

function Z:Start()
  self.seen.uses = self.seen.uses + 1
  self.session = { started = GetTime(), nextAt = GetTime() + Z.MINUTE, lastStack = Stacks() }
  ns.Debug("Sleeping bag used: next stack in 60 s")
  ns.Fire("STATUS_CHANGED")
end

function Z:Stop(why)
  if not self.session then return end
  self.session = nil
  ns.Debug("Sleeping bag countdown ended:", why)
  ns.Fire("STATUS_CHANGED")
end

-- Seconds to the next stack and which stack it is (2 means "2/3 next"),
-- or nil when not waiting. moving = true while paused.
function Z:Countdown()
  local s = self.session
  if not s then return nil end
  local nextStack = math.min(ns.Status.BAG_STACKS, Stacks() + 1)
  if s.moving then return nil, nextStack, true end
  return math.max(0, s.nextAt - GetTime()), nextStack, false
end

-- Status changed: a new stack restarts the minute; a full bag ends it.
local function OnStatus()
  local s = Z.session
  if not s then return end
  local n = Stacks()
  if n > s.lastStack then
    Z.seen.stacks = Z.seen.stacks + 1
    s.lastStack = n
    if n >= ns.Status.BAG_STACKS then
      Z:Stop("full")
      return
    end
    s.nextAt = GetTime() + Z.MINUTE
    s.started = GetTime()
  end
end

ns.Listen("LOGIN", LoadBagSpell)
ns.On("ITEM_DATA_LOAD_RESULT", function(_, id)
  if id == ns.Status.BAG_ITEM then LoadBagSpell() end
end)

ns.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, _, spellID)
  local id = ns.Num(spellID)
  if not id then return end
  if not bagSpellName then LoadBagSpell() end
  local hit = (bagSpellID and id == bagSpellID)
  if not hit and bagSpellName then
    hit = ns.Status.SpellName(id) == bagSpellName
    if hit then bagSpellID = id end
  end
  if hit and Stacks() < ns.Status.BAG_STACKS then Z:Start() end
end)

ns.On("PLAYER_STARTED_MOVING", function()
  local s = Z.session
  if s and not s.moving then
    s.moving = true
    ns.Fire("STATUS_CHANGED")
  end
end)

ns.On("PLAYER_STOPPED_MOVING", function()
  local s = Z.session
  if s and s.moving then
    s.moving = false
    s.nextAt = GetTime() + Z.MINUTE
    s.started = GetTime()
    ns.Fire("STATUS_CHANGED")
  end
end)

ns.Listen("STATUS_CHANGED", OnStatus)

-- Give up when nothing has happened for a while.
C_Timer.NewTicker(5, function()
  local s = Z.session
  if s and GetTime() - s.started > Z.GIVE_UP then Z:Stop("timed out") end
end)
