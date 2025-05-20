local wheelClamps = {}

function ApplyWheelClampVisual(vehicle)
    local clampProp = 'prop_spot_clamp'
    local clampHash = 127052170

    RequestModel(clampHash)
    while not HasModelLoaded(clampHash) do
        Citizen.Wait(100)
    end

    local clamp = CreateObject(clampHash, 0, 0, 0, true, true, false)
    
    SetEntityCollision(clamp, false, false)
    
    local wheelBone = GetEntityBoneIndexByName(vehicle, 'wheel_lf')
    
    if wheelBone == -1 then
        if Config.DebugMode then
            print('Bone wheel_lf not found. Using default position.')
        end
        AttachEntityToEntity(
            clamp, vehicle, 0,
            -0.1, 0.5, 0.4,
            0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )
    else
        AttachEntityToEntity(
            clamp,
            vehicle,
            wheelBone,
            -0.1, 0.0, 0.4,
            0.0, 0.0, 0.0,
            true,
            true,
            false,
            true,
            1,
            true
        )
    end

    SetModelAsNoLongerNeeded(clampHash)
    
    return clamp
end

function RemoveWheelClampVisual(clamp)
    if DoesEntityExist(clamp) then
        DetachEntity(clamp, true, true)
        SetEntityAsMissionEntity(clamp, 1, 1)
        DeleteEntity(clamp)
        if Config.DebugMode then
            print('Removed clamp: ' .. tostring(clamp))
        end
    elseif Config.DebugMode then
        print('Error: Clamp does not exist: ' .. tostring(clamp))
    end
end

function FindAttachedWheelClamp(vehicle)
    local clampHash = 127052170
    local clamp = nil

    local objects = GetGamePool('CObject')
    for _, obj in ipairs(objects) do
        if GetEntityModel(obj) == clampHash and GetEntityAttachedTo(obj) == vehicle then
            clamp = obj
            if Config.DebugMode then
                print('Found attached clamp: ' .. tostring(clamp))
            end
            break
        end
    end

    return clamp
end

function PlayClampAnimation()
    local playerPed = PlayerPedId()
    
    RequestAnimDict('amb@prop_human_bum_bin@idle_b')
    while not HasAnimDictLoaded('amb@prop_human_bum_bin@idle_b') do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 8.0, -8.0, 3000, 0, 0, false, false, false)
    Citizen.Wait(3000)
    ClearPedTasks(playerPed)
end

function GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = math.huge

    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    return closestVehicle, closestDistance
end

