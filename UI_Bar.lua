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
-- The panel's padding and the name's place come from the Border style
-- (ns.Frame:Metrics in UI_Frame.lua).
local SUB_H = 13       -- the short label over each icon (Settings > Icon labels)
local SUBHEADS = { "Bag", "Buffs", "Rest", "5% XP" }
local COUNT = 4
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
    -- Name and border, in the chosen Border style (UI_Frame.lua): Forever's
    -- bronze window rim with "Toasty" in its title bar, Forever's slim line,
    -- or the tooltip border.
    local style = ns.Frame:Style()
    local M = ns.Frame:Metrics(style)
    local framed = style ~= "none"
    local top = M.top
    -- Short labels over the icons ("Bag", "Buffs", "Rest", "5% XP").
    local subs = ns.db.iconLabels
    if subs then top = top + SUB_H end

    local side = M.side
    -- At max level the XP icons (Rest, 5% XP) go: they do nothing there.
    local n = self:VisibleCount()
    for i, slot in ipairs(self.slots) do
      slot:SetShown(i <= n)
      slot.subhead:SetShown(subs and i <= n)
    end
    local rowW = SIZE * n + GAP * (n - 1)
    f:SetSize(rowW + side * 2, top + SIZE + DURATION_H + M.bottom)
    -- Forever's action button ring on each icon, with the bronze styles.
    local rings = (style == "bronze" or style == "slim") and ns.Frame:IconRingOK()
    for _, slot in ipairs(self.slots) do slot.top.ring:SetShown(rings) end
    self.slots[1]:ClearAllPoints()
    self.slots[1]:SetPoint("TOPLEFT", f, "TOPLEFT", side, -top)
    ns.Frame:Apply(style)
    f.title:ClearAllPoints()
    f.title:SetPoint("CENTER", f, "TOP", 0, -M.titleY)
    f.title:SetShown(framed)
    f:SetShown(ns.db.enabled)
  end)
end

function B:VisibleCount()
  if ns.db.hideXPAtMax and ns.AtMaxLevel() and not ns.Demo.active then return 2 end
  return COUNT
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
  -- A game-drawn buff over this icon shows the game's own tooltip.
  if ns.Engine:Covers(self) then B.tipsYielded = (B.tipsYielded or 0) + 1; return end
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

-- While an icon is hovered, a buff can start or end under the cursor: then
-- hand the tooltip over (to the game's, or back to Toasty's). One shared
-- watcher frame, not OnUpdate on the icons (two are secure buttons).
local watch = CreateFrame("Frame")
watch:Hide()
local elapsedSince = 0
watch:SetScript("OnUpdate", function(_, elapsed)
  elapsedSince = elapsedSince + elapsed
  if elapsedSince < 0.1 then return end
  elapsedSince = 0
  local slot = watch.slot
  if not slot then watch:Hide(); return end
  local ours = GameTooltip:IsShown() and GameTooltip:GetOwner() == slot
  local covered = ns.Engine:Covers(slot)
  if covered and ours then
    GameTooltip:Hide()
  elseif not covered and not ours then
    SlotTooltip(slot)
  end
end)

local function HoverStart(self)
  watch.slot = self
  elapsedSince = 0
  watch:Show()
  SlotTooltip(self)
end

