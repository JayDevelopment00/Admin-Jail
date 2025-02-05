local ESX, QBCore
local jailedPlayers = {}

if GetResourceState("es_extended") == "started" then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState("qb-core") == "started" then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function getPlayerData(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and {
            identifier = xPlayer.identifier,
            job = xPlayer.job.name,
        }
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and {
            identifier = Player.PlayerData.citizenid,
            job = Player.PlayerData.job.name,
        }
    end
    return nil
end

if ESX then
    AddEventHandler('esx:playerLoaded', function(source)
        local playerData = getPlayerData(source)
        if playerData then
            --print("Player loaded with ESX: " .. playerData.identifier)
        end
    end)
elseif QBCore then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        local playerData = getPlayerData(source)
        if playerData then
            --print("Player loaded with QBCore: " .. playerData.identifier)
        end
    end)
end

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

local function CancelJailTimer(playerId)
    if jailedPlayers[playerId] and jailedPlayers[playerId].timer then
        ClearTimeout(jailedPlayers[playerId].timer)
        jailedPlayers[playerId] = nil
    end
end

local function getPlayerDetails(source, playerId)
    local adminName, targetName
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        local targetPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and targetPlayer then
            adminName = xPlayer.getName()
            targetName = targetPlayer.getName()
            return adminName, targetName, targetPlayer
        end
    elseif QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local targetPlayer = QBCore.Functions.GetPlayer(playerId)
        if xPlayer and targetPlayer then
            adminName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
            targetName = targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname
            return adminName, targetName, targetPlayer
        end
    end
    return nil, nil, nil
end

RegisterCommand('adminjail', function(source, args, rawCommand)
    local playerId, time = tonumber(args[1]), tonumber(args[2])
    local reason = table.concat(args, ' ', 3)

    if not playerId or not time or not reason then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Invalid parameters. Usage: /adminjail <id> <time> <reason>', icon = 'building' })
        return
    end

    local adminName, targetName, targetPlayer = getPlayerDetails(source, playerId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found.', icon = 'building' })
        return
    end

    FreezePlayer(playerId)
    StartJailTimer(playerId, time)
    TriggerClientEvent('adminjail:teleportToJail', playerId)

    local message = string.format("%s was admin jailed by %s for %d minute(s). Reason: %s", targetName, adminName, time, reason)
    TriggerClientEvent('chat:addMessage', -1, {
        template = '<div style="color: rgba(255, 99, 71, 1); width: fit-content; max-width: 125%; overflow: hidden; word-break: break-word;"><b>AdmCmd: {0}</b></div>',
        args = { message }
    })

    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Player admin jailed successfully.', icon = 'building' })
end, false)

RegisterCommand('adminjailrelease', function(source, args, rawCommand)
    local playerId = tonumber(args[1])
    if not playerId then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Invalid parameters. Usage: /adminjailrelease <playerId>', icon = 'building' })
        return
    end

    local _, targetName, targetPlayer = getPlayerDetails(source, playerId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Player not found.', icon = 'building' })
        return
    end

    CancelJailTimer(playerId)
    UnfreezePlayer(playerId)
    TriggerClientEvent('adminjail:releaseFromJail', playerId)

    TriggerClientEvent('ox_lib:notify', source, { type = 'success', description = 'Player released from admin jail.', icon = 'building' })
end, false)
