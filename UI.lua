local ADDON, ns = ...

local ROWS, ROWH = 7, 44

-- Medieval palette -----------------------------------------------------------
local PARCH  = { 0.82, 0.72, 0.52 }
local INK    = { 0.20, 0.13, 0.07 }
local INKH   = { 0.14, 0.09, 0.05 }
local BRONZE = { 0.72, 0.56, 0.28 }
local GOLD   = { 0.86, 0.72, 0.42 }
local GOLDHI = { 0.98, 0.86, 0.55 }
local WOOD   = { 0.13, 0.09, 0.05 }   -- dark leather/wood for buttons
local WOODHI = { 0.22, 0.15, 0.08 }
local WAX    = { 0.55, 0.12, 0.10 }

local SCRIPT = "Fonts\\MORPHEUS.ttf"   -- blackletter-ish display
local NORM   = "Fonts\\FRIZQT__.ttf"

local backdrop = BackdropTemplateMixin and "BackdropTemplate" or nil

-- helpers --------------------------------------------------------------------
local function Font(fs, path, size, flags)
    if not fs:SetFont(path, size, flags or "") then
        fs:SetFont(NORM, size, flags or "")
    end
end

local function Solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    if t.SetColorTexture then t:SetColorTexture(r, g, b, a or 1)
    else t:SetTexture(r, g, b, a or 1) end
    return t
end

-- frame ----------------------------------------------------------------------
local f = CreateFrame("Frame", "GrudgeLedgerFrame", UIParent, backdrop)
f:SetSize(400, 520)
f:SetPoint("CENTER")
f:SetFrameStrata("DIALOG")
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "GrudgeLedgerFrame") end

-- opaque parchment base so the frame is NEVER see-through
local base = Solid(f, "BACKGROUND", PARCH[1], PARCH[2], PARCH[3], 1)
base:SetPoint("TOPLEFT", 10, -10)
base:SetPoint("BOTTOMRIGHT", -10, 10)
base:SetDrawLayer("BACKGROUND", -8)

-- parchment grain on top of the solid base
local grain = f:CreateTexture(nil, "BACKGROUND")
grain:SetPoint("TOPLEFT", 10, -10)
grain:SetPoint("BOTTOMRIGHT", -10, 10)
grain:SetDrawLayer("BACKGROUND", -6)
grain:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
grain:SetVertexColor(0.92, 0.82, 0.60)
grain:SetAlpha(0.6)

-- ornate fantasy frame border (bulletproof via backdrop, with a line fallback)
if f.SetBackdrop then
    f:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropBorderColor(0.95, 0.88, 0.70)
else
    local function line(p1, p2, horiz, c)
        local t = Solid(f, "BORDER", c[1], c[2], c[3], 1)
        if horiz then t:SetHeight(3) else t:SetWidth(3) end
        t:SetPoint(p1); t:SetPoint(p2)
    end
    line("TOPLEFT", "TOPRIGHT", true, BRONZE)
    line("BOTTOMLEFT", "BOTTOMRIGHT", true, BRONZE)
    line("TOPLEFT", "BOTTOMLEFT", false, BRONZE)
    line("TOPRIGHT", "BOTTOMRIGHT", false, BRONZE)
end

-- title ----------------------------------------------------------------------
local title = f:CreateFontString(nil, "OVERLAY")
Font(title, SCRIPT, 30)
title:SetTextColor(unpack(INKH))
title:SetPoint("TOP", 0, -24)
title:SetText("Grudge Ledger")

local sub = f:CreateFontString(nil, "OVERLAY")
Font(sub, SCRIPT, 14)
sub:SetTextColor(0.42, 0.28, 0.14)
sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
sub:SetText("those who have wronged me")

-- flourish divider: a bronze rule with a center diamond and end caps
do
    local rule = Solid(f, "ARTWORK", BRONZE[1], BRONZE[2], BRONZE[3], 0.8)
    rule:SetHeight(2)
    rule:SetPoint("TOPLEFT", 40, -78)
    rule:SetPoint("TOPRIGHT", -40, -78)
    local function cap(point, ox)
        local c = Solid(f, "OVERLAY", BRONZE[1], BRONZE[2], BRONZE[3], 1)
        c:SetSize(5, 8); c:SetPoint(point, ox, -75)
    end
    cap("TOPLEFT", 38); cap("TOPRIGHT", -38)
    local d = Solid(f, "OVERLAY", GOLD[1], GOLD[2], GOLD[3], 1)
    d:SetSize(8, 8); d:SetPoint("TOP", 0, -73)