local function HoverStop(self)
  if watch.slot == self then watch.slot = nil; watch:Hide() end
  if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
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
  -- Trim the icon art's built-in light edge (it showed as thin lines at the
  -- side of the Bag icon); the game-drawn icons get the same crop.
  b.icon:SetTexCoord(UI.CROP[1], UI.CROP[2], UI.CROP[3], UI.CROP[4])
  b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
  b.duration = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.duration:SetPoint("TOP", b, "BOTTOM", 0, -2)
  -- "No bag" sits on the icon, so a buff drawn over it by the game hides it.
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
  b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.label:SetWidth(SIZE + 4)
  b.label:SetTextColor(0.8, 0.8, 0.8)
  b:SetScript("OnEnter", HoverStart)
  b:SetScript("OnLeave", HoverStop)
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", OnDragStart)
  b:SetScript("OnDragStop", OnDragStop)

  -- On top of everything, the game-drawn buff included: the warning pulse
  -- (Alerts.lua) and, on icon 1, the sleeping bag countdown. Mouse passes
  -- through.
  local top = CreateFrame("Frame", nil, b)
  top:SetAllPoints(b)
  top:SetFrameLevel(b:GetFrameLevel() + 12)
  top:EnableMouse(false)
  b.top = top
  -- Forever's action button ring (bronze on Forever), over the game-drawn
  -- buff too. Shown with the bronze and slim Border styles.
  local ring = top:CreateTexture(nil, "ARTWORK")
  ring:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
  ring:SetSize(SIZE * 46 / 45, SIZE)   -- the atlas's shape (46 x 45 on a 45 button)
  if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("UI-HUD-ActionBar-IconFrame") then
    ring:SetAtlas("UI-HUD-ActionBar-IconFrame")
  end
  ring:Hide()
  top.ring = ring
  local glow = top:CreateTexture(nil, "OVERLAY")
  glow:SetPoint("TOPLEFT", b, "TOPLEFT", -3, 3)
  glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -3)
  glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.72, 0.35)   -- warm bronze, like Forever's highlights
  glow:SetAlpha(0)
  local pulse = glow:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.15)
  fade:SetToAlpha(0.95)
  fade:SetDuration(0.6)
  top.glow, top.pulse = glow, pulse
  return b
end

-- Pulse an icon (a buff in its last minute). Plain frames: fine in combat.
function B:SetWarning(index, on)
  local slot = self.slots[index]
  if not slot then return end
  local top = slot.top
  if on and not top.pulse:IsPlaying() then
    top.pulse:Play()
  elseif not on and top.pulse:IsPlaying() then
    top.pulse:Stop()
    top.glow:SetAlpha(0)
  end
end

