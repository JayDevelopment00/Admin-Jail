fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Jay'
description 'Simple Admin Jail Script Made By Jay Development'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

escrow_ignore {
    'config.lua'
}

dependencies {
    'ox_lib'
}
