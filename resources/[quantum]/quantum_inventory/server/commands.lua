-- Adicionar item ao inventário do staff que executou o item
RegisterCommand('item', function(source, args) 
    local _source = source
    local user_id = quantum.getUserId(_source)
    local item = args[1]
    local amount = (tonumber(args[2]) or 1)
    
    if quantum.hasPermission(user_id, '+Staff.Administrador') then
        if config.items[item] then
            sInventory.giveInventoryItem(user_id, item, amount)    
            quantum.formatWebhook('spawnItem', 'Spawnou', {
                { 'id', user_id },
                { 'Item', item },
                { 'Qtd', amount },
            })
            config.functions.serverNotify(_source, config.texts.notify_title, config.texts.notify_receive_item(amount, item))
        else
            config.functions.serverNotify(_source, config.texts.notify_title, config.texts.notify_non_existent_item)
        end

        local identity = quantum.getUserIdentity(user_id)
    end
end)

-- Limpa hotbar e bag do player
RegisterCommand('cinv', function(source, args)
    local user_id = (args[1] and parseInt(args[1]) or quantum.getUserId(source))
    if (quantum.hasPermission(user_id, '+Staff.COO')) then
        if (exports.quantum_hud:request(source, 'Deseja realmente limpar o inventário do id '..user_id..'?')) then
            sInventory.clearInventory(user_id)
            quantum.formatWebhook('delBag', 'Limpar Inventario', {
                { 'staff', quantum.getUserId(source) },
                { 'id', user_id }
            })
            config.functions.serverNotify(source, config.texts.notify_title, config.texts.notify_success_delete_bag('do jogador de id '..user_id))
        end
    end
end)

-- Limpa todos os grops do chão
RegisterCommand('clearground', function(source, args)
    local user_id = quantum.getUserId(source)
    if (quantum.hasPermission(user_id, '+Staff.COO')) then
        droppedItems = {}
        TriggerClientEvent('updateDroppedItems', -1, droppedItems)
    else
        config.functions.serverNotify(source, config.texts.notify_title, config.texts.notify_no_has_permission)
    end
end)