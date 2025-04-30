fx_version 'cerulean'
game 'gta5'

author 'PerfQ'
description 'Wheel Clamp Script'
version '1.0.0'

shared_scripts {
	'@es_extended/imports.lua',
	'@es_extended/locale.lua',
	'config.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'oxmysql'
}