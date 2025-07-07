lib.checkDependency('ox_lib', '3.30.10')

cooldowns = {}
activeCaptures = {}
currentCaptures = {}

function IsOnCooldown(job)
    if cooldowns[job] then
        local remaining = cooldowns[job] - os.time()
        if remaining > 600 then
            cooldowns[job] = nil 
            return false
        end
        return cooldowns[job] > os.time()
    end
    return false
end

function SetCooldown(job)   
    cooldowns[job] = os.time() + 600 
end

function VerifyCapture(source, job, place)
    if not currentCaptures[source] then return false end
    if job and currentCaptures[source].job ~= job then return false end
    if place and currentCaptures[source].place ~= place then return false end
    return true
end

lib.callback.register("nn_caption:jobexist", function(source, job)
    if DoesJobExist(job) then
        return true
    else
        debugprint("^2[ERROR] ^7NN Caption: ^1" .. job .. " ^7 Frakció nem létezik Kérlek nézd meg a config.lua fájlt!^0")
        return false
    end
end)

lib.callback.register("nn_caption:getTerritoryCoords", function(source, job)
    if NN.fractions[job] and NN.fractions[job].coords then
        return NN.fractions[job].coords
    end
    return nil
end)

lib.callback.register("nn_caption:getjobname", function(source, job)
    if DoesJobExist(job) then
        local row = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {
            job
        })
        return row and row.label or "Ismeretlen Frakció"
    else
        debugprint("^2[ERROR] ^7NN Caption: ^1" .. job .. " ^7 Frakció nem létezik Kérlek nézd meg hogy létezik-e az SQL be!^0")
    end
end)

lib.callback.register("nn_caption:whocaptured", function(source, job)
    if DoesJobExist(job) then
        return whocaptured(job)
    else
        debugprint("^2[ERROR] ^7NN Caption: ^1" .. job .. " ^7 Frakció nem létezik Kérlek nézd meg hogy létezik-e az SQL be!^0")
    end
end)

RegisterNetEvent("nn_caption:capture", function(job, place)
    local source = source
    local playerName = GetPlayerName(source)
    
    currentCaptures[source] = {
        job = job,
        place = place,
        startTime = os.time()
    }

    if job then
        if DoesJobExist(job) then
            if IsOnCooldown(job) then
                local remaining = cooldowns[job] - os.time()
                local minutes = math.floor(remaining / 60)
                local seconds = remaining % 60
                
                LogCooldownWarning(job, playerName, source, remaining)
                
                return lib.notify(source, {
                    title = "NN Caption",
                    description = ("Ez a terület most lett elfoglalva! Várj %d perc és %d másodpercet mielőtt újra próbálkozhatsz!"):format(minutes, seconds),
                    type = "error",
                })
            end

            local xPlayer = ESX.GetPlayerFromId(source)
            local jobname = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {
                job
            })
            local captured = whocaptured(job)
            if not NN.fractions[captured] then 
                return print("^3[ERROR] ^2 NEM LÉTEZIK A FRAKCIÓ KÉRLEK IRD BELE A CONFIG.LUA BA!")
            end
            local minmember = NN.fractions[captured].minmember
            local frakciotagok = ESX.GetExtendedPlayers('job', captured)
            if not xPlayer then return end
            
            LogCaptureAttempt(job, playerName, source)
            
            if xPlayer.job.name == whocaptured(job) then
                return lib.notify(xPlayer.source, {
                    title = "NN Caption",
                    description = "Saját területet nem tudod elfoglalni!",
                    type = "error",
                })
            end
            
            if #frakciotagok < minmember then
                LogNotEnoughMembers(job, playerName, source, minmember, #frakciotagok)
                
                return lib.notify(xPlayer.source, {
                    title = "NN Caption",
                    description = "Nincs elég tag a frakcióban a terület elfoglalásához!",
                    type = "error",
                })
            end
            
            for i, xPlayers in pairs(frakciotagok) do
                lib.notify(xPlayers.source, {
                    title = "NN Caption",
                    duration = 5000,
                    description = "A ".. xPlayer.job.label .. " Frakció elkezde Foglani a területeteket!",
                    type = "warning",
                })
            end
            TriggerClientEvent("nn_caption:startcapture", xPlayer.source, jobname.label, job)
        else
            debugprint("^2[ERROR] ^7NN Caption: ^1" .. job .. " ^7 Frakció nem létezik Kérlek nézd meg hogy létezik-e az SQL be!^0")
        end
    elseif place then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        local placeData = NN.places[place]
        if not placeData then
            return lib.notify(xPlayer.source, {
                title = "NN Caption",
                description = "Ez a hely nem létezik!",
                type = "error",
            })
        end
        if IsOnCooldown(place) then
            local remaining = cooldowns[place] - os.time()
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            
            Sendwebhook(
                "Hely Cooldown",
                string.format(
                    "**%s** (ID: %d) megkísérelte elfoglalni a **%s** helyet, de cooldown van!\n\n**Hátralévő idő:** %d perc %d másodperc",
                    playerName,
                    source,
                    place,
                    minutes,
                    seconds
                ),
                16753920
            )
            
            return lib.notify(xPlayer.source, {
                title = "NN Caption",
                description = ("Ez a hely most lett elfoglalva! Várj %d perc és %d másodpercet mielőtt újra próbálkozhatsz!"):format(minutes, seconds),
                type = "error",
            })
        end
        TriggerClientEvent("nn_caption:startcapture", xPlayer.source, false, false, place)
    else
        debugprint("^2[ERROR] ^7NN Caption: ^1Nem adtál meg frakciót vagy helyet a capture eseményben!^0")
    end
end)

