--[[
    dps-clothingbrowser v1.0
    Admin tool for browsing, identifying, and exporting clothing/uniform configurations

    Commands:
        /cb             Open the clothing browser menu
        /clothingbrowser  Alias

    Browse mode controls:
        Left/Right Arrow    Cycle drawable (+/- 1, hold SHIFT for +/- 10)
        Up/Down Arrow       Cycle texture
        E                   Save current piece to outfit builder
        Backspace           Exit browse mode
]]

-- ============================================================
-- STATE
-- ============================================================
local BrowsingActive = false
local BrowseType = nil   -- 'component' or 'prop'
local BrowseSlot = nil   -- component_id (0-11) or prop_id (0,1,2,6,7)
local CurrentDrawable = 0
local CurrentTexture = 0
local SavedOutfit = { components = {}, props = {} }
local OriginalAppearance = nil
local SavedCount = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function SaveCurrentAppearance()
    local ped = PlayerPedId()
    local app = { components = {}, props = {} }
    for i = 0, 11 do
        app.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i)
        }
    end
    for _, id in ipairs(Config.PropIds) do
        app.props[id] = {
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id)
        }
    end
    return app
end

local function RestoreAppearance(app)
    if not app then return end
    local ped = PlayerPedId()
    for i = 0, 11 do
        local c = app.components[i]
        if c then
            SetPedComponentVariation(ped, i, c.drawable, c.texture, 0)
        end
    end
    for _, id in ipairs(Config.PropIds) do
        local p = app.props[id]
        if p then
            if p.drawable == -1 then
                ClearPedProp(ped, id)
            else
                SetPedPropIndex(ped, id, p.drawable, p.texture, true)
            end
        end
    end
end

local function GetMaxDrawable()
    local ped = PlayerPedId()
    if BrowseType == 'component' then
        return GetNumberOfPedDrawableVariations(ped, BrowseSlot) - 1
    else
        return GetNumberOfPedPropDrawableVariations(ped, BrowseSlot) - 1
    end
end

local function GetMaxTexture()
    local ped = PlayerPedId()
    if BrowseType == 'component' then
        return GetNumberOfPedTextureVariations(ped, BrowseSlot, CurrentDrawable) - 1
    else
        return GetNumberOfPedPropTextureVariations(ped, BrowseSlot, CurrentDrawable) - 1
    end
end

local function ApplySelection()
    local ped = PlayerPedId()
    if BrowseType == 'component' then
        SetPedComponentVariation(ped, BrowseSlot, CurrentDrawable, CurrentTexture, 0)
    else
        if CurrentDrawable == -1 then
            ClearPedProp(ped, BrowseSlot)
        else
            SetPedPropIndex(ped, BrowseSlot, CurrentDrawable, CurrentTexture, true)
        end
    end
end

local function UpdateOverlay()
    lib.hideTextUI()
    local maxDrawable = GetMaxDrawable()
    local maxTexture = math.max(0, GetMaxTexture())
    local slotName = BrowseType == 'component'
        and Config.ComponentNames[BrowseSlot]
        or Config.PropNames[BrowseSlot]

    local savedMark = ''
    if BrowseType == 'component' and SavedOutfit.components[BrowseSlot] then
        local s = SavedOutfit.components[BrowseSlot]
        savedMark = string.format('  |  Saved: %d:%d', s.drawable, s.texture)
    elseif BrowseType == 'prop' and SavedOutfit.props[BrowseSlot] then
        local s = SavedOutfit.props[BrowseSlot]
        savedMark = string.format('  |  Saved: %d:%d', s.drawable, s.texture)
    end

    lib.showTextUI(string.format(
        '[%s %d] %s\nDrawable: %d / %d  |  Texture: %d / %d%s\nArrows: Navigate (SHIFT x10)  |  [E] Save  |  [Backspace] Exit',
        BrowseType == 'component' and 'Comp' or 'Prop',
        BrowseSlot,
        slotName or 'Unknown',
        CurrentDrawable, maxDrawable,
        CurrentTexture, maxTexture,
        savedMark
    ), {
        position = 'top-center',
        icon = 'shirt'
    })
end

