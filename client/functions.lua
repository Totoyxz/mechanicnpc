Initialized = function()
    Heap.Peds = {}

    for _, pedData in ipairs(Mechanics) do
        LoadModels({ pedData.Hash })

        local pedHandle = CreatePed(5, pedData.Hash, pedData.Location, pedData.Heading, false)

        SetEntityAsMissionEntity(pedHandle, true, true)
        SetEntityAsMissionEntity(pedHandle, true, true)
        SetBlockingOfNonTemporaryEvents(pedHandle, true)

        PlayAnimation(pedHandle, "amb@code_human_cross_road@female@idle_a", math.random(5) > 2 and "idle_a" or "idle_b", {
            flag = 11
        })

        table.insert(Heap.Peds, {
            Data = pedData,
            Handle = pedHandle
        })

        local blipHandle = AddBlipForEntity(pedHandle)

        SetBlipSprite(blipHandle, 544)
        SetBlipColour(blipHandle, 2)
        SetBlipDisplay(blipHandle, 4)
        SetBlipScale(blipHandle, 1.0)
        SetBlipAsShortRange(blipHandle, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Mechanic - " .. pedData.Name)
        EndTextCommandSetBlipName(blipHandle)

        CleanupModels({
            pedData.Hash
        })
    end

    if Heap.ESX.IsPlayerLoaded() then
        FetchRepairs()
    end
end

FetchRepairs = function()
    Heap.ESX.TriggerServerCallback("james_mechanicnpc:fetchCurrentRepairs", function(response)
        if response then
            Heap.Mechanics = response
        end
    end)
end

OpenMechanicMenu = function(mechanic, pedData)
    local pedHandle = pedData.Handle

    TaskTurnPedToFaceEntity(Heap.Ped, pedHandle, 1500)
    TaskTurnPedToFaceEntity(pedHandle, Heap.Ped, 1500)

    Trace("Opened mechanic:", mechanic.Name)

    local menuElements = {}

    local closestVehicles = Heap.ESX.Game.GetVehiclesInArea(mechanic.Location, 10.0)

    for _, vehicleHandle in ipairs(closestVehicles) do
        local displayLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicleHandle))
        local vehicleLabel = GetLabelText(displayLabel) ~= "NULL" and GetLabelText(displayLabel) or displayLabel
        local vehiclePlate = GetVehicleNumberPlateText(vehicleHandle)

        table.insert(menuElements, {
            label = vehicleLabel .. " - " .. vehiclePlate,
            vehicle = vehicleHandle
        })
    end

    Heap.ESX.UI.Menu.Open("default", GetCurrentResourceName(), "npc_mechanic_menu", {
        title = "Choose the vehicle you want to repair for $" .. mechanic.Price,
        align = Default.MenuAlignment,
        elements = menuElements
    }, function(menuData, menuHandle)
        local currentVehicle = menuData.current.vehicle

        if not currentVehicle then return end

        if DoesEntityExist(GetPedInVehicleSeat(currentVehicle, -1)) then return Heap.ESX.ShowNotification("There is someone inside the vehicle.") end

        Heap.ESX.TriggerServerCallback("james_mechanicnpc:startRepairing", function(validated, error)
            if validated then
                Heap.ESX.ShowNotification("You paid $" .. mechanic.Price .. ".")

                RepairVehicle(currentVehicle, mechanic, pedHandle)

                menuHandle.close()
            else
                if error == "NOT_ENOUGH_MONEY" then
                    Heap.ESX.ShowNotification("You don't have enough money to pay for the repair.")
                elseif error == "MECHANICS_ONLINE" then
                    Heap.ESX.ShowNotification("There is mechanics online, try calling them before using this mechanic.")
                elseif error == "PLAYER_NOT_LOADED" then
                    Heap.ESX.ShowNotification("Something wrong occured with your character, please relog.")
                end
            end
        end, VehToNet(currentVehicle), pedData.Data)
    end, function(menuData, menuHandle)
        menuHandle.close()
    end)
end

RepairVehicle = function(vehicleEntity, mechanicData, pedHandle)
    ClaimNetwork(vehicleEntity)

    SetVehicleDoorOpen(vehicleEntity, 4, false, false)
end

FinishRepair = function(vehicleEntity)
    if DoesEntityExist(vehicleEntity) then
        ClaimNetwork(vehicleEntity)

        Trace("Repaired vehicle with handleId:", vehicleEntity)

        SetVehicleFixed(vehicleEntity)
        SetVehicleEngineHealth(vehicleEntity, 1000.0)

        SetVehicleDoorsLocked(vehicleEntity, false)
        SetVehicleDoorsLockedForAllPlayers(vehicleEntity, false)
    end
