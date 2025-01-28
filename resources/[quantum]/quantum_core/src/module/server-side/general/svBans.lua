quantum.prepare('quantum_hwid/setUserTokens', 'replace into hwid (token, user_id) values (@token, @user_id)')
quantum.prepare('quantum_hwid/getUserTokens', 'select * from hwid where token = @token')
quantum.prepare('quantum_hwid/getUserIpBanned', 'select id from users where ip = @ip and banned = 1')
quantum.prepare('quantum_hwid/userIsBanned', 'select banned from users where id = @user_id')
quantum.prepare('quantum_hwid/setUserBanned', 'update users set banned = @banned where id = @user_id')

local userIsBanned = function(user_id)
    local getBanned = quantum.query('quantum_hwid/userIsBanned', { user_id = user_id })[1]
    if (getBanned) and getBanned.banned == 1 then 
        return true
    end
    return false
end
exports('isBanned', userIsBanned)

local setUserBanned = function(user_id, banned)
    quantum.execute('quantum_hwid/setUserBanned', { user_id = user_id, banned = banned } )
    quantum.execute('quantum_bans/insertRecord', { user_id = user_id, staff_id = 1, ban_type = 'ban', ban_reason = 'Cheating' })
end
exports('setBanned', setUserBanned)

quantum.prepare('quantum_bans/insertRecord', 'insert into banned_records (user_id, staff_id, ban_type, ban_date, ban_reason) values (@user_id, @staff_id, @ban_type, @ban_date, @ban_reason)')
quantum.prepare('quantum_bans/getRecord', 'select * from banned_records where user_id = @user_id')

local insertBanRecord = function(user_id, banned, admin_id, reason)
    if (user_id) then
        local action = ((banned and 'ban') or 'unban')
        quantum.execute('quantum_bans/insertRecord', { user_id = user_id, staff_id = admin_id, ban_type = action, ban_reason = reason })
    end
end
exports('insertBanRecord', insertBanRecord)

local getBanRecord = function(user_id)
    local query = quantum.query('quantum_bans/getRecord', { user_id = user_id })
    if (query) then
        for k, v in pairs(query) do
            if (v.ban_type == 'ban') then
                return v.ban_reason, v.ban_date, v.staff_id
            end
        end
    end
    return 'Desconhecido', 'Desconhecido', 'Desconhecido'
end
exports('getBanRecord', getBanRecord)

AddEventHandler('quantum:playerSpawn', function(user_id, source, firstSpawn)
    local userTokens = GetNumPlayerTokens(source)
    local identifiers = quantum.getIdentifiers(source)
    if (identifiers.ip) then
        local playerIP = identifiers.ip:gsub('ip:', '')
        local rows = quantum.query('quantum_hwid/getUserIpBanned', { ip = playerIP })
        if (#rows > 0) then
            local users = ''
            for _, value in ipairs(rows) do
                users = users..value.id..', '
            end
            print('^5[quantum SYSTEM]^7 IP BANIDO: '..playerIP..' | PLAYER: '..user_id..' | IDS: '..users)
            quantum.webhook('IpBanned', '```prolog\n[quantum SYSTEM - IP BANNED]\n[PASSAPORTE]: '..user_id..'\n[IP BANNED]: '..(playerIP or '0.0.0')..'\n\n[USERS]: '..users..'\n'..((banido and '[BANIDO AUTOMATICAMENTE]\n') or '')..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S')..'\n```')
        end
    end
    for i = 0, userTokens do
        local token = GetPlayerToken(source, i)
        if (token) then
            local getUserTokens = quantum.query('quantum_hwid/getUserTokens', { token = token })[1]
            if (getUserTokens) then
                if (userIsBanned(getUserTokens.user_id)) then
                    setUserBanned(user_id, true)
                    DropPlayer(source, '[quantum SYSTEM] Você já foi banido neste servidor.\n[ID ANTIGO]: '..getUserTokens.user_id..'\n[ID ATUAL]: '..user_id..'\nEntre em contato conosco em nosso discord. discord.gg/example')
                    quantum.webhook('Hwid', '```prolog\n[quantum SYSTEM - HWID BANNED]\n[PASSAPORTE]: '..user_id..'\n[ID BANNED]: '..getUserTokens.user_id..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S')..'\n```')
                end
            else
                quantum.execute('quantum_hwid/setUserTokens', { token = token, user_id = user_id } )
            end
        end
    end
end)