-- Toasty: the XP food buff, and Nutritious food in your bags.
--
-- On Forever, food marked "Nutritious" gives Well Fed for 15 minutes: the
-- dish's stat bonus plus +5% experience from kills. Every Nutritious item's
-- use spell is "Nutritious Food" (1248377), which is how EllesmereUI finds
-- them in bags (EUI_AuraBuffReminders_Refresh.lua), and so does Toasty.
-- The buff has no spell of its own for the XP: it's on the Well Fed buff,
-- and each food has its own Well Fed spell ID. So a Well Fed buff (by name,
-- Blizzard's food icon 136000, or the food buffs not named Well Fed) counts
-- only when its tooltip mentions experience; the answer is learned per
-- spell ID (ToastyBuffsDB.learned.xpFood / notXpFood), so after the first time a
-- food's buff is known by ID, in combat too (and Engine.lua draws it then).
-- Tooltips and names can't be read in combat (secret values): then only
-- known IDs are asked for, and a buff with a known end time is kept.
local _, ns = ...

local F = {
  s = nil,                   -- the XP Well Fed buff you have, or nil
  bag = nil,                 -- { item, count, icon, name } best Nutritious food in bags
  seen = { checked = 0, xp = 0, notXp = 0, unreadable = 0 },
}
ns.Food = F

F.WELL_FED = 19705
F.WELL_FED_ICON = 136000
F.NUTRITIOUS = 1248377
-- Food buffs not named Well Fed (from EllesmereUI's list).
local OTHER_FOOD = { [18192] = true, [18194] = true, [22730] = true, [25661] = true, [18125] = true, [18141] = true }

local function SpellName(id) return ns.Status.SpellName(id) end

local function Learned()
  local L = ns.db.learned
  L.xpFood = L.xpFood or {}
  L.notXpFood = L.notXpFood or {}
  return L.xpFood, L.notXpFood
end

function F:XPFoodIDs() return (Learned()) end

function F:Icon()
  return ns.UI.SpellIcon(F.WELL_FED, F.WELL_FED_ICON)
end

function F:Name() return SpellName(F.WELL_FED) or "Well Fed" end

---------------------------------------------------------------------------
-- Is this Well Fed the XP kind? true / false, or nil when it can't be read.
---------------------------------------------------------------------------
-- "Experience" in the client languages, as it appears in buff tooltips
-- (lowercase; matched anywhere in a line). English is confirmed; the rest
-- are the usual WoW words, unverified on Forever.
local XP_WORDS = {
  "experience",                 -- enUS, enGB
  "erfahrung",                  -- deDE
  "expérience",                 -- frFR
  "experiencia",                -- esES, esMX
  "esperienza",                 -- itIT
  "experiência",                -- ptBR
  "опыт",                       -- ruRU
  "경험치",                      -- koKR
  "经验",                        -- zhCN
  "經驗",                        -- zhTW
}

local function SaysXP(text)
  local low = string.lower(text)
  for _, w in ipairs(XP_WORDS) do
    if string.find(low, w, 1, true) or string.find(text, w, 1, true) then return true end
  end
  return false
end

local function TooltipSaysXP(instance)
  if not instance or not (C_TooltipInfo and C_TooltipInfo.GetUnitBuffByAuraInstanceID) then return nil end
  local data = ns.Try("TooltipInfo.GetUnitBuffByAuraInstanceID", C_TooltipInfo.GetUnitBuffByAuraInstanceID, "player", instance, "HELPFUL")
  if type(data) ~= "table" or type(data.lines) ~= "table" or #data.lines < 2 then return nil end
  local read = false
  for i = 2, #data.lines do
    local t = data.lines[i] and ns.Str(data.lines[i].leftText)
    if t then
      read = true
      if SaysXP(t) then return true end
    end
  end
  if read then return false end
  return nil
end

local function GivesXP(a, id)
  local xp, notXp = Learned()
  if id and xp[id] then return true end
  if id and notXp[id] then return false end
  local answer = TooltipSaysXP(ns.Num(a.auraInstanceID))
  if answer == nil then
    F.seen.unreadable = F.seen.unreadable + 1
    return nil
  end
  F.seen.checked = F.seen.checked + 1
  if id then
    if answer then
      xp[id] = true
      F.seen.xp = F.seen.xp + 1
      ns.Debug("Learned XP food buff", id)
      ns.Fire("XPFOOD_LEARNED", id)
    else
      notXp[id] = true
      F.seen.notXp = F.seen.notXp + 1
    end
  end
  return answer
end

---------------------------------------------------------------------------
-- Scan
---------------------------------------------------------------------------
function F:Scan()
  if not ns.db then return end
  local inCombat = InCombatLockdown and InCombatLockdown() and true or false
  local xp = Learned()
  local found, foundID

  -- Known XP food buffs by ID: works when the details are hidden.
  if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
    for id in pairs(xp) do
      local a = ns.Try("GetPlayerAuraBySpellID", C_UnitAuras.GetPlayerAuraBySpellID, id)
      if type(a) == "table" then found, foundID = a, id; break end
    end
  end

  -- Out of combat: any Well Fed, checked by its tooltip (and learned).
  if not found and not inCombat and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
    local wellFed = F:Name()
    for i = 1, 100 do
      local a = ns.Try("GetAuraDataByIndex", C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
      if type(a) ~= "table" then break end
      local id, name, icon = ns.Num(a.spellId), ns.Str(a.name), ns.Clean(a.icon)
      if (id and OTHER_FOOD[id]) or (name and name == wellFed) or (icon and icon == F.WELL_FED_ICON) then
        if GivesXP(a, id) then found, foundID = a, id; break end
      end
    end
  end

  local old, now = self.s, GetTime()
  if found then
    local r = ns.Status.ReadAura(found, old)
    r.id = r.id or foundID
    r.filter = "HELPFUL"
    self.s = r
  elseif inCombat and old and old.expires and old.expires > now then
    -- Can't see it in combat, but it can't have ended yet (unless you died).
    local k = {}
    for f, v in pairs(old) do k[f] = v end
    k.kept, k.instance = true, nil
    self.s = k
  else
    self.s = nil
  end
  ns.Fire("STATUS_CHANGED")
end

function F:DropExpired()
  local a = self.s
  if a and a.kept and a.expires and a.expires <= GetTime() then
    self.s = nil
    ns.Fire("STATUS_CHANGED")
  end
end

---------------------------------------------------------------------------
-- Nutritious food in your bags: the best one you can eat (highest required
-- level up to yours), for the eat button.
---------------------------------------------------------------------------
local pending = {}

local function ItemSpell(id)
  if not (C_Item and C_Item.GetItemSpell) then return nil end
  local name, spellID = C_Item.GetItemSpell(id)
  return ns.Str(name), ns.Num(spellID)
end

function F:ScanBags()
  if not (C_Container and C_Container.GetContainerNumSlots) then return end
  local nutritious = SpellName(F.NUTRITIOUS)
  if not nutritious and C_Spell and C_Spell.RequestLoadSpellData then
    pcall(C_Spell.RequestLoadSpellData, F.NUTRITIOUS)
  end
  local myLevel = ns.Num(UnitLevel("player")) or 1
  local best, bestLevel, checked = nil, -1, {}
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    local slots = ns.Num(C_Container.GetContainerNumSlots(bag)) or 0
    for slot = 1, slots do
      local id = ns.Num(C_Container.GetContainerItemID(bag, slot))
      if id and not checked[id] then
        checked[id] = true
        local sname, sid = ItemSpell(id)
        if not sname and not sid then
          if C_Item.RequestLoadItemDataByID and not pending[id] then
            pending[id] = true
            pcall(C_Item.RequestLoadItemDataByID, id)
          end
        elseif sid == F.NUTRITIOUS or (nutritious and sname == nutritious) then
          local minLevel = ns.Num((select(5, C_Item.GetItemInfo(id)))) or 0
          if minLevel <= myLevel and minLevel > bestLevel then
            best, bestLevel = id, minLevel
          end
        end
      end
    end
  end
  local bagFood
  if best then
    bagFood = {
      item = best,
      count = ns.Num(C_Item.GetItemCount(best)) or 1,
      icon = ns.Clean(C_Item.GetItemIconByID and C_Item.GetItemIconByID(best)),
      name = ns.Str(C_Item.GetItemNameByID and C_Item.GetItemNameByID(best)),
    }
  end
  local before = self.bag
  self.bag = bagFood
  if (before and before.item) ~= (bagFood and bagFood.item) or (before and before.count) ~= (bagFood and bagFood.count) then
    ns.Fire("STATUS_CHANGED")
  end
end

---------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------
ns.Listen("LOGIN", function()
  F:ScanBags()
  F:Scan()
  C_Timer.NewTicker(1, function() F:DropExpired() end)
end)

ns.OnUnit("UNIT_AURA", "player", function()
  ns.Coalesce("foodscan", 0.15, function() F:Scan() end)
end)

ns.On("PLAYER_REGEN_ENABLED", function()
  ns.Coalesce("foodscan", 0.3, function() F:Scan() end)
end)

local function BagsSoon() ns.Coalesce("foodbags", 0.3, function() F:ScanBags() end) end
ns.On("BAG_UPDATE_DELAYED", BagsSoon)
ns.On("PLAYER_LEVEL_UP", BagsSoon)
ns.On("ITEM_DATA_LOAD_RESULT", function(_, id)
  if id and pending[id] then pending[id] = nil; BagsSoon() end
end)
ns.On("SPELL_DATA_LOAD_RESULT", function(_, id)
  if id == F.NUTRITIOUS then BagsSoon() end
end)
