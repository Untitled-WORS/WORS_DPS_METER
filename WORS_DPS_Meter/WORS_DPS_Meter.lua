-- Create the main frame
local frame = CreateFrame("Frame", "DPSFrame", UIParent)
frame:SetSize(160, 90)
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

-- Text labels for displaying data
local dpsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dpsText:SetPoint("TOPLEFT", 10, -10)
dpsText:SetText("DPS (0:00): 0.0") -- Updated to show time format

local damageDoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageDoneText:SetPoint("TOPLEFT", dpsText, "BOTTOMLEFT", 0, -10)
damageDoneText:SetText("Damage Done: 0")

local damageTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
damageTakenText:SetPoint("TOPLEFT", damageDoneText, "BOTTOMLEFT", 0, -10)
damageTakenText:SetText("Damage Taken: 0")

-- Variables to track damage and time
local totalDamageDone = 0
local totalDamageTaken = 0
local combatStartTime = 0
local dpsUpdateTimer = nil  -- Timer handle

-- Function to reset damage data
local function resetDamageData()
    totalDamageDone = 0
    totalDamageTaken = 0
    damageTakenText:SetText("Damage Taken: 0")
    damageDoneText:SetText("Damage Done: 0")
    dpsText:SetText("DPS (0:00): 0.0")
    print("Damage metrics have been reset.")
end

-- Function to update the DPS text continuously
local function updateDPS()
    local elapsedTime = GetTime() - combatStartTime
    local minutes = math.floor(elapsedTime / 60)
    local seconds = math.floor(elapsedTime % 60)
    local dps = elapsedTime > 0 and totalDamageDone / elapsedTime or 0
    dpsText:SetText(string.format("DPS (%d:%02d): %.1f", minutes, seconds, dps))
end

-- Event handling
frame:RegisterEvent("UNIT_HITSPLAT")
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Fires when entering combat
frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Fires when leaving combat

-- Debugging output to confirm event registration
print("DPS Meter addon loaded and registered for UNIT_HITSPLAT.")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_HITSPLAT" then
        local arg1, arg2, arg3 = ...

        -- Convert arguments to strings
        local targetName = tostring(arg1)
        local damageType = tostring(arg2)  -- Will be either damage or zero
        local damageAmount = tonumber(arg3) -- The actual damage amount
        -- Debug output to see the converted values
        print("UNIT_HITSPLAT Event Detected")
        print("Arg1: ", arg1, "-- target/player/nameplate..")  -- Log the raw value of arg1
        print("Arg2: ", arg2, "-- damage/zero/damage-max")
        print("Arg3: ", arg3, "-- damage amount")

        -- Check if this is relevant (damage done or taken)
        if targetName == "player" then
            -- Player took damage
            totalDamageTaken = totalDamageTaken + damageAmount
            damageTakenText:SetText("Damage Taken: " .. totalDamageTaken)
            print(string.format("Debug: %s took %d damage. Total Damage Taken: %d", targetName, damageAmount, totalDamageTaken))
        elseif targetName == "target" then
            -- Player dealt damage
            totalDamageDone = totalDamageDone + damageAmount
            damageDoneText:SetText("Damage Done: " .. totalDamageDone)
            print(string.format("Debug: %s dealt %d damage. Total Damage Done: %d", targetName, damageAmount, totalDamageDone))
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Start combat timer when entering combat
        combatStartTime = GetTime()
        updateDPS() -- Update immediately on entry
        if not dpsUpdateTimer then
            dpsUpdateTimer = C_Timer.NewTicker(1, updateDPS) -- Update every second
        end
        print("Debug: Entered combat. Combat timer started.")
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Stop the timer when leaving combat
        if dpsUpdateTimer then
            dpsUpdateTimer:Cancel()
            dpsUpdateTimer = nil
        end
        print("Debug: Exited combat. Combat timer stopped.")
    end
end)

-- Command handling for resetting data
SLASH_DPSRESET1 = "/dpsreset"
SlashCmdList["DPSRESET"] = resetDamageData