-- ============================================================
-- EXPORT
-- ============================================================
local function GetCurrentFullAppearance()
    local ped = PlayerPedId()
    local components = {}
    local props = {}

    for i = 0, 11 do
        table.insert(components, {
            component_id = i,
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i)
        })
    end

    for _, id in ipairs(Config.PropIds) do
        table.insert(props, {
            prop_id = id,
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id)
        })
    end

    return { components = components, props = props }
end

local function FormatOutfitJSON(outfit, label, job, grades)
    local isMale = GetEntityModel(PlayerPedId()) == GetHashKey('mp_m_freemode_01')
    local model = isMale and 'mp_m_freemode_01' or 'mp_f_freemode_01'

    local lines = {}
    table.insert(lines, '{')
    table.insert(lines, string.format('  "label": "%s",', label or 'Unnamed Outfit'))
    table.insert(lines, string.format('  "model": "%s",', model))

    if job and job ~= '' then
        table.insert(lines, string.format('  "job": "%s",', job))
    end
    if grades and #grades > 0 then
        table.insert(lines, string.format('  "grades": [%s],', table.concat(grades, ', ')))
    end

    table.insert(lines, '  "components": [')
    for i, c in ipairs(outfit.components) do
        local comma = i < #outfit.components and ',' or ''
        table.insert(lines, string.format(
            '    {"component_id": %d, "drawable": %d, "texture": %d}%s',
            c.component_id, c.drawable, c.texture, comma
        ))
    end
    table.insert(lines, '  ],')

    table.insert(lines, '  "props": [')
    for i, p in ipairs(outfit.props) do
        local comma = i < #outfit.props and ',' or ''
        table.insert(lines, string.format(
            '    {"prop_id": %d, "drawable": %d, "texture": %d}%s',
            p.prop_id, p.drawable, p.texture, comma
        ))
    end
    table.insert(lines, '  ]')
    table.insert(lines, '}')

    return table.concat(lines, '\n')
end

local function ExportOutfit(outfit, label, job, grades)
    local jsonStr = FormatOutfitJSON(outfit, label, job, grades)

    -- Print to F8 console
    print('^2--- OUTFIT EXPORT: ' .. (label or 'Unnamed') .. ' ---^0')
    print(jsonStr)
    print('^2--- END EXPORT ---^0')

    -- Save server-side
    lib.callback('dps-clothingbrowser:saveExport', false, function(path)
        if path then
            lib.notify({
                title = 'Outfit Exported',
                description = 'Saved to: ' .. path .. '\nAlso printed to F8 console',
                type = 'success',
                duration = 8000
            })
        end
    end, jsonStr, label or ('outfit_' .. os.time()))

    -- Show in alert dialog
    lib.alertDialog({
        header = 'Outfit Export (qs-appearance format)',
        content = jsonStr .. '\n\nAlso printed to F8 console and saved server-side.',
        centered = true
    })
end

-- ============================================================
-- BROWSE MODE
-- ============================================================
local OpenComponentMenu, OpenPropMenu, OpenMainMenu

