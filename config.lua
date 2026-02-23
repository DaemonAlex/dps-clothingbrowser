Config = {}

-- GTA V component ID → name mapping
Config.ComponentNames = {
    [0]  = 'Face',
    [1]  = 'Mask',
    [2]  = 'Hair',
    [3]  = 'Arms/Torso',
    [4]  = 'Pants',
    [5]  = 'Bag',
    [6]  = 'Shoes',
    [7]  = 'Accessories',
    [8]  = 'Undershirt',
    [9]  = 'Body Armor',
    [10] = 'Decals/Badge',
    [11] = 'Tops',
}

-- GTA V prop ID → name mapping
Config.PropNames = {
    [0] = 'Hats',
    [1] = 'Glasses',
    [2] = 'Ears',
    [6] = 'Watches',
    [7] = 'Bracelets',
}

-- All component IDs for full browsing (0-11)
Config.AllComponents = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- Components relevant for uniform building (skip face and hair)
Config.UniformComponents = {1, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- Prop IDs available for browsing
Config.PropIds = {0, 1, 2, 6, 7}

-- Camera offsets per slot (sourced from qs-appearance patterns)
-- Each entry: { fov, offset = vec3, rotation = vec3 }
-- offset is relative to ped position; rotation is cam rotation
Config.CameraOffsets = {
    -- Components
    components = {
        [0]  = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Face
        [1]  = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Mask
        [2]  = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Hair
        [3]  = { fov = 50.0, offset = vector3(0.0, 0.90, 0.35),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Arms/Torso
        [4]  = { fov = 50.0, offset = vector3(0.0, 0.95, -0.10), rotation = vector3(-10.0, 0.0, 180.0) }, -- Pants
        [5]  = { fov = 50.0, offset = vector3(0.0, 0.90, 0.20),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Bag
        [6]  = { fov = 50.0, offset = vector3(0.0, 1.00, -0.60), rotation = vector3(-15.0, 0.0, 180.0) }, -- Shoes
        [7]  = { fov = 50.0, offset = vector3(0.0, 0.90, 0.20),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Accessories
        [8]  = { fov = 50.0, offset = vector3(0.0, 0.90, 0.35),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Undershirt
        [9]  = { fov = 50.0, offset = vector3(0.0, 0.90, 0.30),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Body Armor
        [10] = { fov = 50.0, offset = vector3(0.0, 0.90, 0.35),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Decals/Badge
        [11] = { fov = 50.0, offset = vector3(0.0, 0.90, 0.35),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Tops
    },
    -- Props
    props = {
        [0] = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Hats
        [1] = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Glasses
        [2] = { fov = 40.0, offset = vector3(0.0, 0.65, 0.68),  rotation = vector3(-5.0, 0.0, 180.0) },  -- Ears
        [6] = { fov = 50.0, offset = vector3(0.0, 0.85, -0.05), rotation = vector3(-10.0, 0.0, 180.0) }, -- Watches
        [7] = { fov = 50.0, offset = vector3(0.0, 0.85, -0.05), rotation = vector3(-10.0, 0.0, 180.0) }, -- Bracelets
    },
    -- Full body default (no specific slot selected)
    default = { fov = 60.0, offset = vector3(0.0, 1.80, 0.20), rotation = vector3(-5.0, 0.0, 180.0) },
}
