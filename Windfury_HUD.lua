-- Windfury HUD + constants

Windfury_HUD = {}
Windfury_HUD.ClassColors = {
    DRUID = "FF7D0A",
    HUNTER = "A9D271",
    MAGE = "40C7EB",
    PRIEST = "FFFFFF",
    ROGUE = "FFF569",
    SHAMAN = "0070DE",
    WARLOCK = "8787ED",
    WARRIOR = "C79C6E",
}
Windfury_HUD.DefaultOptions = {
    HideAll = false,
    SelfTimerOnly = false,
    ShowPlayerNames = true,
    ShowRemainingTime = true,
    InCombatOnly = false
}
Windfury_HUD.IconNormal = {1, 1, 1, 1}
Windfury_HUD.IconRed = {1, 0, 0, 1}
Windfury_HUD.Debug = false
Windfury_HUD.PlayerName, _ = UnitName("player")
Windfury_HUD.Prefix = "Windfury_HUD"
Windfury_HUD.Realm = GetRealmName()
Windfury_HUD.VarsLoaded = false
Windfury_HUD.Version = GetAddOnMetadata("Windfury_HUD", "Version")
Windfury_HUD.VersionMap = {}
Windfury_HUD.WfStatus = {}
Windfury_HUD.WfStatusPrefix = "WF_STATUS"

-- Messaging

Windfury_HUD.GetVersionRequestMessage = "GET_VERSION_REQ"
Windfury_HUD.GetVersionResponseMessage = "GET_VERSION_RESP"

C_ChatInfo.RegisterAddonMessagePrefix(Windfury_HUD.Prefix)
C_ChatInfo.RegisterAddonMessagePrefix(Windfury_HUD.WfStatusPrefix)

-- Utility functions

function Windfury_HUD.SendMessage(msg, chan)
    C_ChatInfo.SendAddonMessage(Windfury_HUD.Prefix, msg, chan)
end

function Windfury_HUD.SendStatus()
    local _, expire, _, id = GetWeaponEnchantInfo()
    local _, _, lagHome, _ = GetNetStats()
    local guid = UnitGUID("player")
    if expire == nil then id = nil end
    local msg = guid .. ":" .. tostring(id) .. ":" .. tostring(expire) .. ":" .. lagHome
    C_ChatInfo.SendAddonMessage(Windfury_HUD.WfStatusPrefix, msg, "SAY")
end

function Windfury_HUD.GetVersionRequest(chan)
    Windfury_HUD.VersionMap = {}
    Windfury_HUD.SendMessage(Windfury_HUD.GetVersionRequestMessage, chan)
end

function Windfury_HUD.GetVersionResponse(chan)
    Windfury_HUD.SendMessage(Windfury_HUD.GetVersionResponseMessage .. ":" .. Windfury_HUD.Version, chan)
end

function Windfury_HUD.UpdateTimer()
    local minTime = 10
    local curr = GetTime()
    if Windfury_HUD.Config.SelfTimerOnly then
        local selfTime = Windfury_HUD.WfStatus[Windfury_HUD.PlayerName] or 0
        minTime = max(selfTime - curr, 0)
    else
        for p, t in pairs(Windfury_HUD.WfStatus) do
            minTime = max(min(minTime, t - curr), 0)
        end
    end
    Windfury_HUD.MinTime = minTime
end

function Windfury_HUD.GUIDToName(guid)
    local _, _, _, _, _, name = GetPlayerInfoByGUID(guid)
    return name
end

function Windfury_HUD.GetColorizedPlayerName(name)
    local _, class, _ = UnitClass(name)
    local color = Windfury_HUD.ClassColors[class]
    if GetTime() > Windfury_HUD.WfStatus[name] then color = "606060" end
    return "|cFF" .. color .. name
end

function Windfury_HUD.GetIconColor()
    local time = Windfury_HUD.MinTime
    if time == 0 then return .5, .5, .5, 1
    elseif time < 3 then
        local alpha = math.abs(.5 - math.fmod(time, 1)) + .5
        return 1, 1, 1, alpha
    else return 1, 1, 1, 1
    end
end

function Windfury_HUD.UpdateDuration()
    local remaining = ""
    local time = Windfury_HUD.MinTime
    if time > 0 and time < 10 then remaining = string.format("%.1fs", time) end
    Windfury_HUD_Duration:SetText(remaining)
end

function Windfury_HUD.UpdatePlayers()
    local players = ""
    for p, _ in pairs(Windfury_HUD.WfStatus) do
        players = players .. Windfury_HUD.GetColorizedPlayerName(p) .. "\n"
    end
    Windfury_HUD_PlayerList:SetText(players)
end

function Windfury_HUD.OpenOptions()
    InterfaceOptionsFrame_OpenToCategory(Windfury_HUD.Options)
end

-- Event Handlers

function Windfury_HUD.OnEvent(self, event, ...)
    if event == "CHAT_MSG_ADDON" then Windfury_HUD.OnMessageReceive(...)
    elseif event == "UNIT_INVENTORY_CHANGED" then Windfury_HUD.SendStatus()
    elseif event == "GROUP_ROSTER_UPDATE" then Windfury_HUD.OnGroupUpdate()
    elseif event == "VARIABLES_LOADED" then Windfury_HUD.OnVarsLoaded()
    end
end

