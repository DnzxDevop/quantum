local default_reinforcement = 0.2

RegisterNetEvent('quantum_sound:source')
AddEventHandler('quantum_sound:source',function(sound,volume)
	SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = volume })
end)

RegisterNetEvent('quantum_sound:distance')
AddEventHandler('quantum_sound:distance',function(playerid,maxdistance,sound,volume)
	local distance  = Vdist(GetEntityCoords(PlayerPedId()), GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerid))))
	if distance <= maxdistance then
		SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = volume })
	end
end)

RegisterNetEvent('quantum_sound:fixed')
AddEventHandler('quantum_sound:fixed',function(playerid,x2,y2,z2,maxdistance,sound,volume)
	local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
	local distance = GetDistanceBetweenCoords(x2,y2,z2,x,y,z,true)
	if distance <= maxdistance then
		SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = volume })
	end
end)

RegisterNetEvent('quantum_sound:vehicle')
AddEventHandler('quantum_sound:vehicle',function(veh,maxdistance,sound,reinforcement)
	if NetworkDoesEntityExistWithNetworkId(veh) then
		local v = NetToVeh(veh)
		if DoesEntityExist(v) then
			local distance = #( GetEntityCoords(PlayerPedId()) - GetEntityCoords(v) )	
			if distance <= maxdistance then
				local vol = (1 - (distance/maxdistance))+(reinforcement or default_reinforcement)
				if vol > 1 then	vol = 1 end		
				SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = tonumber(string.format("%.2f",vol)) })
			end
		end
	end
end)

RegisterNetEvent('quantum_sound:variation:fixed')
AddEventHandler('quantum_sound:variation:fixed',function(x,y,z,maxdistance,sound,reinforcement)
	local distance = #( GetEntityCoords(PlayerPedId()) - vector3(x,y,z) )	
	if distance <= maxdistance then
		local vol = (1 - (distance/maxdistance))+(reinforcement or default_reinforcement)
		if vol > 1 then	vol = 1 end
		SendNUIMessage({ transactionType = 'playSound', transactionFile = sound, transactionVolume = tonumber(string.format("%.2f",vol)) })
	end
end)