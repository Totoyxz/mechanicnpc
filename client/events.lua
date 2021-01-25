RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
    Heap.ESX.PlayerData = response
end)

RegisterNetEvent("renz_mechanicnpc:updateRepairs")
AddEventHandler("renz_mechanicnpc:updateRepairs", function(updatedRepairs)
    Heap.Mechanics = updatedRepairs
end)

RegisterNetEvent("renz_mechanicnpc:repairDone")
AddEventHandler("renz_mechanicnpc:repairDone", function(mechanicDone, repairData, notify)
    if not NetworkDoesNetworkIdExist(repairData.NetId) then return end

    local vehEntity = NetToVeh(repairData.NetId)

    FinishRepair(vehEntity)

    if notify then
        Heap.ESX.ShowNotification(mechanicDone .. ": Your repair is done, pick up your vehicle!")
    end
end)

RegisterNetEvent("renz_mechanicnpc:updateSequence")
AddEventHandler("renz_mechanicnpc:updateSequence", function(mechanicName, repairData, sequenceId)
    Trace("Sequence", mechanicName, repairData, sequenceId)

    if not NetworkDoesNetworkIdExist(repairData.NetId) then return end

    local vehEntity = NetToVeh(repairData.NetId)

    if DoesEntityExist(vehEntity) then
        Trace("Update sequence on:", mechanicName, "with handleId:", vehEntity)

        local ped = GetPedHandleWithName(mechanicName)

        if not ped then return end

        RepairSequence(sequenceId, vehEntity, ped.Handle, repairData)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for _, pedData in pairs(Heap.Peds) do
            if DoesEntityExist(pedData.Handle) then
                DeleteEntity(pedData.Handle)
            end
        end
    end
end)