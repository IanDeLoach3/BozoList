local ADDON, ns = ...

-- Saved data -----------------------------------------------------------------
BozoListDB = BozoListDB or {}

local function DB()
    local db = BozoListDB
    db.entries = db.entries or {}
    db.settings = db.settings or {}
    local s = db.settings
    if s.warnTarget   == nil then s.warnTarget   = true end
    if s.warnMouseover== nil then s.warnMouseover= true end
    if s.warnWhisper  == nil then s.warnWhisper  = true end
    if s.warnGroup    == nil then s.warnGroup    = true end
    if s.warnProximity== nil then s.warnProximity= true end
    if s.sound        == nil then s.sound        = true end
    return db
end
ns.DB = DB

-- Forever uses a TWO-NAME system ("First Last"), so names contain a space.
-- Normalize: drop a trailing cross-realm "-Realm" only (keeps "Mary-Jane Smith"),
-- collapse inner whitespace, trim. Keeps both names intact.
local function Normalize(name)
    if not name or name == "" then return nil end
    name = name:gsub("%-[^%s%-]+$", "")        -- remove a trailing -Realm, nothing else
    name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end
ns.Normalize = Normalize

local function Key(name)
    local n = Normalize(name)
    return n and n:lower() or nil
end

local function Stamp()
    return (date and date("%Y-%m-%d")) or ""
end

local INK = "|cffb22222"      -- ink-red header
local function P(text)
    (DEFAULT_CHAT_FRAME or ChatFrame1):AddMessage(INK .. "Bozo List:|r " .. (text or ""))
end
ns.Print = P

-- Data ops -------------------------------------------------------------------
function ns.Add(name, reason)
    local key = Key(name)
    if not key then return false, "No name given." end
    local display = Normalize(name)
    DB().entries[key] = {
        name   = display,
        reason = (reason and reason:gsub("%s*$", "") ~= "") and reason or "No reason given",
        added  = Stamp(),
        by     = UnitName and UnitName("player") or "",
    }
    if ns.Refresh then ns.Refresh() end
    return true, display
end

function ns.Remove(name)
    local key = Key(name)
    if key and DB().entries[key] then
        local d = DB().entries[key].name
        DB().entries[key] = nil
        if ns.Refresh then ns.Refresh() end
        return true, d
    end
    return false
end

function ns.Has(name)
    local key = Key(name)
    if not key then return nil end
    local e = DB().entries[key]
    if e then return e end
    -- forgiving: a detected full "First Last" also matches an entry saved as
    -- just "First" (so you can blacklist by first name alone if you want).
    local first = key:match("^(%S+)")
    if first and first ~= key and DB().entries[first] then
        return DB().entries[first]
    end
    return nil
end

