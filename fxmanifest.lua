fx_version 'cerulean'
game 'gta5'

description 'Draco Library'
name 'Draco Scripts: [d_lib]'
author 'Draco'
version '2.9.2'
lua54 'yes'

shared_scripts {
    'config.lua',
    'locale.lua',
    'loader.lua',
    'resource/init.lua',
    'resource/**/shared.lua'
}

server_scripts {
    'sv_config.lua',
    'imports/callback/server.lua',
    'imports/getFilesInDirectory/server.lua',
    'resource/**/server.lua'
}

client_scripts {
    'resource/**/client.lua'
}

ui_page {
    'html/index.html'
}

files {
    'init.lua',
    'imports/**/client.lua',
    'imports/**/shared.lua',
    'html/css/*.css',
    'html/js/*.js',
    'html/images/*.png',
    'html/sounds/*.ogg',
    'html/index.html'
}

dependencies {
    '/server:7290',
    '/onesync',
}

escrow_ignore {
	'**.*'
}
