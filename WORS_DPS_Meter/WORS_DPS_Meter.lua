-- Create the main frame
local frame = CreateFrame("Frame", "DPSFrame", UIParent)
frame:SetSize(130, 90)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface\\WORS\\OldSchoolBackground2",
    edgeFile = "Interface\\WORS\\OldSchool-Dialog-Border",
    tile = false, tileSize = 32, edgeSize = 32,
    insets = { left = 5, right = 6, top = 6, bottom = 5 }
})
frame:SetBackdropColor(0, 0, 0, 0.5) -- Background color (RGBA)
frame:SetBackdropBorderColor(1, 1, 1, 1) -- Border color (RGBA)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

-- Clamp the frame to the screen
frame:SetClampedToScreen(true)

-- Start moving the frame
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Define spacing for labels and values
local labelOffsetX = 10    -- Distance from left for labels
local valueOffsetX = -10    -- Distance from right for values
local valueLabelSpacing = 25 -- Vertical spacing between values

-- Text labels for displaying data
local dpsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dpsText:SetPoint("TOPLEFT", labelOffsetX, -10) -- Align to the left
dpsText:SetText("DPS:") -- Label for DPS

local dpsNumberText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dpsNumberText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", valueOffsetX, -10) -- Align DPS number to the right

local dpsTimerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dpsTimerText:SetPoint("TOP", frame, 0, -10) -- Center the timer text independently
dpsTimerText:SetText("0:00") -- Initialize with a placeholder for timer

local damageDoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageDoneText:SetPoint("TOPLEFT", dpsText, "BOTTOMLEFT", 0, -10) -- Align to the left
damageDoneText:SetText("Damage Done:") -- Label for Damage Done

local damageDoneNumberText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageDoneNumberText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", valueOffsetX, -10 - valueLabelSpacing) -- Align Damage Done number to the right

local damageTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageTakenText:SetPoint("TOPLEFT", damageDoneText, "BOTTOMLEFT", 0, -10) -- Align to the left
damageTakenText:SetText("Damage Taken:") -- Label for Damage Taken

local damageTakenNumberText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageTakenNumberText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", valueOffsetX, -10 - valueLabelSpacing * 2) -- Align Damage Taken number to the right

-- Variables to track damage and time
local totalDamageDone = 0
local totalDamageTaken = 0
local combatStartTime = GetTime()  -- Start tracking time from login
local dpsUpdateTimer = nil  -- Timer handle

-- Function to update the timer and DPS text continuously
local function updateDPS()
    local elapsedTime = GetTime() - combatStartTime
    local dps = elapsedTime > 0 and totalDamageDone / elapsedTime or 0
    local minutes = math.floor(elapsedTime / 60)
    local seconds = math.floor(elapsedTime % 60)
    dpsTimerText:SetText(string.format("%d:%02d", minutes, seconds)) -- Center aligned timer
    dpsNumberText:SetText(string.format("%.1f", dps)) -- Right-aligned DPS value
end

-- Function to reset damage data
local function resetDamageData()
    totalDamageDone = 0
    totalDamageTaken = 0
    damageTakenText:SetText("Damage Taken: ")
    damageTakenNumberText:SetText("0")
    damageDoneText:SetText("Damage Done: ")
    damageDoneNumberText:SetText("0")
    dpsText:SetText("DPS:") -- Reset timer display
    dpsNumberText:SetText("0.0") -- Reset DPS value
    dpsTimerText:SetText("0:00") -- Reset timer display
    print("Damage metrics have been reset.")
end

-- Event handling
frame:RegisterEvent("UNIT_HITSPLAT")

-- Debugging output to confirm event registration
print("DPS Meter addon loaded and registered for UNIT_HITSPLAT.")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_HITSPLAT" then
        local arg1, arg2, arg3 = ...
        local targetName = tostring(arg1)
        local damageType = tostring(arg2)		
        local damageAmount = tonumber(arg3) -- The actual damage amount
        -- Debug output to see the converted values
        print("UNIT_HITSPLAT Event Detected")
        print("Target Name (arg1):", targetName)
        print("Damage Type (arg2):", damageType)
        print("Damage Amount (arg3):", damageAmount)
        -- Check if this is relevant (damage done or taken)
        if targetName == "player" then
            -- Player took damage
            totalDamageTaken = totalDamageTaken + damageAmount
            damageTakenNumberText:SetText(totalDamageTaken) -- Update damage taken number
            print(string.format("Debug: %s took %d damage. Total Damage Taken: %d", targetName, damageAmount, totalDamageTaken))
        elseif targetName == "target" then
            -- Player dealt damage
            totalDamageDone = totalDamageDone + damageAmount
            damageDoneNumberText:SetText(totalDamageDone) -- Update damage done number
            print(string.format("Debug: %s dealt %d damage. Total Damage Done: %d", targetName, damageAmount, totalDamageDone))
        end
    --elseif event == "PLAYER_REGEN_DISABLED" then
    --elseif event == "PLAYER_REGEN_ENABLED" then
	end
end)

-- Start the DPS update timer to refresh every second
dpsUpdateTimer = C_Timer.NewTicker(1, updateDPS)  -- Update every second

-- Command handling for resetting data
SLASH_DPSRESET1 = "/dpsreset"
SlashCmdList["DPSRESET"] = resetDamageData
