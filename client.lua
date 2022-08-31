local isScoreboardOpen = false
local requestedData

Citizen.CreateThread(function() 
    ESX = nil

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    ESX.PlayerData = ESX.GetPlayerData()

    while true do
        Citizen.Wait(Config.updateScoreboardInterval)
        TriggerServerEvent("mvx_scoreboard:updateValues")
    end
end)

local PlayerPedPreview
function createPedScreen(playerID)
    CreateThread(function()
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_JOINING_SCREEN"), true, -1)
        Citizen.Wait(100)
        N_0x98215325a695e78a(false)
        PlayerPedPreview = ClonePed(playerID, GetEntityHeading(playerID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        Wait(200)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
    end)
end

RegisterCommand('togglescoreboard', function()
    if not isScoreboardOpen then
        TriggerServerEvent('mvx_scoreboard:requestUserData', tonumber(GetPlayerServerId(PlayerId())))
        if Config.showPlayerPed then
            SetFrontendActive(true)
            createPedScreen(PlayerPedId())
        end
        SendNUIMessage({
            action = "show",
            keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
        })
        SetNuiFocus(true,true)
        if Config.screenBlur then
            TriggerScreenblurFadeIn(Config.screenBlurAnimationDuration)
        end
        isScoreboardOpen = true
    elseif isScoreboardOpen then
        if Config.showPlayerPed then
            DeleteEntity(PlayerPedPreview)
            SetFrontendActive(false)
        end
        SendNUIMessage({
            action = "hide",
            keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
        })
        SetNuiFocus(false,false)
        isScoreboardOpen = false
        if Config.screenBlur then
            TriggerScreenblurFadeOut(Config.screenBlurAnimationDuration)
        end
    end
end, false)

RegisterKeyMapping('togglescoreboard', 'Show/Hide Scoreboard', 'keyboard', 'F10')

RegisterNUICallback('closeScoreboard', function()
    ExecuteCommand('togglescoreboard')
end)

RegisterNetEvent("mvx_scoreboard:addUserToScoreboard")
AddEventHandler(
    "mvx_scoreboard:addUserToScoreboard",
    function(playerID, playerName, playerJob, playerGroup)
        SendNUIMessage(
            {
                action="addUserToScoreboard",
                playerID = playerID,
                playerName = playerName,
                playerJob = playerJob,
                playerGroup = playerGroup,
            }
        )
    end
)

RegisterNetEvent("mvx_scoreboard:sendConfigToNUI")
AddEventHandler("mvx_scoreboard:sendConfigToNUI",
    function()
        SendNUIMessage({
            action = "getConfig",
            config = json.encode(Config),
        })
    end
)

RegisterNetEvent("mvx_scoreboard:sendIllegalActivity")
AddEventHandler("mvx_scoreboard:sendIllegalActivity",
    function(data)
        SendNUIMessage({
            action = "addActivity",
            activity = data,
        })
    end
)

RegisterNetEvent("mvx_scoreboard:setValues")
AddEventHandler(
    "mvx_scoreboard:setValues",
    function(onlinePlayers, onlineStaff, onlinePolice, onlineEMS, onlineTaxi, onlinemechanic)
        SendNUIMessage(
            {
                action="updateScoreboard",
                onlinePlayers = onlinePlayers,
                onlineStaff = onlineStaff,
                onlinePolice = onlinePolice,
                onlineEMS = onlineEMS,
                onlineTaxi = onlineTaxi,
                onlinemechanic = onlinemechanic,
            }
        )
    end
)

RegisterNetEvent("mvx_scoreboard:refrehScoreboard")
AddEventHandler(
    "mvx_scoreboard:refrehScoreboard",
    function()
        SendNUIMessage(
            {
                action="refreshScoreboard",
            }
        )
    end
)

RegisterNUICallback('showPlayerPed', function(data)
    if Config.showPlayerPed then
        local playerID = data.playerID
        DeleteEntity(PlayerPedPreview)
        Citizen.Wait(100)
        local playerTargetID = GetPlayerPed(GetPlayerFromServerId(playerID))
        PlayerPedPreview = ClonePed(playerTargetID, GetEntityHeading(playerTargetID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        Wait(200)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
        TriggerServerEvent('mvx_scoreboard:requestUserData', tonumber(data.playerID))
    end
end)

RegisterNetEvent("mvx_scoreboard:receiveRequestedData")
AddEventHandler(
    "mvx_scoreboard:receiveRequestedData",
    function(from, data)
        requestedData = data
        SendNUIMessage(
        {
            action="playerInfoUpdate",
            playerName = requestedData.playerName,
            playerID = requestedData.playerID,
            timePlayed = requestedData.timePlayed,
            roleplayName = requestedData.roleplayName,
        }
    )
    end
)

RegisterNetEvent("mvx_scoreboard:retrieveUserData")
AddEventHandler(
    "mvx_scoreboard:retrieveUserData",
    function(from, to)
        local data = {}
        data.playerName = GetPlayerName(PlayerId())
        data.playerID = to
        local retVal, timePlayed = StatGetInt('mp0_total_playing_time')
        data.timePlayed = timePlayed
        TriggerServerEvent('mvx_scoreboard:sendRequestedData', from, data)
    end
)
