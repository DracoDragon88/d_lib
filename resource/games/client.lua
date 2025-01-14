---@type promise?
local p
local open = false

RegisterNUICallback('game-callback', function(data, cb)
    p:resolve(data)
    p = nil
    open = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Circle
---@param cb function
---@param circles number?
---@param seconds number?
dlib.Circle = function (cb, circles, seconds)
    if open then if cb then cb(false) end return result end open = true
    if circles == nil or circles < 1 then circles = 1 end
    if seconds == nil or seconds < 1 then seconds = 10 end
    p = promise.new()
    SendNUIMessage({
        action = 'circle-start',
        circles = circles,
		time = seconds,
    })
    SetNuiFocus(true, true)

    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

-- Maze
---@param cb function
---@param speed number?
dlib.Maze = function (cb, speed)
    if open then if cb then cb(false) end return result end open = true
    if speed == nil then speed = 10 end
    p = promise.new()
    SendNUIMessage({
        action = "maze-start",
        speed = speed,
    })
    SetNuiFocus(true, true)

    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

-- Safebreach
local TotalLocks = nil
local safeLocks = {}
local currentSafeCorrectPosition = 0.0
local dialRotation = 0.0

local function ResetCrackingGame(data)
    local fails = 0
    for i, v in ipairs(safeLocks) do
        if not v then fails += 1 end
    end

	open = false
    p:resolve({success=data, fails=fails})
    p = nil
	safeLocks = {}

	ReleaseAmbientAudioBank("SAFE_CRACK")
	SetStreamedTextureDictAsNoLongerNeeded("MPSafeCracking")

	if IsEntityPlayingAnim(PlayerPedId(), "mini@safe_cracking", "dial_turn_clock_normal", 3) then
		ClearPedTasks(PlayerPedId())
	end
end

local function MoveSafeDial(clockwise)
	if clockwise then
		dialRotation = dialRotation + 1

		if dialRotation == currentSafeCorrectPosition then
			PlaySoundFrontend(0, "TUMBLER_PIN_FALL", "SAFE_CRACK_SOUNDSET", 1)
		else
			PlaySoundFrontend(0, "TUMBLER_TURN", "SAFE_CRACK_SOUNDSET", 1)
		end

		if dialRotation >= 360 then
			dialRotation = 0.0
		end
	else
		dialRotation = dialRotation - 1

		if dialRotation == currentSafeCorrectPosition then
			PlaySoundFrontend(0, "TUMBLER_PIN_FALL", "SAFE_CRACK_SOUNDSET", 1)
		else
			PlaySoundFrontend(0, "TUMBLER_TURN", "SAFE_CRACK_SOUNDSET", 1)
		end

		if dialRotation <= 0 then
			dialRotation = 360.0
		end
	end
	if Config.Debug then print('dialRotation', dialRotation) end
	Citizen.Wait(10)
end

local function HandleControls()
	Citizen.CreateThread(function()
		while open do
			DisableControlAction(0, 38, true)

			if IsControlJustPressed(0, 22) then
				if dialRotation == currentSafeCorrectPosition then
					PlaySoundFrontend(0, "TUMBLER_PIN_FALL", "SAFE_CRACK_SOUNDSET", 1)

					safeLocks[#safeLocks + 1] = true

					if #safeLocks < TotalLocks then
						currentSafeCorrectPosition = math.random(1, 350)
						if Config.Debug then print('for the cheaters', currentSafeCorrectPosition) end
					else
						ResetCrackingGame(true)
                        dlib.framework.Notify('primary', 'Safe Crack', 'You cracked the safe', 8000)
					end
				else
                    dlib.framework.Notify('error', 'Safe Crack', 'Wrong, Try again and listen carefully!!', 8000)
				end
			elseif IsControlJustPressed(0, 47) then
				ResetCrackingGame(false)
			elseif IsControlJustPressed(0, 172) then
				MoveSafeDial(true)
			elseif IsControlJustPressed(0, 173) then
				MoveSafeDial(false)
			elseif IsControlPressed(0, 174) then
				MoveSafeDial(true)
			elseif IsControlPressed(0, 175) then
				MoveSafeDial(false)
			end

		  	Citizen.Wait(5)
		end
	end)
end

local function DrawButtons(buttonsToDraw)
	Citizen.CreateThread(function()
		local instructionScaleform = RequestScaleformMovie("instructional_buttons")

		while not HasScaleformMovieLoaded(instructionScaleform) do
			Wait(0)
		end

		PushScaleformMovieFunction(instructionScaleform, "CLEAR_ALL")
		PushScaleformMovieFunction(instructionScaleform, "TOGGLE_MOUSE_BUTTONS")
		PushScaleformMovieFunctionParameterBool(0)
		PopScaleformMovieFunctionVoid()

		for buttonIndex, buttonValues in ipairs(buttonsToDraw) do
			PushScaleformMovieFunction(instructionScaleform, "SET_DATA_SLOT")
			PushScaleformMovieFunctionParameterInt(buttonIndex - 1)

			PushScaleformMovieMethodParameterButtonName(buttonValues["button"])
			PushScaleformMovieFunctionParameterString(buttonValues["label"])
			PopScaleformMovieFunctionVoid()
		end

		PushScaleformMovieFunction(instructionScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
		PushScaleformMovieFunctionParameterInt(-1)
		PopScaleformMovieFunctionVoid()
		DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255)

		SetScaleformMovieAsNoLongerNeeded(instructionScaleform)
	end)
end

local function StartCrackingSafe()
	if open then return end
	open = true

	currentSafeCorrectPosition = math.random(1, 350)
	if Config.Debug then print('for the cheaters', currentSafeCorrectPosition) end

    RequestAmbientAudioBank("SAFE_CRACK", false)
    local asset = dlib.requestStreamedTextureDict("MPSafeCracking")
    local asset2 = dlib.requestAnimDict("mini@safe_cracking")

	TaskPlayAnim(PlayerPedId(), "mini@safe_cracking", "dial_turn_clock_normal", 0.5, 1.0, -1, 11, 0.0, 0, 0, 0)

	HandleControls()

	Citizen.CreateThread(function()
		local mit = TotalLocks * 0.05
		local mit2 = 0.45 - mit

		while open do
			Citizen.Wait(0)

			DrawSprite("MPSafeCracking", "Dial_BG", 0.5, 0.4, 0.2, 0.3, 0.0, 255, 255, 255, 255)
			DrawSprite("MPSafeCracking", "Dial", 0.5, 0.4, 0.2 * 0.5, 0.3 * 0.5, dialRotation, 255, 255, 255, 255)

			DrawButtons({
				{
					["label"] = "Right quick",
					["button"] = "~INPUT_CELLPHONE_RIGHT~"
				},
				{
					["label"] = "Right slow",
					["button"] = "~INPUT_CELLPHONE_DOWN~"
				},
				{
					["label"] = "Left slow",
					["button"] = "~INPUT_CELLPHONE_UP~"
				},
				{
					["label"] = "Left fast",
					["button"] = "~INPUT_CELLPHONE_LEFT~"
				},
				{
					["label"] = "Try crack",
					["button"] = "~INPUT_JUMP~"
				},
				{
					["label"] = "Cancel",
					["button"] = "~INPUT_DETONATE~"
				}
			})

			if not IsEntityPlayingAnim(PlayerPedId(), "mini@safe_cracking", "dial_turn_clock_normal", 3) and open then
				TaskPlayAnim(PlayerPedId(), "mini@safe_cracking", "dial_turn_clock_normal", 0.5, 1.0, -1, 11, 0.0, 0, 0, 0)
			end

			local midt
			for i = 1, TotalLocks do
				local lockState = safeLocks[i] and "lock_open" or "lock_closed"

				DrawSprite("MPSafeCracking", lockState, mit2 + (i / 10), 0.6, 0.2 * 0.2, 0.3 * 0.2, 0.0, 255, 255, 255, 255)
			end
		end

        SetStreamedTextureDictAsNoLongerNeeded(asset)
		RemoveAnimDict(asset2)
	end)
end

dlib.SafeBreach = function(locks, cb)
	if open then if cb then cb(false) end return result end
	TotalLocks = tonumber(locks) or 3
	p = promise.new()

	StartCrackingSafe()

    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

-- Scrambler
dlib.Scrambler = function(cb, type, time, mirrored)
    if open then if cb then cb(false) end return result end open = true
    if type == nil then type = "alphabet" end
    if time == nil then time = 10 end
    if mirrored == nil then mirrored = 0 end

    p = promise.new()
    SendNUIMessage({
        action = "scrambler-start",
        type = type,
        time = time,
        mirrored = mirrored,

    })
    SetNuiFocus(true, true)

    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

--- Thermite
---@param cb fun(success:boolean)
---@param time number
---@param gridsize number
---@param wrong number
dlib.Thermite = function(cb, time, gridsize, wrong)
    if open then if cb then cb(false) end return result end open = true
    if time == nil then time = 10 end
    if gridsize == nil then gridsize = 6 end
    if wrong == nil then wrong = 3 end
    p = promise.new()
    SendNUIMessage({
        action = "thermite-start",
        time = time,
        gridsize = gridsize,
        wrong = wrong,
    })
    SetNuiFocus(true, true)

    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

local function startThermiteFire(coords, time, spred)
    Citizen.CreateThread(function ()
        local fireStarted = StartScriptFire(coords.x, coords.y, coords.z-1.0, spred or 0, false)
        local fireStarted2 = StartScriptFire(coords.x, coords.y, coords.z-1.0, spred or 0, false)
        local fireStarted3 = StartScriptFire(coords.x, coords.y, coords.z-1.0, spred or 0, false)
        Citizen.Wait(time or 8000)
        RemoveScriptFire(fireStarted)
        RemoveScriptFire(fireStarted2)
        RemoveScriptFire(fireStarted3)
    end)
end

dlib.ThermiteDoor = function(coords)
    local _bombprop = joaat("hei_prop_heist_thermite")
    local asset1 = dlib.requestAnimDict("anim@heists@ornate_bank@thermal_charge")
    local asset2 = dlib.requestModel("hei_p_m_bag_var22_arm_s")
    local asset3 = dlib.requestNamedPtfxAsset("scr_ornate_heist")
    local ped = PlayerPedId()

    SetEntityHeading(ped, coords.w)
    Wait(100)
    local rotx, roty, rotz = table.unpack(GetEntityRotation(PlayerPedId()))
    local bagscene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotx, roty, rotz + 1.1, 2, false, false, 1065353216, 0, 1.3)
    local bag = CreateObject("hei_p_m_bag_var22_arm_s", coords.x, coords.y, coords.z,  true,  true, false)

    SetEntityCollision(bag, false, true)
    NetworkAddPedToSynchronisedScene(ped, bagscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.2, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(bag, bagscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
    -- SetPedComponentVariation(ped, 5, 0, 0, 0)
    NetworkStartSynchronisedScene(bagscene)
    Wait(1500)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local bomb = CreateObject(_bombprop, x, y, z + 0.3,  true,  true, true)

    SetEntityCollision(bomb, false, true)
    AttachEntityToEntity(bomb, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    Wait(2000)
    DeleteObject(bag)
    -- SetPedComponentVariation(ped, 5, 45, 0, 0)
    DetachEntity(bomb, 1, 1)
    FreezeEntityPosition(bomb, true)
    SetPtfxAssetNextCall("scr_ornate_heist")
    local effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", ptfx, 0.0, 0.0, 0.0, 1.0, false, false, false, false)

    NetworkStopSynchronisedScene(bagscene)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, 0, 0, 0)
    TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 3000, 49, 1, 0, 0, 0)
    Wait(5000)
    startThermiteFire(coords, 8000, 5)
    ClearPedTasks(ped)
    DeleteObject(bomb)
    StopParticleFxLooped(effect, 0)

    RemoveAnimDict(asset1)
    SetModelAsNoLongerNeeded(asset2)
    RemoveNamedPtfxAsset(asset3)
end

-- Var
dlib.VarHack = function(cb, blocks, speed)
    if open then if cb then cb(false) end return false end open = true
    if speed == nil or (speed < 2) then speed = 20 end
    if blocks == nil or (blocks < 1 or blocks > 15) then blocks = 5 end
    p = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "var-start",
        blocks = blocks,
        speed = speed,
    })
    local result = Citizen.Await(p)
    if cb then
        cb(result.success, result.fails)
    else
        return result.success, result.fails
    end
end

-- Hacking
dlib.Hacking = function(solutionsize, timeout)
    if open then return false end open = true
    p = promise.new()
    SetNuiFocus(true, false)
    SendNUIMessage({
        action = 'startHack',
        solutionsize = solutionsize or 5,
        timeout = timeout or 30
    })
    local result = Citizen.Await(p)
    return result.success, result.fails
end

TriggerEvent("__cfx_export_ps-ui_Circle", dlib.Circle)
TriggerEvent("__cfx_export_ps-ui_Maze", dlib.Maze)
TriggerEvent("__cfx_export_ps-ui_Scrambler", dlib.Scrambler)
TriggerEvent("__cfx_export_ps-ui_Thermite", dlib.Thermite)
TriggerEvent("__cfx_export_ps-ui_VarHack", dlib.VarHack)