-- Toasty: /toasty and /toast. Style rules: Blizzard system-message look
-- (ns.Print / ns.PrintLine) and short phrases.
local _, ns = ...
local P = function(text) ns.PrintLine(text) end

local function Yes(v) return ns.UI.Wrap(ns.UI.GREEN, v) end
local function No(v) return ns.UI.Wrap(ns.UI.RED, v) end
local function Gray(v) return ns.UI.Wrap(ns.UI.GRAY, v) end

local function Has(path)
  local v = _G
  for part in string.gmatch(path, "[^%.]+") do
    if type(v) ~= "table" then return false end
    v = v[part]
  end
  return v ~= nil
end

-- Developer report: what this client offers, and what the addon has seen.
-- Built to answer the "Needs in-game verification" list in the README.
local function Probe()
  local S, O, B = ns.Status, ns.Objects, ns.Bar
  local build, _, _, iface = GetBuildInfo()
  ns.Print("Probe: build", build, "interface", iface, "version", ns.VERSION)

  local apis = {
    "C_UnitAuras.GetPlayerAuraBySpellID", "C_UnitAuras.GetAuraDataByIndex", "UnitAura", "GameTooltip.SetUnitBuffByAuraInstanceID",
    "GameTooltip.SetUnitDebuffByAuraInstanceID",
    "C_Item.GetItemCount", "C_Container.GetItemCooldown", "C_Spell.GetSpellTexture",
    "SecondsToTimeAbbrev", "TooltipDataProcessor.AddTooltipPostCall", "Enum.TooltipDataType.Object",
    "issecretvalue", "C_StringUtil.CreateNumericRuleFormatter", "C_AddOns.LoadAddOn",
    "Settings.RegisterCanvasLayoutCategory", "MinimalSliderWithSteppersMixin",
  }
  local line = {}
  for _, name in ipairs(apis) do
    line[#line + 1] = Has(name) and Yes(name) or No(name)
    if #line == 3 then P("  " .. table.concat(line, "  ")); line = {} end
  end
  if #line > 0 then P("  " .. table.concat(line, "  ")) end

  P("  Buffs (ID · on you now):")
  for _, key in ipairs({ "wellRested", "benefits", "nearby", "boosted" }) do
    local def, a = S.AURAS[key], S.s[key]
    local learned = ns.db.learned[key]
    local now = Gray("off")
    if a then
      local left = S:Left(a)
      now = (a.kept and ns.UI.Wrap(ns.UI.YELLOW, "kept") or Yes("on")) .. " id " .. tostring(a.id) .. " · stacks " .. tostring(a.stacks)
        .. " · " .. (left and (ns.Duration(left) .. " of " .. tostring(ns.Duration(a.duration) or "?")) or "no end")
    end
    P("    " .. S:Name(key) .. (S.clientNames[key] and "" or No(" (name not from client)"))
      .. " · " .. def.id .. (learned and learned ~= def.id and (" learned " .. learned) or "") .. " · " .. now)
  end

  local En = ns.Engine
  local errs = {}
  for where, err in pairs(En.errors) do errs[#errs + 1] = where .. ": " .. err end
  P("  Game-drawn buffs (aura containers): " .. (En.built and Yes("built") or No("not built"))
    .. " · setting " .. (ns.db.engine and "on" or Gray("off"))
    .. (En.reason and (" · " .. En.reason) or "")
    .. " · layers " .. #En.layers .. " (+food " .. tostring(En.foodBuilds or 0) .. ") · buttons made " .. En.buttons
    .. " · tooltips left to the game " .. tostring(B.tipsYielded or 0)
    .. (#errs > 0 and (" · errors " .. No(table.concat(errs, "; "))) or ""))
  P("  Border: setting " .. tostring(ns.db.borderStyle) .. " · drawn " .. ns.Frame:Style() .. " · art: " .. ns.Frame:Report())
  P("  Combat: in combat " .. tostring(InCombatLockdown() and true or false)
    .. " · by-ID lookup worked in combat " .. (S.byIDInCombat and Yes("yes") or Gray("not yet"))
    .. " · unreadable auras last scan " .. S.seen.unreadable
    .. " · found by ID " .. S.seen.byID .. " · kept " .. S.seen.kept)
  local start, duration = S:BagCooldown()
  P("  Cozy Sleeping Bag: " .. S.bagCount .. " in bags · cooldown "
    .. ((start and duration and duration > 1.5) and ns.Duration(start + duration - GetTime()) or "none")
    .. " · button " .. (B:BagArmed() and Yes("uses bag") or Gray("does nothing"))
    .. " · cast on key down " .. tostring(GetCVar and GetCVar("ActionButtonUseKeyDown")))
  local Fd = ns.Food
  local xpIDs = {}
  for id in pairs(Fd:XPFoodIDs()) do xpIDs[#xpIDs + 1] = tostring(id) end
  table.sort(xpIDs)
  local fb = Fd.s
  P("  XP food: buff " .. (fb and ((fb.kept and ns.UI.Wrap(ns.UI.YELLOW, "kept") or Yes("on")) .. " id " .. tostring(fb.id)
      .. " · " .. tostring(ns.Duration(S:Left(fb)) or "no end")) or Gray("off"))
    .. " · XP Well Fed IDs " .. (#xpIDs > 0 and table.concat(xpIDs, ", ") or "none yet")
    .. " · tooltips checked " .. Fd.seen.checked .. " (XP " .. Fd.seen.xp .. ", not " .. Fd.seen.notXp .. ", unreadable " .. Fd.seen.unreadable .. ")"
    .. " · game-drawn layer " .. (ns.Engine:HasFood() and Yes("yes") or Gray("no")))
  P("  Nutritious food: \"" .. tostring(S.SpellName(Fd.NUTRITIOUS) or No("name not loaded")) .. "\" · in bags "
    .. (Fd.bag and (tostring(Fd.bag.name or Fd.bag.item) .. " x" .. Fd.bag.count) or "none")
    .. " · button " .. (B.actions[4] and Yes("eats " .. tostring(B.actions[4])) or Gray("does nothing")))
  local Z = ns.Sleep
  local zl, zn, zm = Z:Countdown()
  P("  Sleeping bag: Well-Rested " .. S:BagStacks() .. "/" .. S.BAG_STACKS
    .. " · countdown " .. (zm and "paused (moving)" or zl and (math.ceil(zl) .. " s to stack " .. zn) or "off")
    .. " · bag uses seen " .. Z.seen.uses .. " · stacks timed " .. Z.seen.stacks)
  local Al = ns.Alerts
  local ol, oh = ns.Objects:NextObject()
  P("  Level " .. tostring(ns.Num(UnitLevel("player"))) .. (ns.AtMaxLevel() and " (max: XP icons " .. (ns.db.hideXPAtMax and "hidden" or "shown") .. ")" or "")
    .. " · warnings " .. (ns.db.warnings and "on" or "off") .. " (" .. Al.seen.warned .. " sent, " .. Al.seen.dropped .. " drops)"
    .. " · next camp object " .. (ol and ((ol <= 0 and "ready") or ((oh == "about" and "about " or "") .. ns.Duration(ol))) or "unknown")
    .. (ns.char.object and (" (" .. tostring(ns.char.object.name) .. ")") or ""))
  P("  Object tooltips: hook " .. tostring(O.mode or No("none")) .. " · explained " .. O.seen.shown
    .. " · other world tooltips " .. O.seen.unknown .. " · last other: " .. tostring(O.lastUnknown or "none"))
  P("  Icons shown " .. tostring(B.frame and B.frame:IsShown() or false)
    .. " · in combat " .. tostring(InCombatLockdown() and true or false)
    .. " · demo " .. tostring(ns.Demo.active == true)
    .. " · settings page " .. tostring(ns.Options.category ~= nil or ns.Options.canvas ~= nil))
end

local function Help()
  ns.Print("commands:")
  P("  /toasty (or /toast, /toastybuffs): open the settings")
  P("  /toasty show | hide: show or hide the icons")
  P("  /toasty demo: cycle the icons through every state (again to stop)")
  P("  /toasty tip <object>: show a camp object's tooltip, e.g. /toasty tip Camp Chair")
  P("  /toasty reset: move the icons back to their first spot")
  P("  /toasty probe: developer report")
end

-- Key and globals carry the full name so they can't clash with another
-- addon called Toasty (Toasty Toasts exists on Forever).
SLASH_TOASTYBUFFS1 = "/toasty"
SLASH_TOASTYBUFFS2 = "/toast"
SLASH_TOASTYBUFFS3 = "/toastybuffs"
SlashCmdList.TOASTYBUFFS = function(msg)
  if not ns.db then return end
  local cmd, rest = string.match(msg or "", "^%s*(%S*)%s*(.-)%s*$")
  cmd = string.lower(cmd or "")
  if cmd == "" or cmd == "settings" or cmd == "options" or cmd == "config" then
    ns.Options:Open()
  elseif cmd == "show" or cmd == "on" then
    ns.Options:Set("enabled", true)
    ns.Print("Icons on." .. (InCombatLockdown() and " They appear when you leave combat." or ""))
  elseif cmd == "hide" or cmd == "off" then
    ns.Options:Set("enabled", false)
    ns.Print("Icons off." .. (InCombatLockdown() and " They hide when you leave combat." or ""))
  elseif cmd == "demo" or cmd == "test" then
    ns.Options:Set("demo", not ns.db.demo)
  elseif cmd == "tip" then
    ns.Objects:Test(rest)
  elseif cmd == "reset" then
    ns.Bar:ResetPosition()
    ns.Print("Icons moved back.")
  elseif cmd == "probe" then
    Probe()
  else
    Help()
  end
end

ns.Listen("LOGIN", function()
  ns.Debug("v" .. ns.VERSION .. " loaded. /toasty for the settings.")
end)
