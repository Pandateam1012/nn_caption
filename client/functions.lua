blip = {}
blipradius = {}
local hex = nil
local territoryBlips = {}
local placeBlips = {}
E = 38
local captureing = false

function debugprint(msg)
    if NN.debug then
        print(msg)
    end
end

function HexToBlipColor(hex)
    if not hex then return 3 end 
    
    if type(hex) == "number" then
        return hex 
    end
    
    hex = tostring(hex):gsub("#", "")
    if #hex == 6 then
        hex = hex .. "FF"
    end
    return tonumber("0x" .. hex) or 3
end

function HexToRGB(hex)
    if not hex then 
        return { r = 0, g = 250, b = 50, a = 150 } 
    end
    
    if type(hex) == "table" then
        hex.a = hex.a or 151
        return hex
    end
    
    if type(hex) == "number" then
        hex = string.format("%08X", hex)
    else
        hex = tostring(hex):gsub("#", "")
    end
    
    if #hex == 6 then
        hex = hex .. "FF"
    elseif #hex < 6 then
        if #hex == 3 then
            hex = hex:gsub("(.)(.)(.)", "%1%1%2%2%3%3") .. "FF"
        else
            return { r = 0, g = 250, b = 50, a = 150 }
        end
    end
    
    return {
        r = tonumber("0x" .. hex:sub(1, 2)) or 0,
        g = tonumber("0x" .. hex:sub(3, 4)) or 250,
        b = tonumber("0x" .. hex:sub(5, 6)) or 50,
        a = tonumber("0x" .. hex:sub(7, 8)) or 151
    }
end

