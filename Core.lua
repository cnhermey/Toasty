-- Toasty: event dispatch, internal message bus, saved settings.
local addonName, ns = ...

---------------------------------------------------------------------------
-- One event frame, many handlers.
-- Events that may not exist on this client are registered with pcall.
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

frame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for i = 1, #list do
    list[i](event, ...)
  end
end)

function ns.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    if not pcall(frame.RegisterEvent, frame, event) then
      ns.Debug("Event not available:", event)
    end
  end
  table.insert(handlers[event], fn)
end

-- Unit-scoped events (UNIT_AURA for "player" only, not every nameplate).
-- Falls back to a plain registration plus a unit check.
function ns.OnUnit(event, unit, fn)
  local f = CreateFrame("Frame")
  local ok = f.RegisterUnitEvent and pcall(f.RegisterUnitEvent, f, event, unit)
  if not ok and not pcall(f.RegisterEvent, f, event) then
    ns.Debug("Event not available:", event)
    return
  end
  f:SetScript("OnEvent", function(_, ev, u, ...)
    if u == unit then fn(ev, u, ...) end
  end)
end

---------------------------------------------------------------------------
-- Internal message bus (not WoW events).
---------------------------------------------------------------------------
local listeners = {}

function ns.Listen(msg, fn)
  listeners[msg] = listeners[msg] or {}
  table.insert(listeners[msg], fn)
end

function ns.Fire(msg, ...)
  local list = listeners[msg]
  if not list then return end
  for i = 1, #list do
    list[i](...)
  end
end

---------------------------------------------------------------------------
-- Saved settings (account-wide).
---------------------------------------------------------------------------
ns.DEFAULTS = {
  enabled = true,          -- show the icon bar
  locked = false,          -- no Shift-drag
  scale = 100,             -- icon bar size in percent
  framed = true,           -- "Toasty" name and a bordered panel around the icons
  iconLabels = true,       -- "Bag", "Fire", "Rested", "XP" over the icons
  barPoint = nil,          -- { point, relPoint, x, y } after a Shift-drag
  objectTips = true,       -- explain camp objects when you hover them in the world
  engine = true,           -- let the game draw the buffs (works in combat)
  learned = {},            -- spell IDs seen on this client, by our key
  demo = false,            -- demo icons; always off after a reload
  debug = false,
}

-- Settings from 0.1.0 (the old HUD) that no longer exist.
local OLD_KEYS = { "alwaysShow", "showEffects", "hudPoint", "alertReady", "warnSeconds", "alertFire", "onScreen", "sound" }

local function Fill(db, defaults)
  for k, v in pairs(defaults) do
    if db[k] == nil then
      if type(v) == "table" then
        local copy = {}
        for kk, vv in pairs(v) do copy[kk] = vv end
        db[k] = copy
      else
        db[k] = v
      end
    end
  end
end

ns.On("ADDON_LOADED", function(_, name)
  if name ~= addonName then return end
  ToastyDB = ToastyDB or {}
  local db = ToastyDB
  if (db.schema or 1) < 2 then
    for _, k in ipairs(OLD_KEYS) do db[k] = nil end
    if db.learned then db.learned.fire, db.learned.fireIDs = nil, nil end
  end
  Fill(db, ns.DEFAULTS)
  db.schema = 2
  db.demo = false
  ns.db = db
  ns.Fire("INIT")
end)

ns.On("PLAYER_LOGIN", function()
  ns.loggedIn = true
  ns.Fire("LOGIN")
end)

-- The sleeping bag button is a secure button: its click action and the
-- bar's position can only change out of combat (see ns.AfterCombat).
ns.On("PLAYER_REGEN_ENABLED", function() ns.RunAfterCombat() end)