end

-- close button (gold X on dark wood) -----------------------------------------
local close = CreateFrame("Button", nil, f)
close:SetSize(22, 22)
close:SetPoint("TOPRIGHT", -16, -16)
local cbg = Solid(close, "BACKGROUND", WOOD[1], WOOD[2], WOOD[3], 1); cbg:SetAllPoints()
local cbrd = Solid(close, "BORDER", BRONZE[1], BRONZE[2], BRONZE[3], 1); cbrd:SetAllPoints()
local cin = Solid(close, "ARTWORK", WOOD[1], WOOD[2], WOOD[3], 1)
cin:SetPoint("TOPLEFT", 1, -1); cin:SetPoint("BOTTOMRIGHT", -1, 1)
local cx = close:CreateFontString(nil, "OVERLAY")
Font(cx, SCRIPT, 16); cx:SetAllPoints(); cx:SetText("X"); cx:SetTextColor(unpack(GOLD))
close:SetScript("OnEnter", function() cx:SetTextColor(unpack(GOLDHI)) end)
close:SetScript("OnLeave", function() cx:SetTextColor(unpack(GOLD)) end)
close:SetScript("OnClick", function() f:Hide() end)

-- medieval button factory (dark leather + bronze trim + gold script) ---------
local function MedButton(text, w)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(w or 90, 24)
    local bg = Solid(b, "BACKGROUND", WOOD[1], WOOD[2], WOOD[3], 1); bg:SetAllPoints()
    local function edge(p1, p2, horiz)
        local t = Solid(b, "BORDER", BRONZE[1], BRONZE[2], BRONZE[3], 1)
        if horiz then t:SetHeight(1) else t:SetWidth(1) end
        t:SetPoint(p1); t:SetPoint(p2)
    end
    edge("TOPLEFT", "TOPRIGHT", true); edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    edge("TOPLEFT", "BOTTOMLEFT", false); edge("TOPRIGHT", "BOTTOMRIGHT", false)
    local label = b:CreateFontString(nil, "OVERLAY")
    Font(label, SCRIPT, 15)
    label:SetPoint("CENTER", 0, 0)
    label:SetTextColor(unpack(GOLD))
    label:SetText(text)
    b:SetScript("OnEnter", function() bg:SetColorTexture(WOODHI[1], WOODHI[2], WOODHI[3], 1); label:SetTextColor(unpack(GOLDHI)) end)
    b:SetScript("OnLeave", function() bg:SetColorTexture(WOOD[1], WOOD[2], WOOD[3], 1); label:SetTextColor(unpack(GOLD)) end)
    b:SetScript("OnMouseDown", function() label:SetPoint("CENTER", 0, -1) end)
    b:SetScript("OnMouseUp", function() label:SetPoint("CENTER", 0, 0) end)
    return b
end

-- parchment-inset edit box ---------------------------------------------------
local function MedBox(w)
    local wrap = CreateFrame("Frame", nil, f)
    wrap:SetSize(w, 24)
    local bg = Solid(wrap, "BACKGROUND", 0.90, 0.82, 0.62, 1); bg:SetAllPoints()
    local function edge(p1, p2, horiz)
        local t = Solid(wrap, "BORDER", 0.35, 0.24, 0.12, 1)
        if horiz then t:SetHeight(1) else t:SetWidth(1) end
        t:SetPoint(p1); t:SetPoint(p2)
    end
    edge("TOPLEFT", "TOPRIGHT", true); edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    edge("TOPLEFT", "BOTTOMLEFT", false); edge("TOPRIGHT", "BOTTOMRIGHT", false)
    local eb = CreateFrame("EditBox", nil, wrap)
    eb:SetPoint("TOPLEFT", 5, -2); eb:SetPoint("BOTTOMRIGHT", -5, 2)
    eb:SetAutoFocus(false)
    Font(eb, NORM, 12)
    eb:SetTextColor(unpack(INK))
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    return wrap, eb
end