local function StartBrowse(browseType, slot, initialDrawable)
    if BrowsingActive then return end
    BrowsingActive = true
    BrowseType = browseType
    BrowseSlot = slot

    if initialDrawable then
        CurrentDrawable = initialDrawable
        CurrentTexture = 0
    else
        local ped = PlayerPedId()
        if browseType == 'component' then
            CurrentDrawable = GetPedDrawableVariation(ped, slot)
            CurrentTexture = GetPedTextureVariation(ped, slot)
        else
            CurrentDrawable = GetPedPropIndex(ped, slot)
            CurrentTexture = GetPedPropTextureIndex(ped, slot)
            if CurrentDrawable < 0 then CurrentDrawable = 0 end
        end
    end

    if not OriginalAppearance then
        OriginalAppearance = SaveCurrentAppearance()
    end

    ApplySelection()
    UpdateOverlay()

    CreateThread(function()
        while BrowsingActive do
            Wait(0)

            local maxDrawable = GetMaxDrawable()
            local maxTexture = GetMaxTexture()
            local changed = false
            local shift = IsControlPressed(0, 21) -- SHIFT

            -- Disable most controls, keep movement and camera
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)   -- Look LR
            EnableControlAction(0, 2, true)   -- Look UD
            EnableControlAction(0, 30, true)  -- Move LR (A/D)
            EnableControlAction(0, 31, true)  -- Move UD (W/S)
            EnableControlAction(0, 21, true)  -- Sprint (Shift)
            EnableControlAction(0, 22, true)  -- Jump (Space)
            EnableControlAction(0, 245, true) -- Chat (T)
            EnableControlAction(0, 249, true) -- Push to talk (N)

            -- Right arrow: +1 drawable (SHIFT = +10)
            if IsDisabledControlJustPressed(0, 175) then
                local step = shift and 10 or 1
                CurrentDrawable = CurrentDrawable + step
                if CurrentDrawable > maxDrawable then
                    CurrentDrawable = shift and maxDrawable or 0
                end
                CurrentTexture = 0
                changed = true
            end

            -- Left arrow: -1 drawable (SHIFT = -10)
            if IsDisabledControlJustPressed(0, 174) then
                local step = shift and 10 or 1
                CurrentDrawable = CurrentDrawable - step
                if CurrentDrawable < 0 then
                    CurrentDrawable = shift and 0 or maxDrawable
                end
                CurrentTexture = 0
                changed = true
            end

            -- Up arrow: +1 texture
            if IsDisabledControlJustPressed(0, 172) then
                CurrentTexture = CurrentTexture + 1
                if CurrentTexture > maxTexture then CurrentTexture = 0 end
                changed = true
            end

            -- Down arrow: -1 texture
            if IsDisabledControlJustPressed(0, 173) then
                CurrentTexture = CurrentTexture - 1
                if CurrentTexture < 0 then CurrentTexture = maxTexture end
                changed = true
            end

            -- E: Save piece to outfit builder
            if IsDisabledControlJustPressed(0, 38) then
                if browseType == 'component' then
                    if not SavedOutfit.components[BrowseSlot] then
                        SavedCount = SavedCount + 1
                    end
                    SavedOutfit.components[BrowseSlot] = {
                        drawable = CurrentDrawable,
                        texture = CurrentTexture
                    }
                else
                    if not SavedOutfit.props[BrowseSlot] then
                        SavedCount = SavedCount + 1
                    end
                    SavedOutfit.props[BrowseSlot] = {
                        drawable = CurrentDrawable,
                        texture = CurrentTexture
                    }
                end
                lib.notify({
                    title = 'Piece Saved',
                    description = string.format('%s: drawable %d, texture %d',
                        browseType == 'component'
                            and Config.ComponentNames[BrowseSlot]
                            or Config.PropNames[BrowseSlot],
                        CurrentDrawable, CurrentTexture
                    ),
                    type = 'success'
                })
                UpdateOverlay()
            end

            -- Backspace: Exit browse mode
            if IsDisabledControlJustPressed(0, 177) then
                BrowsingActive = false
            end

            if changed then
                ApplySelection()
                UpdateOverlay()
            end
        end

        lib.hideTextUI()

        -- Return to the slot selection menu
        Wait(200)
        if BrowseType == 'component' then
            OpenComponentMenu()
        else
            OpenPropMenu()
        end
    end)
end

-- ============================================================
-- MENUS
-- ============================================================
local OpenOutfitBuilder

OpenComponentMenu = function()
    local ped = PlayerPedId()
    local options = {}

    for _, id in ipairs(Config.UniformComponents) do
        local current = GetPedDrawableVariation(ped, id)
        local max = GetNumberOfPedDrawableVariations(ped, id)
        local saved = SavedOutfit.components[id]

        table.insert(options, {
            title = string.format('[%d] %s', id, Config.ComponentNames[id]),
            description = string.format(
                'Current: %d | Total: %d%s',
                current, max,
                saved and string.format(' | Saved: %d:%d', saved.drawable, saved.texture) or ''
            ),
            icon = 'shirt',
            onSelect = function()
                StartBrowse('component', id)
            end
        })
    end

    lib.registerContext({
        id = 'cb_components',
        title = 'Browse Components',
        menu = 'cb_main',
        options = options
    })
    lib.showContext('cb_components')
end