end

RepairSequence = function(sequenceId, vehicleEntity, pedHandle, mechanicData)
    local sequenceData = RepairSequences[sequenceId]

    if not sequenceData then return Trace("Error:", sequenceId, "doesn't exist in sequences.") end

    local vehicleDimension, _ = GetModelDimensions(GetEntityModel(vehicleEntity))
    local repairLocation = GetOffsetFromEntityInWorldCoords(vehicleEntity, sequenceData.OffsetX and vehicleDimension.x + sequenceData.OffsetX or 0.0, vehicleDimension.y + sequenceData.Offset, 0.0)

    if sequenceId == #RepairSequences then
        repairLocation = mechanicData.Location
    else
        SetVehicleDoorsLocked(vehicleEntity, true)
        SetVehicleDoorsLockedForAllPlayers(vehicleEntity, true)
    end

    local animData = sequenceData.Animation

    ClearPedTasks(pedHandle)

    local _, taskSequence = OpenSequenceTask()
    TaskGoStraightToCoord(0, repairLocation, 1.0, 7500, 1193033728, 1056964608)
    TaskTurnPedToFaceEntity(0, vehicleEntity, 1000)
    TaskClearLookAt(0)

    if animData then
        LoadModels({
            animData.Dictionary
        })

        TaskPlayAnim(0, animData.Dictionary, animData.Animation, 8.0, -8.0, -1, 49, -1)

        CleanupModels({
            animData.Dictionary
        })
    end

    CloseSequenceTask(taskSequence)

    TaskPerformSequence(pedHandle, taskSequence)
end

GetPedHandleWithName = function(pedName)
    if not Heap.Peds then return false end

    for _, pedData in ipairs(Heap.Peds) do
        if pedData.Data.Name == pedName then
            return pedData
        end
    end

    return false
end

DrawButtons = function(buttonsToDraw)
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
end

DrawBusySpinner = function(text)
    SetLoadingPromptTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    ShowLoadingPrompt(3)
end

PlayAnimation = function(ped, dict, anim, settings)
	if dict then
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(0)
        end

        if settings == nil then
            TaskPlayAnim(ped, dict, anim, 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
        else 
            local speed = 1.0
            local speedMultiplier = -1.0
            local duration = 1.0
            local flag = 0
            local playbackRate = 0

            if settings["speed"] then
                speed = settings["speed"]
            end

            if settings["speedMultiplier"] then
                speedMultiplier = settings["speedMultiplier"]
            end

            if settings["duration"] then
                duration = settings["duration"]
            end

            if settings["flag"] then
                flag = settings["flag"]
            end

            if settings["playbackRate"] then
                playbackRate = settings["playbackRate"]
            end

            TaskPlayAnim(ped, dict, anim, speed, speedMultiplier, duration, flag, playbackRate, 0, 0, 0)

            while not IsEntityPlayingAnim(ped, dict, anim, 3) do
                Citizen.Wait(0)
            end
        end
    
        RemoveAnimDict(dict)
	else
		TaskStartScenarioInPlace(ped, anim, 0, true)
	end
end

LoadModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			while not HasModelLoaded(model) do
				RequestModel(model)
	
				Citizen.Wait(10)
			end
		else
			while not HasAnimDictLoaded(model) do
				RequestAnimDict(model)
	
				Citizen.Wait(10)
			end    
		end
	end
end

CleanupModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			SetModelAsNoLongerNeeded(model)
		else
			RemoveAnimDict(model)  
		end
	end
end

DrawScriptMarker = function(markerData)
    DrawMarker(markerData["type"] or 1, markerData["pos"] or vector3(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, (markerData["type"] == 6 and -90.0 or markerData["rotate"] and -180.0) or 0.0, 0.0, 0.0, markerData["size"] or vector3(1.0, 1.0, 1.0), markerData["rgb"] or vector3(255, 255, 255), 100, markerData["bob"] and true or false, true, 2, false, false, false, false)
end

DrawScriptText = function(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = (string.len(text)) / 370

    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

ClaimNetwork = function(handle)
    local timeout = 0

    NetworkRequestControlOfEntity(handle)

    while not NetworkHasControlOfEntity(handle) or timeout > 250 do
        Citizen.Wait(0)

        timeout = timeout + 1
    end
end

OpenInput = function(label, type)
	AddTextEntry(type, label)

	DisplayOnscreenKeyboard(1, type, "", "", "", "", "", 30)

	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Wait(0)
	end

	if GetOnscreenKeyboardResult() then
	  	return GetOnscreenKeyboardResult()
	end
end