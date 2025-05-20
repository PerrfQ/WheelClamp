Config = {}
Config.DebugMode = true
Config.ESX = true
Config.QBCore = false
Config.RemoveItem = true
Config.Standalone = false
Config.EnableCommands = true
Config.JobName = 'police'
Config.EnableItem = true -- Włącz obsługę przedmiotu

if Config.EnableItem and not Config.ESX then
    Config.EnableItem = false
    print('Warning: Item enabled but ESX not active. Disabling item support.')
end
if Config.ESX and (Config.QBCore or Config.Standalone) then
    Config.ESX = false
    print('Warning: Multiple frameworks enabled. Defaulting to Standalone.')
end
if Config.QBCore and Config.Standalone then
    Config.QBCore = false
    print('Warning: Multiple frameworks enabled. Defaulting to Standalone.')
end