function RGBToHex(rgb)
    if not rgb or not rgb.r or not rgb.g or not rgb.b then
        return "#00FA32" 
    end
    return string.format("#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
end

function PlaceMarker(coords, color, job, place)
    local rgbColor = HexToRGB(color)
    local hexColor = RGBToHex(rgbColor)
    if job then 
        local capure = lib.callback.await("nn_caption:whocaptured", 100, job)
        local jobname = lib.callback.await("nn_caption:getjobname", 100, capure)
        while not jobname do
            Wait(100)
            jobname = lib.callback.await("nn_caption:getjobname", 100, capure)
        end
        local tp = lib.marker.new({
            type = 22,
            coords = coords,
            color = rgbColor,
            width = 0.8,
            height = 1.1,
        })

        local downpt = lib.marker.new({
            type = 6,
            coords = coords + vec3(0.0, 0.0, -0.9),
            color = rgbColor,
            width = 1.2,
            height = 1.2,
            rotation = vec3(270.0, 90.0, 0.0),
        })
        
        lib.points.new({
            coords = coords,
            distance = 20,
            nearby = function(self)
                if self.currentDistance < 2.0 then
                    local isOpen = lib.isTextUIOpen()
                    if not isOpen then
                        lib.showTextUI("[E] - Foglalás - ".. jobname, {
                            position = "right-center",
                            icon = "fa-solid fa-flag",
                            iconColor = "white",
                            style = {
                                backgroundColor = hexColor .. "B3",
                                color = "white",
                                fontSize = "20px"
                            }
                        })
                    end
                    if IsControlJustReleased(0, E) then
                        Capture(job, false)
                        captureing = not captureing
                        lib.hideTextUI()
                    end
                else
                    local isOpen = lib.isTextUIOpen()
                    if isOpen then
                        lib.hideTextUI()
                        capure = lib.callback.await("nn_caption:whocaptured", false, job)
                        jobname = lib.callback.await("nn_caption:getjobname", false, capure)
                    end
                end
                tp:draw()
                downpt:draw()
            end,
            onExit = function(self)
                NN.CancelProgressbar()
                captureing = false
                TriggerServerEvent("nn_caption:cancelcapture")
            end,
            onEnter = function()
                captureing = false
            end
        })
    elseif place then
        local tp = lib.marker.new({
            type = 22,
            coords = coords,
            color = rgbColor,
            width = 0.8,
            height = 1.1,
        })

        local downpt = lib.marker.new({
            type = 6,
            coords = coords + vec3(0.0, 0.0, -0.9),
            color = rgbColor,
            width = 1.2,
            height = 1.2,
            rotation = vec3(270.0, 90.0, 0.0),
        })

        lib.points.new({
            coords = coords,
            distance = 20,
            nearby = function(self)
                if self.currentDistance < 2.0 then
                    local isOpen = lib.isTextUIOpen()
                    if not isOpen then
                        lib.showTextUI("[E] - Foglalás - ".. place, {
                            position = "right-center",
                            icon = "fa-solid fa-flag",
                            iconColor = "white",
                            style = {
                                backgroundColor = hexColor .. "B3",
                                color = "white",
                                fontSize = "20px"
                            }
                        })
                    end
                    if IsControlJustReleased(0, E) then
                        Capture(false, place)
                        lib.hideTextUI()
                    end
                else
                    local isOpen = lib.isTextUIOpen()
                    if isOpen then
                        lib.hideTextUI()
                    end
                end
                tp:draw()
                downpt:draw()
            end,
            onExit = function(self)
                NN.CancelProgressbar()
                captureing = false
                TriggerServerEvent("nn_caption:cancelcapture")
            end,
            onEnter = function()
                captureing = false
            end
        })
    end
end

function Capture(job, place)
    if captureing then
        TriggerServerEvent("nn_caption:capture", job, place)
    end
end


function PlaceBlip(coords, color, job, placename)
    if job then
        local jobname = lib.callback.await("nn_caption:getjobname", 100, job)
        while not jobname do
            Wait(100)
            jobname = lib.callback.await("nn_caption:getjobname", 100, job)
        end
        
        if not territoryBlips[job] then
            territoryBlips[job] = {
                main = AddBlipForCoord(coords),
                radius = AddBlipForRadius(coords, 100.0)
            }
            
            SetBlipCategory(territoryBlips[job].main, 50) 
            SetBlipCategory(territoryBlips[job].radius, 50)
            AddTextEntry("BLIP_CAT_" .. 50, "Terület Foglalás")
        end
        
        SetBlipSprite(territoryBlips[job].main, 164)
        SetBlipColour(territoryBlips[job].main, HexToBlipColor(color))
        SetBlipScale(territoryBlips[job].main, 1.3)
        SetBlipAsShortRange(territoryBlips[job].main, true)
        
        SetBlipAlpha(territoryBlips[job].radius, 128)
        SetBlipColour(territoryBlips[job].radius, HexToBlipColor(color))
        SetBlipAsShortRange(territoryBlips[job].radius, true)
        
        UpdateBlipName(job, jobname, "N/A")
    elseif placename then
        if not placeBlips[placename] then
            placeBlips[placename] = {
                main = AddBlipForCoord(coords),
                radius = AddBlipForRadius(coords, 100.0)
            }
            SetBlipSprite(placeBlips[placename].main, NN.places[placename].blip.sprite or 164)
            SetBlipColour(placeBlips[placename].main, HexToBlipColor(color))
            SetBlipScale(placeBlips[placename].main, 0.8)
            SetBlipAsShortRange(placeBlips[placename].main, true)
            SetBlipAlpha(placeBlips[placename].radius, 128)
            SetBlipColour(placeBlips[placename].radius, HexToBlipColor(color))
            SetBlipAsShortRange(placeBlips[placename].radius, true)

            UpdateBlipName(false, placename, "N/A", placename)
        end
    else
        print("^2[ERROR] ^7NN Caption: ^1Nem adtál meg frakciót vagy helyet a PlaceBlip függvényben!^0")
    end
end

function UpdateBlipName(job, originalName, capturedBy, placename)
    if job then
        if not territoryBlips[job] or not DoesBlipExist(territoryBlips[job].main) then
            local coords = lib.callback.await('nn_caption:getTerritoryCoords', 100, job)
            if coords then
                PlaceBlip(coords, NN.fractions[job].color, job)
            else
                return
            end
        end

        local displayName
        if capturedBy and capturedBy ~= "N/A" then
            local capturerName = lib.callback.await("nn_caption:getjobname", 100, capturedBy)
            while not capturerName do
                Wait(100)
                capturerName = lib.callback.await("nn_caption:getjobname", 100, capturedBy)
            end
            
            if capturerName == originalName then
                displayName = originalName
            else
                displayName = ("%s (Elfoglalta: %s)"):format(originalName, capturerName)
            end
        else
            displayName = originalName
        end

        if territoryBlips[job] and DoesBlipExist(territoryBlips[job].main) then
            SetBlipCategory(territoryBlips[job].main, 50)
            AddTextEntry("BLIP_CAT_" .. 50, "Terület Foglalás")
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(displayName)
            EndTextCommandSetBlipName(territoryBlips[job].main)
        end

    elseif placename then
        if not placeBlips[placename] or not DoesBlipExist(placeBlips[placename].main) then
            local coords = lib.callback.await('nn_caption:getPlaceCoords', 100, placename)
            if coords then
                PlaceBlip(coords, Config.Places[placename].color, nil, placename)
            else
                return
            end
        end

        local displayName = placename
        if capturedBy and capturedBy ~= "N/A" then
            local capturerName = lib.callback.await("nn_caption:getjobname", 100, capturedBy)
            while not capturerName do
                Wait(100)
                capturerName = lib.callback.await("nn_caption:getjobname", 100, capturedBy)
            end
            
            if capturerName ~= placename then
                displayName = ("%s (Elfoglalta: %s)"):format(placename, capturerName)
            end
        end

        if placeBlips[placename] and DoesBlipExist(placeBlips[placename].main) then
            SetBlipCategory(placeBlips[placename].main, 50)
            AddTextEntry("BLIP_CAT_" .. 50, "Hely Foglalás")
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(displayName)
            EndTextCommandSetBlipName(placeBlips[placename].main)
        end
    else
        print("^1[ERROR] UpdateBlipName called without job or placename!")
    end
end