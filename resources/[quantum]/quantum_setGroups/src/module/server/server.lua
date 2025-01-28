srv = {}
Tunnel.bindInterface(GetCurrentResourceName(), srv)
vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

local baseGroups = {}

GetGroups = function()
    return config.groups
end
exports('GetGroups', GetGroups)

painelSysGroups = function()
    baseGroups = {}
    for group, groupData in pairs(config.groups) do
        if groupData.information and groupData.information.grades then
            local grades = {}
            for k,_ in pairs(groupData.information.grades) do
                table.insert(grades, k)
            end
            table.insert(baseGroups,{ group = group, grades = grades })
        else
            table.insert(baseGroups,{ group = group, grades = { group } })
        end
    end
end
Citizen.CreateThread(painelSysGroups)

painelUserGroups = function(user_id)
    local cb = {}
    for group, info in pairs(quantum.getUserGroups(user_id)) do
        table.insert(cb, { group = group, grade = info.grade })
    end
    return cb
end

RegisterCommand('group', function(source, args)
    print('1')
    local user_id = quantum.getUserId(source)
    if (user_id) and quantum.hasPermission(user_id, '+Staff.Manager') then
        local prompt = quantum.prompt(source, { 'Passaporte' })
        if (prompt) then
            prompt = prompt[1]
            
            local usergroups = painelUserGroups(prompt)
            local identity = (quantum.getUserIdentity(prompt) or 'Indivíduo Indigente')
            vCLIENT.openNui(source, identity, usergroups, baseGroups)
        end
    end
end)

srv.addGroup = function(id, group, grade)
    local source = source
    quantum.addUserGroup(id, group, grade)
    vCLIENT.updateNui(source, painelUserGroups(id))
    quantum.webhook('Group', '```prolog\n[quantum GROUPS]\n[ACTION]: (ADD GROUP)\n[USER]: '..quantum.getUserId(source)..'\n[TARGET]: '..id..'\n[GROUP]: '..group..'\n[GRADE]: '..grade..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S')..' \r```')
end

srv.delGroup = function(id, group, grade)
    local source = source
    quantum.removeUserGroup(id, group)
    vCLIENT.updateNui(source, painelUserGroups(id))
    quantum.webhook('UnGroup', '```prolog\n[quantum GROUPS]\n[ACTION]: (UNGROUP)\n[USER]: '..quantum.getUserId(source)..'\n[TARGET]: '..id..'\n[GROUP]: '..group..'\n[GRADE]: '..grade..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S')..' \r```')
end

itsAJob = function(org)
    for k,v in pairs(config.groups) do
        if v.information.groupType == 'job' then
            if k == org then return true end
        end 
    end
    return false
end
exports('itsAJob', itsAJob)