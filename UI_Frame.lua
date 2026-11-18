-- Toasty: the panel's border, in Forever's own art.
--
-- WoW Forever repaints several stock Blizzard art pieces with its own
-- bronze "-c60" art. Drawing those pieces makes the panel look like Forever's
-- windows. The recipe (piece names and every measurement) is EllesmereUI's
-- (EllesmereUI_RetailAtlas.lua: ForeverHeavy and ForeverBorder):
--   bronze  the bronze rim of Forever's windows (the UI-Frame-Metal pieces)
--           with their title bar under the top rim: "Toasty" sits in it.
--           Drawn at FRAME_K of the art's size, like EllesmereUI does for
--           small surfaces. Edge strips repeat along their length.
--   slim    the slim bronze line of Forever's action buttons
--           (UI-HUD-ActionBar-Frame), cut into corners and edges from the
--           stretches of each side that are free of scratches.
--   tooltip Blizzard's tooltip border (UI.Plate), the look before 0.10.
-- Each style has a dark body under it. A style whose art the client lacks
-- falls back to tooltip (probe says so). Settings > Border style.
-- Only our own frames and textures: nothing here touches Blizzard frames.
local _, ns = ...
local UI = ns.UI

local FR = { styles = { "bronze", "slim", "tooltip" } }
ns.Frame = FR

FR.NAMES = { bronze = "Forever bronze", slim = "Forever slim", tooltip = "Tooltip" }
FR.K = 0.75   -- bronze frame scale (1 = the art's own size, made for big windows)

local EPS, min = 0.01, math.min

---------------------------------------------------------------------------
-- Bronze (UI-Frame-Metal). Art units; see EllesmereUI's FOREVER_HEAVY.
---------------------------------------------------------------------------
local HEAVY_ART = {
  tl = "UI-Frame-Metal-CornerTopLeft", tr = "UI-Frame-Metal-CornerTopRight",
  bl = "UI-Frame-Metal-CornerBottomLeft", br = "UI-Frame-Metal-CornerBottomRight",
  te = "_UI-Frame-Metal-EdgeTop", be = "_UI-Frame-Metal-EdgeBottom",
  le = "!UI-Frame-Metal-EdgeLeft", re = "!UI-Frame-Metal-EdgeRight",
}
-- The rim's outer edge in from the pieces' left, right, top and bottom; the
-- top pieces' depth with the title bar.
local HML, HMR, HMT, HMB, HTITLE = 12.5, 2.5, 13, 7.5, 43
FR.HEAVY = {
  band = 6,                    -- the rim and its dark line
  fill = 3,                    -- the body's inset from the rim's outer edge
  titleBand = { 6, 23 },       -- the title bar's dark band, from the rim's outer edge
  titleBottom = 27.5,          -- the divider's bottom
}

local function AtlasInfo(name)
  return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) or nil
end

local heavyInfo
local function HeavyInfo()
  if heavyInfo == nil then
    heavyInfo = false
    local info = {}
    for key, name in pairs(HEAVY_ART) do
      info[key] = AtlasInfo(name)
      if not info[key] then return false end
    end
    heavyInfo = info
  end
  return heavyInfo
end

local function Cut(t, info, u1, u2, v1, v2)
  local L, T = info.leftTexCoord, info.topTexCoord
  local W, H = info.rightTexCoord - L, info.bottomTexCoord - T
  t:SetTexCoord(L + W * u1, L + W * u2, T + H * v1, T + H * v2)
end

-- The box's OnSizeChanged (w x h in art units: the rim's outer edge).
local function HeavyLayout(box, w, h)
  local ring = FR.heavy
  local I, p, top = heavyInfo, ring.p, HTITLE
  local cw, th, bh0 = I.tl.width, I.tl.height, I.bl.height
  local cl = min(cw, w / 2 + HML)
  local cr = min(cw, w / 2 + HMR)
  local bh = min(bh0, h + HMT + HMB - top)
  local gx = w + HML + HMR - cl - cr
  local gy = h + HMT + HMB - top - bh
  p.tl:SetSize(cl, top); Cut(p.tl, I.tl, 0, cl / cw, 0, top / th)
  p.tr:SetSize(cr, top); Cut(p.tr, I.tr, 1 - cr / cw, 1, 0, top / th)
  p.bl:SetSize(cl, bh);  Cut(p.bl, I.bl, 0, cl / cw, 1 - bh / bh0, 1)
  p.br:SetSize(cr, bh);  Cut(p.br, I.br, 1 - cr / cw, 1, 1 - bh / bh0, 1)
  local te, be, le, re = I.te, I.be, I.le, I.re
  p.te:SetHeight(top)
  p.te:SetTexCoord(0, gx / te.width, te.topTexCoord,
    te.topTexCoord + (te.bottomTexCoord - te.topTexCoord) * top / te.height)
  p.be:SetHeight(bh)
  p.be:SetTexCoord(0, gx / be.width,
    be.bottomTexCoord - (be.bottomTexCoord - be.topTexCoord) * bh / be.height, be.bottomTexCoord)
  p.le:SetWidth(cl)
  p.le:SetTexCoord(le.leftTexCoord,
    le.leftTexCoord + (le.rightTexCoord - le.leftTexCoord) * cl / le.width, 0, gy / le.height)
  p.re:SetWidth(cr)
  p.re:SetTexCoord(re.rightTexCoord - (re.rightTexCoord - re.leftTexCoord) * cr / re.width,
    re.rightTexCoord, 0, gy / re.height)
  ring.roomX, ring.roomY, ring.sized = gx > EPS, gy > EPS, true
  FR:ShowHeavy(ring.on)
