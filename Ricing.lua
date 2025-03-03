-- Allow glow of tab target to be bigger, and aoe brightness to be increased beyond normal limits
ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].showValueMax = 2000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].maxValue = 20
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].showValueMax = 2000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].maxValue = 20

local origPithkaFunction
local origPithkaFunction2
local origRaidificatorFunction
local origHideGroupFunction
local origMatchBrandsFunction
local origMazeFunction

local function OnAddOnLoaded(_, name)
    if name ~= "Ricing" then return end
    EVENT_MANAGER:UnregisterForEvent("Ricing", EVENT_ADD_ON_LOADED)

    local CUSTOM_MAX_LATENCY = 9999
    local HIGH_LATENCY = 300
    local MEDIUM_LATENCY = 200
    local LOW_LATENCY = 0
    local LATENCY_ICONS = {
        [HIGH_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_lowPop.dds", color = ZO_ERROR_COLOR },
        [MEDIUM_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_medPop.dds", color = ZO_SELECTED_TEXT },
        [LOW_LATENCY] = { image = "EsoUI/Art/Campaign/campaignBrowser_hiPop.dds", color = ZO_SELECTED_TEXT },
    }

    local controlsToHide = {
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
        if not KEYBOARD_CHAT_SYSTEM.isMinimized and not IsShiftKeyDown() then 
            KEYBOARD_CHAT_SYSTEM.shouldMinimizeAfterEntry = true
        else 
            KEYBOARD_CHAT_SYSTEM.shouldMinimizeAfterEntry = false
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
    table.remove(WORLD_MAP_SCENE.fragments, 19) -- TOP_BAR_FRAGMENT
    table.remove(WORLD_MAP_SCENE.fragments, 18) -- 
    table.remove(WORLD_MAP_SCENE.fragments, 17) -- idk why these must be removed but whatever lol
    WORLD_MAP_SCENE:RefreshFragments()

    ZO_Compass:SetAnchor(TOPLEFT, COMPASS_FRAME.control, TOPLEFT, 0, -512) -- hide compass


    local function ApplySynergySettings()
        if not SYNERGY then return end
    
        if SYNERGY.action then
            SYNERGY.action:SetHidden(true)
        end

        SYNERGY.container:ClearAnchors()
        SYNERGY.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 900, 800)
    end
    SecurePostHook(SYNERGY, "OnSynergyAbilityChanged", function(self, ...)
        ApplySynergySettings()
    end)

    ----------- Addon specific stuff -----------

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
        if not origPithkaFunction2 then -- remove tooltip for non-existent achievement links
            origPithkaFunction2 = PITHKA.UI.Icons.achievement
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
        PITHKA.UI.Icons.achievement = function(data)
            if data.a==nil then 
                data.t  = PITHKA.UI.Constants.texture.X
                data.c  = PITHKA.UI.Constants.rgbGray
                return PITHKA.UI.Icons.basic(data)
            end
        end
    end

    if HideGroupNecro and OSIStore then -- show dps icons when hiding group so i know where people are
        OPTIONS = ZO_SavedVars:NewAccountWide( "OSIStore", 1, nil, {} )
        if not origHideGroupFunction then 
            origHideGroupFunction = HideGroupNecro.hideMembers
        end
        HideGroupNecro.hideMembers = function(enable)
            origHideGroupFunction(enable)
            if enable then 
                OPTIONS[3].show = true
            else 
                OPTIONS[3].show = false
            end
        end
    end

    if Breadcrumbs then 
        local triangleCorners = {
            {196136, 37820}, -- Green (1)
            {203774, 37870}, -- Blue (2)
            {200000, 44336}, -- Red (3)
        }

        local function CreateMazeBreadcrumbs()
            local n = 0
            local x_total = 0
            local z_total = 0
            for i=1, 12 do 
                local zone, x, _, z = GetUnitRawWorldPosition("group" .. i)
                local health, maxhp, _ = GetUnitPower("group" .. i, COMBAT_MECHANIC_FLAGS_HEALTH)
                if zone == 1427 and health > 0 then -- is group member in the trial and alive?
                    n = n + 1                       -- assuming all members have been ported into the ansuul fight,
                    x_total = x_total + x           -- (no PTE shenanigans here please rastananana)
                    z_total = z_total + z           -- also assuming no people are in portal still. could mess stuff up
                end
            end

            if n > 0 then -- just in case
                local x_avg = x_total / n
                local z_avg = z_total / n
            
                local minDistance = 0
                local furthestCorner = nil
                for i, corner in ipairs(triangleCorners) do -- compare average group member position to maze corners
                    local x_corner, z_corner = corner[1], corner[2]
                    local distance = math.sqrt((x_avg - x_corner)^2 + (z_avg - z_corner)^2)
                    
                    if distance > minDistance then
                        minDistance = distance
                        furthestCorner = i
                    end
                end
                local point_list = {{}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},}
                local maze_line_colour = {1, 1, 1}
                if furthestCorner == 1 then 
                    maze_line_colour = {0, 1, 0}
                    -- d("Poison")
                    point_list = {
                        {200983, 40389},
                        {199312, 41474},
                        {199071, 41220},
                        {200361, 38907},
                        {200216, 38419},
                        {199684, 38295},
                        {199537, 38466},
                        {198577, 40089},
                        {198291, 40107},
                        {198099, 39383},
                        {198433, 37959},
                        {197609, 39035},
                        {197269, 38912},
                        {197118, 38645},
                    }
                elseif furthestCorner == 2 then 
                    maze_line_colour = {0, 0, 1}
                    -- d("Lightning")
                    point_list = {
                        {199164, 40760},
                        {199459, 40191},
                        {198815, 38867},
                        {199256, 38605},
                        {200618, 40845},
                        {201647, 40665},
                        {201213, 39943},
                        -- wait!
                        {201017, 39587},
                        {201313, 38685},
                        {202056, 39322},
                        {202580, 39778},
                        {202649, 39541},
                        {202195, 38519},
                        {202335, 38271},
                    }
                elseif furthestCorner == 3 then 
                    maze_line_colour = {1, 0, 0}
                    -- d("Fire")
                    point_list = {
                        {199964, 38901},
                        {201689, 39972},
                        {201605, 40121},
                        {200177, 40150},
                        {198833, 40626},
                        {198752, 40961},
                        {198821, 41106},
                        {200678, 41111},
                        {200602, 41853},
                        {199263, 41790},
                        {199207, 42250},
                        {200278, 42628},
                        {200486, 42841},
                        {200042, 43160},
                    }
                end
                local line_list = {}
                if point_list then 
                    for i=1, #point_list do 
                        if point_list[i+1] == nil then break end
                        local x1, z1 = point_list[i][1], point_list[i][2]
                        local x2, z2 = point_list[i+1][1], point_list[i+1][2]
                        local line = Breadcrumbs.CreateLinePrimitive(x1, 30200, z1, x2, 30200, z2, maze_line_colour)
                        table.insert(line_list, line)
                    end
                    Breadcrumbs.CreateTemporaryLines(line_list, 19000)
                end
            end
        end

        if SEH then -- sanity's edge helper
            if not origMazeFunction then 
                origMazeFunction = SEH.Ansuul.TheRitual
            end
            SEH.Ansuul.TheRitual = function(result, ...)
                origMazeFunction(result, ...)
                if result == ACTION_RESULT_EFFECT_GAINED_DURATION then -- starts at 45 seconds, maze spawns at ~35.7 seconds
                    zo_callLater(function() CreateMazeBreadcrumbs() end, 9000)
                end
            end
        end
    end

    if CombatAlertsData then -- tell movement direction on rockgrove portal eye because im braindead asf
        CombatAlertsData.rg.eye = {
			[153517] = "Clockwise (LEFT)  " .. zo_iconFormatInheritColor("CombatAlerts/art/arrow-cw.dds", 96, 96),
			[153518] = "Counter-Clockwise (RIGHT)  " .. zo_iconFormatInheritColor("CombatAlerts/art/arrow-ccw.dds", 96, 96),
		}
    end

    local x_pos = Ricing_Top_Level_Control_X
    local z_pos = Ricing_Top_Level_Control_Z
    local function UpdatePosition()
        local _, x, _, z = GetUnitRawWorldPosition("player")
        x_pos:SetText("X: " .. x)
        z_pos:SetText("Z: " .. z)
    end

    local hidden = true
    local function TogglePositionVisiblity()
        if hidden then
            hidden = false
            Ricing_Top_Level_Control:SetHidden(false)
            EVENT_MANAGER:RegisterForUpdate("RicingPositionUpdate", 20, UpdatePosition)
        else
            hidden = true
            Ricing_Top_Level_Control:SetHidden(true)
            EVENT_MANAGER:UnregisterForUpdate("RicingPositionUpdate")
        end
    end

    SLASH_COMMANDS["/showpos"] = TogglePositionVisiblity
    SLASH_COMMANDS["/grouporder"] = function() for i=1,GetGroupSize() do d(i .. " " .. GetUnitDisplayName("group"..i)) end end
end

EVENT_MANAGER:RegisterForEvent("Ricing", EVENT_ADD_ON_LOADED, OnAddOnLoaded)