local wheelClamps = {}

if Config.EnableItem and Config.ESX then
    ESX.RegisterUsableItem('wheelclamp', function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getInventoryItem('wheelclamp').count < 1 then
            TriggerClientEvent('wheelclamp:notify', source, 'You don\'t have a wheel clamp!')
            return
        end
        if not CheckJob(source) then
            TriggerClientEvent('wheelclamp:notify', source, 'You are not authorized to use a wheel clamp!')
            return
        end
        TriggerClientEvent('wheelclamp:useClamp', source)
    end)
end

if Config.EnableItem and Config.QBCore then
    QBCore.Functions.CreateUseableItem('wheelclamp', function(source)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player.Functions.GetItemByName('wheelclamp') then
            TriggerClientEvent('wheelclamp:notify', source, 'You don\'t have a wheel clamp!')
            return
        end
        if not CheckJob(source) then
            TriggerClientEvent('wheelclamp:notify', source, 'You are not authorized to use a wheel clamp!')
            return
        end
        TriggerClientEvent('wheelclamp:useClamp', source)
    end)
end


function LoadWheelClamps()
    local results = MySQL.query.await('SELECT plate FROM wheel_clamps')
    wheelClamps = {}
    for _, row in ipairs(results) do
        wheelClamps[row.plate] = true
    end
    if Config.DebugMode then
        print('Loaded ' .. #results .. ' active clamps from database.')
    end
end

function SaveWheelClamps()
    MySQL.query.await('DELETE FROM wheel_clamps')
    
    local inserts = {}
    for plate, _ in pairs(wheelClamps) do
        table.insert(inserts, {plate = plate})
    end
    if #inserts > 0 then
        MySQL.insert.await('INSERT INTO wheel_clamps (plate) VALUES (:plate)', inserts)
        if Config.DebugMode then
            print('Saved ' .. #inserts .. ' clamps to database.')
        end
    elseif Config.DebugMode then
        print('No clamps to save.')
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LoadWheelClamps()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5 * 60 * 1000)
        SaveWheelClamps()
        LoadWheelClamps()
    end
end)

function CheckJob(src)
    if not src or src <= 0 then
        if Config.DebugMode then
            print('Error: Invalid source ID for CheckJob: ' .. tostring(src))
        end
        return false
    end

    -- Lista dozwolonych prac z config.lua
    local allowedJobs = Config.AllowedJobs or { Config.JobName }

    if Config.Standalone then
        if Config.DebugMode then
            print(string.format('CheckJob for source %d (Standalone): Allowed (no job check)', src))
        end
        return #allowedJobs == 0 or true -- Zwraca true, jeśli nie ma ograniczeń pracy
    elseif Config.ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then
            if Config.DebugMode then
                print(string.format('Error: ESX player not found for source %d', src))
            end
            return false
        end
        local jobName = xPlayer.job.name
        local hasPermission = false
        for _, job in ipairs(allowedJobs) do
            if jobName == job then
                hasPermission = true
                break
            end
        end
        if Config.DebugMode then
            print(string.format('CheckJob for source %d (ESX): Job=%s, Allowed=%s', src, jobName, tostring(hasPermission)))
        end
        return hasPermission
    elseif Config.QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then
            if Config.DebugMode then
                print(string.format('Error: QBCore player not found for source %d', src))
            end
            return false
        end
        local jobName = Player.PlayerData.job.name
        local hasPermission = false
        for _, job in ipairs(allowedJobs) do
            if jobName == job then
                hasPermission = true
                break
            end
        end
        if Config.DebugMode then
            print(string.format('CheckJob for source %d (QBCore): Job=%s, Allowed=%s', src, jobName, tostring(hasPermission)))
        end
        return hasPermission
    end

    if Config.DebugMode then
        print('Error: No valid framework configured for CheckJob (source: ' .. tostring(src) .. ')')
    end
    return false
end

RegisterServerEvent('wheelclamp:checkPermission')
AddEventHandler('wheelclamp:checkPermission', function(plate, action, vehicle)
    local src = source
    if not src or src <= 0 then
        if Config.DebugMode then
            print('Error: Invalid source for permission check: ' .. tostring(plate))
        end
        return
    end

    if not plate or not action or (action ~= 'apply' and action ~= 'remove') then
        if Config.DebugMode then
            print('Error: Invalid parameters for permission check - plate: ' .. tostring(plate) .. ', action: ' .. tostring(action))
        end
        TriggerClientEvent('wheelclamp:notify', src, 'Invalid action or vehicle!')
        return
    end

    local allowed = CheckJob(src)
    if Config.DebugMode then
        local framework = Config.Standalone and 'Standalone' or Config.ESX and 'ESX' or Config.QBCore and 'QBCore' or 'Unknown'
        print(string.format('Permission check for %s clamp on %s by source %d (%s): %s', action, plate, src, framework, tostring(allowed)))
    end

    TriggerClientEvent('wheelclamp:permissionResult', src, plate, action, allowed, vehicle)
end)

