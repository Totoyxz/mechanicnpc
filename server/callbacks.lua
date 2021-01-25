Citizen.CreateThread(function()
    Heap.ESX.RegisterServerCallback("renz_mechanicnpc:startRepairing", function(source, callback, netVehicleId, mechanicData)
        local character = Heap.ESX.GetPlayerFromId(source)

        if not character then return callback(false, "PLAYER_NOT_LOADED") end

        if Default.OnlyAllowRepairWhenThereAreNoMechanics then
            local playersOnline = GetPlayersWithJob()

            if playersOnline > 0 then return callback(false, "MECHANICS_ONLINE") end
        end

        local validatedMoney = false

        if character.getMoney() >= mechanicData.Price then
            validatedMoney = true

            character.removeMoney(mechanicData.Price)
        elseif character.getAccount("bank").money >= mechanicData.Price then
            validatedMoney = true

            character.removeAccountMoney("bank", mechanicData.Price)
        end

        if validatedMoney then
            mechanicData.NetId = netVehicleId
            mechanicData.Started = os.time()
            mechanicData.Source = source

            Heap.Mechanics[mechanicData.Name] = mechanicData

            callback(true)

            TriggerClientEvent("renz_mechanicnpc:updateSequence", -1, mechanicData.Name, mechanicData, 1)

            UpdateRepairs()
        else
            callback(false, "NOT_ENOUGH_MONEY")
        end
    end)

    Heap.ESX.RegisterServerCallback("renz_mechanicnpc:fetchCurrentRepairs", function(source, callback)
        local character = Heap.ESX.GetPlayerFromId(source)

        if not character then return callback(false) end

        callback(Heap.Mechanics)
    end)
end)