end

function FR:ShowHeavy(on)
  local ring = self.heavy
  if not ring then return end
  ring.on = on
  local p, show = ring.p, on and ring.sized
  p.tl:SetShown(show); p.tr:SetShown(show); p.bl:SetShown(show); p.br:SetShown(show)
  p.te:SetShown(show and ring.roomX); p.be:SetShown(show and ring.roomX)
  p.le:SetShown(show and ring.roomY); p.re:SetShown(show and ring.roomY)
  ring.fill:SetShown(on)
end

local function BuildHeavy(f)
  local I = HeavyInfo()
  if not I then return nil end
  local art = CreateFrame("Frame", nil, f)
  art:SetScale(FR.K)
  art:SetFrameLevel(f:GetFrameLevel())
  art:SetAllPoints(f)
  local box = CreateFrame("Frame", nil, art)
  box:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  local ring = { art = art, box = box, p = {}, on = false }
  -- The dark body under the rim.
  ring.fill = art:CreateTexture(nil, "BACKGROUND")
  ring.fill:SetColorTexture(0.05, 0.045, 0.04, 0.92)
  ring.fill:SetPoint("TOPLEFT", box, "TOPLEFT", FR.HEAVY.fill, -FR.HEAVY.fill)
  ring.fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -FR.HEAVY.fill, FR.HEAVY.fill)
  ring.fill:Hide()
  for key, info in pairs(I) do
    local t = art:CreateTexture(nil, "BORDER")
    local along = (key == "te" or key == "be") and "h" or (key == "le" or key == "re") and "v" or nil
    t:SetTexture(info.file or info.filename, along == "h" and "REPEAT" or "CLAMP", along == "v" and "REPEAT" or "CLAMP")
    if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    t:Hide()
    ring.p[key] = t
  end
  local p = ring.p
  p.tl:SetPoint("TOPLEFT", box, "TOPLEFT", -HML, HMT)
  p.tr:SetPoint("TOPRIGHT", box, "TOPRIGHT", HMR, HMT)
  p.bl:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", -HML, -HMB)
  p.br:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", HMR, -HMB)
  p.te:SetPoint("TOPLEFT", p.tl, "TOPRIGHT"); p.te:SetPoint("TOPRIGHT", p.tr, "TOPLEFT")
  p.be:SetPoint("BOTTOMLEFT", p.bl, "BOTTOMRIGHT"); p.be:SetPoint("BOTTOMRIGHT", p.br, "BOTTOMLEFT")
  p.le:SetPoint("TOPLEFT", p.tl, "BOTTOMLEFT"); p.le:SetPoint("BOTTOMLEFT", p.bl, "TOPLEFT")
  p.re:SetPoint("TOPRIGHT", p.tr, "BOTTOMRIGHT"); p.re:SetPoint("BOTTOMRIGHT", p.br, "TOPRIGHT")
  box:SetScript("OnSizeChanged", HeavyLayout)
  return ring
end

---------------------------------------------------------------------------
-- Slim (UI-HUD-ActionBar-Frame). Art units: the art is RS a side, the
-- line's outer edge RM in, corners RC square, edges RD deep. Each edge is
-- cut from the stretch of its side that is clear of scratches (LIVE_RUN).
---------------------------------------------------------------------------
local SLIM_ATLAS = "UI-HUD-ActionBar-Frame"
local RS, RM, RC, RD = 55, 3, 12, 6
local LIVE_RUN = { [5] = { 16, 39 }, [6] = { 16, 40 }, [7] = { 19, 43 }, [8] = { 12, 36 } }
local SLIM_FILL = 2.75

