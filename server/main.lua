--[[
    dps-clothingbrowser Server
    Handles outfit export file saving
]]

lib.callback.register('dps-clothingbrowser:saveExport', function(source, jsonStr, name)
    local safeName = (name or 'outfit'):gsub('[^%w%-_]', '_')
    local timestamp = os.date('%Y%m%d_%H%M%S')
    local filename = string.format('exports/%s_%s.json', safeName, timestamp)

    local success = SaveResourceFile(GetCurrentResourceName(), filename, jsonStr, -1)

    if success then
        local playerName = GetPlayerName(source) or 'Unknown'
        print(string.format('[dps-clothingbrowser] %s exported outfit: %s', playerName, filename))
        return filename
    end

    return nil
end)