function Windfury_HUD.OnMessageReceive(...)
    local prefix = select(1, ...)
    local msg = select(2, ...)
    local channel = select(3, ...)
    -- Handle WF Status Messages
    if prefix == Windfury_HUD.WfStatusPrefix then --and channel == "PARTY" then
        local guid, id, expire, lag1 = strsplit(":", msg)
        local name = Windfury_HUD.GUIDToName(guid)
        local _, _, lag2 = GetNetStats()
        local totalLag = (lag1 + lag2 * 2) / 1000
        if Windfury_HUD.Debug and Windfury_HUD.WfStatus[name] == nil then
            print(name .. " is using WF_STATUS protocol!")
        end
        if Windfury_HUD.Debug then
            print(name .. ": " .. msg)
        end
        if id == "564" then Windfury_HUD.WfStatus[name] = GetTime() + 10 - totalLag
        elseif id ~= "nil" then Windfury_HUD.WfStatus[name] = nil
        end
    -- Handle Windfury HUD Messages
    elseif prefix == Windfury_HUD.Prefix then
        local cmd, payload = strsplit(":", msg, 2)
        if cmd == Windfury_HUD.GetVersionRequestMessage then
            Windfury_HUD.GetVersionResponse(channel)
        elseif cmd == Windfury_HUD.GetVersionResponseMessage then
            local sender = select(4, ...)
            if Windfury_HUD.Debug then
                print(sender .. ":" .. payload)
            end
            Windfury_HUD.VersionMap[sender] = payload
        end
    end
end

function Windfury_HUD.OnGroupUpdate()
    local party = {}
    if UnitInParty("player") then
        for i=1,GetNumSubgroupMembers() do
            local name, _ = UnitName("party" .. i)
            party[name] = true
        end
        for p, _ in pairs(Windfury_HUD.WfStatus) do
            if party[p] == nil then
                Windfury_HUD.WfStatus[p] = nil
            end
        end
    else Windfury_HUD.WfStatus = {}
    end
    Windfury_HUD.SendStatus()
end

function Windfury_HUD.OnUpdate()
    Windfury_HUD.UpdateTimer()
    -- Main frame
    if Windfury_HUD.Options:IsVisible() and not Windfury_HUD.Config.HideAll then
        Windfury_HUD.Frame:Show()
        Windfury_HUD_PlayerList:SetText("Player1\nPlayer2\nPlayer3\nPlayer4\nPlayer5")
        Windfury_HUD_Duration:SetText("10s")
    elseif Windfury_HUD.Debug or (next(Windfury_HUD.WfStatus) and not Windfury_HUD.Config.HideAll and (not Windfury_HUD.Config.InCombatOnly or InCombatLockdown())) then
        Windfury_HUD.Frame:Show()
        local r, g, b, a = Windfury_HUD.GetIconColor()
        Windfury_HUD.Frame:SetBackdropColor(r, g, b, a)
        Windfury_HUD.UpdateDuration()
        Windfury_HUD.UpdatePlayers()
    else
        Windfury_HUD.Frame:Hide()
    end

    -- Player list
    if Windfury_HUD.Config.ShowPlayerNames then
        Windfury_HUD_PlayerList:Show()
    else
        Windfury_HUD_PlayerList:Hide()
    end

    -- Duration
    if Windfury_HUD.Config.ShowRemainingTime then
        Windfury_HUD_Duration:Show()
    else
        Windfury_HUD_Duration:Hide()
    end
end

function Windfury_HUD.OnMouseDown()
    if IsShiftKeyDown() then
        Windfury_HUD.Frame:StartMoving()
    elseif IsAltKeyDown() then
        Windfury_HUD.Resizing = true
        Windfury_HUD.Frame:StartSizing()
    elseif IsControlKeyDown() then
        Windfury_HUD.Frame:SetSize(64, 64)
        Windfury_HUD_Duration:SetScale(1)
        Windfury_HUD_PlayerList:SetScale(1)
    end
end

function Windfury_HUD.OnMouseUp()
    Windfury_HUD.Frame:StopMovingOrSizing()
    if Windfury_HUD.Resizing then
        local scale = Windfury_HUD.Frame:GetHeight() / 64
        Windfury_HUD.Frame:SetWidth(Windfury_HUD.Frame:GetHeight())
        Windfury_HUD_Duration:SetScale(scale)
        Windfury_HUD_PlayerList:SetScale(scale)
        Windfury_HUD.Resizing = false
    end
end

function Windfury_HUD.OnLoad(self, ...)
    if self:GetName() == "Windfury_HUD_Info" then
        Windfury_HUD.Frame = self
        Windfury_HUD.Frame:SetScript("OnEvent", Windfury_HUD.OnEvent)
        Windfury_HUD.Frame:RegisterEvent("CHAT_MSG_ADDON")
        Windfury_HUD.Frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
        Windfury_HUD.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
        Windfury_HUD.Frame:RegisterEvent("VARIABLES_LOADED")
    end
end

function Windfury_HUD.OnVarsLoaded()
    if not Windfury_HUD_Config then
        Windfury_HUD_Config = {}
    end
    if not Windfury_HUD_Config[Windfury_HUD.Realm] then
        Windfury_HUD_Config[Windfury_HUD.Realm] = {}
    end
    if not Windfury_HUD_Config[Windfury_HUD.Realm][Windfury_HUD.PlayerName] then
        Windfury_HUD_Config[Windfury_HUD.Realm][Windfury_HUD.PlayerName] = {}
    end
    Windfury_HUD.Config = Windfury_HUD_Config[Windfury_HUD.Realm][Windfury_HUD.PlayerName]
    for k, v in pairs(Windfury_HUD.DefaultOptions) do
        if not Windfury_HUD.Config[k] then Windfury_HUD.Config[k] = v end
    end
    Windfury_HUD.Options.Init()
    Windfury_HUD.VarsLoaded = true
end

SLASH_WINDFURYHUD1 = "/windfuryhud"
SLASH_WINDFURYHUD2 = "/wfhud"
SLASH_WINDFURYHUD3 = "/wfh"
SlashCmdList["WINDFURYHUD"] = function() Windfury_HUD.Options:Show() end
