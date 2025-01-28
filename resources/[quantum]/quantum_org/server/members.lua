gbMembers = {}

Tunnel.bindInterface('core_ilegal/members', gbMembers)


quantum.prepare("members/getAllMembers", "select * from user_groups where groupId = @fac")
quantum.prepare("members/countAllMembers", "select COUNT(*) from user_groups where groupId = @fac")

--======================================================================================================================
local webhook_enterBlack = "dndcwebhook/webhooks/1151367537737609216/SQvQJpCCupPTEcsf2hr6d8c1t-wBQBv5vusspjEhDVr1EuKIcGdc_BVCsWzLzcw_UQ-P"
local webhook_exitBlack = "dndcwebhook/webhooks/1151367637054529587/DRt1kRhR1CxHg5UKE0ByP2hCpiQBOrHrHj1Mo-UvBfUkAI3d_ahif_84MYP9dffNS8G2"

quantum.prepare("members/getBlacklist", "SELECT * FROM facs_blacklist WHERE user_id = @user_id")
quantum.prepare("members/setBlacklist", "REPLACE INTO facs_blacklist(user_id,org,expires) VALUES(@user_id,@org,@expires)")
quantum.prepare("members/delBlacklist", "DELETE FROM facs_blacklist WHERE user_id = @user_id")

gbMembers.inBlacklist = function(user_id)
    local data = quantum.query("members/getBlacklist",{ user_id = user_id })
    return data[1] or false
end