RegisterServerEvent('wheelclamp:addClamp')
AddEventHandler('wheelclamp:addClamp', function(plate)
    local src = source
    if not src or src <= 0 then
        if Config.DebugMode then
            print('Error: Invalid source for adding clamp: ' .. tostring(plate))
        end
        return
    end
    local xPlayer = Config.ESX and ESX.GetPlayerFromId(src) or nil
    local qbPlayer = Config.QBCore and QBCore.Functions.GetPlayer(src) or nil
    if Config.EnableItem and Config.RemoveItem then
        if Config.ESX and xPlayer then
            if xPlayer.getInventoryItem('wheelclamp').count >= 1 then
                xPlayer.removeInventoryItem('wheelclamp', 1)
            else
                TriggerClientEvent('wheelclamp:notify', src, 'You don\'t have a wheel clamp!')
                return
            end
        elseif Config.QBCore and qbPlayer then
            if qbPlayer.Functions.GetItemByName('wheelclamp') then
                qbPlayer.Functions.RemoveItem('wheelclamp', 1)
                TriggerClientEvent('QBCore:Notify', src, 'Wheel clamp used.', 'success')
            else
                TriggerClientEvent('wheelclamp:notify', src, 'You don\'t have a wheel clamp!')
                return
            end
        end
    end
    wheelClamps[plate] = true
    MySQL.insert.await('INSERT INTO wheel_clamps (plate) VALUES (:plate)', {
        plate = plate
    })
    TriggerClientEvent('wheelclamp:notify', src, 'Wheel clamp applied.')
    if Config.DebugMode then
        print('Added clamp for vehicle: ' .. plate)
    end
end)

RegisterServerEvent('wheelclamp:removeClamp')
AddEventHandler('wheelclamp:removeClamp', function(plate)
    local src = source
    if not src or src <= 0 then
        if Config.DebugMode then
            print('Error: Invalid source for removing clamp: ' .. tostring(plate))
        end
        return
    end

    wheelClamps[plate] = nil
    MySQL.query.await('DELETE FROM wheel_clamps WHERE plate = :plate', {
        plate = plate
    })
    TriggerClientEvent('wheelclamp:notify', src, 'Wheel clamp removed.')
    if Config.DebugMode then
        print('Removed clamp for vehicle: ' .. plate)
    end
end)

RegisterServerEvent('wheelclamp:checkClamp')
AddEventHandler('wheelclamp:checkClamp', function(plate)
    local src = source
    if not src or src <= 0 then
        if Config.DebugMode then
            print('Error: Invalid source for checking clamp: ' .. tostring(plate))
        end
        return
    end

    local hasClamp = wheelClamps[plate] or false
    TriggerClientEvent('wheelclamp:clampStatus', src, plate, hasClamp)
    if Config.DebugMode then
        print('Checked clamp for plate: ' .. plate .. ', hasClamp: ' .. tostring(hasClamp))
    end
end)

exports('AddClamp', function(src, plate)
    if not src or src <= 0 or not plate then
        if Config.DebugMode then
            print('Error: Invalid parameters for AddClamp')
        end
        return false
    end

    if not CheckJob(src) then
        TriggerClientEvent('wheelclamp:notify', src, 'You are not authorized to apply a wheel clamp!')
        return false
    end

    wheelClamps[plate] = true
    MySQL.insert.await('INSERT INTO wheel_clamps (plate) VALUES (:plate)', {
        plate = plate
    })
    TriggerClientEvent('wheelclamp:notify', src, 'Wheel clamp applied.')
    if Config.DebugMode then
        print('Added clamp for vehicle: ' .. plate)
    end
    return true
end)

exports('RemoveClamp', function(src, plate)
    if not src or src <= 0 or not plate then
        if Config.DebugMode then
            print('Error: Invalid parameters for RemoveClamp')
        end
        return false
    end

    if not CheckJob(src) then
        TriggerClientEvent('wheelclamp:notify', src, 'You are not authorized to remove a wheel clamp!')
        return false
    end

    wheelClamps[plate] = nil
    MySQL.query.await('DELETE FROM wheel_clamps WHERE plate = :plate', {
        plate = plate
    })
    TriggerClientEvent('wheelclamp:notify', src, 'Wheel clamp removed.')
    if Config.DebugMode then
        print('Removed clamp for vehicle: ' .. plate)
    end
    return true
end)