local function Build()
  local f = CreateFrame("Frame", "ToastyBuffsBar", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetSize(SIZE * COUNT + GAP * (COUNT - 1), SIZE + DURATION_H)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetFrameStrata("LOW")
  -- Shift-drag the panel itself, not only the icons.
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", OnDragStart)
  f:SetScript("OnDragStop", OnDragStop)
  B.frame = f

  -- The border art (built once, shown per Border style).
  ns.Frame:Build(f)

  -- The name, gold like Blizzard's window titles, centered over the icons.
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetPoint("CENTER", f, "TOP", 0, -16)   -- placed again by ApplyLayout
  f.title:SetText("Toasty")

  -- All four lit: a small campfire icon on each side of the name.
  local FIRE = UI.SpellIcon(1229737, "Interface\\Icons\\Spell_Fire_Fire")  -- Basic Campfire
  f.fires = {}
  for i, side in ipairs({ { "RIGHT", "LEFT", -4 }, { "LEFT", "RIGHT", 4 } }) do
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetSize(14, 14)
    t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    t:SetTexture(FIRE)
    t:SetPoint(side[1], f.title, side[2], side[3], 0)
    t:Hide()
    f.fires[i] = t
  end

  B.slots[1] = MakeSlot(f, "ToastyBuffsBagButton")
  B.slots[2] = MakeSlot(f, false)
  B.slots[2]:SetPoint("TOPLEFT", B.slots[1], "TOPRIGHT", GAP, 0)
  B.slots[3] = MakeSlot(f, false)
  B.slots[3]:SetPoint("TOPLEFT", B.slots[2], "TOPRIGHT", GAP, 0)
  B.slots[4] = MakeSlot(f, "ToastyBuffsFoodButton")
  B.slots[4]:SetPoint("TOPLEFT", B.slots[3], "TOPRIGHT", GAP, 0)

  -- The sleeping bag countdown on icon 1: a cooldown swipe for the minute
  -- to the next Well-Rested stack, and the seconds in the middle.
  local top = B.slots[1].top
  top.cd = CreateFrame("Cooldown", nil, top, "CooldownFrameTemplate")
  top.cd:SetAllPoints(top)
  if top.cd.SetHideCountdownNumbers then top.cd:SetHideCountdownNumbers(true) end
  if top.cd.SetDrawEdge then top.cd:SetDrawEdge(false) end
  top.cd:Hide()
  top.timer = top:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  top.timer:SetPoint("CENTER", top, "CENTER", 0, 0)

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
  if s.wellRested then
    local v = BuffView(s.wellRested, "wellRested")
    local n = S:BagStacks(s.wellRested)
    if n < S.BAG_STACKS then
      v.hint = n .. "/" .. S.BAG_STACKS .. " stacks. Keep resting on your sleeping bag: one more stack a minute, up to +"
        .. S.BAG_STACKS .. "% XP."
    end
    return v
  end
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
  local dim = v.gray and 0.5 or 1   -- gray and dim, like an unusable action button
  slot.icon:SetVertexColor(dim, dim, dim)
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

-- "Toasty!": when all four icons are lit (Well-Rested, Camp Benefits,
-- Boosted Rest, XP food), the name turns red with a campfire on each side.
-- Read from Toasty's own buff state, also when the game draws the icons.
function B:ApplyToasty(s, food)
  local f = self.frame
  local S = ns.Status
  -- A full sleeping bag (3 stacks) counts; at max level only Bag and Buffs.
  local bag = s.wellRested and S:BagStacks(s.wellRested) >= S.BAG_STACKS
  local all
  if self:VisibleCount() < COUNT then
    all = bag and s.benefits and true or false
  else
    all = bag and s.benefits and s.boosted and food and true or false
  end
  local c = all and UI.RED or UI.GOLD
  f.title:SetTextColor(c.r, c.g, c.b)
  local show = all and ns.db.framed
  for _, t in ipairs(f.fires) do t:SetShown(show) end
  self.toasty = all
end

-- Icon 1 extras: "Bag 2/3" while the sleeping bag isn't full, and the
-- countdown to the next stack after you use the bag (Sleep.lua).
function B:PaintBagProgress(truth)
  local S, slot = ns.Status, self.slots[1]
  local n = S:BagStacks(truth.wellRested)
  local left, nextStack, moving
  if ns.Demo.active then
    local d = ns.Demo.sleep
    if d then left, nextStack = math.max(0, d.nextAt - GetTime()), d.next end
  else
    left, nextStack, moving = ns.Sleep:Countdown()
  end
  local waiting = left or moving
  if (truth.wellRested and n < S.BAG_STACKS) or waiting then
    slot.subhead:SetText("Bag " .. n .. "/" .. S.BAG_STACKS)
    slot.subhead:SetTextColor(UI.YELLOW.r, UI.YELLOW.g, UI.YELLOW.b)
  else
    slot.subhead:SetText(SUBHEADS[1])
    slot.subhead:SetTextColor(0.82, 0.82, 0.82)
  end
  local top = slot.top
  if moving then
    top.cd:Hide()
    top.cdStart = nil
    top.timer:SetText("still")
    top.timer:SetTextColor(UI.YELLOW.r, UI.YELLOW.g, UI.YELLOW.b)
  elseif left then
    local start = math.floor((GetTime() - (60 - left)) * 10 + 0.5) / 10
    if top.cdStart ~= start then
      top.cdStart = start
      top.cd:SetCooldown(start, 60)
      top.cd:Show()
    end
    top.timer:SetText(math.ceil(left))
    top.timer:SetTextColor(1, 1, 1)
  else
    if top.cdStart then top.cd:Hide(); top.cdStart = nil end
    top.timer:SetText("")
  end
end

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

  local truth = ns.Demo.active and ns.Demo.s or S.s   -- what you really have
  local v1 = SleepView(s, bags)
  if engine and truth.wellRested then
    -- The game draws Well-Rested here: leave nothing underneath to peek out.
    v1 = { icon = nil, title = S:Name("wellRested") }
  end
  Paint(self.slots[1], v1)
  self:PaintBagProgress(truth)
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

  self:ApplyToasty(ns.Demo.active and ns.Demo.s or S.s, ns.Demo.active and ns.Demo.s.food or F.s)

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
  if key == "scale" or key == "enabled" or key == "framed" or key == "borderStyle" or key == "iconLabels"
    or key == "hideXPAtMax" or key == "demo" then
    B:ApplyLayout()
  end
  B:Refresh()
end)

-- Reaching max level drops the XP icons (out of combat).
ns.On("PLAYER_LEVEL_UP", function()
  C_Timer.After(0.5, function() B:ApplyLayout(); B:Refresh() end)
end)