function ns.List()
    local t = {}
    for _, v in pairs(DB().entries) do t[#t + 1] = v end
    table.sort(t, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    return t
end

-- Warnings -------------------------------------------------------------------
local function Ding()
    if not DB().settings.sound or not PlaySound then return end
    if SOUNDKIT then
        pcall(PlaySound, SOUNDKIT.IG_QUEST_FAILED or SOUNDKIT.RAID_WARNING)
    else
        pcall(PlaySound, "igQuestFailed")
    end
end

local lastWarn = {}
local function Check(name, context)
    if not name then return end
    local e = ns.Has(name)
    if not e then return end
    local k = name:lower()
    local now = GetTime and GetTime() or 0
    if lastWarn[k] and (now - lastWarn[k]) < 15 then return end
    lastWarn[k] = now
    P("|cffd4b483" .. e.name .. "|r is in your ledger  |cff9a7b55(" .. (e.reason or "") .. " - " .. context .. ")|r")
    Ding()
    if ns.Alert then ns.Alert(e.name, e.reason, context) end
    if RaidNotice_AddMessage and RaidWarningFrame then
        local color = (ChatTypeInfo and ChatTypeInfo["RAID_WARNING"]) or { r = 0.8, g = 0.2, b = 0.1 }
        pcall(RaidNotice_AddMessage, RaidWarningFrame, e.name .. " - " .. (e.reason or "on your ledger"), color)
    end
end
ns.Check = Check

local function ScanGroup()
    if not DB().settings.warnGroup then return end
    local raid = (GetNumRaidMembers and GetNumRaidMembers())
        or (IsInRaid and IsInRaid() and GetNumGroupMembers and GetNumGroupMembers()) or 0
    if raid and raid > 0 then
        for i = 1, raid do
            local u = "raid" .. i
            if UnitExists(u) then Check(UnitName(u), "in your raid") end
        end
        return
    end
    local party = (GetNumPartyMembers and GetNumPartyMembers())
        or (GetNumSubgroupMembers and GetNumSubgroupMembers()) or 0
    for i = 1, party do
        local u = "party" .. i
        if UnitExists(u) then Check(UnitName(u), "in your party") end
    end
end

-- Proximity: scan the actual nameplate frames under WorldFrame ---------------
-- (NAME_PLATE_UNIT_ADDED does not exist on vanilla 1.60.1, so we read the real
--  nameplate frames instead. Requires nameplates to be ON -- press V / enable
--  friendly-player nameplates in Interface options.)
local nearByName = {}   -- lowerName -> { name, reason }

local function RefreshProximity()
    if not ns.Proximity then return end
    local list = {}
    for _, v in pairs(nearByName) do list[#list + 1] = v end
    ns.Proximity(list)
end
ns.ClearProximity = function() wipe(nearByName); RefreshProximity() end

local function isNameplate(frame)
    if not frame or frame:GetName() then return false end
    if not frame.IsShown or not frame:IsShown() then return false end
    if frame.GetNumChildren and frame:GetNumChildren() >= 1 then
        local bar = select(1, frame:GetChildren())
        if bar and bar.GetObjectType and bar:GetObjectType() == "StatusBar" then
            return true
        end
    end
    return false
end

local function plateName(frame)
    if not frame.GetNumRegions then return nil end
    for i = 1, frame:GetNumRegions() do
        local r = select(i, frame:GetRegions())
        if r and r.GetObjectType and r:GetObjectType() == "FontString" then
            local t = r:GetText()
            -- skip the level number; keep the full name incl. the surname/space
            if t and t ~= "" and not t:find("^%d+$") then
                return (t:gsub("^%s+", ""):gsub("%s+$", ""))
            end
        end
    end
    return nil
end

-- returns (nameplatesFound, {lowerName = {name,reason}}); debugCB(name) optional
local function ScanNameplates(debugCB)
    local found, matched = 0, {}
    if WorldFrame and WorldFrame.GetChildren then
        local kids = { WorldFrame:GetChildren() }
        for _, child in ipairs(kids) do
            if isNameplate(child) then
                found = found + 1
                local nm = plateName(child)
                if nm then
                    if debugCB then debugCB(nm) end
                    local e = ns.Has(nm)
                    if e then matched[nm:lower()] = { name = e.name, reason = e.reason } end
                end
            end
        end
    end
    return found, matched
end
ns.ScanNameplates = ScanNameplates

local scanner = CreateFrame("Frame")
local scanAcc = 0
scanner:SetScript("OnUpdate", function(self, elapsed)
    scanAcc = scanAcc + elapsed
    if scanAcc < 0.4 then return end
    scanAcc = 0
    if not DB().settings.warnProximity then return end
    if not next(DB().entries) then
        if next(nearByName) then wipe(nearByName); RefreshProximity() end
        return
    end
    local _, matched = ScanNameplates(nil)
    -- fire a one-time alert for anyone newly in range
    for key, v in pairs(matched) do
        if not nearByName[key] then Check(v.name, "nearby") end
    end
    -- rebuild the near set only if it actually changed
    local changed = false
    for key in pairs(nearByName) do if not matched[key] then changed = true break end end
    if not changed then
        for key in pairs(matched) do if not nearByName[key] then changed = true break end end
    end
    if changed then
        wipe(nearByName)
        for key, v in pairs(matched) do nearByName[key] = v end
        RefreshProximity()
    end
end)

-- Events ---------------------------------------------------------------------
local ev = CreateFrame("Frame")
local function reg(e) pcall(ev.RegisterEvent, ev, e) end
reg("PLAYER_LOGIN")
reg("PLAYER_TARGET_CHANGED")
reg("UPDATE_MOUSEOVER_UNIT")
reg("CHAT_MSG_WHISPER")
reg("PARTY_MEMBERS_CHANGED")   -- classic
reg("RAID_ROSTER_UPDATE")      -- classic
reg("GROUP_ROSTER_UPDATE")     -- modern (pcall guards if unknown)

ev:SetScript("OnEvent", function(self, event, ...)
    local s = DB().settings
    if event == "PLAYER_LOGIN" then
        local n = 0
        for _ in pairs(DB().entries) do n = n + 1 end
        P("ledger loaded \226\128\148 " .. n .. " name" .. (n == 1 and "" or "s") .. " recorded.  |cff9a7b55/bl|r to open.")
    elseif event == "PLAYER_TARGET_CHANGED" then
        if s.warnTarget and UnitExists("target") and UnitIsPlayer("target") then
            Check(UnitName("target"), "targeted")
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        if s.warnMouseover and UnitExists("mouseover") and UnitIsPlayer("mouseover") then
            Check(UnitName("mouseover"), "nearby")
        end
    elseif event == "CHAT_MSG_WHISPER" then
        if s.warnWhisper then
            local _, sender = ...
            if sender then Check(sender:match("^([^%-]+)") or sender, "whispered you") end
        end
    else -- any roster update
        ScanGroup()
    end
end)

-- Flag blacklisted whispers right on the message in chat ---------------------
if ChatFrame_AddMessageEventFilter then
    local function whisperFilter(self, event, msg, author, ...)
        local e = author and ns.Has(author)
        if e then
            local why = e.reason or "on your ledger"
            if #why > 28 then why = why:sub(1, 27) .. "..." end
            return false, "|cffcc2222[BOZO: " .. why .. "]|r " .. (msg or ""), author, ...
        end
        return false
    end
    pcall(ChatFrame_AddMessageEventFilter, "CHAT_MSG_WHISPER", whisperFilter)
end

-- Slash commands -------------------------------------------------------------
StaticPopupDialogs["BOZOLIST_CLEAR"] = {
    text = "Burn the entire Bozo List?\nEvery name is lost for good.",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function()
        BozoListDB.entries = {}
        if ns.Refresh then ns.Refresh() end
        P("the ledger is ash. A clean page.")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

SLASH_BOZOLIST1 = "/bl"
SLASH_BOZOLIST2 = "/bozo"
SLASH_BOZOLIST3 = "/blacklist"
SlashCmdList["BOZOLIST"] = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()

    if cmd == "add" then
        local nm, reason
        local qn, qr = rest:match('^"([^"]+)"%s*(.-)$')   -- "First Last" reason
        if qn then
            nm, reason = qn, qr
        else
            nm, reason = rest:match("^(%S+)%s*(.-)$")       -- SingleName reason
        end
        if not nm or nm == "" then
            if UnitExists("target") and UnitIsPlayer("target") then nm = UnitName("target") end
        end
        local ok, d = ns.Add(nm, reason)
        P(ok and ("inscribed |cffd4b483" .. d .. "|r.")
            or "give a name, or target a player. Two-part names need quotes: |cff9a7b55/bl add \"First Last\" reason|r")
    elseif cmd == "remove" or cmd == "rem" or cmd == "del" then
        local ok, d = ns.Remove(rest)
        P(ok and ("struck |cffd4b483" .. (d or rest) .. "|r from the ledger.") or "that name isn't in the ledger.")
    elseif cmd == "clear" then
        StaticPopup_Show("BOZOLIST_CLEAR")
    elseif cmd == "sound" then
        local s = DB().settings; s.sound = not s.sound
        P("warning sound " .. (s.sound and "on." or "off."))
    elseif cmd == "prox" or cmd == "proximity" or cmd == "nearby" then
        local s = DB().settings; s.warnProximity = not s.warnProximity
        if not s.warnProximity and ns.ClearProximity then ns.ClearProximity() end
        P("nearby pop-up " .. (s.warnProximity and "on." or "off."))
    elseif cmd == "scan" then
        local names = {}
        local found = ns.ScanNameplates and ns.ScanNameplates(function(nm) names[#names + 1] = nm end) or 0
        P("nameplates detected: |cffd4b483" .. found .. "|r")
        if names[1] then
            P("names read: " .. table.concat(names, ", "))
        else
            P("no names read \226\128\148 turn nameplates |cffd4b483ON|r (press V, and enable Friendly Players in Interface > Names), then stand near someone and /bl scan again.")
        end
    elseif cmd == "help" or cmd == "?" then
        P("commands:")
        P("  |cff9a7b55/bl|r \226\128\148 open the ledger")
        P("  |cff9a7b55/bl add <name> <reason>|r \226\128\148 (no name = your target)")
        P("     two-part names need quotes: |cff9a7b55/bl add \"First Last\" reason|r")
        P("  |cff9a7b55/bl remove <name>|r \226\128\148 full name, e.g. First Last")
        P("  |cff9a7b55/bl clear|r \226\128\148 wipe the ledger")
        P("  |cff9a7b55/bl sound|r \226\128\148 toggle the warning sound")
        P("  |cff9a7b55/bl prox|r \226\128\148 toggle the bottom-right nearby pop-up")
    else
        if ns.Toggle then ns.Toggle() else P("UI not loaded.") end
    end
end