RegisterNetEvent("nn_caption:donecapture", function(job, place)
    local source = source
    local playerName = GetPlayerName(source)
    
    if not VerifyCapture(source, job, place) then
        debugprint("^2[WARNING] ^7NN Caption: Invalid capture attempt from "..playerName.." (ID: "..source..")")
        return
    end
    
    currentCaptures[source] = nil
    
    if job then
        if DoesJobExist(job) then
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then return end
            local jobname = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {job})
            if not jobname then return end
            
            if activeCaptures[source] and activeCaptures[source][job] then
                local lastCapture = activeCaptures[source][job]
                if os.time() - lastCapture < 60 then
                    return lib.notify(source, {
                        title = "NN Caption",
                        description = "Nem tudod újra elfoglalni ugyanazt a területet ilyen gyorsan!",
                        type = "error"
                    })
                end
            end
            
            activeCaptures[source] = activeCaptures[source] or {}
            activeCaptures[source][job] = os.time()
            
            SetCooldown(job)
            if job == xPlayer.job.name then
                MySQL.update.await('UPDATE nn_caption SET `capuredby` = ?, `capuredat` = ? WHERE `job` = ?', {
                    "N/A",
                    os.date('%Y-%m-%d %H:%M:%S'),
                    job
                })
            else
                MySQL.update.await('UPDATE nn_caption SET `capuredby` = ?, `capuredat` = ? WHERE `job` = ?', {
                    xPlayer.job.name,
                    os.date('%Y-%m-%d %H:%M:%S'),
                    job
                })
                
                LogTerritoryCapture(xPlayer.job.name, job, playerName, source)
            end
            
            local frakciotagok = ESX.GetExtendedPlayers('job', xPlayer.job.name)
            local payout = NN.fractions[job].payout or 0
            for _, xTarget in pairs(frakciotagok) do
                xTarget.addMoney(payout)
                lib.notify(xTarget.source, {
                    title = "NN Caption",
                    duration = 10000,
                    description = ("%s elfoglalta a területet a frakciótoknak! Minden tag kapott $%d-t."):format(
                        playerName, payout
                    ),
                    type = "success",
                })
            end
            TriggerClientEvent("nn_caption:donecapture", -1, job, xPlayer.job.name)
        else
            debugprint("^2[ERROR] ^7NN Caption: ^1"..job.."^7 Frakció nem létezik!^0")
        end
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        if place then
            if activeCaptures[source] and activeCaptures[source][place] then
                local lastCapture = activeCaptures[source][place]
                if os.time() - lastCapture < 60 then 
                    return lib.notify(source, {
                        title = "NN Caption",
                        description = "Nem tudod újra elfoglalni ugyanazt a helyet ilyen gyorsan!",
                        type = "error"
                    })
                end
            end
            
            activeCaptures[source] = activeCaptures[source] or {}
            activeCaptures[source][place] = os.time()
            
            SetCooldown(place)
            local payout = NN.places[place].payout or 0
            xPlayer.addMoney(payout)
            
            LogPlaceCapture(place, playerName, source, payout)
            
            lib.notify(xPlayer.source, {
                title = "NN Caption",
                duration = 10000,
                description = ("Elfoglaltad a %s helyet! Kapott $%d-t."):format(place, payout),
                type = "success",
            })
            TriggerClientEvent("nn_caption:donecapture", -1, false, xPlayer.job.name, place)
        end
    end
