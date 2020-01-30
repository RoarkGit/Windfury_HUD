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
Windfury_HUD.Debug = true
Windfury_HUD.PlayerName, _ = UnitName("player")
Windfury_HUD.Prefix = "WF_STATUS"
Windfury_HUD.Realm = GetRealmName()
Windfury_HUD.VarsLoaded = false
Windfury_HUD.Version = "1.0"
Windfury_HUD.WfStatus = {}

C_ChatInfo.RegisterAddonMessagePrefix(Windfury_HUD.Prefix)

-- Utility functions

function Windfury_HUD.SendMessage(msg)
    C_ChatInfo.SendAddonMessage(Windfury_HUD.Prefix, msg, "PARTY")
end

function Windfury_HUD.SendStatus()
    local _, expire, _, id = GetWeaponEnchantInfo()
    local _, _, lagHome, _ = GetNetStats()
    local guid = UnitGUID("player")
    if expire == nil then id = nil end
    local msg = guid .. ":" .. tostring(id) .. ":" .. tostring(expire) .. ":" .. lagHome
    Windfury_HUD.SendMessage(msg)
end

function Windfury_HUD.UpdateTimer()
    local minTime = 10
    local curr = GetTime()
    if Windfury_HUD.Config.SelfTimerOnly then
        minTime = max(Windfury_HUD.WfStatus[Windfury_HUD.PlayerName] - curr, 0)
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
    --if Windfury_HUD.Windfury_HUD["Windfury_HUDTimerOnly"] and Windfury_HUD.WfStatus[Windfury_HUD.name] then time = max(Windfury_HUD.WfStatus[Windfury_HUD.Name] - GetTime(), 0) end
    if time == 0 then return .5, .5, .5, 1
    elseif time < 3 then
        local alpha = math.abs(.5 - math.fmod(time, 1)) + .5
        return 1, 1, 1, alpha
    else return 1, 1, 1, 1
    end
end

function Windfury_HUD.UpdateDuration()
    local remaining = ""
    if Windfury_HUD.Config.ShowRemainingTime then
        local time = Windfury_HUD.MinTime
        if time > 0 and time < 10 then remaining = string.format("%.1fs", time) end
    end
    Windfury_HUD_Duration:SetText(remaining)
end

function Windfury_HUD.UpdatePlayers()
    local players = ""
    if Windfury_HUD.Config.ShowPlayerNames then
        for p, _ in pairs(Windfury_HUD.WfStatus) do
            players = players .. Windfury_HUD.GetColorizedPlayerName(p) .. "\n"
        end
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
    local channel = select(3, ...)
    if prefix == Windfury_HUD.Prefix and channel == "PARTY" then
        local msg = select(2, ...)
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
        if id == "564" then Windfury_HUD.WfStatus[name] =  GetTime() + 10 - totalLag end
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
    if next(Windfury_HUD.WfStatus) and not Windfury_HUD.Config.HideAll and (not Windfury_HUD.Config.InCombatOnly or InCombatLockdown()) then
        Windfury_HUD.Frame:Show()
        local r, g, b, a = Windfury_HUD.GetIconColor()
        Windfury_HUD.Frame:SetBackdropColor(r, g, b, a)
        Windfury_HUD.UpdateDuration()
        Windfury_HUD.UpdatePlayers()
    else
        Windfury_HUD.Frame:Hide()
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
    elseif self:GetName() == "Windfury_HUD_Options_Frame" then
        Windfury_HUD.Options = self
        self.name = "Windfury HUD"
        self.okay = Windfury_HUD.OptionsOkay
        InterfaceOptions_AddCategory(self)
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
    if not Windfury_HUD.Config.HideAll then Windfury_HUD.Config.HideAll = Windfury_HUD.DefaultOptions.HideAll end
    if not Windfury_HUD.Config.SelfTimerOnly then Windfury_HUD.Config.SelfTimerOnly = Windfury_HUD.DefaultOptions.SelfTimerOnly end
    if not Windfury_HUD.Config.ShowPlayerNames then Windfury_HUD.Config.ShowPlayerNames = Windfury_HUD.DefaultOptions.ShowPlayerNames end
    if not Windfury_HUD.Config.ShowRemainingTime then Windfury_HUD.Config.ShowRemainingTime = Windfury_HUD.DefaultOptions.ShowRemainingTime end
    if not Windfury_HUD.Config.InCombatOnly then Windfury_HUD.Config.InCombatOnly = Windfury_HUD.DefaultOptions.InCombatOnly end
    Windfury_HUD_Options_Frame_HideAllBtn:SetChecked(Windfury_HUD.Config.HideAll)
    Windfury_HUD_Options_Frame_SelfTimerOnlyBtn:SetChecked(Windfury_HUD.Config.SelfTimerOnly)
    Windfury_HUD_Options_Frame_ShowPlayerNamesBtn:SetChecked(Windfury_HUD.Config.ShowPlayerNames)
    Windfury_HUD_Options_Frame_ShowRemainingTimeBtn:SetChecked(Windfury_HUD.Config.ShowRemainingTime)
    Windfury_HUD_Options_Frame_InCombatOnlyBtn:SetChecked(Windfury_HUD.Config.InCombatOnly)
    Windfury_HUD.VarsLoaded = true
end

SLASH_WINDFURYHUD1 = "/windfuryhud"
SLASH_WINDFURYHUD2 = "/wfhud"
SLASH_WINDFURYHUD3 = "/wfh"
SlashCmdList["WINDFURYHUD"] = function() Windfury_HUD.Options:Show() end
