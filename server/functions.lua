local webhook = "https://discord.com/api/webhooks/1390325623351803994/yUph0vy_H5gMmtMg7INnzdPlEWnhqSaXlT5I1314jyTq3sqgns7k-a2VBXOSWjwcOTcu"

function Sendwebhook(title, description, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16753920, 
            ["footer"] = {
                ["text"] = os.date("%Y.%m.%d - %H:%M:%S")
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        embeds = embed,
        username = "NN Log",
        avatar_url = "https://cdn.discordapp.com/attachments/1274682111818862603/1387574369454391356/image.png?ex=6867ba15&is=68666895&hm=23eb1acbabcb0295bcbe7d700be2b751f8d58ba9b7bf6664c0ac0b0fb6f7adf6&" 
    }), { ['Content-Type'] = 'application/json' })
end

function DoesJobExist(job)
    local row = MySQL.single.await('SELECT `name` FROM `jobs` WHERE `name` = ? LIMIT 1', {
        job
    })
    return row and true or false
end

function whocaptured(job)
    local row = MySQL.scalar.await('SELECT `capuredby` FROM `nn_caption` WHERE `job` = ? LIMIT 1', {
        job
    })
    if not row then return print("^1[ERROR] ^3 NEM TALÁLTUK MEG AZ nn_caption TABLET AZ SQL BE! q")end
    if row == "N/A" then
        return job
    end
    return row or job
end

function debugprint(msg)
    if NN.debug then
        print(msg)
    end
end


function LogTerritoryCapture(attackerJob, defenderJob, playerName, playerId)
    local attackerLabel = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {attackerJob})
    local defenderLabel = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {defenderJob})
    
    Sendwebhook(
        "Terület Elfoglalás",
        string.format(
            "**%s** (%s) elfoglalta a **%s** területét!\n\n**Játékos:** %s (ID: %d)",
            attackerLabel and attackerLabel.label or attackerJob,
            attackerJob,
            defenderLabel and defenderLabel.label or defenderJob,
            playerName,
            playerId
        ),
        16711680
    )
end

function LogPlaceCapture(placeName, playerName, playerId, payout)
    Sendwebhook(
        "Hely Elfoglalás",
        string.format(
            "**%s** elfoglalta a **%s** helyet!\n\n**Játékos:** %s (ID: %d)\n**Fizetés:** $%d",
            playerName,
            placeName,
            playerName,
            playerId,
            payout
        ),
        65280
    )
end

function LogCaptureAttempt(job, playerName, playerId)
    local jobLabel = MySQL.single.await('SELECT `label` FROM `jobs` WHERE `name` = ? LIMIT 1', {job})
    
    Sendwebhook(
        "Területfoglalási Kísérlet",
        string.format(
            "**%s** (%s) megkísérelte elfoglalni a **%s** területét!\n\n**Játékos:** %s (ID: %d)",
            playerName,
            jobLabel and jobLabel.label or job,
            job,
            playerName,
            playerId
        ),
        16776960
    )
end

function LogCooldownWarning(job, playerName, playerId, remainingTime)
    local minutes = math.floor(remainingTime / 60)
    local seconds = remainingTime % 60
    
    Sendwebhook(
        "Cooldown Figyelmeztetés",
        string.format(
            "**%s** (ID: %d) megkísérelte elfoglalni a **%s** területét, de cooldown van!\n\n**Hátralévő idő:** %d perc %d másodperc",
            playerName,
            playerId,
            job,
            minutes,
            seconds
        ),
        16753920 
    )
end

function LogNotEnoughMembers(job, playerName, playerId, required, current)
    Sendwebhook(
        "Nincs Elég Tag",
        string.format(
            "**%s** (ID: %d) megkísérelte elfoglalni a **%s** területét, de nincs elég tag a frakcióban!\n\n**Szükséges:** %d\n**Jelenlegi:** %d",
            playerName,
            playerId,
            job,
            required,
            current
        ),
        16711680 
    )
end