end)

AddEventHandler("onResourceStart", function(resourcename)
    if resourcename == GetCurrentResourceName() then
        if GetCurrentResourceName() ~= "nn_caption" then
            print("^1[FIGYELMEZTETÉS] ^7NE ÍRD ÁT A SCRIPT NEVÉT! A script nevének 'nn_caption'-nek kell lennie!^0")
            print("^1[FIGYELMEZTETÉS] ^7Jelenlegi script név: '"..resourcename.."'^0")
            return
        end

        Sendwebhook(
            "Script Indítása",
            "NN Caption script sikeresen elindult!",
            65280
        )
        
        local createTable = [[
            CREATE TABLE IF NOT EXISTS `nn_caption` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `job` VARCHAR(255) NOT NULL UNIQUE,
                `label` VARCHAR(255) NOT NULL,
                `capuredby` VARCHAR(255) NOT NULL,
                `capuredat` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
        ]]
        
        MySQL.query(createTable, {}, function(success)
            if success then
                debugprint("^2[INFO] ^7NN Caption: ^2SQL Sikeresen feltöltve!^0")
                
                MySQL.query('SELECT `job` FROM `nn_caption`', {}, function(existingJobs)
                    local existingJobNames = {}
                    if existingJobs and #existingJobs > 0 then
                        for _, job in ipairs(existingJobs) do
                            existingJobNames[job.job] = true
                        end
                    end
                    
                    for jobName, _ in pairs(NN.fractions) do
                        if DoesJobExist(jobName) then
                            if existingJobNames[jobName] then
                                debugprint("^3[INFO] ^7NN Caption: ^3"..jobName.." Frakció már létezik^0")
                                goto continue
                            end
                            
                            local label = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {jobName})
                            if not label then
                                debugprint("^2[ERROR] ^7NN Caption: ^1Failed to get label for "..jobName.."^0")
                                goto continue
                            end
                            
                            MySQL.insert('INSERT IGNORE INTO `nn_caption` (`job`, `label`, `capuredby`, `capuredat`) VALUES (?, ?, ?, ?)', {
                                jobName, 
                                label.label,
                                "N/A", 
                                os.date('%Y-%m-%d %H:%M:%S')
                            }, function(insertId)
                                if insertId then
                                    debugprint("^2[INFO] ^7NN Caption: ^2Added "..jobName.." to table^0")
                                else
                                    debugprint("^2[ERROR] ^7NN Caption: ^1Failed to add "..jobName.."^0")
                                end
                            end)
                        else
                            debugprint("^2[ERROR] ^7NN Caption: ^1Job "..jobName.." doesn't exist^0")
                        end
                        
                        ::continue::
                    end
                end)
            else
                debugprint("^2[ERROR] ^7NN Caption: ^1Failed to create table^0")
            end
        end)

        MySQL.query('SELECT `job`, `capuredby` FROM `nn_caption` WHERE `capuredby` != "N/A"', {}, function(rows)
            if rows and #rows > 0 then
                for _, row in ipairs(rows) do
                    local job = row.job
                    local capturedBy = row.capuredby
                    local territoryLabel = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {job})
                    local capturerLabel = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {capturedBy})
                    debugprint("^2[INFO] ^7NN Caption: ^2Foglalás Visszatétele: " .. job .. " Elfoglalta: " .. capturedBy)
                    if territoryLabel and capturerLabel then
                        Wait(2000)
                        TriggerClientEvent("nn_caption:donecapture", -1, job, capturedBy)
                    end
                end
            end
        end)

        MySQL.query('SELECT `job`, `capuredat` FROM `nn_caption` WHERE `capuredby` != "N/A"', {}, function(rows)
            if rows and #rows > 0 then
                for _, row in ipairs(rows) do
                    local captureTime = row.capuredat 
                    local currentTime = os.time()
                    if currentTime - captureTime < 600 then
                        cooldowns[row.job] = captureTime + 600
                    end
                end
            end
        end)
    end
end)