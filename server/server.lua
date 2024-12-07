local framework = esx

if GetResourceState("es_extended") == "started" then
    framework = "esx"
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState("qb-core") == "started" then
    framework = "qbcore"
    QBCore = exports['qb-core']:GetCoreObject()
else
    print("No framework detected")
end

function getPlayerData(source)
    if framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return {
            identifier = xPlayer.identifier,
            job = xPlayer.job.name,
        }
    elseif framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        return {
            identifier = Player.PlayerData.citizenid,
            job = Player.PlayerData.job.name,
        }
    else
        return nil
    end
end

if framework == "esx" then
    AddEventHandler('esx:playerLoaded', function(source)
        local playerData = getPlayerData(source)
        print("Player loaded with ESX: " .. playerData.identifier)
    end)
elseif framework == "qbcore" then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        local source = source
        local playerData = getPlayerData(source)
        print("Player loaded with QBCore: " .. playerData.identifier)
    end)
end

local jailedPlayers = {}

local function FreezePlayer(playerId)
    TriggerClientEvent('adminjail:freezePlayer', playerId)
end

local function UnfreezePlayer(playerId)
    TriggerClientEvent('adminjail:unfreezePlayer', playerId)
end

local function StartJailTimer(playerId, time)
    if jailedPlayers[playerId] then
        CancelJailTimer(playerId)
    end

    jailedPlayers[playerId] = {
        timer = SetTimeout(time * 60000, function()
            UnfreezePlayer(playerId)
            TriggerClientEvent('adminjail:releaseFromJail', playerId)
            jailedPlayers[playerId] = nil
        end),
        jailTime = time
    }
end

function CancelJailTimer(playerId)
    if jailedPlayers[playerId] and jailedPlayers[playerId].timer then
        ClearTimeout(jailedPlayers[playerId].timer)
        jailedPlayers[playerId] = nil
    end
end

ESX.RegisterCommand('adminjail', 'admin', function(xPlayer, args, showError)
    if args.playerId and args.time and args.reason then
        local targetPlayer = ESX.GetPlayerFromId(args.playerId)
        if targetPlayer then
            FreezePlayer(args.playerId)

            StartJailTimer(args.playerId, tonumber(args.time))

            TriggerClientEvent('adminjail:teleportToJail', args.playerId)
            
            local targetName = targetPlayer.getName()
            local adminName = xPlayer.getName()
            local time = tonumber(args.time)
            local reason = args.reason

            local timeText
            if time == 1 then
                timeText = time .. " minute"
            else
                timeText = time .. " minutes"
            end

            local message = "" .. targetName .. " was admin jailed by " .. adminName .. " for " .. timeText .. ". Reason: " .. reason

            TriggerClientEvent('chat:addMessage', -1, {
                template = '<div style="color: rgba(255, 99, 71, 1); width: fit-content; max-width: 125%; overflow: hidden; word-break: break-word; "><b>AdmCmd: {0}</b></div>',
                args = { message }
            })

            TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'success', description = 'Player admin jailed successfully.' })
        else
            TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'error', description = 'Player not found.' })
        end
    else
        TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'error', description = 'Invalid parameters. Usage: /adminjail <playerId> <time> <reason>' })
    end
end, true, { help = 'Jail a player', validate = true, arguments = {
    { name = 'playerId', help = 'ID of the player', type = 'number' },
    { name = 'time', help = 'Jail time in minutes', type = 'number' },
    { name = 'reason', help = 'Reason for jailing', type = 'string' }
}})

ESX.RegisterCommand('adminjailrelease', 'admin', function(xPlayer, args, showError)
    if args.playerId then
        local targetPlayer = ESX.GetPlayerFromId(args.playerId)
        if targetPlayer then
            CancelJailTimer(args.playerId)
            UnfreezePlayer(args.playerId)
            
            TriggerClientEvent('adminjail:releaseFromJail', args.playerId)
            
            TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'success', description = 'Player released from admin jail.' })
        else
            TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'error', description = 'Player not found.' })
        end
    else
        TriggerClientEvent('ox_lib:notify', xPlayer.source, { type = 'error', description = 'Invalid parameters.' })
    end
end, true, { help = 'Release a player from jail', validate = true, arguments = {
    { name = 'playerId', help = 'ID of the player', type = 'number' }
}})