local function BuildSlim(f)
  local info = AtlasInfo(SLIM_ATLAS)
  if not info then return nil end
  local file = info.file or info.filename
  local L, T = info.leftTexCoord, info.topTexCoord
  local W, H = info.rightTexCoord - L, info.bottomTexCoord - T
  local box = CreateFrame("Frame", nil, f)
  box:SetFrameLevel(f:GetFrameLevel())
  box:SetPoint("TOPLEFT", f, "TOPLEFT", -RM, RM)
  box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", RM, -RM)
  local ring = { box = box, pieces = {} }
  ring.fill = box:CreateTexture(nil, "BACKGROUND")
  ring.fill:SetColorTexture(0.05, 0.045, 0.04, 0.9)
  ring.fill:SetPoint("TOPLEFT", f, "TOPLEFT", SLIM_FILL, -SLIM_FILL)
  ring.fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -SLIM_FILL, SLIM_FILL)
  local c, d = RC / RS, RD / RS
  local AT = {
    { "TOPLEFT", 0, 0 }, { "TOPRIGHT", 0, 0 }, { "BOTTOMLEFT", 0, 0 }, { "BOTTOMRIGHT", 0, 0 },
    { "TOPLEFT", RC, 0, "TOPRIGHT", -RC, 0 },
    { "BOTTOMLEFT", RC, 0, "BOTTOMRIGHT", -RC, 0 },
    { "TOPLEFT", 0, -RC, "BOTTOMLEFT", 0, RC },
    { "TOPRIGHT", 0, -RC, "BOTTOMRIGHT", 0, RC },
  }
  local CORNER = { { 0, c, 0, c }, { 1 - c, 1, 0, c }, { 0, c, 1 - c, 1 }, { 1 - c, 1, 1 - c, 1 } }
  local EDGE = {
    [5] = { LIVE_RUN[5][1] / RS, LIVE_RUN[5][2] / RS, 0, d },
    [6] = { LIVE_RUN[6][1] / RS, LIVE_RUN[6][2] / RS, 1 - d, 1 },
    [7] = { 0, d, LIVE_RUN[7][1] / RS, LIVE_RUN[7][2] / RS },
    [8] = { 1 - d, 1, LIVE_RUN[8][1] / RS, LIVE_RUN[8][2] / RS },
  }
  for i = 1, 8 do
    local t = box:CreateTexture(nil, "BORDER")
    t:SetTexture(file)
    local at = AT[i]
    t:SetPoint(at[1], box, at[1], at[2], at[3])
    local cut = CORNER[i] or EDGE[i]
    t:SetTexCoord(L + W * cut[1], L + W * cut[2], T + H * cut[3], T + H * cut[4])
    if at[4] then
      t:SetPoint(at[4], box, at[4], at[5], at[6])
      if i <= 6 then t:SetHeight(RD) else t:SetWidth(RD) end
    else
      t:SetSize(RC, RC)
    end
    ring.pieces[i] = t
  end
  box:Hide()
  return ring
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------
function FR:Build(f)
  self.f = f
  self.heavy = BuildHeavy(f)
  self.slim = BuildSlim(f)
end

-- The style the panel really draws: the setting, or tooltip when its art
-- is missing; "none" without Name and border.
function FR:Style()
  if not ns.db.framed then return "none" end
  local want = ns.db.borderStyle or "bronze"
  if want == "bronze" and not self.heavy then return "tooltip" end
  if want == "slim" and not self.slim then return "tooltip" end
  return want
end

-- Room each style needs around the content, in UI units: top (down to the
-- first row: labels or icons), side, bottom, and where the name's center
-- sits below the top edge.
function FR:Metrics(style)
  if style == "bronze" then
    local k, H = self.K, self.HEAVY
    return { top = H.titleBottom * k + 6, side = H.band * k + 7, bottom = H.band * k + 5,
             titleY = (H.titleBand[1] + H.titleBand[2]) / 2 * k }
  elseif style == "slim" or style == "tooltip" then
    return { top = 9 + 14 + 5, side = 12, bottom = 6, titleY = 9 + 7 }
  end
  return { top = 0, side = 0, bottom = 0, titleY = 0 }
end

function FR:Apply(style)
  local f = self.f
  UI.Plate(f, style == "tooltip")
  self:ShowHeavy(style == "bronze")
  if self.slim then self.slim.box:SetShown(style == "slim") end
end

-- Forever's action button ring around an icon (bronze and slim styles).
FR.ICON_RING = "UI-HUD-ActionBar-IconFrame"
function FR:IconRingOK() return AtlasInfo(self.ICON_RING) ~= nil end

function FR:Report()
  return (self.heavy and "bronze yes" or "bronze no") .. " · " .. (self.slim and "slim yes" or "slim no")
    .. " · icon ring " .. (self:IconRingOK() and "yes" or "no")
end