-- rule above the list
local listTop = Solid(f, "ARTWORK", BRONZE[1], BRONZE[2], BRONZE[3], 0.6)
listTop:SetHeight(1)
listTop:SetPoint("TOPLEFT", 30, -92)
listTop:SetPoint("TOPRIGHT", -30, -92)

-- scroll + rows --------------------------------------------------------------
local scroll = CreateFrame("ScrollFrame", "GrudgeLedgerScroll", f, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 28, -100)
scroll:SetPoint("BOTTOMRIGHT", -40, 112)
scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROWH, ns.Refresh)
end)

local rows = {}
for i = 1, ROWS do
    local r = CreateFrame("Frame", nil, f)
    r:SetSize(336, ROWH - 4)
    if i == 1 then
        r:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -2)
    else
        r:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
    end

    local line = Solid(r, "ARTWORK", 0.30, 0.20, 0.10, 0.25)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0); line:SetPoint("BOTTOMRIGHT", 0, 0)

    r.name = r:CreateFontString(nil, "OVERLAY")
    Font(r.name, SCRIPT, 17)
    r.name:SetTextColor(unpack(INKH))
    r.name:SetPoint("TOPLEFT", 4, -2)
    r.name:SetJustifyH("LEFT")

    r.reason = r:CreateFontString(nil, "OVERLAY")
    Font(r.reason, NORM, 11)
    r.reason:SetTextColor(unpack(INK))
    r.reason:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 1, -2)
    r.reason:SetWidth(295)
    r.reason:SetJustifyH("LEFT")
    if r.reason.SetWordWrap then r.reason:SetWordWrap(false) end

    r.del = CreateFrame("Button", nil, r)
    r.del:SetSize(20, 20)
    r.del:SetPoint("TOPRIGHT", 0, -4)
    local x = r.del:CreateFontString(nil, "OVERLAY")
    Font(x, SCRIPT, 17); x:SetAllPoints(); x:SetText("X"); x:SetTextColor(0.45, 0.10, 0.08)
    r.del:SetScript("OnEnter", function() x:SetTextColor(0.80, 0.14, 0.12) end)
    r.del:SetScript("OnLeave", function() x:SetTextColor(0.45, 0.10, 0.08) end)
    r.del:SetScript("OnClick", function() if r.disp then ns.Remove(r.disp) end end)

    r:Hide()
    rows[i] = r
end

-- add controls (bottom) ------------------------------------------------------
local nameLbl = f:CreateFontString(nil, "OVERLAY")
Font(nameLbl, SCRIPT, 13); nameLbl:SetTextColor(0.42, 0.28, 0.14)
nameLbl:SetPoint("BOTTOMLEFT", 28, 90); nameLbl:SetText("Name")

local nameWrap, nameBox = MedBox(120)
nameWrap:SetPoint("BOTTOMLEFT", 28, 68)

local reasonLbl = f:CreateFontString(nil, "OVERLAY")
Font(reasonLbl, SCRIPT, 13); reasonLbl:SetTextColor(0.42, 0.28, 0.14)
reasonLbl:SetPoint("BOTTOMLEFT", nameWrap, "TOPRIGHT", 12, 2); reasonLbl:SetText("Grievance")

local reasonWrap, reasonBox = MedBox(214)
reasonWrap:SetPoint("LEFT", nameWrap, "RIGHT", 12, 0)

local function DoAdd()
    local nm = nameBox:GetText()
    if not nm or nm:gsub("%s", "") == "" then
        if UnitExists("target") and UnitIsPlayer("target") then nm = UnitName("target") end
    end
    if nm and nm ~= "" then
        ns.Add(nm, reasonBox:GetText())
        nameBox:SetText(""); reasonBox:SetText("")
        nameBox:ClearFocus(); reasonBox:ClearFocus()
    else
        ns.Print("type a name or target a player first.")
    end
end
reasonBox:SetScript("OnEnterPressed", DoAdd)
nameBox:SetScript("OnEnterPressed", function() reasonBox:SetFocus() end)

