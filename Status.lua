-- Toasty: your camping status, read from your own buffs and bags.
--   * Well-Rested (429959): the Cozy Sleeping Bag buff, with its stacks.
--   * Camp Benefits (1229741): the camp buffs you get after resting 1 minute.
--   * Campfire Nearby (1283391): you're inside a campfire's radius.
--   * Boosted Rest (1229451, a debuff): the Camp Tent's rested XP is on
--     cooldown. Without it, a Camp Tent can give you rested XP again.
--   * Cozy Sleeping Bag (item 211527): how many are in your bags.
-- Forever quirks: spell IDs may differ from the guides, so each buff is
-- matched by ID *and* by its name, and an ID seen by name is learned into
-- ToastyBuffsDB.learned.
-- Combat: Forever makes aura IDs, names, times and stacks secret, so a scan
-- by index can't tell which buff is which (0.3.0 then showed every icon as
-- missing). So each buff is first asked for directly by its known ID
-- (C_UnitAuras.GetPlayerAuraBySpellID: whether it exists should stay
-- readable). Until that is seen working in combat, a buff we had but can't
-- identify any more is kept ("kept") and its known end time keeps counting;
-- it goes when that time runs out or the next readable scan says so.
-- Times and stacks that are secret keep the last readable value, or show
-- nothing. Never a guess.
local _, ns = ...

local S = {
  s = {},                  -- key -> aura info, for buffs you have now
  bagCount = 0,
  seen = { scans = 0, unreadable = 0, byID = 0, kept = 0 },
  byIDInCombat = false,    -- the by-ID lookup has found a buff during combat
}
ns.Status = S

S.BAG_ITEM = 211527
S.BAG_ICON = "Interface\\Icons\\INV_Misc_Bag_BigBagOfEnchantments"

S.AURAS = {
  wellRested = { id = 429959,  name = "Well-Rested",     filter = "HELPFUL" },
  benefits   = { id = 1229741, name = "Camp Benefits",   filter = "HELPFUL" },
  nearby     = { id = 1283391, name = "Campfire Nearby", filter = "HELPFUL" },
  boosted    = { id = 1229451, name = "Boosted Rest",    filter = "HARMFUL" },
}

local ids, names = {}, {}
S.clientNames = {}

local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then
    return ns.Str(ns.Try("C_Spell.GetSpellName", C_Spell.GetSpellName, id))
  end
  if GetSpellInfo then return ns.Str((ns.Try("GetSpellInfo", GetSpellInfo, id))) end
end
S.SpellName = SpellName

local function BuildNames()
  for key, def in pairs(S.AURAS) do
    ids[key] = { [def.id] = true }
    local learned = ns.db.learned[key]
    if learned then ids[key][learned] = true end
    local n = SpellName(def.id)
    S.clientNames[key] = n ~= nil
    names[key] = n or def.name
  end
end

function S:Name(key) return names[key] or S.AURAS[key].name end

-- The icon to show for a buff you don't have (the spell's own icon).
function S:Icon(key)
  local learned = ns.db and ns.db.learned[key]
  return ns.UI.SpellIcon(learned or S.AURAS[key].id)
end

---------------------------------------------------------------------------
-- Aura scan: one pass over your buffs and one over your debuffs per change.
---------------------------------------------------------------------------
local function Missing(v) return not ns.IsSecret(v) and v == nil end

local function EachAura(filter, fn)
  if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    for i = 1, 100 do
      local a = ns.Try("GetAuraDataByIndex", C_UnitAuras.GetAuraDataByIndex, "player", i, filter)
      if type(a) ~= "table" then break end
      fn(a)
    end
  elseif UnitAura then
    for i = 1, 100 do
      local name, icon, count, _, duration, expires, _, _, _, spellId = UnitAura("player", i, filter)
      if Missing(name) then break end
      fn({ name = name, icon = icon, applications = count, duration = duration, expirationTime = expires, spellId = spellId })
    end
  end
end

-- Read is defined below; Food.lua uses it too (S.ReadAura).

-- Ask for one buff by its known IDs. Returns the aura and the ID asked for.
local function ByID(key)
  if not (C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID) then return nil end
  for id in pairs(ids[key]) do
    local a = ns.Try("GetPlayerAuraBySpellID", C_UnitAuras.GetPlayerAuraBySpellID, id)
    if type(a) == "table" then return a, id end
  end
end

local function Read(a, prev)
  local r = {
    icon = ns.Clean(a.icon),
    stacks = ns.Num(a.applications),
    duration = ns.Num(a.duration),
    expires = ns.Num(a.expirationTime),
    instance = ns.Num(a.auraInstanceID),
    id = ns.Num(a.spellId),
  }
  if prev then
    -- Hidden in combat: keep what we could read before.
    if r.expires == nil and ns.IsSecret(a.expirationTime) then r.expires, r.duration = prev.expires, prev.duration end
    if r.stacks == nil and ns.IsSecret(a.applications) then r.stacks = prev.stacks end
  end
  if r.duration == 0 then r.expires = nil end   -- doesn't run out
  return r
