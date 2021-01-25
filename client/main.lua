Heap = {
    Mechanics = {}
}

Citizen.CreateThread(function()
    while not Heap.ESX do
        Heap.ESX = exports["es_extended"]:getSharedObject()

        Citizen.Wait(100)
    end

    Initialized()
end)

Citizen.CreateThread(function()
    while true do
        local sleepThread = 5000

        local newPed = PlayerPedId()

        if Heap.Ped ~= newPed then
            Heap.Ped = newPed
        end

        Citizen.Wait(sleepThread)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(500)

    while true do
        local sleepThread = 500

        local ped = Heap.Ped
        local pedCoords = GetEntityCoords(ped)

        if Heap.Peds and #Heap.Peds > 0 then
            for mechanicIndex, pedData in ipairs(Heap.Peds) do
                local pedHandle = pedData.Handle

                if DoesEntityExist(pedHandle) then
                    local mechanic = Mechanics[mechanicIndex]
                    local mechanicCoords = GetEntityCoords(pedHandle)

                    local usable = not Heap.Mechanics[mechanic.Name] and not IsEntityDead(pedHandle)

                    local dstCheck = #(pedCoords - mechanicCoords)

                    if dstCheck <= 1.4 then
                        sleepThread = 5

                        if usable and IsControlJustPressed(0, 38) then
                            OpenMechanicMenu(mechanic, pedData)
                        end

                        local displayText = usable and "Press ~INPUT_CONTEXT~ to speak with ~y~" .. mechanic.Name .. "~s~." or IsEntityDead(pedHandle) and "~y~" .. mechanic.Name .. "~s~ is dead and therefore you cannot speak with him." or "~y~" .. mechanic.Name .. "~s~ is currently repairing a vehicle, please wait."

                        Heap.ESX.ShowHelpNotification(displayText)
                    end
                end
            end
        end

        Citizen.Wait(sleepThread)
    end
end)
