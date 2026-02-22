fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dps-clothingbrowser'
description 'Admin tool for browsing, identifying, and exporting clothing/uniform configurations'
version '1.0.0'
author 'DPS'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/browser.lua',
}

server_scripts {
    'server/main.lua',
}
