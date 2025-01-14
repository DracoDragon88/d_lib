dlib.player = {}

dlib.player.GetPlayers = function()
	local players = {}

	for _,player in ipairs(GetActivePlayers()) do
		local ped = GetPlayerPed(player)

		if DoesEntityExist(ped) then
			table.insert(players, player)
		end
	end

	return players
end

dlib.player.GetClosestPlayer = function(_coords, notme)
	local AllPlayers      = dlib.player.GetPlayers()
	local closestDistance = -1
	local closestPlayer   = -1
	local coords          = _coords
	local usePlayerPed    = notme or false
	local playerPed       = PlayerPedId()
	local playerId        = PlayerId()
	if coords == nil then
		usePlayerPed = true
		coords       = GetEntityCoords(playerPed)
	end

	for _, player in ipairs(AllPlayers) do
		local target = GetPlayerPed(player)

		if not usePlayerPed or (usePlayerPed and player ~= playerId) then
			local targetCoords = GetEntityCoords(target)
			local distance     = GetDistanceBetweenCoords(targetCoords, coords.x, coords.y, coords.z, true)

			if closestDistance == -1 or closestDistance > distance then
				closestPlayer   = player
				closestDistance = distance
			end
		end
	end

	return closestPlayer, closestDistance
end

dlib.player.GetPlayersInArea = function(coords, area)
	local AllPlayers       = dlib.player.GetPlayers()
	if not coords then coords = GetEntityCoords(PlayerPedId()) end
	if not area then area = 5.0 end
	local playersInArea = {}
	for _, player in ipairs(AllPlayers) do
		local target       = GetPlayerPed(player)
		local targetCoords = GetEntityCoords(target)
		local distance     = #(targetCoords - coords)
		if distance <= area then
			table.insert(playersInArea, player)
		end
	end

	return playersInArea
end

dlib.player.GetNearbyPlayers = function(dist, GetOthersOnly)
	local coords = GetEntityCoords(PlayerPedId(), true)
	local nearPlayers = {}
	local AllPlayers = dlib.player.GetPlayers()
	for _, player in ipairs(AllPlayers) do
		if not GetOthersOnly or player ~= PlayerId() then
			local ped = GetPlayerPed(player)
			local targetCoords = GetEntityCoords(ped)
			local distance = #(targetCoords - coords)
			if distance <= dist then
				table.insert(nearPlayers, {
					id = GetPlayerServerId(player)
				})
			end
		end
	end

	local players

	if #nearPlayers > 0 then
		-- local p = promise.new()
		players = dlib.callback.await('d-lib:server:getPlayerNamesNearby', false, nearPlayers)
		-- players = Citizen.Await(p)
	end

	return players or {}
end

return dlib.player