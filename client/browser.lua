--[[
    dps-clothingbrowser v2.0
    NUI-based admin tool for browsing, identifying, and exporting clothing/uniform configurations

    Commands:
        /cb               Open the clothing browser
        /clothingbrowser   Alias

    Controls (handled in NUI JavaScript — no game key conflicts):
        Left/Right Arrow    Cycle drawable (+/- 1, hold SHIFT for +/- 10)
        Up/Down Arrow       Cycle texture
        E                   Save current piece to outfit builder
        Escape              Close browser
]]

-- ============================================================
-- STATE
-- ============================================================
local IsOpen = false
local BrowseType = nil          -- 'component' or 'prop'
local BrowseSlot = nil          -- slot ID
local CurrentDrawable = 0
local CurrentTexture = 0
local SavedOutfit = { components = {}, props = {} }
local OriginalAppearance = nil
local BasePedHeading = 0.0

-- Camera state
local BrowserCam = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function SaveCurrentAppearance()
    local ped = PlayerPedId()
    local app = { components = {}, props = {} }
    for i = 0, 11 do
        app.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
        }
    end
    for _, id in ipairs(Config.PropIds) do
        app.props[id] = {
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id),
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

local function GetBrowseResult()
    return {
        drawable = CurrentDrawable,
        texture = CurrentTexture,
        maxDrawable = math.max(0, GetMaxDrawable()),
        maxTexture = math.max(0, GetMaxTexture()),
    }
end

local function GetSlotMeta()
    local ped = PlayerPedId()
    local meta = { components = {}, props = {} }

    for i = 0, 11 do
        meta.components[tostring(i)] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
        }
    end
    for _, id in ipairs(Config.PropIds) do
        meta.props[tostring(id)] = {
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id),
        }
    end

    return meta
end

local function GetSavedPiecesForNUI()
    local data = { components = {}, props = {} }
    for id, v in pairs(SavedOutfit.components) do
        data.components[tostring(id)] = { drawable = v.drawable, texture = v.texture }
    end
    for id, v in pairs(SavedOutfit.props) do
        data.props[tostring(id)] = { drawable = v.drawable, texture = v.texture }
    end
    return data
end

-- ============================================================
-- CAMERA SYSTEM
-- ============================================================
local function CreateBrowserCamera(offsetData)
    local ped = PlayerPedId()
    local pedPos = GetEntityCoords(ped)
    local heading = BasePedHeading
    local hr = math.rad(heading)

    local off = offsetData.offset
    -- Rotate offset by ped heading so camera is always in front
    local camX = pedPos.x + off.x * math.cos(hr) - off.y * math.sin(hr)
    local camY = pedPos.y + off.x * math.sin(hr) + off.y * math.cos(hr)
    local camZ = pedPos.z + off.z

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, camX, camY, camZ)

    -- Camera rotation: add ped heading to the Z rotation so it faces the ped
    local rot = offsetData.rotation
    SetCamRot(cam, rot.x, rot.y, heading + rot.z, 2)
    SetCamFov(cam, offsetData.fov)

    return cam
end

local function MoveCameraToSlot(slotType, slotId)
    local offsets = slotType == 'component'
        and Config.CameraOffsets.components[slotId]
        or  Config.CameraOffsets.props[slotId]

    if not offsets then
        offsets = Config.CameraOffsets.default
    end

    -- Reset ped heading before moving camera to prevent drift
    local ped = PlayerPedId()
    SetEntityHeading(ped, BasePedHeading)

    local newCam = CreateBrowserCamera(offsets)

    if BrowserCam then
        SetCamActiveWithInterp(newCam, BrowserCam, 500, 1, 1)
        Wait(500)
        DestroyCam(BrowserCam, false)
    else
        SetCamActive(newCam, true)
        RenderScriptCams(true, true, 500, true, false)
    end

    BrowserCam = newCam
end

local function DestroyBrowserCamera()
    if BrowserCam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(BrowserCam, false)
        BrowserCam = nil
    end
end

