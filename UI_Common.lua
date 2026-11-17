-- Toasty: shared look. Style rule (as Queb and Familiar): every element should look
-- like Blizzard's own UI, so colors come from Blizzard's constants and art
-- from Blizzard's textures, with fallbacks when an asset is missing.
local addonName, ns = ...

local UI = {}
ns.UI = UI

local function Const(c, r, g, b)
  if type(c) == "table" and c.r then return c end
  return { r = r, g = g, b = b }
end
UI.GOLD   = Const(NORMAL_FONT_COLOR, 1, 0.82, 0)
UI.WHITE  = Const(HIGHLIGHT_FONT_COLOR, 1, 1, 1)
UI.GRAY   = Const(GRAY_FONT_COLOR, 0.5, 0.5, 0.5)
UI.GREEN  = Const(GREEN_FONT_COLOR, 0.1, 1, 0.1)
UI.RED    = Const(RED_FONT_COLOR, 1, 0.1, 0.1)
UI.YELLOW = Const(YELLOW_FONT_COLOR, 1, 1, 0)
UI.ORANGE = Const(ORANGE_FONT_COLOR, 1, 0.5, 0.25)

local function Hex(c)
  return string.format("ff%02x%02x%02x", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end
function UI.Wrap(c, text) return "|c" .. Hex(c) .. text .. "|r" end

UI.ICON = "Interface\\Icons\\Spell_Fire_Fire"
UI.BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

-- A tooltip-style panel (Blizzard's tooltip background and border), as
-- Familiar's HUD. on = false takes it away again.
function UI.Plate(frame, on)
  if not frame.SetBackdrop then return end
  if on == false then
    frame:SetBackdrop(nil)
    return
  end
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  frame:SetBackdropColor(0.06, 0.06, 0.06, 0.85)
  frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end

function UI.PlaySound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then PlaySound(SOUNDKIT[kit]) end
end

-- A spell's icon on this client, else the fallback.
function UI.SpellIcon(id, fallback)
  local tex
  if C_Spell and C_Spell.GetSpellTexture then
    tex = ns.Try("C_Spell.GetSpellTexture", C_Spell.GetSpellTexture, id)
  elseif GetSpellTexture then
    tex = ns.Try("GetSpellTexture", GetSpellTexture, id)
  end
  return ns.Clean(tex) or fallback or UI.ICON
end
