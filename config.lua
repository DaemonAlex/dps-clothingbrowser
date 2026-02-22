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

-- Components relevant for uniform building (skip face and hair)
Config.UniformComponents = {1, 3, 4, 5, 6, 7, 8, 9, 10, 11}

-- Prop IDs available for browsing
Config.PropIds = {0, 1, 2, 6, 7}