gbMembers.setBlacklist = function(user_id,org,days)
    local expires = os.time() + parseInt(86400*days)
    quantum.execute("members/setBlacklist",{ user_id = user_id, org = org, expires = expires})
    local identity = quantum.getUserIdentity(user_id)
    quantum._webhook(webhook_enterBlack,"```prolog\n[ID]: "..user_id.." "..identity.firstname.." "..identity.lastname.."\n[FAC]: "..org.."\n[BLACKLIST]: "..days.." dias\n"..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S ```'))
end
exports("setBlacklist",gbMembers.setBlacklist)

delBlacklist = function(user_id)
    local blacklist = gbMembers.inBlacklist(user_id)
    if blacklist then
        quantum.execute("members/delBlacklist",{ user_id = user_id })
        local identity = quantum.getUserIdentity(user_id)
        quantum._webhook(webhook_exitBlack,"```prolog\n[LOJA]\n[ID]: "..user_id.." "..identity.firstname.." "..identity.lastname.."\n[FAC]: "..blacklist.org.."\n[SAIU BLACKLIST]\n"..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S ```'))
        return true
    end
end
exports("delBlacklist",delBlacklist)

AddEventHandler("quantum:playerSpawn",function(user_id, source)
    local blacklist = gbMembers.inBlacklist(user_id)
    if blacklist then
        blacklist.expires = parseInt(blacklist.expires)
        if (os.time() > blacklist.expires) then
            quantum.execute("members/delBlacklist",{ user_id = user_id })
            TriggerClientEvent("notify",source,"Blacklist","Seu tempo de Blacklist terminou! Você já pode se candidatar á uma nova <b>Organização</b>!",30000)
            local identity = quantum.getUserIdentity(user_id)
            quantum.webhook(webhook_exitBlack,"```prolog\n[ID]: "..user_id.." "..identity.firstname.." "..identity.lastname.."\n[FAC]: "..blacklist.org.."\n[SAIU BLACKLIST]\n"..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S ```'))
        else
            local exp_date = os.date("%d/%m/%Y às %H:%M", blacklist.expires)
            TriggerClientEvent("notify",source,"Blacklist","Você está na Blacklist! Aguarde até <b>"..exp_date.."</b> ou compre a remoção na Loja!",30000)
        end
    end
end)
--======================================================================================================================

local webhook_admit = "dndcwebhook/webhooks/1107712903827697674/3d3Q5HaCpaTVumlVbj6v5EQqz8epojvtVKjVnn3PkfaODsuae4-2QB5vPHFys9kWu3Xd"
local webhook_dismiss = "dndcwebhook/webhooks/1107712996555366501/AB7vJGjwkaNp7Uwc4q9V8irEvxsJrQ976zPRsb7dTobq98Tj5Aehd38YqgmIf7tFICdH"

gbMembers.getMembersAmount = function(fac)
    return { amount = quantum.scalar('members/countAllMembers', { fac = fac }), vagas = config.organizations[fac].vagas }
end

gbMembers.getPermissions = function(id)
    local _source = source
    local userGroup, groupInfo
    
    local user_id = id or quantum.getUserId(_source)

    userGroup, groupInfo = quantum.getUserGroupByType(user_id,'fac') 
    if not userGroup then
        userGroup, groupInfo = quantum.getUserGroupByType(user_id,'job')
    end

    if userGroup and config.organizations[userGroup] then
        return { fac = userGroup, role = groupInfo.grade, fac_type = quantum.getGroupType(userGroup), permissions_roles = config.organizations[userGroup].roles, has_products = config.organizations[userGroup].products ~= nil }
    end
end

gbMembers.getAllMembers = function(fac)
    local result = quantum.query('members/getAllMembers', { fac = fac })
    local cb = {}
    for k,v in pairs(result) do
        local userData = quantum.getUserIdentity(v.user_id)
        table.insert(cb,{
            user_id = v.user_id,
            fac = v.groupId, 
            role = v.gradeId,
            name = userData.firstname .." ".. userData.lastname,
            rg = userData.registration,
            phone = userData.phone,
            age = userData.age,
            status = getServiceState(fac,v.user_id)
        })
    end
    return cb
end

gbMembers.searchUser = function(user_id)
    local userData = quantum.getUserIdentity(user_id)
    if userData then
        userData.name = userData.firstname .." ".. userData.lastname 
        userData.rg = userData.registration
        return userData
    end
    return { name = 'Desconhecido', rg = '?', phone = '?' }
end

gbMembers.admit = function(fac, user_id)
    local leader_id = quantum.getUserId(source)
    local leader_idt = quantum.getUserIdentity(leader_id)

    local allMembers = gbMembers.getAllMembers(fac)
    local permission = gbMembers.getPermissions(user_id)
    local user_source = quantum.getUserSource(user_id)

    if (not user_source) then
        return { result = 'error', message = 'Membro fora da Cidade!' }
    end
    if #allMembers < config.organizations[fac].vagas then 
        if permission ~= nil then
            return { result = 'error', message = 'Cidadão já pertence a uma organização!' }
        else
            if (not gbMembers.inBlacklist(user_id)) then
                local response = quantum.request(user_source,'Você foi convidado para a organização '..fac..'. Deseja aceitar?',30000)
                if response then
                    local grades = config.organizations[fac].grades
                    quantum.addUserGroup(user_id,fac, grades[#grades] )
                    TriggerClientEvent('Notify',user_source,'sucesso','Você acabou de ser contratado pela <b>'..fac..'</b>.')
                     
                    local identity = quantum.getUserIdentity(user_id)
                    quantum._webhook(webhook_admit,"```prolog\n[ID]: "..leader_id.." "..leader_idt.firstname.." "..leader_idt.lastname.."\n[FAC]: "..fac.." ("..grades[#grades]..")\n[CONTRATOU]: "..user_id.." "..identity.firstname.." "..identity.lastname.."\n"..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S ```'))
                    
                    return { result = 'success', message = 'Membro contratado com sucesso!' }
                else
                    TriggerClientEvent('Notify',user_source,'negado','Você acabou de recusar uma proposta da organização <b>'..fac..'</b>.')
                    return { result = 'error', message = 'O passaporte '..user_id..' recusou a oferta!' }
                end
            else
                return { result = 'error', message = 'Cidadão na Blacklist!' }
            end
        end
    else 
        return { result = 'error', message = 'A organização já atingiu o limite máximo de membros!' }
    end
end

gbMembers.dismiss = function(fac, user_id)
    local leader_id = quantum.getUserId(source)
    local leader_idt = quantum.getUserIdentity(leader_id)

    local user_source = quantum.getUserSource(user_id)
    local hasGroup, hasGrade = quantum.hasGroup(user_id,fac)
    if hasGroup then
        if searchGradeIndex(fac, hasGrade) > 1 then 
            quantum.removeUserGroup(user_id, fac )
            gbMembers.setBlacklist(user_id, fac, 7)
            if user_source then          
                TriggerClientEvent('Notify',user_source,'negado','Você acabou de ser demitido da organização <b>'..fac..'</b> e entrou na Blacklist.')
            end

            local identity = quantum.getUserIdentity(user_id)
            quantum._webhook(webhook_dismiss,"```prolog\n[ID]: "..leader_id.." "..leader_idt.firstname.." "..leader_idt.lastname.."\n[FAC]: "..fac.." ("..tostring(hasGrade)..")\n[DEMITIU]: "..user_id.." "..identity.firstname.." "..identity.lastname.."\n"..os.date('\n[DATA]: %d/%m/%Y [HORA]: %H:%M:%S ```'))

            return { result = 'success', message = 'Membro demitido com sucesso!' }
        else
            return { result = 'error', message = 'Você não pode demitir lideres da organização!' }
        end
    else 
        return { result = 'error', message = 'Você só pode demitir membros da organização!' }
    end
end

gbMembers.updateRole = function(fac, user_id, method)
    local _source = source
    local current_user_id = quantum.getUserId(_source)
    local user_source = quantum.getUserSource(user_id)
    if user_id ~= current_user_id then
        local hasGroup, hasGrade = quantum.hasGroup(user_id,fac)
        if hasGroup then
            local grades = config.organizations[fac].grades

            if (method == 'promote') then

                local currIdx = searchGradeIndex(fac, hasGrade)
                local newIdx = (currIdx-1)
                if (newIdx > 1) then
                    quantum.addUserGroup(user_id, fac, grades[newIdx] )
                    if user_source then
                        TriggerClientEvent('Notify',user_source,'sucesso','Agora você é um '..grades[newIdx]..' na organização <b>'..fac..'</b>.')
                    end
                    return { result = 'success', message = 'Cargo de membro alterado com sucesso!' }
                else
                    return { result = 'error', message = 'Cargo do membro atingiu o máximo!' }
                end
                            
            elseif (method == 'downgrade') then

                local currIdx = searchGradeIndex(fac, hasGrade)
                local newIdx = (currIdx+1)
                if (currIdx > 1) and (newIdx <= #grades) then
                    quantum.addUserGroup(user_id, fac, grades[newIdx] )          
                    if user_source then
                        TriggerClientEvent('Notify',user_source,'sucesso','Agora você é um '..grades[newIdx]..' na organização <b>'..fac..'</b>.')
                    end
                    return { result = 'success', message = 'Cargo de membro alterado com sucesso!' }
                else
                    return { result = 'error', message = 'Cargo do membro atingiu o mímimo!' }
                end

            end
          
        else
            return { result = 'error', message = 'Não reconhecemos o membro dessa organização!' }
        end
    else 
        return { result = 'error', message = 'Você não pode alterar o cargo deste usuário!' }
    end
    return { result = 'error', message = 'Sistema Indisponivel.' }
end

searchGradeIndex = function(fac,grade) 
    for i=1, #config.organizations[fac].grades do 
        if config.organizations[fac].grades[i] == grade then 
            return i 
        end
    end
    return 0
end


local serviceCheckers = { 
    online = function(user_id,group)
        return (quantum.getUserSource(user_id) ~= nil)
    end,

    active = function(user_id,group)
        return (quantum.getUserSource(user_id) and quantum.hasGroupActive(user_id,group))
    end,
}

getServiceState = function(fac,user_id)
    local cfg = config.organizations[fac]
    if cfg and cfg.serviceCheck then
        return serviceCheckers[cfg.serviceCheck](user_id,fac)
    end
    return false
end