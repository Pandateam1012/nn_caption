CreateThread(function()
    for job, data in pairs(NN.fractions) do
        local success = lib.callback.await("nn_caption:jobexist", 100, job)
        debugprint("^2[Info] ^7NN Caption: ^1".. job .. " ^7 Frakció ellenőrzése: " .. tostring(success) .. "^0")
        if not success then
            print("^2[ERROR] ^7NN Caption: ^1" .. job .. " ^7 Frakció nem létezik Kérlek nézd meg a config.lua fájlt!^0")
            return
        else
            PlaceMarker(data.coords, data.color, job)
            PlaceBlip(data.coords, data.color, job)
        end
    end
    for place, data in pairs(NN.places) do
        PlaceMarker(data.coords, data.blip.color, false, place)
        PlaceBlip(data.coords, data.blip.color, false, place)
    end
end)

RegisterNetEvent("nn_caption:startcapture", function(s, job, place)
    if job then
        local capure = lib.callback.await("nn_caption:whocaptured", false, job)
        local jobname = lib.callback.await("nn_caption:getjobname", 100, capure)
        if not jobname then
            return
        end
        NN.Progressbar("Terület elfoglalása ".. jobname , NN.timetocapture)
        TriggerServerEvent("nn_caption:donecapture", job, false)
    else
        local placeName = place
        print(place)
        NN.Progressbar("Terület elfoglalása " .. placeName, NN.timetocapture)
        TriggerServerEvent("nn_caption:donecapture", false, place)
    end
end)

RegisterNetEvent("nn_caption:donecapture", function(job, newjob, place)
    if job then
        local originalName = lib.callback.await("nn_caption:getjobname", 100, job)
        UpdateBlipName(job, originalName, newjob)
    else
        print(newjob, place)
        UpdateBlipName(false, place, newjob, place)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local isOpen = lib.isTextUIOpen()
        if isOpen then
            lib.hideTextUI()
        end
    end
end)