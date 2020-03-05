Windfury_HUD.Options = CreateFrame("Frame", "Windfury_HUD_Options_Frame")
Windfury_HUD.Options:Hide()

function Windfury_HUD.Options.Init()
    Windfury_HUD.Options.ButtonConfig = {
        {"SelfTimerOnly", "Self timer only", "Only show remaining time for own Windfury buff"},
        {"ShowPlayerNames", "Show player names", nil},
        {"ShowRemainingTime", "Show remaining time", "Show remaining time on Windfury buff"},
        {"ShowMeleeOnly", "Show melee only", "Only shows rogues and warriors on HUD."},
        {"InCombatOnly", "Show in combat only", "Only show display when in combat"},
        {"HideAll", "Hide all displays", nil},
        {"InvertDisplay", "Invert display", "Only show display when Windfury is missing on players"}
    }
    Windfury_HUD.Options:SetFrameStrata("DIALOG")
    Windfury_HUD.Options:SetWidth(300)
    Windfury_HUD.Options:SetPoint("CENTER")
    Windfury_HUD.Options:SetMovable(true)
    Windfury_HUD.Options:EnableMouse(true)
    Windfury_HUD.Options:SetScript("OnMouseDown", function(self) self:StartMoving() end)
    Windfury_HUD.Options:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
    Windfury_HUD.Options:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = "true",
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 11, right = 12, top = 12, bottom = 11},
    })
    local headerBg = Windfury_HUD.Options:CreateTexture(nil, "ARTWORK")
    headerBg:SetTexture("Interface/DialogFrame/UI-DialogBox-Header")
    headerBg:SetSize(250, 64)
    headerBg:SetPoint("TOP", 0, 15)
    local headerText = Windfury_HUD.Options:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetText("Windfury HUD")
    headerText:SetPoint("TOP")

    Windfury_HUD.Options.AddButtons()
    local closeBtn = CreateFrame("Button", nil, Windfury_HUD.Options, "OptionsButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", -15, 16)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function(self) Windfury_HUD.Options:Hide() end)
end

function Windfury_HUD.Options.SetOption(self)
    Windfury_HUD.Config[self.key] = self:GetChecked()
end

function Windfury_HUD.Options.CreateCheckButton(x, y, key, text, tooltipText)
    local name = key .. "Btn"
    checkBtn = CreateFrame("CheckButton", name, Windfury_HUD.Options, "OptionsCheckButtonTemplate")
    checkBtn:SetPoint("TOPLEFT", x, y)
    checkBtn:SetScript("OnClick", Windfury_HUD.Options.SetOption)
    _G[name .. "Text"]:SetText(text)
    checkBtn.tooltipText = tooltipText
    checkBtn.key = key
    checkBtn:SetChecked(Windfury_HUD.Config[key])
end

function Windfury_HUD.Options.AddButtons()
    local x, y = 20, -20
    local count = 0
    for _, btn in pairs(Windfury_HUD.Options.ButtonConfig) do
        local key, text, tooltipText = unpack(btn)
        count = count + 1
        Windfury_HUD.Options.CreateCheckButton(x, y, key, text, tooltipText)
        y = y - 30
    end
    Windfury_HUD.Options:SetHeight(40 + count * 30)
end
