--[[
    dps-clothingbrowser Server
    Saves outfits to database with gender auto-merge.
    Export "LSPD Patrol" on male, then "LSPD Patrol" on female —
    both genders end up on the same DB row, ready to query later.
]]

-- ============================================================
-- DATABASE INIT
-- ============================================================
MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dps_outfits` (
            `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `name`       VARCHAR(100) NOT NULL,
            `label`      VARCHAR(255) NOT NULL,
            `job`        VARCHAR(50)  DEFAULT NULL,
            `min_grade`  INT UNSIGNED NOT NULL DEFAULT 0,
            `male_data`  JSON         DEFAULT NULL,
            `female_data` JSON        DEFAULT NULL,
            `created_by` VARCHAR(100) DEFAULT NULL,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print('[dps-clothingbrowser] Database table ready')
end)

-- ============================================================
-- HELPERS
-- ============================================================

-- Convert dps-clothingbrowser export format into wasabi-style gender data
-- Each piece carries metadata: slot name, type label, and IDs
local function ConvertToGenderData(parsed)
    local clothing = {}
    if parsed.components then
        for _, c in ipairs(parsed.components) do
            clothing[#clothing + 1] = {
                component = c.component_id,
                name = Config.ComponentNames[c.component_id] or ('Component ' .. c.component_id),
                drawable = c.drawable,
                texture = c.texture,
            }
        end
    end

    local props = {}
    if parsed.props then
        for _, p in ipairs(parsed.props) do
            props[#props + 1] = {
                component = p.prop_id,
                name = Config.PropNames[p.prop_id] or ('Prop ' .. p.prop_id),
                drawable = p.drawable,
                texture = p.texture,
            }
        end
    end

    return { clothing = clothing, props = props }
end

-- ============================================================
-- EXPORT CALLBACK
-- ============================================================
lib.callback.register('dps-clothingbrowser:saveExport', function(source, jsonStr, name)
    local parsed = json.decode(jsonStr)
    if not parsed then return nil end

    local label = parsed.label or 'Unnamed Outfit'
    local safeName = (name or 'outfit'):gsub('[^%w%-_ ]', '_')
    local modelStr = parsed.model or 'mp_m_freemode_01'
    local isMale = modelStr == 'mp_m_freemode_01'
    local gender = isMale and 'male' or 'female'
    local genderData = ConvertToGenderData(parsed)
    local genderJson = json.encode(genderData)

    -- Determine job and minGrade
    local job = parsed.job
    if job == '' then job = nil end

    local minGrade = 0
    if parsed.grades and #parsed.grades > 0 then
        minGrade = parsed.grades[1]
        for _, g in ipairs(parsed.grades) do
            if g < minGrade then minGrade = g end
        end
    end

    local playerName = GetPlayerName(source) or 'Unknown'
    local dataColumn = isMale and 'male_data' or 'female_data'

    -- Upsert: insert new or update existing row's gender column
    MySQL.query.await(string.format([[
        INSERT INTO `dps_outfits` (`name`, `label`, `job`, `min_grade`, `%s`, `created_by`)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `label` = VALUES(`label`),
            `job` = VALUES(`job`),
            `min_grade` = VALUES(`min_grade`),
            `%s` = VALUES(`%s`),
            `created_by` = VALUES(`created_by`)
    ]], dataColumn, dataColumn, dataColumn), {
        safeName:lower(), label, job, minGrade, genderJson, playerName,
    })

    -- Check if both genders are now filled
    local row = MySQL.single.await(
        'SELECT `male_data`, `female_data` FROM `dps_outfits` WHERE `name` = ?',
        { safeName:lower() }
    )

    local status = (row and row.male_data and row.female_data)
        and 'COMPLETE (both genders)'
        or  string.format('%s saved', gender)

    print(string.format(
        '[dps-clothingbrowser] %s saved outfit "%s" to database — %s',
        playerName, label, status
    ))

    -- Also print to F8 console for the exporting player
    print('^2--- OUTFIT EXPORT: ' .. label .. ' ---^0')
    print(jsonStr)
    print('^2--- END EXPORT ---^0')

    return safeName:lower()
end)