OpenPropMenu = function()
    local ped = PlayerPedId()
    local options = {}

    for _, id in ipairs(Config.PropIds) do
        local current = GetPedPropIndex(ped, id)
        local max = GetNumberOfPedPropDrawableVariations(ped, id)
        local saved = SavedOutfit.props[id]

        table.insert(options, {
            title = string.format('[%d] %s', id, Config.PropNames[id]),
            description = string.format(
                'Current: %d | Total: %d%s',
                current, max,
                saved and string.format(' | Saved: %d:%d', saved.drawable, saved.texture) or ''
            ),
            icon = 'hat-wizard',
            onSelect = function()
                StartBrowse('prop', id)
            end
        })
    end

    lib.registerContext({
        id = 'cb_props',
        title = 'Browse Props',
        menu = 'cb_main',
        options = options
    })
    lib.showContext('cb_props')
end

OpenOutfitBuilder = function()
    local options = {}

    -- Show saved components
    for _, id in ipairs(Config.UniformComponents) do
        local data = SavedOutfit.components[id]
        if data then
            table.insert(options, {
                title = string.format('%s: %d:%d',
                    Config.ComponentNames[id] or ('Comp ' .. id),
                    data.drawable, data.texture
                ),
                description = string.format(
                    'Component %d | Drawable %d | Texture %d (click to remove)',
                    id, data.drawable, data.texture
                ),
                icon = 'check',
                onSelect = function()
                    SavedOutfit.components[id] = nil
                    SavedCount = SavedCount - 1
                    lib.notify({
                        title = 'Removed',
                        description = Config.ComponentNames[id] .. ' removed from outfit',
                        type = 'inform'
                    })
                    OpenOutfitBuilder()
                end
            })
        end
    end

    -- Show saved props
    for _, id in ipairs(Config.PropIds) do
        local data = SavedOutfit.props[id]
        if data then
            table.insert(options, {
                title = string.format('%s: %d:%d',
                    Config.PropNames[id] or ('Prop ' .. id),
                    data.drawable, data.texture
                ),
                description = string.format(
                    'Prop %d | Drawable %d | Texture %d (click to remove)',
                    id, data.drawable, data.texture
                ),
                icon = 'check',
                onSelect = function()
                    SavedOutfit.props[id] = nil
                    SavedCount = SavedCount - 1
                    lib.notify({
                        title = 'Removed',
                        description = Config.PropNames[id] .. ' removed from outfit',
                        type = 'inform'
                    })
                    OpenOutfitBuilder()
                end
            })
        end
    end

    if SavedCount == 0 then
        table.insert(options, {
            title = 'No pieces saved yet',
            description = 'Use [E] while browsing to save pieces',
            icon = 'info-circle',
            disabled = true
        })
    end

    -- Export saved pieces
    table.insert(options, {
        title = 'Export Saved Pieces',
        description = 'Export saved pieces as qs-appearance format',
        icon = 'file-export',
        onSelect = function()
            if SavedCount == 0 then
                lib.notify({ title = 'Nothing to export', type = 'error' })
                return
            end

            local input = lib.inputDialog('Export Outfit', {
                { type = 'input', label = 'Outfit Label', placeholder = 'e.g. LSPD Patrol Uniform' },
                { type = 'input', label = 'Job Name (optional)', placeholder = 'e.g. police' },
                { type = 'input', label = 'Grades (comma-separated, optional)', placeholder = 'e.g. 0,1,2,3' },
            })
            if not input then return end

            -- Build outfit from saved pieces
            local outfit = { components = {}, props = {} }
            for id, data in pairs(SavedOutfit.components) do
                table.insert(outfit.components, {
                    component_id = id,
                    drawable = data.drawable,
                    texture = data.texture
                })
            end
            for id, data in pairs(SavedOutfit.props) do
                table.insert(outfit.props, {
                    prop_id = id,
                    drawable = data.drawable,
                    texture = data.texture
                })
            end

            -- Sort by ID for clean output
            table.sort(outfit.components, function(a, b) return a.component_id < b.component_id end)
            table.sort(outfit.props, function(a, b) return a.prop_id < b.prop_id end)

            local grades = nil
            if input[3] and input[3] ~= '' then
                grades = {}
                for g in input[3]:gmatch('%d+') do
                    table.insert(grades, tonumber(g))
                end
            end

            ExportOutfit(outfit, input[1], input[2], grades)
        end
    })

    -- Clear all
    if SavedCount > 0 then
        table.insert(options, {
            title = 'Clear All Saved',
            description = 'Remove all saved pieces',
            icon = 'trash',
            onSelect = function()
                SavedOutfit = { components = {}, props = {} }
                SavedCount = 0
                lib.notify({ title = 'Cleared', description = 'All saved pieces removed', type = 'inform' })
                OpenOutfitBuilder()
            end
        })
    end

    lib.registerContext({
        id = 'cb_outfit',
        title = string.format('Outfit Builder (%d pieces)', SavedCount),
        menu = 'cb_main',
        options = options
    })
    lib.showContext('cb_outfit')
