-- Toasty: shared helpers.
-- Every file receives the same private namespace table `ns` from the TOC loader.
local addonName, ns = ...

ns.ADDON_NAME = addonName

do
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  ns.VERSION = (getMeta and getMeta(addonName, "Version")) or "dev"
end

---------------------------------------------------------------------------
-- Secret values (12.x engine). WoW: Forever can hand back restricted values,
-- mostly in combat. Never compare, branch on, do arithmetic with, or format
-- a secret. Widgets (StatusBar:SetValue, FontString:SetText) accept them.
---------------------------------------------------------------------------
function ns.IsSecret(v)
  return issecretvalue ~= nil and issecretvalue(v) == true
end

-- The value when it can be read, else nil.
function ns.Clean(v)
  if ns.IsSecret(v) then return nil end
  return v
end

-- A readable number, else nil.
function ns.Num(v)
  if ns.IsSecret(v) then return nil end
  if type(v) ~= "number" then return nil end
  return v
end

-- A readable, non-empty string, else nil.
function ns.Str(v)
  if ns.IsSecret(v) or type(v) ~= "string" or v == "" then return nil end
  return v
end

---------------------------------------------------------------------------
-- Calls that may not exist or may fail on this client. Each place that fails
-- is reported once (with debug on), so one changed API never breaks the rest.
---------------------------------------------------------------------------
local reported = {}
local function Pack(...) return { n = select("#", ...), ... } end
function ns.Try(where, fn, ...)
  if type(fn) ~= "function" then return nil end
  local r = Pack(pcall(fn, ...))
  if not r[1] then
    if not reported[where] then
      reported[where] = true
      ns.Debug("API error in", where, tostring(r[2]))
    end
    return nil
  end
  return unpack(r, 2, r.n)
end

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------
-- Native look: Toasty messages look like Blizzard system messages (system
-- chat color, short "Toasty:" prefix).
local TAG = "Toasty: "

local function ToText(v)
  if ns.IsSecret(v) then return "<secret>" end
  return tostring(v)
end

local function SystemColor()
  local info = ChatTypeInfo and ChatTypeInfo.SYSTEM
  if info and info.r then return info.r, info.g, info.b end
  return 1, 1, 0
end

function ns.PrintLine(text)
  DEFAULT_CHAT_FRAME:AddMessage(text, SystemColor())
end

function ns.Print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = ToText((select(i, ...)))
  end
  ns.PrintLine(TAG .. table.concat(parts, " "))
end

function ns.Debug(...)
  if ns.db and ns.db.debug then
    ns.Print("[debug]", ...)
  end
end

---------------------------------------------------------------------------
-- Timers: Coalesce runs fn once, `delay` seconds after the FIRST request in
-- a burst (never starves under constant events). Debounce restarts the timer
-- on every request (runs after things go quiet).
---------------------------------------------------------------------------
local pending = {}
function ns.Coalesce(key, delay, fn)
  if pending[key] then return end
  pending[key] = true
  C_Timer.After(delay, function()
    pending[key] = nil
    fn()
  end)
end

local timers = {}
function ns.Debounce(key, delay, fn)
  if timers[key] then timers[key]:Cancel() end
  timers[key] = C_Timer.NewTimer(delay, function()
    timers[key] = nil
    fn()
  end)
end

function ns.Cancel(key)
  if timers[key] then
    timers[key]:Cancel()
    timers[key] = nil
  end
end

---------------------------------------------------------------------------
-- Combat queue: protected frame changes (create, move, show, attributes) are
-- refused in combat. Queue them for PLAYER_REGEN_ENABLED instead.
---------------------------------------------------------------------------
local afterCombat = {}
function ns.AfterCombat(key, fn)
  if not InCombatLockdown() then
    fn()
    return
  end
  afterCombat[key] = fn
end

function ns.RunAfterCombat()
  local queued = afterCombat
  afterCombat = {}
  for _, fn in pairs(queued) do fn() end
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------
function ns.Percent(cur, max)
  cur, max = ns.Num(cur), ns.Num(max)
  if not cur or not max or max <= 0 then return nil end
  return cur / max * 100
end

function ns.Clock(t)
  return date("%H:%M:%S", t or time())
end

-- Seconds as a short clock: "0:42", "7:12", "1:02:05" (probe output). nil stays nil.
function ns.Duration(sec)
  sec = ns.Num(sec)
  if not sec then return nil end
  if sec < 0 then sec = 0 end
  sec = math.floor(sec + 0.5)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%d:%02d", m, s)
end

-- Seconds the way Blizzard's buff bar writes them ("12 m", "45 s", "2 h").
function ns.BuffTime(sec)
  sec = ns.Num(sec)
  if not sec then return nil end
  if sec < 0 then sec = 0 end
  if SecondsToTimeAbbrev then
    local ok, fmt, value = pcall(SecondsToTimeAbbrev, sec)
    if ok and type(fmt) == "string" then
      local ok2, text = pcall(string.format, fmt, value)
      if ok2 then return text end
    end
  end
  if sec >= 3600 then return math.ceil(sec / 3600) .. " h" end
  if sec >= 60 then return math.ceil(sec / 60) .. " m" end
  return math.floor(sec) .. " s"
end