local function ResetCameraToFullBody()
    local offsets = Config.CameraOffsets.default
    local ped = PlayerPedId()
    SetEntityHeading(ped, BasePedHeading)

    local newCam = CreateBrowserCamera(offsets)

    if BrowserCam then
        SetCamActiveWithInterp(newCam, BrowserCam, 500, 1, 1)
        Wait(500)
        DestroyCam(BrowserCam, false)
    else
        SetCamActive(newCam, true)
        RenderScriptCams(true, true, 500, true, false)
    end

    BrowserCam = newCam
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
            texture = GetPedTextureVariation(ped, i),
        })
    end

    for _, id in ipairs(Config.PropIds) do
        table.insert(props, {
            prop_id = id,
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id),
        })
    end

    return { components = components, props = props }
end

local function BuildSavedOutfitExport()
    local outfit = { components = {}, props = {} }

    for id, data in pairs(SavedOutfit.components) do
        table.insert(outfit.components, {
            component_id = id,
            drawable = data.drawable,
            texture = data.texture,
        })
    end
    for id, data in pairs(SavedOutfit.props) do
        table.insert(outfit.props, {
            prop_id = id,
            drawable = data.drawable,
            texture = data.texture,
        })
    end

    table.sort(outfit.components, function(a, b) return a.component_id < b.component_id end)
    table.sort(outfit.props, function(a, b) return a.prop_id < b.prop_id end)

    return outfit
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================
local function OpenBrowser()
    if IsOpen then return end
    IsOpen = true

    local ped = PlayerPedId()

    -- Save original appearance
    if not OriginalAppearance then
        OriginalAppearance = SaveCurrentAppearance()
    end

    -- Store base heading
    BasePedHeading = GetEntityHeading(ped)

    -- Freeze player
    FreezeEntityPosition(ped, true)

    -- Determine model
    local isMale = GetEntityModel(ped) == GetHashKey('mp_m_freemode_01')

    -- Start with full body camera
    CreateThread(function()
        ResetCameraToFullBody()
    end)

    -- Gather slot metadata
    local slotMeta = GetSlotMeta()
    local savedPieces = GetSavedPiecesForNUI()

    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        model = isMale and 'male' or 'female',
        slotMeta = slotMeta,
        savedPieces = savedPieces,
    })
end

local function CloseBrowser()
    if not IsOpen then return end
    IsOpen = false

    -- Release NUI
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    -- Destroy camera
    DestroyBrowserCamera()

    -- Unfreeze player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    -- Reset state
    BrowseType = nil
    BrowseSlot = nil
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================
RegisterNUICallback('close', function(_, cb)
    CloseBrowser()
    cb({ ok = true })
end)

RegisterNUICallback('selectSlot', function(data, cb)
    BrowseType = data.type
    BrowseSlot = data.id

    local ped = PlayerPedId()
    if BrowseType == 'component' then
        CurrentDrawable = GetPedDrawableVariation(ped, BrowseSlot)
        CurrentTexture = GetPedTextureVariation(ped, BrowseSlot)
    else
        CurrentDrawable = GetPedPropIndex(ped, BrowseSlot)
        CurrentTexture = GetPedPropTextureIndex(ped, BrowseSlot)
        if CurrentDrawable < 0 then CurrentDrawable = 0 end
    end

    -- Move camera to this slot
    CreateThread(function()
        MoveCameraToSlot(BrowseType, BrowseSlot)
    end)

    cb(GetBrowseResult())
end)

RegisterNUICallback('changeDrawable', function(data, cb)
    if not BrowseType or not BrowseSlot then
        cb({ drawable = 0, texture = 0, maxDrawable = 0, maxTexture = 0 })
        return
    end

    local delta = data.delta or 0
    local maxDrawable = GetMaxDrawable()

    CurrentDrawable = CurrentDrawable + delta
    if CurrentDrawable > maxDrawable then
        -- If jumped past max (shift+10), clamp or wrap
        if math.abs(delta) > 1 then
            CurrentDrawable = maxDrawable
        else
            CurrentDrawable = 0
        end
    elseif CurrentDrawable < 0 then
        if math.abs(delta) > 1 then
            CurrentDrawable = 0
        else
            CurrentDrawable = maxDrawable
        end
    end

    CurrentTexture = 0
    ApplySelection()
    cb(GetBrowseResult())
end)

