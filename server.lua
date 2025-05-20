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
    if Config.Standalone then
        return true
    elseif Config.ESX then
        if not ESX then
            if Config.DebugMode then
                print('Error: ESX framework not loaded.')
            end
            return false
        end
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.job.name == Config.JobName
    elseif Config.QBCore then
        if not QBCore then
            if Config.DebugMode then
                print('Error: QBCore framework not loaded.')
            end
            return false
        end
        local Player = QBCore.Functions.GetPlayer(src)
        return Player and Player.PlayerData.job.name == Config.JobName
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

    local allowed = CheckJob(src)
    if Config.DebugMode then
        print('Permission check for ' .. action .. ' clamp on ' .. plate .. ' by source ' .. src .. ': ' .. tostring(allowed))
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