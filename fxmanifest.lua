fx_version "cerulean"
game "gta5"
author "NoName Scripts"
description "NoName Caption"

client_script "client/*.lua"
server_script "server/*.lua"
server_script '@oxmysql/lib/MySQL.lua'


shared_script "config.lua"
shared_script "@ox_lib/init.lua"
shared_script "@es_extended/imports.lua"