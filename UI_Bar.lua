-- Toasty: the icon bar. Three icons in a row, drawn like the icons on
-- Blizzard's buff bar: 30 px icon, stack count in NumberFontNormal at the
-- bottom right, time left under the icon in GameFontNormalSmall (gold, white
-- under a minute, written by Blizzard's own SecondsToTimeAbbrev).
--   1. Well-Rested with its stacks. Without it: a button that uses your
--      Cozy Sleeping Bag. Without a bag: a gray bag icon, "No bag".
--   2. Camp Benefits. Without it: Campfire Nearby when you're by a fire,
--      else a gray Camp Benefits icon.
--   3. Boosted Rest (the Camp Tent's cooldown debuff). Without it: a gray
--      Boosted Rest icon, meaning a Camp Tent can give you rested XP again.
-- With aura containers (Engine.lua), the game draws the buffs over these
-- icons, in combat too; this file then paints only the idle state under
-- them (bag button, "No bag", gray icons). Without them, it paints
-- everything from Status.lua.
-- Icon 1 is a SecureActionButton (using an item needs one), so this bar is
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
    b = CreateFrame("Button", "ToastyBagButton", parent, "SecureActionButtonTemplate")
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
  local f = CreateFrame("Frame", "ToastyBar", UIParent)
  f:SetSize(SIZE * 3 + GAP * 2, SIZE + DURATION_H)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetFrameStrata("LOW")
  B.frame = f

  B.slots[1] = MakeSlot(f, true)
  B.slots[1]:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  B.slots[2] = MakeSlot(f, false)
  B.slots[2]:SetPoint("TOPLEFT", B.slots[1], "TOPRIGHT", GAP, 0)
  B.slots[3] = MakeSlot(f, false)
  B.slots[3]:SetPoint("TOPLEFT", B.slots[2], "TOPRIGHT", GAP, 0)

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

-- The bag button's click action follows what icon 1 shows (out of combat).
function B:ApplyAction(useBag)
  if self.useBag == useBag then return end
  ns.AfterCombat("action", function()
    local b = self.slots[1]
    if useBag then
      b:SetAttribute("type", "item")
      b:SetAttribute("item", "item:" .. ns.Status.BAG_ITEM)
    else
      b:SetAttribute("type", nil)
      b:SetAttribute("item", nil)
    end
    self.useBag = useBag
  end)
end

function B:Refresh()
  if not self.frame then return end
  local S = ns.Status
  local s = ns.Demo.active and ns.Demo.s or S.s
  local bags = ns.Demo.active and (ns.Demo.bags or 0) or S.bagCount
  -- The game draws the buffs itself: paint only what lies under them.
  -- Boosted Rest (a debuff) is still Toasty's to draw.
  if ns.Engine and ns.Engine:Active() then s = { boosted = s.boosted } end

  local real = SleepView(S.s, S.bagCount)
  self:ApplyAction(real.useBag == true)

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
end

ns.Listen("LOGIN", function()
  Build()
  B:Refresh()
end)
ns.Listen("STATUS_CHANGED", function() B:Refresh() end)
ns.Listen("SETTINGS_CHANGED", function(key)
  if key == "scale" or key == "enabled" then B:ApplyLayout() end
  B:Refresh()
end)
