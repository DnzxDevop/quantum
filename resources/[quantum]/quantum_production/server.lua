sProduction = {}
Tunnel.bindInterface('quantum_production', sProduction);

sProduction.validateProduction = function(index, amount, org)
    local _source = source
    local user_id = quantum.getUserId(_source)

    local validatedProduction = true
    local materials = configs.productions[org].products[index].materials
    for k,v in pairs(materials) do
        if quantum.getInventoryItemAmount(user_id, k) < v.amount then
            validatedProduction = false
            break;
        end
    end

    if validatedProduction then 
        for k,v in pairs(materials) do
            quantum.tryGetInventoryItem(user_id, k, v.amount)
        end
        return true
    else
        return false
    end
end

sProduction.giveItem = function(index, amount, org)
    local _source = source
    local user_id = quantum.getUserId(_source)

    quantum.giveInventoryItem(user_id, index, amount)
    quantum.formatWebhook(configs.productions[org].webhook, 'Enviar item', {
        { 'item', quantum.itemNameList(index) },
        { 'id', user_id },
        { 'qtd', amount }
    })
    TriggerClientEvent("notify", _source, 'Produção', 'Você produziu '..amount..' '..quantum.itemNameList(index)..'!')
end

sProduction.hasPermission = function(perm)
    local _source = source
    local user_id = quantum.getUserId(_source)

    return quantum.checkPermissions(user_id, perm)
end

sProduction.moneyLaundry = function(production)
    local moneyPerFical = configs.moneyPerFiscal
    local governTax = configs.governTax
    if production.buff then
        governTax = configs.governTaxWithBuff
    end

    local _source = source
    local user_id = quantum.getUserId(_source)
    local response = exports.quantum_hud:prompt(_source, {
        'Valor em dinheiro sujo:'
    })

    if response then
        response = parseInt(response[1])
        if response > 0 and response % moneyPerFical == 0 then
            local totalBeforeLaundry = response - response * governTax
            if exports.quantum_hud:request(_source, 'Você deseja lavar R$'..quantum.format(response)..' de dinheiro sujo gastando '..parseInt(response/moneyPerFical)..' notas fiscais?', 15000) then
                if quantum.getInventoryItemAmount(user_id, 'dinheirosujo') >= response then
                    if quantum.getInventoryItemAmount(user_id, 'nota-fiscal') >= parseInt(response/moneyPerFical) then
                        if quantum.tryGetInventoryItem(user_id, "dinheirosujo", response) and quantum.tryGetInventoryItem(user_id, "nota-fiscal", parseInt(response/moneyPerFical)) then
                            local ped = GetPlayerPed(_source)
                            TriggerClientEvent('quantum_animations:setAnim', _source, 'mexer')
                            Player(_source).state.BlockTasks = true
                            FreezeEntityPosition(ped, true) 
                            TriggerClientEvent('progressBar', _source, 'Lavando dinheiro', 10000)
                            Wait(10000)    
                            FreezeEntityPosition(ped, false)
                            ClearPedTasks(ped)
                            quantum.givePaypalMoney(user_id, totalBeforeLaundry)
                            Player(_source).state.BlockTasks = false
                            TriggerClientEvent('notify', _source, 'Lavagem de Dinheiro', 'Foram adicionados R$'..quantum.format(totalBeforeLaundry)..' na sua conta do Paypal! Não se esqueça de entregar 60% do valor inicial ao cliente.', 10000);
                            quantum.formatWebhook(production.webhook, 'Lavagem', {
                                { 'id', user_id },
                                { 'Dinheiro Sujo', 'R$'..quantum.format(response) },
                                { 'Notas Fiscais', response/moneyPerFical },
                                { 'Dinheiro enviado ao Paypal', 'R$'..quantum.format(response - response * governTax) },
                            })
                        else
                            DropPlayer(_source, 'Transação ilegal! Abra ticket.')
                            exports.quantum_core:setBanned(user_id, true)
                            exports.quantum_core:insertBanRecord(user_id, true, -1, '[PRODUCTION] Transação ilegal!')
                        end
                    else
                        TriggerClientEvent('notify', _source, 'Lavagem de Dinheiro', 'Você não possui <b>notas fiscais</b> suficientes!', 10000);
                    end
                else
                    TriggerClientEvent('notify', _source, 'Lavagem de Dinheiro', 'Você não possui <b>dinheiro sujo</b> suficiente!', 10000);
                end
            end
        else 
            TriggerClientEvent('notify', _source, 'Lavagem de Dinheiro', 'O valor inserido precisa ser multiplo de 100000. Exemplos: 100000, 200000, 500000...', 20000);
        end
    end
end

sProduction.openSellDrugs = function(production)
    local drugs = {'maconha', 'metanfetamina', 'cocaina', 'lanca-perfume'}
    local _source = source
    local user_id = quantum.getUserId(_source)

    local response = exports.quantum_hud:prompt(_source, {
        'Quantidade de droga: (min: 10/max: 125)'
    })

    if response then
        response = tonumber(response[1])
        if response ~= nil then
            if response >= 10 and response < 126 then
                if exports.quantum_hud:request(_source, 'Você deseja vender '..response..' droga?', 15000) then
                    local hasDrugs = false
                    for k,v in pairs(drugs) do
                        if quantum.tryGetInventoryItem(user_id, v, response) then
                            hasDrugs = true
                            break
                        end
                    end 

                    if hasDrugs then
                        quantum.giveInventoryItem(user_id, 'dinheirosujo', response * 750)
                        quantum.formatWebhook(production.webhook, 'Venda de droga ao NPC', {
                            { 'id', user_id },
                            { 'Qtd de Drogas', response},
                            { 'Valor recebido', 'R$'..quantum.format(response * 750)},
                        })
                        TriggerClientEvent('notify', _source, 'Tráfico', 'Você vendeu uns produtinhos!')
                    else    
                        TriggerClientEvent('notify', _source, 'Tráfico', 'Você não possui essa quantidade de droga!')
                    end
                end
            else
                TriggerClientEvent('notify', _source, 'Tráfico', 'Você precisa digitar um número inteiro entre 10 e 126!')
            end
        else
            TriggerClientEvent('notify', _source, 'Tráfico', 'Você precisa digitar um número inteiro entre 10 e 126!')
        end
    end
end