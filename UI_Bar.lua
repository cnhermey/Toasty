-- Toasty: the icon bar. Four icons in a row, drawn like the icons on
-- Blizzard's buff bar: 30 px icon, stack count in NumberFontNormal at the
-- bottom right, time left under the icon in GameFontNormalSmall (gold, white
-- under a minute, written by Blizzard's own SecondsToTimeAbbrev).
--   1. Well-Rested with its stacks. Without it: a button that uses your
--      Cozy Sleeping Bag. Without a bag: a gray bag icon, "No bag".
--   2. Camp Benefits. Without it: Campfire Nearby when you're by a fire,
--      else a gray Camp Benefits icon.
--   3. Boosted Rest (the Camp Tent's cooldown debuff). Without it: a gray
--      Boosted Rest icon, meaning a Camp Tent can give you rested XP again.
--   4. Well Fed from Nutritious food (+5% XP). Without it: a button that
--      eats your best Nutritious food; without food, "No food".
-- With aura containers (Engine.lua), the game draws the buffs over these
-- icons, in combat too; this file then paints only the idle state under
-- them (bag button, "No bag", gray icons). Without them, it paints
-- everything from Status.lua.
-- Icons 1 and 4 are SecureActionButtons (using an item needs one), so this bar is
-- a protected frame: its position, size, visibility and the button's click
-- action only change out of combat (queued with ns.AfterCombat). Icons and
-- text are plain textures and font strings, so they update in combat.
local _, ns = ...
local UI = ns.UI

local B = { slots = {} }
ns.Bar = B

local SIZE = 30      -- Blizzard's buff icon size
local GAP = 6
local DURATION_H = 14
-- The panel around the icons (Settings > Name and border).
local PAD_X = 12       -- left and right of the icons
local PAD_TOP = 9      -- above the name
local TITLE_H = 14     -- the name's line
local TITLE_GAP = 5    -- name to icons
local PAD_BOTTOM = 6   -- under the time text
local SUB_H = 13       -- the short label over each icon (Settings > Icon labels)
local SUBHEADS = { "Bag", "Fire", "Rested", "XP" }
local COUNT = 4
local ROW_W = SIZE * COUNT + GAP * (COUNT - 1)
local WARN = BUFF_DURATION_WARNING_TIME or 60   -- white text under a minute

---------------------------------------------------------------------------
-- Position (out of combat only)
---------------------------------------------------------------------------
local function SavePosition()
  local point, _, relPoint, x, y = B.frame:GetPoint(1)
  ns.db.barPoint = { point, relPoint, x, y }
end

function B:ApplyLayout()
  ns.AfterCombat("layout", function()
    local f = self.frame
    if not f then return end
    f:ClearAllPoints()
    local p = ns.db.barPoint
    if p and p[1] then
      f:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
    else
      -- Under the minimap, beside where Blizzard's buffs sit.
      f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -150)
    end
    f:SetScale((ns.db.scale or 100) / 100)
    -- Name and border: a tooltip-style panel with "Toasty" over the icons.
    local framed = ns.db.framed
    local top = framed and (PAD_TOP + TITLE_H + TITLE_GAP) or 0
    -- Short labels over the icons ("Bag", "Fire", "Rested", "XP").
    local subs = ns.db.iconLabels
    if subs then top = top + SUB_H end
    for _, slot in ipairs(self.slots) do slot.subhead:SetShown(subs) end
    local side = framed and PAD_X or 0
    f:SetSize(ROW_W + side * 2, top + SIZE + DURATION_H + (framed and PAD_BOTTOM or 0))
    self.slots[1]:ClearAllPoints()
    self.slots[1]:SetPoint("TOPLEFT", f, "TOPLEFT", side, -top)
    UI.Plate(f, framed)
    f.title:SetShown(framed)
    f:SetShown(ns.db.enabled)
  end)
end

function B:ResetPosition()
  ns.db.barPoint = nil
  self:ApplyLayout()
end

local function OnDragStart()
  if ns.db.locked or not IsShiftKeyDown() or InCombatLockdown() then return end
  B.frame:StartMoving()
  B.moving = true
end

local function OnDragStop()
  if not B.moving then return end
  B.moving = false
  B.frame:StopMovingOrSizing()
  SavePosition()
end

---------------------------------------------------------------------------
-- Tooltips: Blizzard's own buff, item and spell tooltips.
---------------------------------------------------------------------------
local function TipFooter()
  if not ns.db.locked then GameTooltip:AddLine("Shift-drag to move.", 0.5, 0.5, 0.5) end
end

local function SlotTooltip(self)
  local v = self.view
  if not v then return end
  GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
  local done = false
  if v.instance and not ns.Demo.active then
    if v.filter == "HARMFUL" and GameTooltip.SetUnitDebuffByAuraInstanceID then
      ns.Try("SetUnitDebuffByAuraInstanceID", GameTooltip.SetUnitDebuffByAuraInstanceID, GameTooltip, "player", v.instance, "HARMFUL")
    elseif GameTooltip.SetUnitBuffByAuraInstanceID then
      ns.Try("SetUnitBuffByAuraInstanceID", GameTooltip.SetUnitBuffByAuraInstanceID, GameTooltip, "player", v.instance, "HELPFUL")
    end
    done = GameTooltip:NumLines() > 0
  end
  if not done and v.item and GameTooltip.SetItemByID then
    ns.Try("SetItemByID", GameTooltip.SetItemByID, GameTooltip, v.item)
    done = GameTooltip:NumLines() > 0
  end
  if not done and v.spell and GameTooltip.SetSpellByID then
    ns.Try("SetSpellByID", GameTooltip.SetSpellByID, GameTooltip, v.spell)
    done = GameTooltip:NumLines() > 0
  end
  if not done then GameTooltip:AddLine(v.title or "", 1, 1, 1) end
  if v.hint then GameTooltip:AddLine(v.hint, UI.GREEN.r, UI.GREEN.g, UI.GREEN.b, true) end
  TipFooter()
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
local function MakeSlot(parent, secure)
  local b
  if secure then
    b = CreateFrame("Button", secure, parent, "SecureActionButtonTemplate")
    -- Down and up: the secure template picks the one that matches the
    -- "cast on key down" setting, so the bag is used once.
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints()
  else
    b = CreateFrame("Frame", nil, parent)
    b:EnableMouse(true)
  end
  b:SetSize(SIZE, SIZE)
  b.icon = b:CreateTexture(nil, "BACKGROUND")
  b.icon:SetAllPoints()
  b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
  b.duration = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.duration:SetPoint("TOP", b, "BOTTOM", 0, -2)
  -- "No bag" sits on the icon, so a buff drawn over it by the game hides it.
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
  b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.label:SetWidth(SIZE + 4)
  b.label:SetTextColor(0.8, 0.8, 0.8)
  b:SetScript("OnEnter", SlotTooltip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", OnDragStart)
  b:SetScript("OnDragStop", OnDragStop)
  return b
end

local function Build()
  local f = CreateFrame("Frame", "ToastyBar", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(ROW_W, SIZE + DURATION_H)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetFrameStrata("LOW")
  -- Shift-drag the panel itself, not only the icons.
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", OnDragStart)
  f:SetScript("OnDragStop", OnDragStop)
  B.frame = f

  -- The name, gold like Blizzard's window titles, centered over the icons.
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("TOP", f, "TOP", 0, -PAD_TOP)
  f.title:SetText("Toasty")

  B.slots[1] = MakeSlot(f, "ToastyBagButton")
  B.slots[2] = MakeSlot(f, false)
  B.slots[2]:SetPoint("TOPLEFT", B.slots[1], "TOPRIGHT", GAP, 0)
  B.slots[3] = MakeSlot(f, false)
  B.slots[3]:SetPoint("TOPLEFT", B.slots[2], "TOPRIGHT", GAP, 0)
  B.slots[4] = MakeSlot(f, "ToastyFoodButton")
  B.slots[4]:SetPoint("TOPLEFT", B.slots[3], "TOPRIGHT", GAP, 0)

  -- Each icon's short label, centered over it in Blizzard's small font.
  for i, slot in ipairs(B.slots) do
    slot.subhead = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slot.subhead:SetPoint("BOTTOM", slot, "TOP", 0, 3)
    slot.subhead:SetTextColor(0.82, 0.82, 0.82)
    slot.subhead:SetText(SUBHEADS[i])
  end

  -- Time left: redraw twice a second, like the buff bar.
  local acc = 0
  f:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.5 then return end
    acc = 0
    B:Refresh()
  end)

  B:ApplyLayout()
end

---------------------------------------------------------------------------
-- What each slot shows. A view is { icon, gray, stacks, left, text,
-- instance | item | spell (tooltip), title, hint }.
---------------------------------------------------------------------------
local function BuffView(a, key)
  local S = ns.Status
  return {
    icon = a.icon or S:Icon(key),
    stacks = a.stacks,
    left = S:Left(a),
    instance = a.instance,
    filter = S.AURAS[key].filter,
    spell = a.id or S.AURAS[key].id,
    title = S:Name(key),
  }
end

local function SleepView(s, bags)
  local S = ns.Status
  if s.wellRested then return BuffView(s.wellRested, "wellRested") end
  if bags > 0 then
    return {
      icon = S.BAG_ICON, item = S.BAG_ITEM, stacks = bags > 1 and bags or nil, useBag = true,
      title = "Cozy Sleeping Bag",
      hint = "Click to use your Cozy Sleeping Bag (" .. S:Name("wellRested") .. ").",
    }
  end
  return {
    icon = S.BAG_ICON, gray = true, text = "No bag", item = S.BAG_ITEM,
    title = "Cozy Sleeping Bag",
    hint = "You don't have a Cozy Sleeping Bag in your bags.",
  }
end

local function CampView(s)
  local S = ns.Status
  if s.benefits then return BuffView(s.benefits, "benefits") end
  if s.nearby then
    local v = BuffView(s.nearby, "nearby")
    v.hint = "Sit (/sit) by the campfire for 1 minute to get the camp buffs."
    return v
  end
  return {
    icon = S:Icon("benefits"), gray = true, spell = ns.db.learned.benefits or S.AURAS.benefits.id,
    title = S:Name("benefits"),
    hint = "No camp buffs. Sit by a campfire for 1 minute to get them.",
  }
end

local function ClearCooldown(cd)
  if cd.Clear then cd:Clear() else cd:SetCooldown(0, 0) end
end

local function RestView(s)
  local S = ns.Status
  if s.boosted then
    local v = BuffView(s.boosted, "boosted")
    v.hint = "A Camp Tent can't give you rested XP again until this ends."
    return v
  end
  return {
    icon = S:Icon("boosted"), gray = true, spell = ns.db.learned.boosted or S.AURAS.boosted.id,
    title = S:Name("boosted"),
    hint = "Ready: rest at a camp with a Camp Tent for more rested XP.",
  }
end

-- Icon 4: the XP food buff (Well Fed from Nutritious food). Without it, a
-- button that eats your best Nutritious food; without food, "No food".
local function FoodView(buff, bag)
  local F = ns.Food
  local hint = "Nutritious food: Well Fed with +5% experience from kills for 15 minutes."
  if buff then
    return {
      icon = buff.icon or F:Icon(), left = ns.Status:Left(buff), instance = buff.instance,
      filter = "HELPFUL", spell = buff.id or F.WELL_FED, title = F:Name(),
    }
  end
  if bag then
    return {
      icon = bag.icon or F:Icon(), item = bag.item, stacks = bag.count, useItem = bag.item,
      title = bag.name or "Nutritious food", hint = "Click to eat it. " .. hint,
    }
  end
  return {
    icon = F:Icon(), gray = true, text = "No food", spell = F.WELL_FED,
    title = F:Name(), hint = "No Nutritious food in your bags. " .. hint,
  }
end

local function Paint(slot, v)
  slot.view = v
  slot.icon:SetTexture(v.icon)
  slot.icon:SetDesaturated(v.gray and true or false)
  slot.icon:SetVertexColor(v.gray and 0.6 or 1, v.gray and 0.6 or 1, v.gray and 0.6 or 1)
  slot.count:SetText(v.stacks and v.stacks > 1 and v.stacks or "")
  slot.label:SetText(v.text or "")
  if v.text then
    slot.duration:SetText("")
  elseif v.left then
    slot.duration:SetText(ns.BuffTime(v.left) or "")
    local c = v.left < WARN and UI.WHITE or UI.GOLD
    slot.duration:SetTextColor(c.r, c.g, c.b)
  else
    slot.duration:SetText("")
  end
end

-- A secure icon's click action (icons 1 and 4) follows what it shows: use
-- this item, or nothing. Out of combat only.
B.actions = {}
function B:ApplyAction(index, itemID)
  itemID = itemID or false
  if self.actions[index] == itemID then return end
  ns.AfterCombat("action" .. index, function()
    local b = self.slots[index]
    if itemID then
      b:SetAttribute("type", "item")
      b:SetAttribute("item", "item:" .. itemID)
    else
      b:SetAttribute("type", nil)
      b:SetAttribute("item", nil)
    end
    self.actions[index] = itemID
  end)
end
-- Old name, for the probe: does the bag button use the bag?
function B:BagArmed() return self.actions[1] == ns.Status.BAG_ITEM end

function B:Refresh()
  if not self.frame then return end
  local S = ns.Status
  local s = ns.Demo.active and ns.Demo.s or S.s
  local bags = ns.Demo.active and (ns.Demo.bags or 0) or S.bagCount
  local F = ns.Food
  local food = ns.Demo.active and ns.Demo.s.food or F.s
  local bagFood = ns.Demo.active and ns.Demo.bagFood or F.bag
  -- The game draws the buffs itself: paint only what lies under them.
  -- Boosted Rest (a debuff) is still Toasty's to draw, and the food buff
  -- until a food layer exists (its spell IDs are learned on first sight).
  local engine = ns.Engine and ns.Engine:Active()
  if engine then
    s = { boosted = s.boosted }
    if ns.Engine:HasFood() then food = nil end
  end

  local real = SleepView(S.s, S.bagCount)
  self:ApplyAction(1, real.useBag and S.BAG_ITEM or nil)
  local realFood = FoodView(F.s, F.bag)
  self:ApplyAction(4, realFood.useItem)

  local v1 = SleepView(s, bags)
  Paint(self.slots[1], v1)
  local cd = self.slots[1].cooldown
  if v1.useBag and not ns.Demo.active then
    local start, duration = S:BagCooldown()
    if start and duration and duration > 1.5 then
      cd:SetCooldown(start, duration)
    else
      ClearCooldown(cd)
    end
  else
    ClearCooldown(cd)
  end

  Paint(self.slots[2], CampView(s))
  Paint(self.slots[3], RestView(s))

  local v4 = FoodView(food, bagFood)
  Paint(self.slots[4], v4)
  ClearCooldown(self.slots[4].cooldown)
  if v4.useItem and not ns.Demo.active and C_Container and C_Container.GetItemCooldown then
    local start, duration = ns.Try("GetItemCooldown", C_Container.GetItemCooldown, v4.useItem)
    start, duration = ns.Num(start), ns.Num(duration)
    if start and duration and duration > 1.5 then self.slots[4].cooldown:SetCooldown(start, duration) end
  end
end

ns.Listen("LOGIN", function()
  Build()
  B:Refresh()
end)
ns.Listen("STATUS_CHANGED", function() B:Refresh() end)
ns.Listen("SETTINGS_CHANGED", function(key)
  if key == "scale" or key == "enabled" or key == "framed" or key == "iconLabels" then B:ApplyLayout() end
  B:Refresh()
end)
