local srv = {}
Tunnel.bindInterface('Robberys', srv)
local vCLIENT = Tunnel.getInterface('Robberys')

local robberyCooldown = {}
local payment = 0

local callPolice = function(coord, name)
    local police = quantum.getUsersByPermission('policia.permissao')
    for k, v in pairs(police) do
        local source = quantum.getUserSource(parseInt(v))
        if (source) then
            async(function()
                TriggerClientEvent('quantum_robberys:Blip', source, coord, name)
                TriggerClientEvent('notifypush', source, {
                    code = 'QRU',
                    title = name,
                    description = 'Denúncia Anônima',
                    coords = coord
                })
                -- TriggerClientEvent('announcement', source, 'Roubo em andamento', 'Roubo ao(a) <b>'..name..'</b>', 'Delegacia quantum', true, 10000)
            end)
        end
    end
end

srv.checkRobbery = function(index)
    local source = source
    local user_id = quantum.getUserId(source)
    if (user_id) then
        local _config = Robberys.general[Robberys.locations[index].config]
        
        local id = Robberys.locations[index].id
        local cooldown = (id and tostring(Robberys.locations[index].config..'-'..id) or Robberys.locations[index].config)
        if (robberyCooldown[cooldown]) then
            TriggerClientEvent('notify', source, 'Roubo', 'Aguarde <b>'..robberyCooldown[cooldown]..' segundos</b> para roubar este cofre novamente!')
            return false
        end

        if (_config.lspd) then
            local police = quantum.getUsersByPermission('policia.permissao')
            if (#police < _config.lspd) then
                TriggerClientEvent('notify', source, 'Roubo', 'Não possui <b>contingente</b> o suficiente para fazer essa ação. <br><br> É necessário <b>'.._config.lspd..' policias</b> para realizar esta ação.')
                return false
            end
        end

        if (_config.requireItens) then
            if (not necessaryItens(user_id, _config.requireItens)) then
                return false
            end
        end

        if (_config.task) then
            if (not exports[GetCurrentResourceName()]:Task(source, 4, 8000)) then
                TriggerClientEvent('notify', source, 'Roubo', 'Você falhou na <b>task</b>!')
                return false
            end
        end

        payment = _config.payment
        callPolice(Robberys.locations[index].coord, Robberys.locations[index].name)
        startCooldown(cooldown, _config.cooldown)
        vCLIENT.startRobbery(source, _config, Robberys.locations[index])
        quantum.webhook('Roubos', '```prolog\n[ROBBERY]\n[USER]: '..user_id..'\n[LOCAL]: '..Robberys.locations[index].name..'\n[VALUE]: R$'..quantum.format(payment)..'\n[COORDENADA]: '..tostring(GetEntityCoords(GetPlayerPed(source)))..' '..os.date('\n[DATE]: %d/%m/%Y [HOUR]: %H:%M:%S')..' \r```')
    end
end

srv.robberyPayment = function(seconds)
    local source = source
    local user_id = quantum.getUserId(source)
    if (user_id) then
        local format = math.floor((payment / seconds))
        if (format >= 1) then
            quantum.giveInventoryItem(user_id, 'dinheirosujo', format)
            TriggerClientEvent('notify', source, 'Roubo', 'Você recebeu <b>R$'..quantum.format(format)..'</b> de dinheiro sujo!')
        end
    end
end

srv.cancelRobbery = function(name)
    local police = quantum.getUsersByPermission('policia.permissao')
    for k, v in pairs(police) do
        local source = quantum.getUserSource(parseInt(v))
        if (source) then
            async(function()
                TriggerClientEvent('quantum_robberys:Blip', source, coord, name)
                TriggerClientEvent('notifypush', source, {
                    code = 'QRU',
                    title = 'Assaltante fugiu',
                    description = 'Denúncia Anônima',
                    coords = GetEntityCoords(GetPlayerPed(source))
                })
                -- TriggerClientEvent('announcement', source, 'Assaltante fugiu', 'Do roubo ao(a) <b>'..name..'</b>', 'Delegacia quantum', true, 10000)
            end)
        end
    end
end

local getItens = function(user_id, itens)
    for k, v in pairs(itens) do
        quantum.tryGetInventoryItem(user_id, k, v)
    end
end

necessaryItens = function(user_id, itens)
    for k, v in pairs(itens) do
        if (quantum.getInventoryItemAmount(user_id, k) < v) then
            TriggerClientEvent('notify', quantum.getUserSource(user_id), 'Roubo', 'Você não possui <b>'..v..'x</b> de <b>'..quantum.itemNameList(k)..'</b>.')
            return false
        end
    end
    getItens(user_id, itens)
    return true
end

startCooldown = function(id, time)
    Citizen.CreateThread(function()
        robberyCooldown[id] = time
        while (robberyCooldown[id] > 0) do
            Citizen.Wait(1000)
            robberyCooldown[id] = (robberyCooldown[id] - 1)
        end
        robberyCooldown[id] = nil
    end)
end