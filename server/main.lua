Heap = {
    Mechanics = {}
}

TriggerEvent("esx:getSharedObject", function(library)
    Heap.ESX = library
end)

Citizen.CreateThread(function()
    while true do
        local sleepThread = 5000

        CheckRepairs()

        Citizen.Wait(sleepThread)
    end
end)