end

OpenMainMenu = function()
    local options = {
        {
            title = 'Browse Components',
            description = 'Tops, pants, shoes, vests, masks, etc.',
            icon = 'shirt',
            onSelect = OpenComponentMenu
        },
        {
            title = 'Browse Props',
            description = 'Hats, glasses, ears, watches, bracelets',
            icon = 'hat-wizard',
            onSelect = OpenPropMenu
        },
        {
            title = 'Jump to Drawable',
            description = 'Go directly to a specific slot + drawable ID',
            icon = 'hashtag',
            onSelect = function()
                local typeOptions = {
                    { value = 'component', label = 'Component' },
                    { value = 'prop', label = 'Prop' },
                }
                local input = lib.inputDialog('Jump to Drawable', {
                    { type = 'select', label = 'Type', options = typeOptions },
                    { type = 'number', label = 'Slot ID (Comp: 0-11 | Prop: 0,1,2,6,7)', default = 11 },
                    { type = 'number', label = 'Drawable ID', default = 0 },
                })
                if not input or not input[1] or not input[2] or not input[3] then return end

                local browseType = input[1]
                local slot = math.floor(input[2])
                local drawable = math.floor(input[3])

                StartBrowse(browseType, slot, drawable)
            end
        },
        {
            title = string.format('Outfit Builder (%d pieces)', SavedCount),
            description = 'View, manage, and export saved outfit pieces',
            icon = 'clipboard-list',
            onSelect = OpenOutfitBuilder
        },
        {
            title = 'Snapshot Current Look',
            description = 'Export ALL current clothing as qs-appearance format',
            icon = 'camera',
            onSelect = function()
                local input = lib.inputDialog('Snapshot Export', {
                    { type = 'input', label = 'Outfit Label', placeholder = 'e.g. LSPD Patrol Uniform' },
                    { type = 'input', label = 'Job Name (optional)', placeholder = 'e.g. police' },
                    { type = 'input', label = 'Grades (comma-separated, optional)', placeholder = 'e.g. 0,1,2,3' },
                })
                if not input then return end

                local outfit = GetCurrentFullAppearance()
                local grades = nil
                if input[3] and input[3] ~= '' then
                    grades = {}
                    for g in input[3]:gmatch('%d+') do
                        table.insert(grades, tonumber(g))
                    end
                end

                ExportOutfit(outfit, input[1], input[2], grades)
            end
        },
    }

    if OriginalAppearance then
        table.insert(options, {
            title = 'Restore Original',
            description = 'Revert all appearance changes made this session',
            icon = 'undo',
            onSelect = function()
                RestoreAppearance(OriginalAppearance)
                OriginalAppearance = nil
                lib.notify({
                    title = 'Restored',
                    description = 'Original appearance restored',
                    type = 'success'
                })
            end
        })
    end

    lib.registerContext({
        id = 'cb_main',
        title = 'Clothing Browser',
        options = options
    })
    lib.showContext('cb_main')
end

-- ============================================================
-- COMMANDS
-- ============================================================
RegisterCommand('cb', function()
    OpenMainMenu()
end, false)

RegisterCommand('clothingbrowser', function()
    OpenMainMenu()
end, false)

TriggerEvent('chat:addSuggestion', '/cb', 'Open clothing browser (admin tool)')
