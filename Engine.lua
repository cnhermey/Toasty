-- Toasty: buff icons drawn by the game itself, so they work in combat.
--
-- In combat Forever hides which aura is which from addon code (secret
-- values), so Toasty can't tell by itself whether a buff is up. The 12.1
-- engine Forever runs on has aura containers (Blizzard_AuraContainer): a
-- frame of ours that the game fills with matching auras and draws itself
-- (icon, stack count, countdown), secret or not. EllesmereUI's Cooldown
-- Manager uses the same pattern (EUI_CDM_AuraIcons.lua): our idle icon
-- underneath, and over it an engine aura slot that only shows while an aura
-- with one of our spell IDs is on you (candidateFilters.includeSpellIDs).
--
-- Layers, bottom to top, per icon:
--   1. our idle icon: the sleeping bag button / "No bag" / gray icons
--   2. engine slot(s): Well-Rested | Campfire Nearby, then Camp Benefits on
--      top. Icon 3 (Boosted Rest) has none: a debuff slot didn't show in
--      game (EllesmereUI only uses includeSpellIDs for buffs, which "pass the
--      identity gate"), so Toasty draws it itself from Status.lua.
-- Rules from the engine (see EllesmereUI_AuraKit.lua): set up the slot's
-- button only inside its initializeFrame callback (later calls are refused
-- while auras are secret), never write fields on the button, and give font
-- strings a font before registering them. The engine doesn't place a slot's
-- button: anchor it yourself in that callback (EllesmereUI does
-- button:SetAllPoints(proxy)), or it draws nowhere (0.4.0's bug). Clicks are turned off on the engine buttons, so a click
-- or Shift-drag goes through to Toasty's icon underneath; hovering shows the
-- game's own buff tooltip.
-- When the client has no aura containers, Toasty falls back to its own
-- aura reading (Status.lua) and nothing here runs.
local _, ns = ...

local E = { layers = {}, buttons = 0, errors = {} }
ns.Engine = E


-- Which engine slots sit on which icon, bottom to top.
local LAYERS = {
  { icon = 1, key = "wellRested", filter = "HELPFUL" },
  { icon = 2, key = "nearby",     filter = "HELPFUL" },
  { icon = 2, key = "benefits",   filter = "HELPFUL" },
}

local function Fail(where, err)
  if not E.errors[where] then
    E.errors[where] = tostring(err)
    ns.Debug("Engine", where, tostring(err))
  end
end

function E:Available()
  if not (CreateFrame and C_AddOns) then return false, "no C_AddOns" end
  if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
    pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
  end
  if not CustomAuraContainerMixin and not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
    return false, "no Blizzard_AuraContainer"
  end
  return true
end

---------------------------------------------------------------------------
-- Countdown text the way Blizzard's buff bar writes it: "45 s", "12 m",
-- "2 h", "1 d", always rounded up. Built once; nil if the client can't.
---------------------------------------------------------------------------
local formatter
local function Formatter()
  if formatter ~= nil then return formatter or nil end
  formatter = false
  if C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and Enum and Enum.NumericRuleFormatRounding then
    local Up = Enum.NumericRuleFormatRounding.Up
    local f = C_StringUtil.CreateNumericRuleFormatter()
    local ok = pcall(f.SetBreakpoints, f, {
      { threshold = 0,     format = "%d s", step = 1,     rounding = Up },
      { threshold = 61,    format = "%d m", step = 60,    rounding = Up, components = { { div = 60 } } },
      { threshold = 3601,  format = "%d h", step = 3600,  rounding = Up, components = { { div = 3600 } } },
      { threshold = 86401, format = "%d d", step = 86400, rounding = Up, components = { { div = 86400 } } },
    })
    if ok then formatter = f end
  end
  return formatter or nil
end

---------------------------------------------------------------------------
-- The slot button's look, set once inside the engine's creation window.
---------------------------------------------------------------------------
local function Init(button, host)
  E.buttons = E.buttons + 1
  local ok, err = pcall(function()
    -- Two-point anchors: the button covers Toasty's icon, and follows it.
    button:ClearAllPoints()
    button:SetAllPoints(host)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    -- Text above the icon, never under it.
    local carrier = CreateFrame("Frame", nil, button)
    carrier:SetAllPoints(button)
    carrier:SetFrameLevel(button:GetFrameLevel() + 2)
    carrier:EnableMouse(false)
    local stack = carrier:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    stack:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    local duration = carrier:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    duration:SetPoint("TOP", button, "BOTTOM", 0, -2)

    if button.SetMouseClickEnabled then pcall(button.SetMouseClickEnabled, button, false) end
    button:SetIcon(icon)
    if button.SetApplicationCount then pcall(button.SetApplicationCount, button, stack, {}) end
    if button.SetDurationText then
      local f = Formatter()
      if not (f and pcall(button.SetDurationText, button, duration, { textFormatter = f })) then
        pcall(button.SetDurationText, button, duration, {})
      end
    end
  end)
  if not ok then Fail("init", err) end
end

---------------------------------------------------------------------------
-- Build: one container per layer, centered on its Toasty icon.
---------------------------------------------------------------------------
local function IDs(key)
  local def = ns.Status.AURAS[key]
  local set = { [def.id] = true }
  local learned = ns.db.learned[key]
  if learned then set[learned] = true end
  return set
end

function E:Build()
  if self.built then return end
  local ok, why = self:Available()
  if not ok then self.reason = why; return end
  local slots = ns.Bar.slots
  if not slots[1] then self.reason = "icons not built"; return end
  for i, L in ipairs(LAYERS) do
    local host = slots[L.icon]
    local made, err = pcall(function()
      local c = CreateFrame("AuraContainer", nil, host, "CustomAuraContainerTemplate")
      c:SetPoint("CENTER", host, "CENTER", 0, 0)
      c:SetSize(1, 1)
      c:SetFrameLevel(host:GetFrameLevel() + 3 + i)
      c:AddAuraSlot(L.key, L.filter, {
        candidateFilters = { includeSpellIDs = IDs(L.key) },
        initializeFrame = function(button) Init(button, host) end,
      })
      c:SetUnit("player")
      c:UpdateAllAuras()
      self.layers[i] = c
    end)
    if not made then
      Fail("build " .. L.key, err)
      self.reason = "build failed: " .. tostring(err)
      self:Teardown()
      return
    end
  end
  self.built = true
  self.reason = nil
  Apply()
  ns.Fire("STATUS_CHANGED")
end

-- Hide the engine layers (demo, or a failed build). Shown again by Show.
function E:Teardown()
  for _, c in pairs(self.layers) do pcall(c.Hide, c) end
end

function E:Show()
  for _, c in pairs(self.layers) do pcall(c.Show, c) end
end

-- True when the game draws the buffs (Toasty only paints the idle icons).
function E:Active()
  return self.built == true and ns.db.engine and not ns.Demo.active
end

local function Apply()
  if not E.built then return end
  if ns.db.engine and not ns.db.demo then E:Show() else E:Teardown() end
end

ns.Listen("LOGIN", function()
  -- After the icons exist (UI_Bar builds on LOGIN, earlier in the TOC).
  C_Timer.After(0, function() E:Build() end)
end)

ns.Listen("SETTINGS_CHANGED", function(key)
  if key == "demo" or key == "engine" then Apply() end
end)
