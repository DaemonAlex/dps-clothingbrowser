--[[
    dps-clothingbrowser Server
    Handles outfit export file saving (JSON + wasabi Lua format)
    Wasabi exports auto-merge genders: export "Patrol" on male, then "Patrol"
    on female, and the same .lua file gets both genders filled in.
]]

local resName = GetCurrentResourceName()

-- ============================================================
-- MANIFEST — tracks wasabi exports by label for gender merging
-- ============================================================
local MANIFEST_PATH = 'wasabi-exports/manifest.json'

local function LoadManifest()
    local raw = LoadResourceFile(resName, MANIFEST_PATH)
    if raw and raw ~= '' then
        return json.decode(raw) or {}
    end
    return {}
end

local function SaveManifest(manifest)
    SaveResourceFile(resName, MANIFEST_PATH, json.encode(manifest, { indent = true }), -1)
end

-- ============================================================
-- WASABI LUA GENERATION
-- ============================================================
local function BuildGenderBlock(genderName, genderData)
    local lines = {}
    table.insert(lines, string.format('        %s = {', genderName))
    table.insert(lines, '            clothing = {')

    if genderData and genderData.clothing then
        for _, c in ipairs(genderData.clothing) do
            table.insert(lines, string.format(
                '                { component = %d, drawable = %d, texture = %d },',
                c.component, c.drawable, c.texture
            ))
        end
    else
        table.insert(lines, '                -- Not yet exported')
    end

    table.insert(lines, '            },')
    table.insert(lines, '            props = {')

    if genderData and genderData.props then
        for _, p in ipairs(genderData.props) do
            table.insert(lines, string.format(
                '                { component = %d, drawable = %d, texture = %d },',
                p.component, p.drawable, p.texture
            ))
        end
    end

    table.insert(lines, '            },')
    table.insert(lines, '        },')
    return lines
end

local function GenerateWasabiLua(entry)
    local lines = {}
    table.insert(lines, '    {')
    table.insert(lines, string.format("        label = '%s',", (entry.label or 'Unnamed'):gsub("'", "\\'")))
    table.insert(lines, string.format('        minGrade = %d,', entry.minGrade or 0))

    -- Male block
    for _, line in ipairs(BuildGenderBlock('male', entry.male)) do
        table.insert(lines, line)
    end

    -- Female block
    for _, line in ipairs(BuildGenderBlock('female', entry.female)) do
        table.insert(lines, line)
    end

    table.insert(lines, '    },')
    return table.concat(lines, '\n')
end

-- Convert raw export data (dps-clothingbrowser format) into wasabi gender data
local function ConvertToGenderData(parsed)
    local clothing = {}
    if parsed.components then
        for _, c in ipairs(parsed.components) do
            table.insert(clothing, {
                component = c.component_id,
                drawable = c.drawable,
                texture = c.texture,
            })
        end
    end

    local props = {}
    if parsed.props then
        for _, p in ipairs(parsed.props) do
            table.insert(props, {
                component = p.prop_id,
                drawable = p.drawable,
                texture = p.texture,
            })
        end
    end

    return { clothing = clothing, props = props }
end

-- ============================================================
-- EXPORT CALLBACK
-- ============================================================
lib.callback.register('dps-clothingbrowser:saveExport', function(source, jsonStr, name)
    local safeName = (name or 'outfit'):gsub('[^%w%-_]', '_')
    local timestamp = os.date('%Y%m%d_%H%M%S')
    local jsonFilename = string.format('exports/%s_%s.json', safeName, timestamp)

    local success = SaveResourceFile(resName, jsonFilename, jsonStr, -1)
    if not success then return nil end

    local playerName = GetPlayerName(source) or 'Unknown'
    print(string.format('[dps-clothingbrowser] %s exported outfit: %s', playerName, jsonFilename))

    -- Parse and generate wasabi format
    local parsed = json.decode(jsonStr)
    if not parsed then return jsonFilename end

    local label = parsed.label or 'Unnamed Outfit'
    local modelStr = parsed.model or 'mp_m_freemode_01'
    local isMale = modelStr == 'mp_m_freemode_01'
    local gender = isMale and 'male' or 'female'
    local genderData = ConvertToGenderData(parsed)

    -- Determine minGrade
    local minGrade = 0
    if parsed.grades and #parsed.grades > 0 then
        minGrade = parsed.grades[1]
        for _, g in ipairs(parsed.grades) do
            if g < minGrade then minGrade = g end
        end
    end

    -- Load manifest and merge
    local manifest = LoadManifest()
    local key = safeName:lower()

    if not manifest[key] then
        manifest[key] = {
            label = label,
            minGrade = minGrade,
        }
    end

    -- Update the exported gender, preserve the other
    manifest[key][gender] = genderData
    manifest[key].label = label
    manifest[key].minGrade = minGrade
    SaveManifest(manifest)

    -- Generate the wasabi Lua file (always overwrites with merged data)
    local wasabiLua = GenerateWasabiLua(manifest[key])
    local bothGenders = manifest[key].male and manifest[key].female
    local statusLine = bothGenders
        and '-- Status: COMPLETE (both genders exported)'
        or  string.format('-- Status: %s exported, %s still needed',
                gender, isMale and 'female' or 'male')

    local header = string.format(
        '-- Wasabi uniform entry generated by dps-clothingbrowser\n'
        .. '-- Label: %s\n'
        .. '%s\n'
        .. '-- Paste this into your wasabi_police or wasabi_ambulance config.lua uniforms table\n\n',
        label, statusLine
    )

    local luaFilename = string.format('wasabi-exports/%s.lua', key)
    local luaSuccess = SaveResourceFile(resName, luaFilename, header .. wasabiLua, -1)
    if luaSuccess then
        local status = bothGenders and '(COMPLETE - both genders)' or string.format('(%s only)', gender)
        print(string.format('[dps-clothingbrowser] Wasabi format saved: %s %s', luaFilename, status))
    end

    return jsonFilename
end)
