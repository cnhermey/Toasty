-- Toasty: explains camp objects when you hover them in the world.
--
-- Hovering an object puts its name in the game tooltip. When that name is
-- a camp object (or a campfire), Toasty adds lines saying what it does.
-- Taint safety: only post-hooks on GameTooltip (TooltipDataProcessor for
-- world objects when the client has it, else GameTooltip's OnShow), no
-- fields written on Blizzard frames.
-- Data: Wowhead's "Camping Overview" guide (patch 1.60.1) and Warcraft
-- Tavern. Numbers are the guide's; a missing number means the guide gave none.
-- Buffs that add a number scale with your level: their `text` here is the
-- level 60 value, and the tooltip shows Scaling.lua's value for your level.
local _, ns = ...
local UI = ns.UI

local O = { seen = { shown = 0, unknown = 0 }, unknown = {} }
ns.Objects = O

-- buff = true: you get it by sitting at the campfire for 1 minute.
-- includes: the tier 1 object whose buff a tier 2 or 3 object also gives.
local DATA = {
  -- Alchemy
  ["Mana Well"]          = { prof = "Alchemy", tier = 1, buff = true, text = "Restores 29 mana every 5 sec.", note = "Doesn't stack with Blessing of Wisdom." },
  ["Fermenter"]          = { prof = "Alchemy", tier = 2, text = "Makes certain reagents.", includes = "Mana Well" },
  ["Alchemy Laboratory"] = { prof = "Alchemy", tier = 3, text = "Alchemy Lab for recipes that need one.", includes = "Mana Well" },
  -- Blacksmithing
  ["Sharpening Wheel"]   = { prof = "Blacksmithing", tier = 1, buff = true, text = "+34 Strength.", note = "Doesn't stack with Strength of Earth Totem." },
  ["Anvil"]              = { prof = "Blacksmithing", tier = 2, text = "An anvil you can craft at.", includes = "Sharpening Wheel" },
  ["Master Forge"]       = { prof = "Blacksmithing", tier = 3, text = "Forge for recipes that need one.", includes = "Sharpening Wheel" },
  -- Cooking
  ["Cookie's Feast"]     = { prof = "Cooking", tier = 2, text = "Food that increases Stamina." },
  ["Iron Oven"]          = { prof = "Cooking", tier = 3, text = "Needed for the most advanced cooking recipes." },
  -- Enchanting
  ["Enchanted Lute"]     = { prof = "Enchanting", tier = 1, buff = true, text = "+308 Armor, +13 to all stats and +22 to all resistances.", note = "Doesn't stack with Mark of the Wild." },
  ["Arcane Salvager"]    = { prof = "Enchanting", tier = 2, text = "Disenchanting gives more.", includes = "Enchanted Lute" },
  ["Arcane Forge"]       = { prof = "Enchanting", tier = 3, text = "Arcane Forge for recipes that need one.", includes = "Enchanted Lute" },
  -- Engineering
  ["Reagent Bot"]        = { prof = "Engineering", tier = 1, text = "Sells reagents to you and nearby players, and buys your items." },
  ["Repair Bot"]         = { prof = "Engineering", tier = 2, text = "Sells reagents and repairs your gear." },
  ["Anarchist's Workbench"] = { prof = "Engineering", tier = 3, text = "Workbench for recipes that need it." },
  -- First Aid
  ["First Aid Kit"]      = { prof = "First Aid", tier = 1, buff = true, text = "+56 Stamina.", note = "Doesn't stack with Power Word: Fortitude." },
  ["Toxin Study"]        = { prof = "First Aid", tier = 2, text = "Gives Healing Potions and antivenom." },
  ["Plague Doctor's Laboratory"] = { prof = "First Aid", tier = 3, text = "Gives Healing Potions and poultices." },
  -- Fishing
  ["Fish Bowl"]          = { prof = "Fishing", tier = 1, buff = true, text = "+8% to all stats.", note = "Doesn't stack with Blessing of Kings." },
  ["Fishing Rack"]       = { prof = "Fishing", tier = 2, text = "Lures that raise Fishing skill; uncommon fish nearby for 1 hour.", includes = "Fish Bowl" },
  ["Fishing Hut"]        = { prof = "Fishing", tier = 3, text = "Lures that raise Fishing skill; rare fish nearby for 1 hour.", includes = "Fish Bowl" },
  -- Herbalism
  ["Incense Candle"]     = { prof = "Herbalism", tier = 1, buff = true, text = "+25 Intellect.", note = "Doesn't stack with Arcane Intellect." },
  ["Greenhouse"]         = { prof = "Herbalism", tier = 2, text = "Grows herbs from seeds you plant.", includes = "Incense Candle" },
  ["Seed Hybridizer"]    = { prof = "Herbalism", tier = 3, text = "Multiplies or combines seeds into rarer ones.", includes = "Incense Candle" },
  -- Leatherworking
  ["Camp Tent"]          = { prof = "Leatherworking", tier = 1, buff = true, text = "Rested XP, up to 5% of a level.", note = "No effect if you already have more rested XP than that. Then Boosted Rest is its cooldown." },
  ["Tanning Rack"]       = { prof = "Leatherworking", tier = 2, text = "Makes certain reagents.", includes = "Camp Tent" },
  ["Sewing Machine"]     = { prof = "Leatherworking", tier = 3, text = "Workbench for recipes that need it.", includes = "Camp Tent" },
  -- Mining
  ["Lodestone"]          = { prof = "Mining", tier = 1, buff = true, text = "+90 melee Attack Power.", note = "Doesn't stack with Blessing of Might." },
  ["Rock Garden"]        = { prof = "Mining", tier = 2, text = "Grows a mining node over time.", includes = "Lodestone" },
  ["Molten Foundry"]     = { prof = "Mining", tier = 3, text = "Foundry for recipes that need it.", includes = "Lodestone" },
  -- Skinning
  ["Camp Chair"]         = { prof = "Skinning", tier = 1, buff = true, text = "+2% critical strike chance with spells and attacks.", note = "Doesn't stack with Moonkin Aura." },
  ["Field Guide"]        = { prof = "Skinning", tier = 2, text = "Gives you Track Beasts.", includes = "Camp Chair" },
  ["Trapper's Workbench"] = { prof = "Skinning", tier = 3, text = "Holds a trap.", includes = "Camp Chair" },
  -- Tailoring
  ["Faction Banner"]     = { prof = "Tailoring", tier = 1, buff = true, text = "+32 Spirit for players of the banner's faction.", note = "Doesn't stack with Divine Spirit." },
  ["Spinning Wheel"]     = { prof = "Tailoring", tier = 2, text = "Makes certain reagents.", includes = "Faction Banner" },
  ["Loom"]               = { prof = "Tailoring", tier = 3, text = "Loom for recipes that need it.", includes = "Faction Banner" },
  -- Campfires
  ["Basic Campfire"]      = { fire = 3 },
  ["Journeyman Campfire"] = { fire = 5 },
  ["Expert Campfire"]     = { fire = 10 },
}
O.DATA = DATA

-- Camp object spells (all tiers), from the guides, for your own cooldown.
local OBJECT_SPELLS = {
  [1230564] = "Mana Well",       [1263005] = "Fermenter",        [1263078] = "Alchemy Laboratory",
  [1230171] = "Sharpening Wheel",[1263041] = "Anvil",            [1263073] = "Master Forge",
  [1262978] = "Cookie's Feast",  [1263067] = "Iron Oven",
  [1230643] = "Enchanted Lute",  [1263056] = "Arcane Salvager",  [1263082] = "Arcane Forge",
  [1230656] = "Reagent Bot",     [1263034] = "Repair Bot",       [1263083] = "Anarchist's Workbench",
  [1230117] = "First Aid Kit",   [1262996] = "Toxin Study",      [1263001] = "Plague Doctor's Laboratory",
  [1229745] = "Fish Bowl",       [1262990] = "Fishing Rack",     [1262998] = "Fishing Hut",
  [1229705] = "Incense Candle",  [1262980] = "Greenhouse",       [1263070] = "Seed Hybridizer",
  [1229432] = "Camp Tent",       [1263031] = "Tanning Rack",     [1263079] = "Sewing Machine",
  [1230161] = "Lodestone",       [1262975] = "Rock Garden",      [1263071] = "Molten Foundry",
  [1229517] = "Camp Chair",      [1262985] = "Field Guide",      [1262982] = "Trapper's Workbench",
  [1263425] = "Faction Banner",  [1263032] = "Spinning Wheel",   [1263080] = "Loom",
}
O.OBJECT_COOLDOWN = 3600       -- every camp object shares 1 hour
O.FIELD_GUIDE_PERK = 1225479   -- Legacy perk: 8% shorter per rank (ranks unknown)

-- Longest names first, so "Arcane Forge" isn't read as "Forge".
local ORDER = {}
for name in pairs(DATA) do ORDER[#ORDER + 1] = name end
table.sort(ORDER, function(a, b) return #a > #b end)

local function Lookup(title)
  if DATA[title] then return title, DATA[title] end
  -- The name may come with more around it (an owner's name, say).
  for _, name in ipairs(ORDER) do
    if string.find(title, name, 1, true) then return name, DATA[name] end
  end
end
O.Lookup = Lookup

-- Adds our lines to a tooltip whose title is `title`. Returns true if it did.
function O:AddLines(tt, name, def)
  local g, w, gr, gy = UI.GOLD, UI.WHITE, UI.GREEN, UI.GRAY
  if def.fire then
    tt:AddLine("Campfire", g.r, g.g, g.b)
    tt:AddLine("Cooking, and room for " .. def.fire .. " camp objects.", w.r, w.g, w.b, true)
    tt:AddLine("Sit by it for 1 minute to get the buffs of the camp objects around it.", gr.r, gr.g, gr.b, true)
    return
  end
  tt:AddLine(def.prof .. " camp object (tier " .. def.tier .. ")", g.r, g.g, g.b)
  -- Buffs that scale: the value at your level, then a gray line saying so.
  local Sc = ns.Scaling
  local text, scaleNote = Sc:Describe(name)
  tt:AddLine(text or def.text, w.r, w.g, w.b, true)
  local inc = def.includes and DATA[def.includes]
  if inc then
    local incText, incNote = Sc:Describe(def.includes)
    tt:AddLine("Also gives the " .. def.includes .. " buff: " .. (incText or inc.text), w.r, w.g, w.b, true)
    scaleNote = scaleNote or incNote
  end
  if scaleNote then tt:AddLine(scaleNote, gy.r, gy.g, gy.b, true) end
  if def.buff or inc then
    tt:AddLine("Sit by the campfire for 1 minute to get the buff.", gr.r, gr.g, gr.b, true)
  end
  local note = def.note or (inc and inc.note)
  if note then tt:AddLine(note, gy.r, gy.g, gy.b, true) end
  self:AddPersonalLines(tt, name, def, inc, note)
end

---------------------------------------------------------------------------
-- About you: the class buff you already have, your tent cooldown, and when
-- you can place your next camp object. Buffs can't be read in combat: then
-- those lines are left out, never guessed.
---------------------------------------------------------------------------
local function HasBuffNamed(spellName)
  if InCombatLockdown and InCombatLockdown() then return nil end
  if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
    local a = ns.Try("GetAuraDataBySpellName", C_UnitAuras.GetAuraDataBySpellName, "player", spellName, "HELPFUL")
    return type(a) == "table"
  end
  if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
  for i = 1, 100 do
    local a = ns.Try("GetAuraDataByIndex", C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
    if type(a) ~= "table" then return false end
    if ns.Str(a.name) == spellName then return true end
  end
  return false
end

-- Seconds until your next camp object, how sure ("game"/"about"), or nil.
function O:NextObject()
  local o = ns.char and ns.char.object
  if not (o and o.at) then return nil end
  if o.id and C_Spell and C_Spell.GetSpellCooldown then
    local cd = ns.Try("C_Spell.GetSpellCooldown", C_Spell.GetSpellCooldown, o.id)
    local start, dur = type(cd) == "table" and ns.Num(cd.startTime), type(cd) == "table" and ns.Num(cd.duration)
    if start and dur and start > 0 and dur > 1.5 then return math.max(0, start + dur - GetTime()), "game" end
  end
  return math.max(0, O.OBJECT_COOLDOWN - (time() - o.at)), "about"
end

function O:AddPersonalLines(tt, name, def, inc, note)
  local gr, gy, org = UI.GREEN, UI.GRAY, UI.ORANGE or { r = 1, g = 0.5, b = 0.25 }
  -- The class buff this camp buff doesn't stack with, if you have it.
  local excl = note and string.match(note, "^Doesn't stack with (.-)%.")
  if excl and HasBuffNamed(excl) then
    tt:AddLine("You have " .. excl .. ", so this camp buff won't add to it.", org.r, org.g, org.b, true)
  end
  -- Camp Tent (and the tiers above it): your rested XP cooldown.
  if name == "Camp Tent" or (inc and def.includes == "Camp Tent") then
    local b = ns.Status.s.boosted
    local left = b and ns.Status:Left(b)
    if b then
      tt:AddLine("Your tent cooldown (Boosted Rest): " .. (ns.BuffTime(left) or "on") .. " left.", gy.r, gy.g, gy.b, true)
    elseif not (InCombatLockdown and InCombatLockdown()) then
      tt:AddLine("Your tent rested XP is ready.", gr.r, gr.g, gr.b, true)
    end
  end
  -- Your own next camp object.
  local left, how = self:NextObject()
  if left then
    if left <= 0 then
      tt:AddLine("You can place a camp object now.", gr.r, gr.g, gr.b, true)
    else
      local perk = IsPlayerSpell and ns.Clean(IsPlayerSpell(O.FIELD_GUIDE_PERK))
      tt:AddLine("Your next camp object: " .. (how == "about" and "about " or "") .. (ns.BuffTime(left) or "?")
        .. (how == "about" and perk and " (less with Field Guide)" or "") .. ".", gy.r, gy.g, gy.b, true)
    end
  end
end

-- Your camp object casts: remember when (per character).
ns.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, _, spellID)
  local id = ns.Num(spellID)
  if not id or not ns.char then return end
  local name = OBJECT_SPELLS[id]
  if not name then
    local sn = ns.Status.SpellName(id)
    if sn and DATA[sn] and not DATA[sn].fire then name = sn end
  end
  if name then
    ns.char.object = { at = time(), id = id, name = name }
    O.seen.placed = (O.seen.placed or 0) + 1
    ns.Debug("Placed camp object", name, id)
  end
end)

---------------------------------------------------------------------------
-- Hooks
---------------------------------------------------------------------------
local done = setmetatable({}, { __mode = "k" })   -- tooltips we already added to

local function Title(tt)
  local name = tt.GetName and tt:GetName()
  local fs = name and _G[name .. "TextLeft1"]
  return fs and ns.Str(fs:GetText())
end

local function Annotate(tt, title)
  if not ns.db or not ns.db.objectTips or done[tt] then return end
  title = title or Title(tt)
  if not title then return end
  local name, def = Lookup(title)
  if not def then
    O.seen.unknown = O.seen.unknown + 1
    O.lastUnknown = title
    return
  end
  done[tt] = true
  O.seen.shown = O.seen.shown + 1
  O:AddLines(tt, name, def)
  tt:Show()   -- resize to the new lines
end
O.Annotate = Annotate

local function Install()
  if O.mode then return end
  local modes = {}
  -- Modern clients: called after the game fills a world object's tooltip.
  local objectType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Object
  if objectType and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    local ok = pcall(TooltipDataProcessor.AddTooltipPostCall, objectType, function(tt, data)
      if tt ~= GameTooltip then return end
      local first = type(data) == "table" and type(data.lines) == "table" and data.lines[1]
      Annotate(tt, first and ns.Str(first.leftText) or nil)
    end)
    if ok then modes[#modes + 1] = "processor" end
  end
  -- Every client: a tooltip owned by the world (not a unit, item or spell).
  GameTooltip:HookScript("OnShow", function(tt)
    if tt:GetOwner() ~= UIParent then return end
    if tt.GetUnit and tt:GetUnit() then return end
    if tt.GetItem and tt:GetItem() then return end
    if tt.GetSpell and tt:GetSpell() then return end
    Annotate(tt)
  end)
  modes[#modes + 1] = "onshow"
  GameTooltip:HookScript("OnTooltipCleared", function(tt) done[tt] = nil end)
  GameTooltip:HookScript("OnHide", function(tt) done[tt] = nil end)
  O.mode = table.concat(modes, "+")
end

ns.Listen("LOGIN", Install)

-- /toasty tip <name> [level]: show an object's tooltip at the cursor, to
-- check it, as if you were that level.
function O:Test(name)
  name = name or ""
  local base, lvl = string.match(name, "^(.-)%s+(%d+)$")
  lvl = tonumber(lvl)
  if base and lvl and lvl >= 1 and lvl <= ns.MAX_LEVEL then name = base else lvl = nil end
  local low = string.lower(name)
  for known in pairs(DATA) do
    if string.lower(known) == low then name = known end
  end
  local found, def = Lookup(name)
  if not def then
    ns.Print("Unknown camp object:", name ~= "" and name or "(none). Try: /toasty tip Mana Well")
    return
  end
  GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
  GameTooltip:SetText(found, 1, 1, 1)
  done[GameTooltip] = nil
  ns.Scaling.levelOverride = lvl
  ns.Try("Objects.Test", Annotate, GameTooltip, found)
  ns.Scaling.levelOverride = nil
end
