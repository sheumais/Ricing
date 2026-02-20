ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_FRIENDLY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_GAMEPLAY][SETTING_TYPE_COMBAT][COMBAT_SETTING_MONSTER_TELLS_ENEMY_BRIGHTNESS].maxValue = 500
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].showValueMax = 5000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_GLOW_THICKNESS].maxValue = 50
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].showValueMax = 5000
ZO_SharedOptions_SettingsData[SETTING_PANEL_NAMEPLATES][SETTING_TYPE_IN_WORLD][IN_WORLD_UI_SETTING_TARGET_GLOW_INTENSITY].maxValue = 50

local origRaidificatorFunction
local origHideGroupFunction
local origMazeFunction
local savedVariables

local default_settings = {
    highLatencyTracker = true,
    hideControls = true,
    keepChatClosed = true,
    applySynergySettings = true,
    raidificatorReverse = true,
    hideGroupNecroChanges = true,
    breadcrumbsAnsuulMaze = true,
    autoskipChatter = true,
}

local function OnAddOnLoaded(_, name)
    if name ~= "Ricing" then return end
    EVENT_MANAGER:UnregisterForEvent("Ricing", EVENT_ADD_ON_LOADED)
    savedVariables = ZO_SavedVars:NewAccountWide("RicingSavedVariables", 1, nil, default_settings)

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
        ZO_TopBar,
        ZO_KeybindStripMungeBackgroundTexture,
    }

    local controlsToDisappear = {
        ZO_KeybindStripMungeBackgroundTexture,
        ZO_PerformanceMetersBg,
    }

    if savedVariables.hideControls then
        for _, control in ipairs(controlsToHide) do -- Hide various default UI elements
            control:SetHidden(true)
        end

        for _, control in ipairs(controlsToDisappear) do 
            control:SetTexture("")
            control:SetColor(0,0,0,0)
        end

        ZO_PlayerProgressLevelTypeIcon:SetWidth(0) -- Hide icon

        ZO_MainMenuCategoryBarButton1Membership:ClearAnchors()
        ZO_MainMenuCategoryBarButton1Membership:SetAnchor(LEFT, ZO_PlayerProgressChampionPoints, RIGHT, 10, 0, 0)
        table.remove(WORLD_MAP_SCENE.fragments, 19) -- TOP_BAR_FRAGMENT
        table.remove(WORLD_MAP_SCENE.fragments, 18) -- 
        table.remove(WORLD_MAP_SCENE.fragments, 17) -- idk why these must be removed but whatever lol
        WORLD_MAP_SCENE:RefreshFragments()

        ZO_Compass:SetAnchor(TOPLEFT, COMPASS_FRAME.control, TOPLEFT, 0, -512) -- hide compass

        SecurePostHook(PLAYER_PROGRESS_BAR, "UpdateBar", function(...) PLAYER_PROGRESS_BAR.levelTypeIcon:SetHidden(true) end) -- hide CP colour icon
        for _, categoryInfo in pairs(ZO_CATEGORY_LAYOUT_INFO) do
            categoryInfo.indicators = function()
                return false
            end
        end
    end

    if savedVariables.highLatencyTracker then
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
    end

    if savedVariables.keepChatClosed then
        STUB_SETTING_KEEP_MINIMIZED = true -- Keep chat minimised unless opened by the player
        SecurePostHook(KEYBOARD_CHAT_SYSTEM, "StartTextEntry", function()
            if not KEYBOARD_CHAT_SYSTEM.isMinimized and not IsShiftKeyDown() then 
                KEYBOARD_CHAT_SYSTEM.shouldMinimizeAfterEntry = true
            else 
                KEYBOARD_CHAT_SYSTEM.shouldMinimizeAfterEntry = false
            end
        end)
    end

    if savedVariables.applySynergySettings then
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
    end

    SetFloatingMarkerGlobalAlpha(1)

    ----------- Addon specific stuff -----------

    if Raidificator and savedVariables.raidificatorReverse then -- Hide top left raidificator status
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

    if HideGroupNecro and OSIStore and savedVariables.hideGroupNecroChanges then -- show dps icons when hiding group so i know where people are
        OPTIONS = ZO_SavedVars:NewAccountWide( "OSIStore", 1, nil, {} )
        OPTIONS[3].icon = "esoui/art/icons/mapkey/mapkey_groupmember.dds"
        OPTIONS[3].size = 48
        OPTIONS[3].usesize = true
        OPTIONS[1].icon = "esoui/art/icons/mapkey/mapkey_bg_relic_stormlords.dds"
        OPTIONS.alpha = 0.6
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

    if Breadcrumbs and savedVariables.breadcrumbsAnsuulMaze then 
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

    if CombatAlerts then
        CombatAlerts.vars.dsrDelugeBlame = true
    end

    local function handleRaidScoreChange(e, reason, amount, total)
        local reasonStrings = {
            [RAID_POINT_REASON_BONUS_ACTIVITY_HIGH] = "Bonus Activity High",
            [RAID_POINT_REASON_BONUS_ACTIVITY_LOW] = "Bonus Activity Low",
            [RAID_POINT_REASON_BONUS_ACTIVITY_MEDIUM] = "Bonus Activity Medium",
            [RAID_POINT_REASON_BONUS_POINT_ONE] = "Bonus Point One",
            [RAID_POINT_REASON_BONUS_POINT_TWO] = "Bonus Point Two",
            [RAID_POINT_REASON_BONUS_POINT_THREE] = "Bonus Point Three",
            [RAID_POINT_REASON_KILL_BANNERMEN] = "Kill Bannermen",
            [RAID_POINT_REASON_KILL_BOSS] = "Kill Boss",
            [RAID_POINT_REASON_KILL_CHAMPION] = "Kill Champion",
            [RAID_POINT_REASON_KILL_MINIBOSS] = "Kill Miniboss",
            [RAID_POINT_REASON_KILL_NORMAL_MONSTER] = "Kill Normal Monster",
            [RAID_POINT_REASON_KILL_NOXP_MONSTER] = "Kill NoXP Monster",
            [RAID_POINT_REASON_LIFE_REMAINING] = "Life Remaining",
            [RAID_POINT_REASON_SOLO_ARENA_COMPLETE] = "Solo Arena Complete",
            [RAID_POINT_REASON_SOLO_ARENA_PICKUP_FOUR] = "Solo Arena Pickup Four",
            [RAID_POINT_REASON_SOLO_ARENA_PICKUP_ONE] = "Solo Arena Pickup One",
            [RAID_POINT_REASON_SOLO_ARENA_PICKUP_THREE] = "Solo Arena Pickup Three",
            [RAID_POINT_REASON_SOLO_ARENA_PICKUP_TWO] = "Solo Arena Pickup Two",
        }
        local reasonString = reasonStrings[reason] or "Unknown Reason"
        d("Reason: " .. reasonString .. " | Increase: " .. amount .. " Total: " .. total)
        local timestamp = GetTimeStamp()
        if not savedVariables.dataExport then
            savedVariables.dataExport = {}
        end
        table.insert(savedVariables.dataExport, {
            reason = reasonString,
            amount = amount,
            total = total,
            timestamp = timestamp
        })
    end

    local function handleRaidStart(e, name, weekly)
        if not savedVariables.dataExport then
            savedVariables.dataExport = {}
        end
        table.insert(savedVariables.dataExport, {
            name = name,
            timestamp = timestamp
        })
    end

    local x_pos = Ricing_Top_Level_Control_X
    local z_pos = Ricing_Top_Level_Control_Z
    local function UpdatePosition()
        local _, x, _, z = GetUnitRawWorldPosition("player")
        x_pos:SetText("X: " .. x)
        z_pos:SetText("Z: " .. z)
    end

    local function PlayTimerSound()
        PlaySound("Outfitting_WeaponAdd_Rune")
        EVENT_MANAGER:RegisterForUpdate("RicingNoise", 150, function()
            PlaySound("Outfitting_WeaponAdd_Rune")
        end)
        zo_callLater(function()
            EVENT_MANAGER:UnregisterForUpdate("RicingNoise")
        end, 1350)
    end

    local timer_control = Ricing_Top_Level_Control_Timer
    local timestamp = 0
    local function UpdateTimer()
        local current_timestamp = GetTimeStamp()
        local difference = timestamp - current_timestamp
        if current_timestamp < timestamp + 1 then
            local timer = ZO_FormatTime(difference, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
            timer_control:SetText(timer)
            timer_control:SetHidden(false)
        else 
            EVENT_MANAGER:UnregisterForUpdate("RicingTimerUpdate")
            timestamp = 0
            timer_control:SetHidden(true)
            PlayTimerSound()
        end

        if difference < 15 then
            if difference % 2 == 0 then 
                timer_control:SetColor(1,0,0,1)
            else 
                timer_control:SetColor(1,1,1,1)
            end
        end
    end

    local function SetupTimestamp(minutes)
        EVENT_MANAGER:UnregisterForUpdate("RicingTimerUpdate")
        if minutes ~= "" then 
            timer_control:SetColor(1,1,1,1)
            timestamp = GetTimeStamp() + 60 * minutes
            EVENT_MANAGER:RegisterForUpdate("RicingTimerUpdate", 100, UpdateTimer)
            UpdateTimer()
        else end
    end

    local hidden = true
    local function TogglePositionVisiblity()
        if hidden then
            hidden = false
            x_pos:SetHidden(false)
            z_pos:SetHidden(false)
            EVENT_MANAGER:RegisterForUpdate("RicingPositionUpdate", 20, UpdatePosition)
        else
            hidden = true
            x_pos:SetHidden(true)
            z_pos:SetHidden(true)
            EVENT_MANAGER:UnregisterForUpdate("RicingPositionUpdate")
        end
    end

    local function PrintGroupOrder()
        for i=1,GetGroupSize() do 
            d(i .. ": " .. GetUnitDisplayName("group"..i)) 
        end
    end

    local function TeleportToPrimary()
        RequestJumpToHouse(GetHousingPrimaryHouse())
    end

    local function PrintGlobalTime()
        local hours, minutes, seconds = GetGlobalTimeOfDay()
        local timestamp = hours * 3600 + minutes * 60 + seconds
        local time = ZO_FormatTime(timestamp, TIME_FORMAT_STYLE_CLOCK_TIME, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
        d("Current game-world time: " .. time)
    end

    local function PrintLatency()
        StartChatInput("My current latency is: " .. GetLatency() .. "ms")
    end

    local raidEventsToggled = false
    local function toggleRaidEvents()
        if raidEventsToggled then 
            EVENT_MANAGER:UnregisterForEvent("RicingTrialStart", EVENT_RAID_TRIAL_STARTED)
            EVENT_MANAGER:UnregisterForEvent("RicingScoreUpdate", EVENT_RAID_TRIAL_SCORE_UPDATE)
            raidEventsToggled = false
        else
            EVENT_MANAGER:RegisterForEvent("RicingTrialStart", EVENT_RAID_TRIAL_STARTED, handleRaidStart)
            EVENT_MANAGER:RegisterForEvent("RicingScoreUpdate", EVENT_RAID_TRIAL_SCORE_UPDATE, handleRaidScoreChange)
            raidEventsToggled = true
        end
    end

    local function saveCombatEvent(e, ...)
        local timestamp = GetTimeStamp()
        if not savedVariables.combatEvents then
            savedVariables.combatEvents = {}
        end
        table.insert(savedVariables.combatEvents, {
            timestamp = timestamp,
            data = ...
        })
    end

    local function printCombatEventToChat(eventCode, ...)
        if eventCode == EVENT_COMBAT_EVENT then
            local result, isError, abilityName, _, _, sourceName, _, targetName, _, hitValue, _, damageType, _, sourceUnitId, targetUnitId, abilityId = ...
            -- if result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE then
            -- if hitValue == 1  and abilityName ~= "" then 
            --     d(zo_strformat(
            --         "Damage: Source: <<1>> -> Target: <<2>> | Hit: <<3>> | DamageType: <<4>> | Ability: <<5>> (ID: <<6>>)",
            --         sourceName,
            --         targetName,
            --         hitValue,
            --         GetString("SI_DAMAGETYPE", damageType),
            --         abilityName,
            --         abilityId
            --     ))
            -- end
        -- elseif eventCode == EVENT_POWER_UPDATE then
        --     local unitTag, _, powerType, powerValue, powerMax = ...
        --     d(zo_strformat(
        --         "PowerUpdate: <<1>> | Type: <<2>> | Value: <<3>> / <<4>>",
        --         unitTag,
        --         GetString("SI_COMBATMECHANICFLAGS", powerType),
        --         powerValue,
        --         powerMax
        --     ))
            d(zo_strformat(
                    "Result <<1>>: Source: <<2>> -> Target: <<3>> | Hit: <<4>> | DamageType: <<5>> | Ability: <<6>> (ID: <<7>>)",
                    result,
                    sourceName,
                    targetName,
                    hitValue,
                    GetString("SI_DAMAGETYPE", damageType),
                    abilityName,
                    abilityId
                ))
        end
    end

    local combatEvents = false
    local function logCombatEvents()
        if combatEvents then
            EVENT_MANAGER:UnregisterForEvent("RicingCombatEvents", EVENT_COMBAT_EVENT)
            EVENT_MANAGER:UnregisterForEvent("RicingCombatEvents", EVENT_POWER_UPDATE)
            combatEvents = false
        else
            EVENT_MANAGER:RegisterForEvent("RicingCombatEvents", EVENT_COMBAT_EVENT, printCombatEventToChat)
            EVENT_MANAGER:RegisterForEvent("RicingCombatEvents", EVENT_POWER_UPDATE, printCombatEventToChat)
            combatEvents = true
        end
    end

    local function clearChat()
        local primaryChatContainer = pChat.CONSTANTS.CHAT_SYSTEM.primaryContainer
        local tabIndex = primaryChatContainer.currentBuffer and primaryChatContainer.currentBuffer:GetParent() and primaryChatContainer.currentBuffer:GetParent().tab and primaryChatContainer.currentBuffer:GetParent().tab.index
        pChat.pChatData.tabNotBefore[tabIndex] = GetTimeStamp()
        primaryChatContainer.windows[tabIndex].buffer:Clear()
        primaryChatContainer:SyncScrollToBuffer()
    end

    local function zoneChangedTestFunc()
        EVENT_MANAGER:UnregisterForEvent("RicingZoneChanged", EVENT_ZONE_CHANGED)
        EVENT_MANAGER:RegisterForEvent("RicingZoneChanged", EVENT_ZONE_CHANGED, function(_, z, sz, n, zid, szid)
            d(string.format("Z:%s SZ:%s New:%s ZID:%d SZID:%d", tostring(z), tostring(sz), tostring(n), zid, szid))
        end)
    end

    local function chatterBegin(e, optionCount)
        if optionCount == 0 and not IsShiftKeyDown() then
            EndInteraction(INTERACTION_CONVERSATION)
        end
        for i = 1, optionCount do
            local optionString, optionType, optionalArgument, isImportant, chosenBefore, teleportNPC = GetChatterOption(i)
            if (optionType == CHATTER_TALK_CHOICE or optionType == CHATTER_START_TALK or optionType == CHATTER_START_NEW_QUEST_BESTOWAL or optionType == CHATTER_START_ADVANCE_COMPLETABLE_QUEST_CONDITIONS or optionType == CHATTER_START_COMPLETE_QUEST) and not chosenBefore and not IsShiftKeyDown() then
                SelectChatterOption(i)
                break
            end
        end
    end

    local function conversationUpdated(e, text, optionCount)
        chatterBegin(e, optionCount)
    end

    if savedVariables.autoskipChatter then
        EVENT_MANAGER:RegisterForEvent("RicingConversation", EVENT_CONVERSATION_UPDATED, conversationUpdated)
        EVENT_MANAGER:RegisterForEvent("RicingConversation", EVENT_CHATTER_BEGIN, chatterBegin)
    end

    local speedo_control = Ricing_Top_Level_Control_Speedo
    local stored_position = {}
    local speedo_last_time
    local SPEEDO_WINDOW = 10
    local speed_samples = {}
    local speed_sample_index = 1
    local speed_sample_count = 0

    local function measureSpeedo()
        local zone_id, x, y, z = GetUnitRawWorldPosition("player")
        local now = GetGameTimeMilliseconds()

        if stored_position["x"] == nil then
            stored_position["x"] = x
            stored_position["y"] = y
            stored_position["z"] = z
            speedo_last_time = now
            return
        end

        local time_diff = now - speedo_last_time
        if time_diff <= 0 then return end

        local dx = x - stored_position["x"]
        local dy = y - stored_position["y"]
        local dz = z - stored_position["z"]

        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        local velocity = distance / (time_diff / 1000)

        speed_samples[speed_sample_index] = velocity
        speed_sample_index = speed_sample_index + 1
        if speed_sample_index > SPEEDO_WINDOW then
            speed_sample_index = 1
        end

        if speed_sample_count < SPEEDO_WINDOW then
            speed_sample_count = speed_sample_count + 1
        end

        local sum = 0
        for i = 1, speed_sample_count do
            sum = sum + speed_samples[i]
        end
        local avg_velocity = sum / speed_sample_count

        speedo_control:SetText(string.format("%.1fm/s", avg_velocity / 100))

        speedo_last_time = now
        stored_position["x"] = x
        stored_position["y"] = y
        stored_position["z"] = z
    end

    local speedometer_enabled = false
    local function toggleSpeedometer()
        if speedometer_enabled then
            speedometer_enabled = false
            EVENT_MANAGER:UnregisterForUpdate("RicingSpeedo")
            speedo_control:SetHidden(true)
        else
            speedometer_enabled = true
            EVENT_MANAGER:RegisterForUpdate("RicingSpeedo", 50, measureSpeedo)
            speedo_control:SetHidden(false)
        end
    end

    local trial_saved_data

    local TRIAL_COMPLETE_LIFESPAN_MS = 10000

    local function new_handler(raidName, score, totalTime)
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_RAID_COMPLETE_TEXT, SOUNDS.RAID_TRIAL_COMPLETED)
        local wasUnderTargetTime = GetRaidDuration() <= GetRaidTargetTime()
        local formattedTime = ZO_FormatTimeMilliseconds(totalTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_MILLISECONDS)
        local vitalityBonus = GetCurrentRaidLifeScoreBonus()
        local currentCount = GetRaidReviveCountersRemaining()
        local maxCount = GetCurrentRaidStartingReviveCounters()

        messageParams:SetEndOfRaidData({ score, formattedTime, wasUnderTargetTime, vitalityBonus, zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, currentCount, maxCount) })
        messageParams:SetText(zo_strformat(SI_TRIAL_COMPLETED_LARGE, raidName))
        messageParams:SetLifespanMS(TRIAL_COMPLETE_LIFESPAN_MS)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
        return messageParams
    end

    local old_handler = ZO_CenterScreenAnnounce_GetEventHandler
    function ZO_CenterScreenAnnounce_GetEventHandler(event_id)
        if event_id == CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL then
            return new_handler
        else
            return old_handler(event_id)
        end
    end

    local function createTrialMessage(data)
        local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_RAID_COMPLETE_TEXT, SOUNDS.RAID_TRIAL_COMPLETED)
        messageParams:SetEndOfRaidData({
            data.score,
            data.totalTime,
            data.wasUnderTargetTime,
            data.vitalityBonus,
            zo_strformat(SI_REVIVE_COUNTER_REVIVES_USED, data.currentCount, data.maxCount)
        })
        messageParams:SetText(zo_strformat(SI_TRIAL_COMPLETED_LARGE, data.raidName))
        messageParams:SetLifespanMS(5000)
        messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_RAID_TRIAL)
        return messageParams
    end

    local function saveTrialData(_, raidName, score, totalTime)
        trial_saved_data = {
            raidName = raidName,
            score = score,
            totalTime = ZO_FormatTimeMilliseconds(totalTime, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_MILLISECONDS),
            wasUnderTargetTime = GetRaidDuration() <= GetRaidTargetTime(),
            vitalityBonus = GetCurrentRaidLifeScoreBonus(),
            currentCount = GetRaidReviveCountersRemaining(),
            maxCount = GetCurrentRaidStartingReviveCounters()
        }

        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(createTrialMessage(trial_saved_data))

    end

    local function replayTrialScore()
        if trial_saved_data then
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(createTrialMessage(trial_saved_data))
        else
            local testData = {
                raidName = "Test Trial",
                score = 1000,
                totalTime = ZO_FormatTimeMilliseconds(123456, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_MILLISECONDS),
                wasUnderTargetTime = true,
                vitalityBonus = 0,
                currentCount = 3,
                maxCount = 5
            }
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(createTrialMessage(testData))
        end
    end

    EVENT_MANAGER:RegisterForEvent("RicingTrialSave", EVENT_RAID_TRIAL_COMPLETE, saveTrialData)

    SLASH_COMMANDS["/showpos"] = TogglePositionVisiblity
    SLASH_COMMANDS["/grouporder"] = PrintGroupOrder
    SLASH_COMMANDS["/timer"] = SetupTimestamp
    SLASH_COMMANDS["/home"] = TeleportToPrimary
    SLASH_COMMANDS["/time"] = PrintGlobalTime
    SLASH_COMMANDS["/latencyshare"] = PrintLatency
    SLASH_COMMANDS["/lograiddata"] = toggleRaidEvents
    SLASH_COMMANDS["/logcombatevents"] = logCombatEvents
    SLASH_COMMANDS["/zonechanged"] = zoneChangedTestFunc
    SLASH_COMMANDS["/speedo"] = toggleSpeedometer
    SLASH_COMMANDS["/trialscore"] = replayTrialScore
    if pChat then
        SLASH_COMMANDS["/clear"] = clearChat
    end

    timer_control:SetHidden(true)
    timer_control:SetScale(1.5)
    x_pos:SetHidden(true)
    z_pos:SetHidden(true)

    local panelData = {
        type = "panel",
        name = "Ricing",
        displayName = "Ricing",
        author = "TheMrPancake",
    }

    local optionsTable = {
        {
            type = "checkbox",
            name = "OCE Latency",
            getFunc = function() return savedVariables.highLatencyTracker end,
            setFunc = function(value) savedVariables.highLatencyTracker = value end,
            tooltip = "Increases max latency shown to 9999 and modifies icon colour to reflect that 250 ping is normal.",
            requiresReload = true,
            default = default_settings.highLatencyTracker,
        },
        {
            type = "checkbox",
            name = "Hide Controls",
            getFunc = function() return savedVariables.hideControls end,
            setFunc = function(value) savedVariables.hideControls = value end,
            tooltip = "Hides various UI elements such as the compass, the closed chat background and icons and the menu at the top.",
            requiresReload = true,
            default = default_settings.hideControls,
        },
        {
            type = "checkbox",
            name = "Keep Chat Closed",
            getFunc = function() return savedVariables.keepChatClosed end,
            setFunc = function(value) savedVariables.keepChatClosed = value end,
            tooltip = "The chat box will close itself after you finish typing a message. Hold shift when opening the chat to make it stay open (like normal)",
            requiresReload = true,
            default = default_settings.keepChatClosed,
        },
        {
            type = "checkbox",
            name = "Dialogue Skip",
            getFunc = function() return savedVariables.autoskipChatter end,
            setFunc = function(value) savedVariables.autoskipChatter = value end,
            tooltip = "Automatically talks to NPCs. Hold shift to pause.",
            requiresReload = true,
            default = default_settings.autoskipChatter,
        },
        {
            type = "checkbox",
            name = "Synergy Simplify",
            getFunc = function() return savedVariables.applySynergySettings end,
            setFunc = function(value) savedVariables.applySynergySettings = value end,
            tooltip = "Modify the synergy display to have only the icon and keybind, and move it to a pre-determined location. For better customisation use BetterSynergy addon.",
            requiresReload = true,
            default = default_settings.applySynergySettings,
        },
        {
            type = "checkbox",
            name = "Raidificator: Invert visibility",
            getFunc = function() return savedVariables.raidificatorReverse end,
            setFunc = function(value) savedVariables.raidificatorReverse = value end,
            tooltip = "Inverts the visibility of the raidificator tracker so that it doesn't distract during the run.",
            requiresReload = true,
            default = default_settings.raidificatorReverse,
        },
        {
            type = "checkbox",
            name = "HideGroupNecro: DPS Icons",
            getFunc = function() return savedVariables.hideGroupNecroChanges end,
            setFunc = function(value) savedVariables.hideGroupNecroChanges = value end,
            tooltip = "Sets some custom icons for various things and turns on/off the icons over DPS heads when toggling hidegroup.",
            requiresReload = true,
            default = default_settings.hideGroupNecroChanges,
        },
        {
            type = "checkbox",
            name = "Breadcrumbs & Sanity's Edge Helper: Ansuul Maze",
            getFunc = function() return savedVariables.breadcrumbsAnsuulMaze end,
            setFunc = function(value) savedVariables.breadcrumbsAnsuulMaze = value end,
            tooltip = "Provides a visual line guide for completing the current maze.",
            requiresReload = true,
            default = default_settings.breadcrumbsAnsuulMaze,
        },
        {
            type = "description",
            width = "full",
            text = "Custom commands:\n/showpos - Brings up current 3D position coordinates\n/grouporder - prints the grouporder in chat (spaulder priority)\n/timer [minutes] - timer that counts down and dings when done\n/home - teleports you to your primary house\n/time - print the in-game time. 6 hours irl = day cycle in nirn\n/latencyshare - flex your 9999 ping to the chat\n/speedo - enable a speedometer ui element for measuring your 3D speed\n/trialscore - replay the most recent trial score for a perfect screenshot\n/clear (Requires pChat) - clears the chat",
        },
    }
    if LibAddonMenu2 then 
        LibAddonMenu2:RegisterAddonPanel("RicingLAMPanel", panelData)
        LibAddonMenu2:RegisterOptionControls("RicingLAMPanel", optionsTable)
    end
end

EVENT_MANAGER:RegisterForEvent("Ricing", EVENT_ADD_ON_LOADED, OnAddOnLoaded)