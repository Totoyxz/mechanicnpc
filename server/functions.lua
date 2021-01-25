GetRandomPlayer = function()
    local players = Heap.ESX.GetPlayers()

    local randomPlayer = math.random(#players)

    for playerIndex, playerSource in ipairs(players) do
        if playerIndex == randomPlayer then
            return playerSource
        end
    end

    return false
end

GetPlayersWithJob = function()
    local mechanicJob = Default.MechanicJob

    local players = Heap.ESX.GetPlayers()

    local count = 0

    for _, playerSource in ipairs(players) do
        local character = Heap.ESX.GetPlayerFromId(playerSource)

        if character.job.name == mechanicJob then
            count = count + 1
        end
    end

    return count
end

CheckRepairs = function()
    for mechanicName, repairData in pairs(Heap.Mechanics) do
        local minutesPassed = (os.time() - repairData.Started) / 60

        if minutesPassed > Default.RepairTime then
            local sourcePlayer = Heap.ESX.GetPlayerFromId(repairData.Source)

            local randomPlayer = GetRandomPlayer()

            TriggerClientEvent("renz_mechanicnpc:repairDone", sourcePlayer and sourcePlayer.source or randomPlayer, mechanicName, repairData, sourcePlayer and true or false)
            TriggerClientEvent("renz_mechanicnpc:updateSequence", -1, mechanicName, repairData, #RepairSequences)

            Heap.Mechanics[mechanicName] = nil

            Trace("Mechanic:", mechanicName, "done.")
        elseif minutesPassed > Default.RepairTime / (#RepairSequences - 1) * (repairData.Sequence or 1) then
            repairData.Sequence = (repairData.Sequence or 1) + 1

            TriggerClientEvent("renz_mechanicnpc:updateSequence", -1, mechanicName, repairData, repairData.Sequence)

            Trace("Upgraded sequence:", repairData.Sequence)
        else
            Trace("Mechanic:", mechanicName, math.floor(minutesPassed / Default.RepairTime * 100) .. "% Done", "with vehicleId:", repairData.NetId)
        end
    end

    UpdateRepairs()
end

UpdateRepairs = function()
    TriggerClientEvent("renz_mechanicnpc:updateRepairs", -1, Heap.Mechanics)
end