local tgtBtn = MedButton("Target", 84)
tgtBtn:SetPoint("BOTTOMLEFT", 28, 36)
tgtBtn:SetScript("OnClick", function()
    if UnitExists("target") and UnitIsPlayer("target") then
        nameBox:SetText(UnitName("target")); reasonBox:SetFocus()
    else
        ns.Print("no player targeted.")
    end
end)

local addBtn = MedButton("Inscribe", 110)
addBtn:SetPoint("LEFT", tgtBtn, "RIGHT", 8, 0)
addBtn:SetScript("OnClick", DoAdd)

local clearBtn = MedButton("Burn Ledger", 110)
clearBtn:SetPoint("BOTTOMRIGHT", -28, 36)
clearBtn:SetScript("OnClick", function() StaticPopup_Show("GRUDGE_LEDGER_CLEAR") end)

-- refresh / toggle -----------------------------------------------------------
function ns.Refresh()
    if not f:IsShown() then return end
    local data = ns.List()
    local n = #data
    FauxScrollFrame_Update(scroll, n, ROWS, ROWH)
    local offset = FauxScrollFrame_GetOffset(scroll)
    for i = 1, ROWS do
        local e = data[i + offset]
        local r = rows[i]
        if e then
            r.disp = e.name
            r.name:SetText(e.name)
            r.reason:SetText((e.reason or "") .. "   |cff6b5a44\194\183 " .. (e.added or "") .. "|r")
            r:Show()
        else
            r.disp = nil
            r:Hide()
        end
    end
    if n == 0 then
        rows[1].disp = nil
        rows[1].name:SetText("")
        rows[1].reason:SetText("|cff6b5a44The page is blank. A rare mercy.|r")
        rows[1]:Show()
    end
end

function ns.Toggle()
    if f:IsShown() then f:Hide() else f:Show() end
end

f:SetScript("OnShow", function() ns.Refresh() end)

-- on-screen warning banner ---------------------------------------------------
local alert = CreateFrame("Frame", "GrudgeLedgerAlert", UIParent, backdrop)
alert:SetSize(340, 58)
alert:SetPoint("TOP", 0, -150)
alert:SetFrameStrata("FULLSCREEN_DIALOG")
alert:EnableMouse(false)
alert:Hide()

local abase = Solid(alert, "BACKGROUND", PARCH[1], PARCH[2], PARCH[3], 0.96); abase:SetAllPoints()
do
    local function e(p1, p2, horiz)
        local t = Solid(alert, "BORDER", WAX[1], WAX[2], WAX[3], 1)
        if horiz then t:SetHeight(2) else t:SetWidth(2) end
        t:SetPoint(p1); t:SetPoint(p2)
    end
    e("TOPLEFT", "TOPRIGHT", true); e("BOTTOMLEFT", "BOTTOMRIGHT", true)
    e("TOPLEFT", "BOTTOMLEFT", false); e("TOPRIGHT", "BOTTOMRIGHT", false)
end

local aTitle = alert:CreateFontString(nil, "OVERLAY")
Font(aTitle, SCRIPT, 19); aTitle:SetPoint("TOP", 0, -8); aTitle:SetTextColor(0.55, 0.11, 0.09)
local aSub = alert:CreateFontString(nil, "OVERLAY")
Font(aSub, NORM, 12); aSub:SetPoint("TOP", aTitle, "BOTTOM", 0, -3)
aSub:SetTextColor(unpack(INK)); aSub:SetWidth(322); aSub:SetJustifyH("CENTER")

local holdUntil = 0
alert:SetScript("OnUpdate", function(self, elapsed)
    if GetTime() >= holdUntil then
        local a = self:GetAlpha() - (elapsed / 1.2)
        if a <= 0 then self:Hide(); self:SetAlpha(1) else self:SetAlpha(a) end
    end
end)

function ns.Alert(name, reason, context)
    aTitle:SetText("! " .. (name or "?") .. " !")
    aSub:SetText("|cff8a2a26" .. (reason or "on your ledger") .. "|r   -   " .. (context or ""))
    alert:SetAlpha(1)
    holdUntil = GetTime() + 4
    alert:Show()
end