end

S.ReadAura = Read

function S:Scan()
  if not ns.db then return end
  S.seen.scans = S.seen.scans + 1
  local found, askedID = {}, {}
  local inCombat = InCombatLockdown and InCombatLockdown() and true or false

  -- 1. By ID: works even when the details are hidden.
  for key in pairs(S.AURAS) do
    local a, id = ByID(key)
    if a then
      found[key], askedID[key] = a, id
      S.seen.byID = S.seen.byID + 1
      if inCombat then S.byIDInCombat = true end
    end
  end

  -- 2. By index: finds buffs under a new ID by their name (learning it), and
  -- counts auras we can't identify (hidden ID and name).
  local unreadable = 0
  for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
    EachAura(filter, function(a)
      local id, name = ns.Num(a.spellId), ns.Str(a.name)
      if id == nil and name == nil then unreadable = unreadable + 1 end
      for key, def in pairs(S.AURAS) do
        if def.filter == filter and not found[key]
          and ((id and ids[key][id]) or (name and name == names[key])) then
          found[key] = a
          if id and not ids[key][id] then
            ids[key][id] = true
            ns.db.learned[key] = id
            ns.Debug("Learned", key, "ID", id)
          end
        end
      end
    end)
  end
  S.seen.unreadable = unreadable

  -- Not found, but the scan couldn't read everything, and we haven't seen
  -- the by-ID lookup work in combat: we can't tell it's gone, so keep it.
  local blind = unreadable > 0 and not S.byIDInCombat
  local old, s = self.s, {}
  local now = GetTime()
  for key in pairs(S.AURAS) do
    if found[key] then
      s[key] = Read(found[key], old[key])
      s[key].id = s[key].id or askedID[key]
      s[key].filter = S.AURAS[key].filter
    elseif old[key] and ((blind and (old[key].expires == nil or old[key].expires > now))
        or (inCombat and old[key].expires and old[key].expires > now)) then
      -- In combat, a buff or debuff with a known end time that we can't see
      -- any more is kept until then (Boosted Rest can't end early in a fight).
      local k = {}
      for f, v in pairs(old[key]) do k[f] = v end
      k.kept, k.instance = true, nil   -- the old instance may be gone: spell tooltip instead
      s[key] = k
      S.seen.kept = S.seen.kept + 1
    end
  end
  self.s = s
  ns.Fire("STATUS_CHANGED")
end

-- Kept buffs end when their known time runs out.
function S:DropExpired()
  local now, changed = GetTime(), false
  for key, a in pairs(self.s) do
    if a.kept and a.expires and a.expires <= now then
      self.s[key] = nil
      changed = true
    end
  end
  if changed then ns.Fire("STATUS_CHANGED") end
end

-- Seconds left on a buff, or nil when it doesn't run out or can't be read.
function S:Left(a)
  if not a or not a.expires then return nil end
  return math.max(0, a.expires - GetTime())
end

---------------------------------------------------------------------------
-- Cozy Sleeping Bag
---------------------------------------------------------------------------
function S:CountBags()
  local n
  if C_Item and C_Item.GetItemCount then
    n = ns.Try("C_Item.GetItemCount", C_Item.GetItemCount, S.BAG_ITEM)
  elseif GetItemCount then
    n = ns.Try("GetItemCount", GetItemCount, S.BAG_ITEM)
  end
  self.bagCount = ns.Num(n) or 0
  return self.bagCount
end

-- start, duration of the bag's cooldown, when it's cooling down.
function S:BagCooldown()
  local start, duration
  if C_Container and C_Container.GetItemCooldown then
    start, duration = ns.Try("C_Container.GetItemCooldown", C_Container.GetItemCooldown, S.BAG_ITEM)
  elseif GetItemCooldown then
    start, duration = ns.Try("GetItemCooldown", GetItemCooldown, S.BAG_ITEM)
  end
  return ns.Num(start), ns.Num(duration)
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
ns.Listen("INIT", BuildNames)

ns.Listen("LOGIN", function()
  BuildNames()   -- some names only load after login
  S:CountBags()
  S:Scan()
  C_Timer.NewTicker(1, function() S:DropExpired() end)
end)

-- Leaving combat: read everything again with the details visible.
ns.On("PLAYER_REGEN_ENABLED", function()
  ns.Coalesce("scan", 0.2, function() S:Scan() end)
end)

ns.OnUnit("UNIT_AURA", "player", function()
  ns.Coalesce("scan", 0.1, function() S:Scan() end)
end)

ns.On("PLAYER_ENTERING_WORLD", function()
  ns.Coalesce("scan", 0.5, function() S:Scan() end)
end)

ns.On("BAG_UPDATE_DELAYED", function()
  local before = S.bagCount
  if S:CountBags() ~= before then ns.Fire("STATUS_CHANGED") end
end)

ns.On("BAG_UPDATE_COOLDOWN", function()
  ns.Coalesce("bagcd", 0.1, function() ns.Fire("STATUS_CHANGED") end)
end)