RegisterNUICallback('changeTexture', function(data, cb)
    if not BrowseType or not BrowseSlot then
        cb({ texture = 0, maxTexture = 0 })
        return
    end

    local delta = data.delta or 0
    local maxTexture = GetMaxTexture()

    CurrentTexture = CurrentTexture + delta
    if CurrentTexture > maxTexture then
        CurrentTexture = 0
    elseif CurrentTexture < 0 then
        CurrentTexture = maxTexture
    end

    ApplySelection()
    cb({ texture = CurrentTexture, maxTexture = math.max(0, GetMaxTexture()) })
end)

RegisterNUICallback('jumpToDrawable', function(data, cb)
    if not BrowseType or not BrowseSlot then
        cb({ drawable = 0, texture = 0, maxDrawable = 0, maxTexture = 0 })
        return
    end

    local target = data.drawable or 0
    local maxDrawable = GetMaxDrawable()

    if target > maxDrawable then target = maxDrawable end
    if target < 0 then target = 0 end

    CurrentDrawable = target
    CurrentTexture = 0
    ApplySelection()
    cb(GetBrowseResult())
end)

RegisterNUICallback('savePiece', function(data, cb)
    local browseType = data.type
    local slotId = data.id

    if browseType == 'component' then
        SavedOutfit.components[slotId] = {
            drawable = data.drawable,
            texture = data.texture,
        }
    else
        SavedOutfit.props[slotId] = {
            drawable = data.drawable,
            texture = data.texture,
        }
    end

    cb({ ok = true })
end)

RegisterNUICallback('removePiece', function(data, cb)
    if data.type == 'component' then
        SavedOutfit.components[data.id] = nil
    else
        SavedOutfit.props[data.id] = nil
    end
    cb({ ok = true })
end)

RegisterNUICallback('clearAllPieces', function(_, cb)
    SavedOutfit = { components = {}, props = {} }
    cb({ ok = true })
end)

RegisterNUICallback('resetCamera', function(_, cb)
    CreateThread(function()
        ResetCameraToFullBody()
    end)
    cb({ ok = true })
end)

RegisterNUICallback('getExportData', function(data, cb)
    if data.mode == 'snapshot' then
        cb(GetCurrentFullAppearance())
    elseif data.mode == 'saved' then
        cb(BuildSavedOutfitExport())
    else
        cb({})
    end
end)

RegisterNUICallback('confirmExport', function(data, cb)
    local jsonStr = data.json
    local label = data.label or ('outfit_' .. os.time())

    -- Print to F8 console
    print('^2--- OUTFIT EXPORT: ' .. label .. ' ---^0')
    print(jsonStr)
    print('^2--- END EXPORT ---^0')

    -- Save server-side via ox_lib callback
    lib.callback('dps-clothingbrowser:saveExport', false, function(path)
        if path then
            cb({ ok = true, path = path })
        else
            cb({ ok = false })
        end
    end, jsonStr, label:gsub('[^%w%-_ ]', '_'))
end)

RegisterNUICallback('restoreOriginal', function(_, cb)
    if OriginalAppearance then
        RestoreAppearance(OriginalAppearance)
        OriginalAppearance = nil
        cb({ ok = true, slotMeta = GetSlotMeta() })
    else
        cb({ ok = false })
    end
end)

-- ============================================================
-- COMMANDS
-- ============================================================
RegisterCommand('cb', function()
    if IsOpen then
        CloseBrowser()
    else
        OpenBrowser()
    end
end, false)

RegisterCommand('clothingbrowser', function()
    if IsOpen then
        CloseBrowser()
    else
        OpenBrowser()
    end
end, false)

TriggerEvent('chat:addSuggestion', '/cb', 'Open clothing browser (admin tool)')
