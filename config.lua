Config = {}

Config.DebugMode = true
Config.ESX = true
Config.QBCore = false
Config.Standalone = false
Config.EnableCommands = true
Config.JobName = 'police'
Config.EnableItem = false
if Config.EnableItem and Config.EnableCommands then
    Config.EnableItem = false
    print('Warning: Item and command enabled. Defaulting to command only.')
end

if Config.EnableItem and not Config.ESX then
    Config.EnableItem = false
    print('Warning: Item and command enabled. Defaulting to command only.')
end

if Config.ESX and (Config.QBCore or Config.Standalone) then
    Config.ESX = false
    print('Warning: Multiple frameworks enabled. Defaulting to Standalone.')
end
if Config.QBCore and Config.Standalone then
    Config.QBCore = false
    print('Warning: Multiple frameworks enabled. Defaulting to Standalone.')
end