function ApplyClamp()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local vehicle, distance = GetClosestVehicle(coords)
    if not vehicle or not DoesEntityExist(vehicle) then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('No vehicle nearby!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end

    if distance > 3.0 then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Too far from the vehicle!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if plate ~= nil then
        if Config.DebugMode then
            print('Requesting permission to apply clamp for vehicle: ' .. plate)
        end
        -- Sprawdź uprawnienia przez serwer
        TriggerServerEvent('wheelclamp:checkPermission', plate, 'apply', vehicle)
        -- Zwracamy false, sukces będzie obsługiwany przez callback
        return false
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Vehicle has no license plate!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end
end

function RemoveClamp()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local vehicle, distance = GetClosestVehicle(coords)
    if not vehicle or not DoesEntityExist(vehicle) then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('No vehicle nearby!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end

    if distance > 3.0 then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Too far from the vehicle!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if plate ~= nil then
        local clamp = wheelClamps[plate] or FindAttachedWheelClamp(vehicle)
        if clamp then
            if Config.DebugMode then
                print('Requesting permission to remove clamp from vehicle: ' .. plate)
            end
            -- Sprawdź uprawnienia przez serwer
            TriggerServerEvent('wheelclamp:checkPermission', plate, 'remove', vehicle)
            return false
        else
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('No wheel clamp found on the vehicle!')
            EndTextCommandThefeedPostTicker(true, false)
            return false
        end
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('Vehicle has no license plate!')
        EndTextCommandThefeedPostTicker(true, false)
        return false
    end
end


RegisterNetEvent('wheelclamp:permissionResult')
AddEventHandler('wheelclamp:permissionResult', function(plate, action, allowed, vehicle)
    if Config.DebugMode then
        print('Permission result for ' .. action .. ' clamp on ' .. plate .. ': ' .. tostring(allowed))
    end
    if allowed then
        if action == 'apply' then
            if Config.DebugMode then
                print('Applying clamp to vehicle: ' .. plate)
            end
            PlayClampAnimation()
            local clamp = ApplyWheelClampVisual(vehicle)
            if clamp then
                wheelClamps[plate] = clamp
                TriggerServerEvent('wheelclamp:addClamp', plate)
            else
                BeginTextCommandThefeedPost('STRING')
                AddTextComponentSubstringPlayerName('Failed to apply wheel clamp!')
                EndTextCommandThefeedPostTicker(true, false)
            end
        elseif action == 'remove' then
            if Config.DebugMode then
                print('Removing clamp from vehicle: ' .. plate)
            end
            local clamp = wheelClamps[plate] or FindAttachedWheelClamp(vehicle)
            if clamp then
				PlayClampAnimation()
                RemoveWheelClampVisual(clamp)
                wheelClamps[plate] = nil
                TriggerServerEvent('wheelclamp:removeClamp', plate)
            end
        end
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('You are not authorized to perform this action!')
        EndTextCommandThefeedPostTicker(true, false)
    end
end)

if Config.EnableCommands then
    RegisterCommand('wheelclamp', function(source, args, rawCommand)
        ApplyClamp()
    end, false)

    RegisterCommand('removewheelclamp', function(source, args, rawCommand)
        RemoveClamp()
    end, false)
end 

if Config.EnableItem and Config.ESX then
    RegisterNetEvent('wheelclamp:useClamp')
    AddEventHandler('wheelclamp:useClamp', function()
        ApplyClamp()
    end)
end

if Config.EnableItem and Config.QBCore then
    RegisterNetEvent('wheelclamp:useClamp')
    AddEventHandler('wheelclamp:useClamp', function()
        ApplyClamp()
    end)
end


RegisterNetEvent('wheelclamp:notify')
AddEventHandler('wheelclamp:notify', function(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(true, false)
end)

Citizen.CreateThread(function()
    local lastVehicle = nil
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle then
            if vehicle and vehicle ~= lastVehicle then
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate ~= nil then
                    if Config.DebugMode then
                        print('Checking clamp for vehicle: ' .. plate)
                    end
                    TriggerServerEvent('wheelclamp:checkClamp', plate)
                    lastVehicle = vehicle
                elseif plate == nil then 
                    lastVehicle = nil
                end
            end
        elseif not vehicle then
            lastVehicle = nil
        end
    end
end)

RegisterNetEvent('wheelclamp:clampStatus')
AddEventHandler('wheelclamp:clampStatus', function(plate, hasClamp)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if Config.DebugMode then
        print('Received clampStatus for ' .. plate .. ': hasClamp = ' .. tostring(hasClamp))
    end
    
    if vehicle and GetVehicleNumberPlateText(vehicle) == plate then
        if hasClamp then
            if not wheelClamps[plate] or not DoesEntityExist(wheelClamps[plate]) then
                local existingClamp = FindAttachedWheelClamp(vehicle)
                if existingClamp then
                    wheelClamps[plate] = existingClamp
                else
                    wheelClamps[plate] = ApplyWheelClampVisual(vehicle)
                end
            end
            
            Citizen.CreateThread(function()
                if Config.DebugMode then
                    print('Started immobilization loop for: ' .. plate)
                end
                while vehicle == GetVehiclePedIsIn(playerPed, false) and hasClamp do
                    Citizen.Wait(0)
                    local isEngineOn = GetIsVehicleEngineRunning(vehicle)
                    if isEngineOn then
                        if Config.DebugMode then
                            print('Immobilizing vehicle: ' .. plate)
                        end
                        DisableControlAction(0, 71, true)
                        DisableControlAction(0, 72, true)
                        SetVehicleHandbrake(vehicle, true)
                        BeginTextCommandThefeedPost('STRING')
                        AddTextComponentSubstringPlayerName('Vehicle has a wheel clamp!')
                        EndTextCommandThefeedPostTicker(true, false)
                    end
                end
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleHandbrake(vehicle, false)
                    EnableControlAction(0, 71, true)
                    EnableControlAction(0, 72, true)
                    if Config.DebugMode then
                        print('Resetting vehicle state: ' .. plate)
                    end
                end
            end)
        else
            local clamp = wheelClamps[plate] or FindAttachedWheelClamp(vehicle)
            if clamp then
                RemoveWheelClampVisual(clamp)
                wheelClamps[plate] = nil
            end
            if vehicle and DoesEntityExist(vehicle) then
                SetVehicleHandbrake(vehicle, false)
                EnableControlAction(0, 71, true)
                EnableControlAction(0, 72, true)
            end
        end
    end
end)

exports('ApplyClamp', ApplyClamp)
exports('RemoveClamp', RemoveClamp)