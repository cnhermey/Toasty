-- Toasty: how much a camp buff gives at your level.
--
-- Camp buffs that add a number (mana, Strength, Stamina, Intellect, Spirit,
-- Attack Power, the Lute's armor/stats/resistances) grow with the level of
-- the player who gets the buff, not with the builder's profession skill
-- (skill 20/140/300 only unlocks the tier 1/2/3 objects). The percentage
-- buffs (Fish Bowl 8%, Camp Chair 2%) and the Camp Tent don't scale.
--
-- Two sources, best first:
--   1. Learned: out of combat, Toasty reads your own camp buff tooltips and
--      saves each number with the level you had when the buff arrived
--      (ToastyBuffsDB.scaling[stat][level]). Account-wide: the value depends
--      on level only, so every character helps fill it in.
--   2. The level bands below, from the client's own tooltip data as
--      published by endgametools.com ("every object's value by level",
--      November 2026). Blizzard's 21 October table gives the same ranges.
-- A buff that was already on you when you levelled up isn't learned from:
-- it may still carry the old level's number.
-- Tooltip words are English only (other clients still get the bands).
local _, ns = ...

local Sc = {
  seen = { read = 0, unreadable = 0, learned = 0, changed = 0, mismatch = 0, skippedLevel = 0 },
  last = nil,           -- "Strength 34 at 60" from the last tooltip read
  instances = {},       -- auraInstanceID -> your level when that buff first showed
}
ns.Scaling = Sc

-- Each scaling object: its stats (in order), and bands of
-- { from level, value per stat }. Text(v) writes the tooltip line.
local OBJECTS = {
  ["Mana Well"] = {
    stats = { "mp5" },
    bands = { { 1, 10 }, { 24, 15 }, { 34, 20 }, { 44, 24 }, { 54, 29 } },
    Text = function(v) return "Restores " .. v[1] .. " mana every 5 sec." end,
  },
  ["Sharpening Wheel"] = {
    stats = { "str" },
    bands = { { 1, 6 }, { 24, 11 }, { 38, 20 }, { 52, 34 } },
    Text = function(v) return "+" .. v[1] .. " Strength." end,
  },
  ["First Aid Kit"] = {
    stats = { "sta" },
    bands = { { 1, 3 }, { 12, 8 }, { 24, 21 }, { 36, 34 }, { 48, 45 }, { 60, 56 } },
    Text = function(v) return "+" .. v[1] .. " Stamina." end,
  },
  ["Lodestone"] = {
    stats = { "ap" },
    bands = { { 1, 12 }, { 12, 20 }, { 22, 32 }, { 32, 49 }, { 42, 67 }, { 52, 90 } },
    Text = function(v) return "+" .. v[1] .. " melee Attack Power." end,
  },
  ["Incense Candle"] = {
    stats = { "int" },
    bands = { { 1, 2 }, { 14, 6 }, { 28, 12 }, { 42, 18 }, { 56, 25 } },
    Text = function(v) return "+" .. v[1] .. " Intellect." end,
  },
  ["Faction Banner"] = {
    stats = { "spi" },
    bands = { { 1, 14 }, { 40, 19 }, { 50, 27 }, { 60, 32 } },
    Text = function(v) return "+" .. v[1] .. " Spirit for players of the banner's faction." end,
  },
  ["Enchanted Lute"] = {
    stats = { "armor", "stats", "res" },
    bands = { { 1, 28, 0, 0 }, { 10, 71, 2, 0 }, { 20, 114, 4, 0 }, { 30, 163, 7, 6 },
              { 40, 211, 9, 12 }, { 50, 260, 12, 16 }, { 60, 308, 13, 22 } },
    Text = function(v)
      local parts = { "+" .. v[1] .. " Armor" }
      if v[2] and v[2] > 0 then parts[#parts + 1] = "+" .. v[2] .. " to all stats" end
      if v[3] and v[3] > 0 then parts[#parts + 1] = "+" .. v[3] .. " to all resistances" end
      if #parts == 3 then return parts[1] .. ", " .. parts[2] .. " and " .. parts[3] .. "." end
      return table.concat(parts, " and ") .. "."
    end,
  },
}
Sc.OBJECTS = OBJECTS

-- How each stat reads in an English buff tooltip. %K is the stat's words.
-- "Increases Strength by 34", "+34 Strength", "Restores 29 mana every 5 sec",
-- "armor by 308, all attributes by 13 and all resistances by 22".
local WORDS = {
  mp5   = { "mana every 5", "mana per 5" },
  str   = { "strength" },
  sta   = { "stamina" },
  int   = { "intellect" },
  spi   = { "spirit" },
  ap    = { "attack power" },
  armor = { "armor" },
  stats = { "all stats", "all attributes" },
  res   = { "all resistances" },
}

local function Level()
  if Sc.levelOverride then return Sc.levelOverride end
  return ns.Num(UnitLevel("player"))
end

local function Store()
  ns.db.scaling = ns.db.scaling or {}
  return ns.db.scaling
end

-- The band values for `level`, and the next band (or nil at the top).
local function Band(obj, level)
  local cur, nxt = obj.bands[1], nil
  for i, b in ipairs(obj.bands) do
    if level >= b[1] then cur, nxt = b, obj.bands[i + 1] end
  end
  return cur, nxt
end

-- Values for `name` at `level`: { v1, v2, ... }, and how many came from your
-- own buffs ("seen") vs the bands.
function Sc:Values(name, level)
  local obj = OBJECTS[name]
  if not obj or not level then return nil end
  local band = Band(obj, level)
  local learned = Store()
  local v, seen = {}, 0
  for i, stat in ipairs(obj.stats) do
    local l = learned[stat] and learned[stat][level]
    if l then v[i], seen = l, seen + 1 else v[i] = band[i + 1] end
  end
  return v, seen, #obj.stats
end

-- For Objects.lua: the buff text at your level, and a gray note line.
-- Returns nil for objects that don't scale.
function Sc:Describe(name)
  local obj = OBJECTS[name]
  if not obj then return nil end
  local level = Level()
  if not level then
    -- Level unreadable (shouldn't happen): show level 60, and say so.
    local top = obj.bands[#obj.bands]
    local v = {}
    for i = 2, #top do v[#v + 1] = top[i] end
    return obj.Text(v), "At level 60. Less at lower levels."
  end
  local v, seen, total = self:Values(name, level)
  local _, nxt = Band(obj, level)
  local note = "At your level (" .. level .. ")"
  if seen == total then note = note .. ", from your own buff" end
  if nxt then
    local nv = {}
    for i = 2, #nxt do nv[#nv + 1] = nxt[i] end
    note = note .. ". More at level " .. nxt[1] .. ": " .. obj.Text(nv)
  else
    note = note .. "."
  end
  return obj.Text(v), note
end

---------------------------------------------------------------------------
-- Learning from your own buff tooltips (out of combat, English clients).
---------------------------------------------------------------------------
-- The number tied to `word` in a lowercase line, or nil. Skips percentages
-- (the Fish Bowl's "8% to all stats").
local function NumberFor(line, word)
  local w = string.gsub(word, "(%p)", "%%%1")
  local patterns = { w .. "[%a ]-by (%d+)", "(%d+) to " .. w, "(%d+) " .. w, w .. " %+(%d+)" }
  for _, p in ipairs(patterns) do
    local _, e, n = string.find(line, p)
    if n then
      -- "by 8%": when the number ends the match, look at the next character.
      local after = (p == patterns[1] or p == patterns[4]) and string.sub(line, e + 1, e + 1) or ""
      if after ~= "%" then return tonumber(n) end
    end
  end
end

local function Parse(lines)
  local found = {}
  for _, text in ipairs(lines) do
    local line = string.lower(text)
    for stat, words in pairs(WORDS) do
      if not found[stat] then
        for _, word in ipairs(words) do
          local n = NumberFor(line, word)
          if n and n > 0 and n < 10000 then found[stat] = n; break end
        end
      end
    end
  end
  return found
end
Sc.Parse = Parse   -- for testing

local function TooltipLines(instance)
  if not (C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID) then return nil end
  local data = ns.Try("TooltipInfo.GetUnitBuffByAuraInstanceID", C_TooltipInfo.GetUnitBuffByAuraInstanceID, "player", instance, "HELPFUL")
  if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
  local out = {}
  for i = 2, #data.lines do
    local t = data.lines[i] and ns.Str(data.lines[i].leftText)
    if t then out[#out + 1] = t end
  end
  return #out > 0 and out or nil
end

-- Which buffs to read: Camp Benefits, and any buff named like a camp object.
local function IsCampBuff(a)
  local id, name = ns.Num(a.spellId), ns.Str(a.name)
  local S = ns.Status
  if id and (id == S.AURAS.benefits.id or id == ns.db.learned.benefits) then return true end
  if name and (name == S:Name("benefits") or OBJECTS[name] or (ns.Objects and ns.Objects.DATA[name])) then return true end
  return false
end

local function Learn(found, level)
  local store = Store()
  local bits = {}
  for stat, n in pairs(found) do
    store[stat] = store[stat] or {}
    local old = store[stat][level]
    if old == nil then
      Sc.seen.learned = Sc.seen.learned + 1
      ns.Debug("Learned camp buff", stat, n, "at level", level)
    elseif old ~= n then
      Sc.seen.changed = Sc.seen.changed + 1
      ns.Debug("Camp buff", stat, "at level", level, "was", old, "now", n)
    end
    store[stat][level] = n
    bits[#bits + 1] = stat .. " " .. n
  end
  if #bits > 0 then
    table.sort(bits)
    Sc.last = table.concat(bits, ", ") .. " at level " .. level
  end
end

function Sc:Scan()
  if not ns.db then return end
  if InCombatLockdown and InCombatLockdown() then return end
  local locale = GetLocale and GetLocale() or "enUS"
  if string.sub(locale, 1, 2) ~= "en" then return end
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
  local level = ns.Num(UnitLevel("player"))
  if not level then return end
  local live = {}
  for i = 1, 100 do
    local a = ns.Try("GetAuraDataByIndex", C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if type(a) ~= "table" then break end
    local inst = ns.Num(a.auraInstanceID)
    if inst and IsCampBuff(a) then
      live[inst] = true
      local firstLevel = self.instances[inst]
      if firstLevel == nil then
        -- First time we see this buff (or first since login): take your
        -- level now. PLAYER_LEVEL_UP below marks older buffs.
        firstLevel = level
        self.instances[inst] = level
      end
      if firstLevel ~= level then
        self.seen.skippedLevel = self.seen.skippedLevel + 1
      else
        local lines = TooltipLines(inst)
        if not lines then
          self.seen.unreadable = self.seen.unreadable + 1
        else
          self.seen.read = self.seen.read + 1
          Learn(Parse(lines), level)
        end
      end
    end
  end
  for inst in pairs(self.instances) do
    if not live[inst] then self.instances[inst] = nil end
  end
end

-- Learned values that disagree with the bands, for the probe.
function Sc:Mismatches()
  local out, store = {}, Store()
  for name, obj in pairs(OBJECTS) do
    for i, stat in ipairs(obj.stats) do
      for level, n in pairs(store[stat] or {}) do
        local band = Band(obj, level)
        if band[i + 1] ~= n then
          out[#out + 1] = name .. " " .. stat .. " at " .. level .. ": seen " .. n .. ", table " .. tostring(band[i + 1])
        end
      end
    end
  end
  table.sort(out)
  return out
end

function Sc:LearnedCount()
  local n = 0
  for _, levels in pairs(Store()) do
    for _ in pairs(levels) do n = n + 1 end
  end
  return n
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
local function Soon() ns.Coalesce("scalingscan", 0.5, function() Sc:Scan() end) end
ns.Listen("LOGIN", Soon)
ns.OnUnit("UNIT_AURA", "player", Soon)
ns.On("PLAYER_REGEN_ENABLED", Soon)
-- A buff you had before levelling may keep its old number: mark every live
-- buff as from another level so it isn't learned from.
ns.On("PLAYER_LEVEL_UP", function()
  for inst, lvl in pairs(Sc.instances) do Sc.instances[inst] = lvl - 0.5 end
end)
