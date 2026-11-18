-- Toasty: settings page in Esc > Options > AddOns > Toasty.
--
-- Every setting is a Blizzard control (UICheckButtonTemplate checkboxes,
-- MinimalSliderWithSteppers sliders, UIPanelButtonTemplate buttons), and
-- every control writes ToastyBuffsDB through Options:Set. Style rules (as Queb,
-- Familiar and Pass the Spleen): native Blizzard look, short labels.
local _, ns = ...

local O = { pages = {} }
ns.Options = O

local NAME = "Toasty Buffs"

-- Central setter: every control goes through here.
function O:Set(key, value)
  if not ns.db or ns.db[key] == value then return end
  ns.db[key] = value
  ns.Fire("SETTINGS_CHANGED", key)
  self:RefreshAll()
end

---------------------------------------------------------------------------
-- Layout: columns of sections.
---------------------------------------------------------------------------
local LAYOUT = {
  {
    { header = "Icons" },
    { kind = "check", key = "enabled", label = "Show the camping icons",
      tip = "Well-Rested (or your sleeping bag), Camp Benefits and Boosted Rest, like your buff bar. Changes wait until you leave combat." },
    { kind = "check", key = "framed",  label = "Name and border",
      tip = "Show \"Toasty\" above the icons, in a panel with a border. Changes wait until you leave combat." },
    { kind = "cycle", key = "borderStyle", label = "Border style",
      values = { "bronze", "slim", "tooltip" },
      names = { bronze = "Forever bronze", slim = "Forever slim", tooltip = "Tooltip" },
      tip = "Forever bronze: the rim of Forever's windows, with Toasty in its title bar. Forever slim: Forever's thin bronze line. Tooltip: Blizzard's tooltip border. Changes wait until you leave combat." },
    { kind = "check", key = "iconLabels", label = "Icon labels",
      tip = "Show Bag, Buffs, Rest and 5% XP over the icons. Changes wait until you leave combat." },
    { kind = "check", key = "onlyMissing", label = "Only show what's missing",
      tip = "Hide an icon while you have its buff: a full 3/3 Well-Rested, Camp Benefits, Boosted Rest, XP food. A showing icon means go get it. It comes back in the buff's last minute. Changes wait until you leave combat." },
    { kind = "check", key = "locked",  label = "Lock position",
      tip = "When unlocked, Shift-drag an icon to move them." },
    { kind = "slider", key = "scale", label = "Size", min = 70, max = 150, step = 5, suffix = "%" },
    { kind = "button", label = "Reset position", width = 120, onClick = function() ns.Bar:ResetPosition() end },
  },
  {
    { header = "Alerts" },
    { kind = "check", key = "warnings", label = "Warnings",
      tip = "In a buff's last minute its icon pulses and a chat line says so; another line when it runs out." },
    { kind = "check", key = "hideXPAtMax", label = "Hide XP icons at level 60",
      tip = "Rest and 5% XP do nothing at max level, so hide them there." },
    { header = "Camp objects" },
    { kind = "check", key = "objectTips", label = "Explain camp objects",
      tip = "When you hover a camp object or campfire in the world, its tooltip says what it does." },
    { kind = "button", label = "Test tooltip", width = 110, onClick = function() ns.Objects:Test("Enchanted Lute") end },
    { header = "Testing" },
    { kind = "check", key = "engine", label = "Game-drawn buffs",
      tip = "The game draws the buffs on the icons, so they stay right in combat. Turn off to let Toasty draw them itself (they can't be read in combat then)." },
    { kind = "check", key = "demo",  label = "Demo icons",
      tip = "Cycles the icons through every state. Turns off after a reload." },
    { kind = "check", key = "debug", label = "Debug messages" },
  },
}

local COL_W = 230
local CHECK_H, SLIDER_H, HEADER_H, BUTTON_H = 26, 44, 26, 30

local function CheckLabel(cb)
  local t = cb.Text or cb.text
  if not t then
    t = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("LEFT", cb, "RIGHT", 2, 1)
  else
    t:SetFontObject("GameFontHighlight")
  end
  return t
end

