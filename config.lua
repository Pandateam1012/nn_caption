NN = {}

NN.debug = false -- debug mód bekapcsolása, ha true akkor a konzolra ki ír mindent

-- a 3* 60 * 1000 az 3 perc (ms)
NN.timetocapture = 3* 60 * 1000 -- idő amíg elfoglalja a területet

NN.places = {
    ["Humane"] = {
        coords = vec3(3596.2422, 3703.3232, 29.6894),
        blip = {
            sprite = 499,
            color = "#2acc89",
        },
        payout = math.random(1000, 3000), -- payout = false vagy math.random(1000, 3000)
    },
}

NN.fractions = {
    ["unemployed"] = {
        coords = vec3(-75.1534, -819.3939, 326.1751),
        minmember = 3, -- hány ember kell a foglaláshoz?
        color = "#00FF00",
        payout = math.random(1500, 5000), -- payout = false vagy math.random(1500, 5000)
    },
    ["skibidimaffa"] = {
        coords = vec3(3518.7405, 3782.7686, 29.9242),
        minmember = 5,
        color = "#c7c68e",
        payout = math.random(1500, 5000),
    },
    ["police"] = {
        coords = vec3(3203.4299, 3714.2976, 148.8020),
        minmember = 1,
        color = "#2a82cc",
        payout = math.random(1500, 5000),
    },
}

NN.Progressbar = function(label, duration)
    lib.progressBar({ -- FIGYELEM A OX_LIB ES PROGRESSBAR AL NEM LEHET ITEM EKET HASZNÁLNI (Fegyvert ujratőlteni, vagy elővenni a fegyvert)
        duration = duration,
        label = label,
    })
end

NN.CancelProgressbar = function()
    if lib.progressActive() then
        lib.cancelProgress()
    end
end