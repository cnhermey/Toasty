-- Toasty: explains camp objects when you hover them in the world.
--
-- Hovering an object puts its name in the game tooltip. When that name is
-- a camp object (or a campfire), Toasty adds lines saying what it does.
-- Taint safety: only post-hooks on GameTooltip (TooltipDataProcessor for
-- world objects when the client has it, else GameTooltip's OnShow), no
-- fields written on Blizzard frames.
-- Data: Wowhead's "Camping Overview" guide (patch 1.60.1) and Warcraft
-- Tavern. Numbers are the guide's; a missing number means the guide gave none.
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
  ["First Aid Kit"]      = { prof = "First Aid", tier = 1, buff = true, text = "Increases Stamina.", note = "Doesn't stack with Power Word: Fortitude." },
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
  tt:AddLine(def.text, w.r, w.g, w.b, true)
  local inc = def.includes and DATA[def.includes]
  if inc then
    tt:AddLine("Also gives the " .. def.includes .. " buff: " .. inc.text, w.r, w.g, w.b, true)
  end
  if def.buff or inc then
    tt:AddLine("Sit by the campfire for 1 minute to get the buff.", gr.r, gr.g, gr.b, true)
  end
  local note = def.note or (inc and inc.note)
  if note then tt:AddLine(note, gy.r, gy.g, gy.b, true) end
end

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

-- /toasty tip <name>: show an object's tooltip at the cursor, to check it.
function O:Test(name)
  name = name or ""
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
  Annotate(GameTooltip, found)
end