local function MakeCheck(page, item)
  local cb = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  CheckLabel(cb):SetText(item.label)
  if item.tip then
    cb:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(item.label, 1, 1, 1)
      GameTooltip:AddLine(item.tip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  cb:SetScript("OnClick", function(self)
    local on = self:GetChecked() and true or false
    ns.UI.PlaySound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    O:Set(item.key, on)
  end)
  page.refreshers[#page.refreshers + 1] = function()
    cb:SetChecked(ns.db[item.key] and true or false)
  end
  return cb, CHECK_H
end

-- Slider: Blizzard's MinimalSliderWithSteppers when available, else - / +
-- buttons (as Familiar).
local function MakeSlider(page, item)
  local holder = CreateFrame("Frame", nil, page)
  holder:SetSize(COL_W - 8, SLIDER_H)
  local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", holder, "TOPLEFT", 4, 0)
  label:SetText(item.label)
  local valueText = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  local step = item.step or 1

  local function Show(v) valueText:SetText(v .. (item.suffix or "")) end
  local function Set(v)
    v = math.floor(v / step + 0.5) * step
    v = math.max(item.min, math.min(item.max, v))
    Show(v)
    if not page.updating then O:Set(item.key, v) end
  end

  local slider
  if MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Event then
    local ok, s = pcall(CreateFrame, "Frame", nil, holder, "MinimalSliderWithSteppersTemplate")
    if ok and s and s.Init then
      s:SetSize(150, 20)
      s:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
      local steps = math.floor((item.max - item.min) / step)
      if pcall(s.Init, s, ns.db[item.key] or item.min, item.min, item.max, steps) then
        s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v) Set(v) end, holder)
        slider = s
        valueText:SetPoint("LEFT", s, "RIGHT", 8, 0)
      else
        s:Hide()
      end
    end
  end
  if not slider then
    local minus = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
    minus:SetSize(24, 20)
    minus:SetText("-")
    minus:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    valueText:SetPoint("LEFT", minus, "RIGHT", 10, 0)
    valueText:SetWidth(40)
    local plus = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
    plus:SetSize(24, 20)
    plus:SetText("+")
    plus:SetPoint("LEFT", valueText, "RIGHT", 6, 0)
    minus:SetScript("OnClick", function() Set((ns.db[item.key] or item.min) - step) end)
    plus:SetScript("OnClick", function() Set((ns.db[item.key] or item.min) + step) end)
  end

  page.refreshers[#page.refreshers + 1] = function()
    local v = ns.db[item.key] or item.min
    Show(v)
    if slider and slider.SetValue then
      page.updating = true
      pcall(slider.SetValue, slider, v)
      page.updating = false
    end
  end
  return holder, SLIDER_H
end

local function MakeButton(page, item)
  local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  b:SetSize(item.width or 100, 22)
  b:SetText(item.label)
  b:SetScript("OnClick", function()
    ns.UI.PlaySound("IG_MAINMENU_OPTION")
    item.onClick()
  end)
  return b, BUTTON_H
end

-- A choice among a few values: its label, then a button showing the current
-- one; a click moves to the next.
local function MakeCycle(page, item)
  local holder = CreateFrame("Frame", nil, page)
  holder:SetSize(220, 44)
  local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("TOPLEFT", holder, "TOPLEFT", 4, -2)
  fs:SetText(item.label)
  local b = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
  b:SetSize(item.width or 150, 22)
  b:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
  local function Current()
    local v = ns.db[item.key]
    for i, c in ipairs(item.values) do if c == v then return i end end
    return 1
  end
  b:SetScript("OnClick", function()
    ns.UI.PlaySound("IG_MAINMENU_OPTION")
    local nextV = item.values[Current() % #item.values + 1]
    O:Set(item.key, nextV)
  end)
  if item.tip then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(item.label, 1, 1, 1)
      GameTooltip:AddLine(item.tip, nil, nil, nil, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  page.refreshers[#page.refreshers + 1] = function()
    b:SetText(item.names[item.values[Current()]] or tostring(ns.db[item.key]))
  end
  return holder, 50
end

local function MakeHeader(page, item)
  local fs = page:CreateFontString(nil, "OVERLAY", "GameFontNormal") -- gold, like Blizzard's option headers
  fs:SetText(item.header)
  return fs, HEADER_H
end

-- Build the Settings page inside `parent`. Returns the page frame.
function O:BuildPage(parent)
  local page = CreateFrame("Frame", nil, parent)
  page.refreshers = {}
  local lowest = 0
  for col, items in ipairs(LAYOUT) do
    local x, y = 8 + (col - 1) * COL_W, -6
    for _, item in ipairs(items) do
      local widget, h
      if item.header then
        widget, h = MakeHeader(page, item)
        if y < -6 then y = y - 6 end
        widget:SetPoint("TOPLEFT", page, "TOPLEFT", x + 4, y - 6)
      elseif item.kind == "check" then
        widget, h = MakeCheck(page, item)
        widget:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
      elseif item.kind == "slider" then
        widget, h = MakeSlider(page, item)
        widget:SetPoint("TOPLEFT", page, "TOPLEFT", x, y - 2)
      elseif item.kind == "cycle" then
        widget, h = MakeCycle(page, item)
        widget:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
      elseif item.kind == "button" then
        widget, h = MakeButton(page, item)
        widget:SetPoint("TOPLEFT", page, "TOPLEFT", x + 4, y - 4)
      end
      y = y - h
    end
    lowest = math.min(lowest, y)
  end
  page:SetSize(8 + #LAYOUT * COL_W, -lowest + 10)
  page:SetScript("OnShow", function(self) O:RefreshPage(self) end)
  self.pages[#self.pages + 1] = page
  return page
end

function O:RefreshPage(page)
  if not ns.db then return end
  for _, fn in ipairs(page.refreshers) do fn() end
end

function O:RefreshAll()
  for _, page in ipairs(self.pages) do
    if page:IsVisible() then self:RefreshPage(page) end
  end
end

---------------------------------------------------------------------------
-- Esc > Options > AddOns > Toasty: the page on a Blizzard canvas.
---------------------------------------------------------------------------
local function RegisterOptions()
  if O.canvas then return end
  local canvas = CreateFrame("Frame")
  canvas.name = NAME
  canvas:Hide()
  canvas:SetScript("OnShow", function(self)
    if self.page then return end
    local icon = self:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -8)
    icon:SetTexture(ns.UI.ICON)
    local title = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    title:SetText(NAME)
    self.page = O:BuildPage(self)
    self.page:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -44)
    O:RefreshPage(self.page)
  end)
  if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, canvas, NAME)
    if ok and cat then
      Settings.RegisterAddOnCategory(cat)
      O.category = cat
    end
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(canvas)
  end
  O.canvas = canvas
end
ns.Listen("LOGIN", RegisterOptions)

-- Open Esc > Options at this page.
function O:Open()
  if self.category and Settings and Settings.OpenToCategory then
    local id = self.category.GetID and self.category:GetID() or self.category.ID
    if pcall(Settings.OpenToCategory, id) then return end
  end
  if InterfaceOptionsFrame_OpenToCategory and self.canvas then
    InterfaceOptionsFrame_OpenToCategory(self.canvas)
    return
  end
  ns.Print("Open Esc > Options > AddOns > " .. NAME .. ".")
end
