local autologinActive = false
local AutologinLoopFrame = CreateFrame("Frame")
local checkInterval = 0.2 -- 200 ms
local elapsedSinceLastCheck = 0

local lastGlueDialogErrorText = nil


-- Cannot find a way to hook the GlueDialog Error text directly, so we use a secure hook
hooksecurefunc("GlueDialog_Show", function(which, text)
    if text and text ~= "" then
        lastGlueDialogErrorText = text
    end
end)

local function IsOnLoginScreen()
    -- Replace with your actual check if needed
    return GlueParent and GlueParent:IsShown()
end

local function Autologin_OnUpdate(self, elapsed)

    -- Reseting lastGlueDialogText if GlueDialog is not shown
    if lastGlueDialogErrorText ~= nil and (not GlueDialog or not GlueDialog:IsShown()) then
        lastGlueDialogErrorText = nil
    end

    elapsedSinceLastCheck = elapsedSinceLastCheck + elapsed
    if elapsedSinceLastCheck >= checkInterval then
        elapsedSinceLastCheck = 0

        -- User Stoped Autologin
        if not autologinActive then
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Check if we are still on the login screen
        if not IsOnLoginScreen() then
            AutologinStatusText:SetText("Not on login screen!")
            autologinActive = false
            AutologinRetryButton:SetText("Autologin START")
            self:SetScript("OnUpdate", nil)

            AutologinStatusBox:SetBackdropColor(1.0, 0.0, 0.0, 1.0)  -- Red (R, G, B, Alpha)
            -- Play alarm sound to indicate we are not on the login screen
            PlayAlarm()

            return
        end




        if GlueDialog and GlueDialog:IsShown() then
            local dialogType = GlueDialog.which or "UNKNOWN"
            -- If GlueDialog is shown, we assume we are in a dialog state
            AutologinStatusText:SetText("Type: " .. dialogType .. " | Text: " .. (GlueDialogText:GetText() or "NO TEXT"))

            if dialogType == "CANCEL" then
                AutologinStatusText:SetText("Type: " .. dialogType .. " | Text: " .. (GlueDialogText:GetText() or "NO TEXT"))



            elseif dialogType == "CONNECTION_HELP_HTML" then
                AutologinStatusText:SetText("Type: " .. dialogType .. " | Text: " .. lastGlueDialogErrorText or "NO ERROR")
                               
                
                -- Click the OK button for HTML dialog
                if GlueDialogButton2
                    and GlueDialogButton2:IsShown()
                    and GlueDialogButton2:IsVisible()
                    and GlueDialogButton2:IsEnabled()
                then
                    GlueDialogButton2:Click()
                end

            else
                AutologinStatusText:SetText("UNKNOWN Type: " .. dialogType .. " | Text: " .. (GlueDialogText:GetText() .. "| ERROR:" .. lastGlueDialogErrorText or "NO TEXT"))
                AutologinStatusBox:SetBackdropColor(1.0, 0.0, 0.0, 1.0)  -- Red (R, G, B, Alpha)

                -- Play alarm sound for unknown dialog types
                PlayAlarm()
            end


        elseif RealmQueueFrame and RealmQueueFrame:IsShown() then
            local status = RealmQueueStatusText:GetText() or "No position"
            local eta = RealmQueueEstimate:GetText() or "No ETA"
            AutologinStatusText:SetText("In queue: " .. status .. " | ETA: " .. eta)


        else
            AutologinStatusText:SetText("Status: Running")
            if AccountLoginLoginButton 
                and AccountLoginLoginButton:IsShown()
                and AccountLoginLoginButton:IsVisible()
                and AccountLoginLoginButton:IsEnabled() then

                AutologinStatusText:SetText("Attempting login...")
                AccountLoginLoginButton:Click()
            end
        end

    end
end

lastAlarmTime = 0
function PlayAlarm()
        -- Only play alarm if enough time has passed
    local alarmCooldown = 1 -- seconds
    local currentTime = GetTime()
    if (currentTime - lastAlarmTime) > alarmCooldown then
        PlaySoundFile("Interface\\GlueXML\\Sounds\\alarm.wav")
        lastAlarmTime = currentTime
    end
end


function Autologin()
    autologinActive = not autologinActive

    if autologinActive then
        AutologinRetryButton:SetText("Autologin STOP")
        AutologinStatusText:SetText("Status: Running")
        elapsedSinceLastCheck = 0
        AutologinLoopFrame:SetScript("OnUpdate", Autologin_OnUpdate)

        -- Change status box to yellow when script starts
        AutologinStatusBox:SetBackdropColor(1.0, 1.0, 0.0, 1.0)  -- Yellow (R, G, B, Alpha)
    else
        AutologinRetryButton:SetText("Autologin START")
        AutologinStatusText:SetText("Status: Idle")
        AutologinLoopFrame:SetScript("OnUpdate", nil)

        AutologinStatusBox:SetBackdropColor(1.0, 1.0, 1.0, 1.0)  -- White (R, G, B, Alpha)
    end
end