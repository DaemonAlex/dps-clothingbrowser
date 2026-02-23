fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dps-clothingbrowser'
description 'Admin tool for browsing, identifying, and exporting clothing/uniform configurations'
version '2.0.0'
author 'DPS'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/styles/main.css',
    'ui/js/utils.js',
    'ui/js/app.js',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/browser.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql',
}