-- bottom-right "nearby" box (same parchment graphic) -------------------------
local prox = CreateFrame("Frame", "GrudgeLedgerProximity", UIParent, backdrop)
prox:SetSize(230, 96)
prox:SetPoint("BOTTOMRIGHT", -16, 180)
prox:SetFrameStrata("HIGH")
prox:SetClampedToScreen(true)
prox:SetMovable(true); prox:EnableMouse(true); prox:RegisterForDrag("LeftButton")
prox:SetScript("OnDragStart", prox.StartMoving)
prox:SetScript("OnDragStop", prox.StopMovingOrSizing)
prox:Hide()

local pbase = Solid(prox, "BACKGROUND", PARCH[1], PARCH[2], PARCH[3], 1)
pbase:SetPoint("TOPLEFT", 6, -6); pbase:SetPoint("BOTTOMRIGHT", -6, 6); pbase:SetDrawLayer("BACKGROUND", -8)
local pgrain = prox:CreateTexture(nil, "BACKGROUND")
pgrain:SetPoint("TOPLEFT", 6, -6); pgrain:SetPoint("BOTTOMRIGHT", -6, 6); pgrain:SetDrawLayer("BACKGROUND", -6)
pgrain:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
pgrain:SetVertexColor(0.92, 0.82, 0.60); pgrain:SetAlpha(0.6)
if prox.SetBackdrop then
    prox:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 22,
        insets = { left = 7, right = 8, top = 8, bottom = 7 } })
    prox:SetBackdropBorderColor(0.95, 0.88, 0.70)
else
    local function ln(p1, p2, horiz)
        local t = Solid(prox, "BORDER", BRONZE[1], BRONZE[2], BRONZE[3], 1)
        if horiz then t:SetHeight(2) else t:SetWidth(2) end
        t:SetPoint(p1); t:SetPoint(p2)
    end
    ln("TOPLEFT", "TOPRIGHT", true); ln("BOTTOMLEFT", "BOTTOMRIGHT", true)
    ln("TOPLEFT", "BOTTOMLEFT", false); ln("TOPRIGHT", "BOTTOMRIGHT", false)
end

local pHead = prox:CreateFontString(nil, "OVERLAY")
Font(pHead, SCRIPT, 16); pHead:SetPoint("TOP", 0, -11); pHead:SetTextColor(0.55, 0.11, 0.09)
pHead:SetText("Grudge Nearby")
local pRule = Solid(prox, "ARTWORK", BRONZE[1], BRONZE[2], BRONZE[3], 0.6)
pRule:SetHeight(1); pRule:SetPoint("TOPLEFT", 14, -30); pRule:SetPoint("TOPRIGHT", -14, -30)

local pRows = {}
for i = 1, 3 do
    local row = prox:CreateFontString(nil, "OVERLAY")
    Font(row, NORM, 11)
    row:SetPoint("TOPLEFT", 14, -34 - (i - 1) * 18)
    row:SetPoint("RIGHT", prox, "RIGHT", -12, 0)
    row:SetJustifyH("LEFT")
    if row.SetWordWrap then row:SetWordWrap(false) end
    pRows[i] = row
end
local pMore = prox:CreateFontString(nil, "OVERLAY")
Font(pMore, NORM, 10); pMore:SetPoint("BOTTOM", 0, 9); pMore:SetTextColor(0.42, 0.28, 0.14)

function ns.Proximity(entries)
    if not entries or #entries == 0 then prox:Hide(); return end
    table.sort(entries, function(a, b) return (a.name or "") < (b.name or "") end)
    local shown = math.min(#entries, 3)
    for i = 1, 3 do
        local e = entries[i]
        if e then
            pRows[i]:SetText("|cff8a1f1a" .. (e.name or "?") .. "|r  |cff3a2a18" .. (e.reason or "") .. "|r")
            pRows[i]:Show()
        else
            pRows[i]:SetText(""); pRows[i]:Hide()
        end
    end
    if #entries > 3 then pMore:SetText("+ " .. (#entries - 3) .. " more"); pMore:Show()
    else pMore:SetText(""); pMore:Hide() end
    prox:SetHeight(40 + shown * 18 + ((#entries > 3) and 14 or 6))
    prox:Show()
end
