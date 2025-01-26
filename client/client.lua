local ESX, QBCore

if GetResourceState("es_extended") == "started" then
    ESX = exports['es_extended']:getSharedObject()
elseif GetResourceState("qb-core") == "started" then
    QBCore = exports['qb-core']:GetCoreObject()
end

if ESX then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
        end
    end)
elseif QBCore then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        while true do
            Citizen.Wait(1000)
        end
    end)
end

RegisterNetEvent('adminjail:teleportToJail')
AddEventHandler('adminjail:teleportToJail', function()
    local playerPed = PlayerPedId()
    local jailLocation = Config.JailLocation
    SetEntityCoords(playerPed, jailLocation.x, jailLocation.y, jailLocation.z)
end)

RegisterNetEvent('adminjail:releaseFromJail')
AddEventHandler('adminjail:releaseFromJail', function()
    local playerPed = PlayerPedId()
    local releaseLocation = Config.ReleaseLocation
    SetEntityCoords(playerPed, releaseLocation.x, releaseLocation.y, releaseLocation.z)
end)

RegisterNetEvent('adminjail:freezePlayer')
AddEventHandler('adminjail:freezePlayer', function()
    local playerPed = PlayerPedId()
    if playerPed then
        FreezeEntityPosition(playerPed, true)
        SetEntityCollision(playerPed, false, false)
        SetPlayerControl(playerPed, false)
    end
end)

RegisterNetEvent('adminjail:unfreezePlayer')
AddEventHandler('adminjail:unfreezePlayer', function()
    local playerPed = PlayerPedId()
    if playerPed then
        FreezeEntityPosition(playerPed, false)
        SetEntityCollision(playerPed, true, true)
        SetPlayerControl(playerPed, true)
    end
end)
