-- Allow glow of tab target to be bigger, and aoe brightness to be increased beyond normal limits
ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].showValueMax = 2000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].maxValue = 20
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].showValueMax = 2000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].maxValue = 20

local CUSTOM_MAX_LATENCY = 9999
local HIGH_LATENCY = 300
local MEDIUM_LATENCY = 200
local LOW_LATENCY = 0
local LATENCY_ICONS = {
    [HIGH_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_lowPop.dds", color = ZO_ERROR_COLOR },
    [MEDIUM_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_medPop.dds", color = ZO_SELECTED_TEXT },
    [LOW_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_hiPop.dds", color = ZO_SELECTED_TEXT }
}

local origPithkaFunction
local origRaidificatorFunction

function OnAddOnLoaded(_, name)
    if name ~= "Ricing" then return end
    EVENT_MANAGER:UnregisterForEvent("Ricing", EVENT_ADD_ON_LOADED)

    local controlsToHide = {
        ZO_FocusedQuestTrackerPanel,
        ZO_CompassFrameLeft,
        ZO_CompassFrameCenter,
        ZO_CompassFrameRight,
        ZO_CompassFrame,
        ZO_PerformanceMetersBg,
        ZO_ChatWindowMinBarBG,
        ZO_ChatWindowNumNotifications,
        ZO_ChatWindowNumOnlineFriends,
        ZO_ChatWindowNumUnreadMail,
        ZO_ChatWindowMail,
        ZO_ChatWindowNotifications,
        ZO_ChatWindowFriends,
        ZO_ChatWindowMinBarMaximize,
        ZO_MainMenuCategoryBar,
        ZO_MainMenuCategoryBarButton1Image,
        ZO_MainMenuCategoryBarButton1RemainingCrowns,
        ZO_MainMenuCategoryBarButton2Image,
        ZO_MainMenuCategoryBarPaddingBar1Image,
        ZO_MainMenuCategoryBarButton3Image,
        ZO_MainMenuCategoryBarButton4Image,
        ZO_MainMenuCategoryBarButton5Image,
        ZO_MainMenuCategoryBarButton6Image,
        ZO_MainMenuCategoryBarButton7Image,
        ZO_MainMenuCategoryBarButton8Image,
        ZO_MainMenuCategoryBarButton9Image,
        ZO_MainMenuCategoryBarButton10Image,
        ZO_MainMenuCategoryBarButton11Image,
        ZO_MainMenuCategoryBarButton12Image,
        ZO_MainMenuCategoryBarButton13Image,
        ZO_MainMenuCategoryBarButton14Image,
        ZO_MainMenuCategoryBarButton15Image,
        ZO_MainMenuCategoryBarButton16Image,
        ZO_MainMenuCategoryBarButton17Image,
        ZO_MainMenuCategoryBarButton18Image,
        ZO_MainMenuCategoryBarButton1Image,
        ZO_TopBarBackground,
        ZO_BottomBarBackground,
        ZO_KeybindStripMungeBackgroundTexture,
    }

    local controlsToDisappear = {
        ZO_KeybindStripMungeBackgroundTexture,
    }

    for _, control in ipairs(controlsToHide) do -- Hide various default UI elements
        control:SetHidden(true)
    end

    for _, control in ipairs(controlsToDisappear) do 
        control:SetTexture("")
        control:SetColor(0,0,0,0)
    end

    ZO_PlayerProgressLevelTypeIcon:SetWidth(0) -- Hide icon

    ZO_PreHook(PERFORMANCE_METERS, "SetLatency", function(self, latency) -- Fix latency to be useful for OCE players
        if latency > CUSTOM_MAX_LATENCY then
            latency = CUSTOM_MAX_LATENCY
        end
        local overMaxLabel
        if latency == CUSTOM_MAX_LATENCY then
            overMaxLabel = zo_strformat(SI_LATENCY_EXTREME_FORMAT, latency)
        end
    
        if overMaxLabel then
            self.latencyLabel:SetText(overMaxLabel)
        else
            self.latencyLabel:SetText(latency)
        end
        local threshold = LOW_LATENCY
        if latency >= MEDIUM_LATENCY then
            threshold = (latency >= HIGH_LATENCY) and HIGH_LATENCY or MEDIUM_LATENCY
        end
        if self.previousLatencyThreshold ~= threshold then
            local icon = LATENCY_ICONS[threshold]
            self.latencyBars:SetTexture(icon.image)
            self.latencyBars:SetColor(icon.color:UnpackRGBA())
            self.latencyLabel:SetColor(icon.color:UnpackRGBA())
            self.previousLatencyThreshold = threshold
        end
        return true
    end)

    STUB_SETTING_KEEP_MINIMIZED = true -- Keep chat minimised unless opened by the player
    SecurePostHook(KEYBOARD_CHAT_SYSTEM, "StartTextEntry", function()
        if not KEYBOARD_CHAT_SYSTEM.isMinimized then 
            KEYBOARD_CHAT_SYSTEM.shouldMinimizeAfterEntry = true
        end
    end)

    SecurePostHook(PLAYER_PROGRESS_BAR, "UpdateBar", function(...) PLAYER_PROGRESS_BAR.levelTypeIcon:SetHidden(true) end) -- hide CP colour icon
    SecurePostHook(MAIN_MENU_KEYBOARD, "RefreshCategoryIndicators", -- hide indicator on top menu
    function() 
        for i, categoryLayoutData in ipairs(ZO_CATEGORY_LAYOUT_INFO) do
            local indicators = categoryLayoutData.indicators
            if indicators then
                local buttonControl = ZO_MenuBar_GetButtonControl(MAIN_MENU_KEYBOARD.categoryBar, categoryLayoutData.descriptor)
                if buttonControl then
                    local indicatorTexture = buttonControl:GetNamedChild("Indicator")
                    indicatorTexture:Hide()
                end
            end
        end
    end)
    ZO_MainMenuCategoryBarButton1Membership:ClearAnchors()
    ZO_MainMenuCategoryBarButton1Membership:SetAnchor(LEFT, ZO_PlayerProgressChampionPoints, RIGHT, 10, 0, 0)


    ZO_Compass:SetAnchor(TOPLEFT, COMPASS_FRAME.control, TOPLEFT, 0, -512) -- hide compass

    if Raidificator then -- Hide top left raidificator status
        if not origRaidificatorFunction then 
            origRaidificatorFunction = Raidificator.UpdateStatusElement
        end
        Raidificator.UpdateStatusElement = function(...)
            origRaidificatorFunction(...)
            if not RaidificatorStatusFrame:IsHidden() then
			    RaidificatorStatusFrame:SetHidden(true)
            end
        end
    end

    if PITHKA and PITHKA_GUI then -- Resize trial window dynamically, and add padding at the bottom
        if not origPithkaFunction then 
            origPithkaFunction = PITHKA.UI.Layout.updateScreenSize
        end
        PITHKA.UI.Layout.updateScreenSize = function(...)
            local w, h
            origPithkaFunction(...)
            if PITHKA.SV.state.currentScreen == 'trial' then 
                w = 930 + (PITHKA.SV.state.showExtra and 225 or 0)
                h = 150 + 25 * #PITHKA.Data.Achievements.DBFilter({TYPE='trial'}) 
                PITHKA_GUI:SetDimensions(w, h)
            end
        end
    end
end

EVENT_MANAGER:RegisterForEvent("Ricing", EVENT_ADD_ON_LOADED, OnAddOnLoaded)