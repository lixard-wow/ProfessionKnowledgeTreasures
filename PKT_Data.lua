PKT = PKT or {}

PKT.ZONE_NAMES = {
    [2393] = "Silvermoon City",
    [2395] = "Eversong Woods",
    [2437] = "Zul'Aman",
    [2536] = "Atal'Aman",
    [2413] = "Harandar",
    [2405] = "Voidstorm",
    [2444] = "Slayer's Rise",
    [2576] = "The Den",
}

PKT.ZONE_ORDER = { 2393, 2395, 2437, 2536, 2405, 2444, 2413 }

PKT.ZONE_GROUPS = {
    { 2413, 2576 },
    { 2405, 2444 },
}

PKT.ZONE_FLYABLE = {
    { 2393, 2395 },
}

PKT.ZONE_TRANSIT = {
    [2536] = 2393,
    [2395] = 2393,
    [2413] = 2393,
}

PKT.PORTALS = {
    { mapID=2393, x=0.3670, y=0.6857, name="Portal to Harandar",                   dest=2413, unlockQuest=nil },
    { mapID=2393, x=0.3528, y=0.6565, name="Portal to Voidstorm",                  dest=2405, unlockQuest=nil },
    { mapID=2576, x=0.6470, y=0.7110, name="Portal to Silvermoon (The Den)",       dest=2393, unlockQuest=nil },
    { mapID=2576, x=0.6177, y=0.7347, name="Portal to Voidstorm (The Den)",        dest=2405, unlockQuest=nil },
    { mapID=2405, x=0.5155, y=0.7030, name="Portal to Silvermoon (Howling Ridge)", dest=2393, unlockQuest=nil },
    { mapID=2405, x=0.5170, y=0.7040, name="Portal to Harandar (Howling Ridge)",   dest=2413, unlockQuest=nil },

}

PKT.PROF_NAMES = {
    [2906] = "Alchemy",
    [2907] = "Blacksmithing",
    [2909] = "Enchanting",
    [2910] = "Engineering",
    [2912] = "Herbalism",
    [2913] = "Inscription",
    [2914] = "Jewelcrafting",
    [2915] = "Leatherworking",
    [2916] = "Mining",
    [2917] = "Skinning",
    [2918] = "Tailoring",
}

PKT.TREASURES = {}

local function Add(profID, mapID, x, y, questID, name, notes)
    if not PKT.TREASURES[profID] then PKT.TREASURES[profID] = {} end
    table.insert(PKT.TREASURES[profID], { name=name, mapID=mapID, x=x, y=y, quest=questID, notes=notes })
end

local SC, EW, ZA, AT, HR, VS, SR = 2393, 2395, 2437, 2536, 2413, 2405, 2444

Add(2906, SC, 0.4780, 0.5160, 89117, "Pristine Potion", "Roof of Silvermoon Alchemy & Enchants building - fly up above the entrance doorway")
Add(2906, SC, 0.4910, 0.7560, 89115, "Freshly Plucked Peacebloom", "Inside a plant box at the flower vendor, SE of main hub")
Add(2906, SC, 0.4510, 0.4475, 89111, "Vial of Eversong Oddities", "The Shining Span, sitting on bench - may have phasing issues, try relogging")
Add(2906, ZA, 0.4040, 0.5120, 89114, "Vial of Zul'Aman Oddities", "At the end of a wooden cart, SW of Maisara Deeps")
Add(2906, AT, 0.4910, 0.2320, 89116, "Measured Ladle", "On table under small hut, NE area - phased, requires For Zul'Aman! achievement")
Add(2906, HR, 0.3475, 0.2470, 89113, "Vial of Rootlands Oddities", "On ground next to stairs inside main building - phased, requires Seeds of the Rift quest")
Add(2906, VS, 0.3280, 0.4330, 89118, "Failed Experiment", "Extremely small bottle on the ground - zoom in close to see it")
Add(2906, SR, 0.4180, 0.4050, 89112, "Vial of Voidstorm Oddities")

Add(2907, SC, 0.2690, 0.6030, 89177, "Deconstructed Forge Techniques", "On ground between two shelves near translocation orb, far west side of Dawning Lane")
Add(2907, SC, 0.4850, 0.7480, 89184, "Silvermoon Blacksmith's Hammer", "On the ground under a table, SE of the main hub")
Add(2907, SC, 0.4930, 0.6130, 89183, "Sin'dorei Master's Forgemace", "On a table inside the crest upgrade room near the blacksmith")
Add(2907, EW, 0.4830, 0.7570, 89178, "Silvermoon Smithing Kit", "On the ground beside a blood elf tent and fence")
Add(2907, EW, 0.5680, 0.4070, 89180, "Metalworking Cheat Sheet", "Between a bookshelf and table inside building near Farstrider Hold")
Add(2907, AT, 0.3320, 0.6580, 89179, "Carefully Racked Spear", "Attached to stone wall pillar inside temple - phased, requires For Zul'Aman! achievement")
Add(2907, HR, 0.6630, 0.5080, 89182, "Rutaani Floratender's Sword", "On top of giant mushroom east of the Den - fly up")
Add(2907, SR, 0.3060, 0.6890, 89181, "Voidstorm Defense Spear", "Inside Bastion of Might, through the right-hand door, under a table")

Add(2909, EW, 0.6075, 0.5300, 89103, "Everblazing Sunmote", "Just inside a makeshift tent on the river bank")
Add(2909, EW, 0.6349, 0.3259, 89107, "Sin'dorei Enchanting Rod", "At base of pillar on floating platform with Orb of Translocation - not at ground level")
Add(2909, EW, 0.4020, 0.6123, 89101, "Enchanted Sunfire Silk", "Under a table/barrel inside building - very small, looks like a stick on the floor")
Add(2909, ZA, 0.4040, 0.5120, 89106, "Loa-Blessed Dust", "On a wooden cart NE of Atal'Aman near Shrine of Kulzi")
Add(2909, AT, 0.4875, 0.2255, 89100, "Enchanted Amani Mask", "Hanging on post under hut - phased, complete Heart of the Amani quest first")
Add(2909, HR, 0.3775, 0.6520, 89104, "Entropic Shard", "On the ground surrounded by plants and rocks, north of Fungara Village")
Add(2909, HR, 0.6580, 0.5020, 89105, "Primal Essence Orb", "On top of large mushroom west of Har'athir - minimap icon not visible until at correct height")
Add(2909, VS, 0.3550, 0.5880, 89102, "Pure Void Crystal", "Between the tents")

Add(2910, SC, 0.5115, 0.5725, 89139, "What To Do When Nothing Works", "Upper balcony above Silvery Serenades bookshop in Murder Row")
Add(2910, SC, 0.5140, 0.7460, 89133, "One Engineer's Junk", "On the ground beside a table in the auction house room")
Add(2910, EW, 0.3955, 0.4580, 89135, "Manual of Mistakes and Mishaps", "On a table at ground level of a building at Sunsail Anchorage")
Add(2910, ZA, 0.3420, 0.8790, 89140, "Handy Wrench", "At the base of a small hill, SE of the Den of Nalorakk entrance")
Add(2910, AT, 0.6510, 0.3450, 89138, "Offline Helper Bot", "On a stone ledge in the warlord's stair area - phased, requires For Zul'Aman! achievement")
Add(2910, HR, 0.6790, 0.4980, 89136, "Expeditious Pylon", "On top of large mushroom NW of Har'athir - fly up")
Add(2910, SR, 0.2900, 0.3920, 89134, "Miniaturized Transport Skiff", "On the ground next to a void-themed brazier in the northern area")
Add(2910, SR, 0.5415, 0.5100, 89137, "Ethereal Stormwrench", "On the ground beside a crate in the Shenzar Refinery")

Add(2912, SC, 0.4902, 0.7593, 89160, "Simple Leaf Pruners", "On a table next to flower vendor, SE of main hub")
Add(2912, EW, 0.6425, 0.3046, 89158, "A Spade", "Stuck in the ground next to a flower path, east of Silvermoon City")
Add(2912, ZA, 0.4180, 0.4590, 89161, "Sweeping Harvester's Scythe", "Known bug: Harvester's Sickle (the Harandar treasure) sometimes spawns here instead - if missing, try relogging or toggling Warmode")
Add(2912, HR, 0.5111, 0.5571, 89155, "Planting Shovel", "Stuck in the ground on the left side outside the Inn, leaning against a tree near the mailbox")
Add(2912, HR, 0.7610, 0.5110, 89157, "Harvester's Sickle", "In Har'athir area")
Add(2912, HR, 0.3832, 0.6704, 89162, "Bloomed Bud", "Growing near rocks and foliage, SW of The Den")
Add(2912, HR, 0.3660, 0.2500, 89159, "Lightbloom Root", "At base of tree root, NW area - phased, requires completing Seeds of the Rift quest")
Add(2912, VS, 0.3460, 0.5700, 89156, "Peculiar Lotus", "On the ground near rocks and plant life on the west side of the zone")

Add(2913, SC, 0.4759, 0.5040, 89073, "Songwriter's Pen", "Floating next to crates above Inscription area - very tiny, move mouse slowly over top of crates")
Add(2913, EW, 0.4035, 0.6123, 89074, "Songwriter's Quill", "On a table inside the bottom level of building at Goldenmist Village")
Add(2913, EW, 0.3930, 0.4540, 89072, "Half-Baked Techniques", "On a desk at ground floor of tower near Sunsail Anchorage harbor")
Add(2913, EW, 0.4830, 0.7560, 89069, "Spare Ink", "Sitting on edge of a bench next to a tent")
Add(2913, ZA, 0.4048, 0.4935, 89068, "Leather-Bound Techniques", "In small cave near Shrine of Kulzi, next to 2 troll spirits - cave entrance at ~40.5, 50.0")
Add(2913, HR, 0.5240, 0.5260, 89070, "Intrepid Explorer's Marker", "On top of large root/tree trunk ~30 feet up - exit cave and backtrack, minimap icon appears late")
Add(2913, HR, 0.5270, 0.5000, 89071, "Leftover Sanguithorn Pigment", "On a bench under a trader's tent on the top side of The Den")
Add(2913, SR, 0.6070, 0.8410, 89067, "Void-Touched Quill", "On top of a desk in the right-side room inside Bastion of Valor")

Add(2914, SC, 0.2860, 0.4640, 89124, "Dual-Function Magnifiers", "In a small building under a table - reported as bugged and unlootable; check if fixed")
Add(2914, SC, 0.5060, 0.5650, 89122, "Sin'dorei Masterwork Chisel", "Under a table inside a store accessed via alleyway in Murder Row")
Add(2914, SC, 0.5550, 0.4800, 89127, "Vintage Soul Gem", "On a box at the end of an alleyway in Murder Row")
Add(2914, EW, 0.3970, 0.3880, 89129, "Sin'dorei Gem Faceters", "On a table under a small hut SW of Silvermoon City, near West Sanctum")
Add(2914, EW, 0.5670, 0.4090, 89125, "Poorly Rounded Vial", "On a table inside a library building near Farstrider Hold")
Add(2914, SR, 0.3060, 0.6900, 89123, "Speculative Voidstorm Crystal", "Under a bench in the far-right side room inside Bastion of Might")
Add(2914, SR, 0.5420, 0.5120, 89128, "Ethereal Gem Pliers", "On the ground next to a void plasma ball contraption in Shenzar Refinery")
Add(2914, SR, 0.6290, 0.5350, 89126, "Shattered Glass", "Shattered in small pieces on the path at the Sparring Grounds")

Add(2915, SC, 0.4480, 0.5620, 89096, "Artisan's Considered Order", "On crate on the left side under the Artisan's Consortium hub in The Bazaar")
Add(2915, ZA, 0.3075, 0.8400, 89091, "Prestigiously Racked Hide", "On right-hand side hallway just before entrance to the Den of Nalorakk dungeon")
Add(2915, ZA, 0.3310, 0.7890, 89089, "Amani Leatherworker's Tool", "At back of small cave near Torntusk Overlook - cave entrance at ~33.5, 78.8")
Add(2915, AT, 0.4520, 0.4530, 89092, "Bundle of Tanner's Trinkets", "Between two pillars at Altar of Malacrass - phased, requires completing Amani storyline")
Add(2915, HR, 0.3610, 0.2520, 89095, "Haranir Leatherworking Knife", "On the ground in front of a wild beast - may require Harandar story progression")
Add(2915, HR, 0.5170, 0.5131, 89094, "Haranir Leatherworking Mallet", "On a table next to trader's hut - phased, complete To Sow the Seed quest first")
Add(2915, VS, 0.3480, 0.5690, 89090, "Ethereal Leatherworking Knife", "Sitting next to rocks and mushrooms near The Ingress")
Add(2915, SR, 0.5380, 0.5160, 89093, "Pattern: Beyond The Void", "On the ground beside the main console inside Shenzar Refinery")

Add(2916, EW, 0.3800, 0.4530, 89147, "Solid Ore Punchers", "Hanging on a caravan near the docks at Sunsail Anchorage")
Add(2916, ZA, 0.4190, 0.4630, 89145, "Spelunker's Lucky Charm", "Sitting at end of a log down in small valley SW of Maisara Deeps - may require Amani campaign")
Add(2916, AT, 0.3360, 0.6600, 89149, "Amani Expert's Chisel", "On ground in temple structure - phased, complete Amani storyline first")
Add(2916, HR, 0.3880, 0.6590, 89151, "Spare Expedition Torch", "On the ground next to plant stalks, SW of The Den")
Add(2916, SR, 0.3420, 0.7600, 89150, "Star Metal Deposit", "Near base of ridge - reported as bugged and unlootable on multiple chars; check if fixed")
Add(2916, SR, 0.2873, 0.3856, 89148, "Glimmering Void Pearl", "On the ground beside pink plants in The Fangall area")
Add(2916, SR, 0.3000, 0.6900, 89144, "Miner's Guide to Voidstorm", "On ground next to desk and crates inside Bastion of Might - must enter the building")
Add(2916, SR, 0.5424, 0.5159, 89146, "Lost Voidstorm Satchel", "On ground next to a broken void vessel at the Shenzar Refinery entrance")

Add(2917, SC, 0.4320, 0.5570, 89171, "Sin'dorei Tanning Oil", "On floor between skinning and leatherworking trainers in The Bazaar")
Add(2917, EW, 0.4840, 0.7625, 89173, "Thalassian Skinning Knife", "On a table at Solaarian Sunbath, just south of Tranquillien")
Add(2917, ZA, 0.3305, 0.7905, 89172, "Amani Skinning Knife", "On the ground inside small cave - cave entrance at ~33.5, 78.8 near Torntusk Overlook")
Add(2917, ZA, 0.4040, 0.3600, 89170, "Amani Tanning Oil", "Inside a structure on a table in NW Zul'Aman - very small detection radius")
Add(2917, AT, 0.4500, 0.4470, 89167, "Cadre Skinning Knife", "On ground under hut near Altar of Malacrass - phased, requires For Zul'Aman! achievement")
Add(2917, HR, 0.6950, 0.4920, 89168, "Primal Hide", "Inside small cave between two tables at Har'athir - cave entrance at ~69.9, 50.3")
Add(2917, HR, 0.7600, 0.5100, 89166, "Lightbloom Afflicted Hide", "On the ground beside foliage and roots near the portal area")
Add(2917, SR, 0.4549, 0.4243, 89169, "Voidstorm Leather Sample", "Near trees, rocks, and an oozing lake in The Husk area")

Add(2918, SC, 0.3170, 0.6820, 89084, "Particularly Enchanting Tablecloth", "On the edge of a desk near a doorway in a small house in Gardens of Remembrance")
Add(2918, SC, 0.3580, 0.6120, 89079, "A Really Nice Curtain", "Hanging on second floor of Welcome Wares store near Thalassian University")
Add(2918, EW, 0.4630, 0.3480, 89080, "Sin'dorei Outfitter's Ruler", "Second level of building near North Sanctum - use Orb of Translocation ramp; phased, complete local tailor questline first")
Add(2918, ZA, 0.4040, 0.4940, 89085, "Artisan's Cover Comb", "On ground inside small cave NE of Atal'Aman near Shrine of Kulzi")
Add(2918, HR, 0.6980, 0.5100, 89081, "Wooden Weaving Sword", "On the ground at the base of a tree in Hara'thir")
Add(2918, HR, 0.7050, 0.5080, 89078, "A Child's Stuffy", "On the ground next to a bench inside a small home in Hara'thir")
Add(2918, SR, 0.6140, 0.8500, 89083, "Satin Throw Pillow", "On the ground next to a wooden crate in the back room of Bastion of Valor")
Add(2918, SR, 0.6200, 0.8350, 89082, "Book of Sin'dorei Stitches", "On the floor at main entrance of Bastion of Valor - PvP area, fly in quickly from south")

PKT.DMF_MAP_ID = 974

PKT.DMF_QUESTS = {
    [2906] = {
        vendor = "Sylannia", npcID = 14844,
        x = 0.4840, y = 0.4330, questID = 29506,
        provided = { "Cocktail Shaker (quest tool)" },
        needed = {
            { name = "Moonberry Juice",   itemID = 1645,  count = 5, tip = "Buy from any innkeeper or food vendor" },
            { name = "Fizzy Faire Drink", itemID = 19299, count = 5, tip = "Buy from Sylannia herself" },
        },
        steps = {
            "Accept the quest from Sylannia.",
            "Buy 5x Fizzy Faire Drink from Sylannia herself.",
            "Buy 5x Moonberry Juice from an innkeeper or food vendor.",
            "Use the Cocktail Shaker to mix drinks into 5x Moonberry Fizz.",
            "Turn in to Sylannia for +2 Knowledge.",
        },
    },
    [2907] = {
        vendor = "Yebb Neblegear", npcID = 14829,
        x = 0.5170, y = 0.5750, questID = 29508,
        provided = { "Iron Stock (quest tool)" },
        needed = {},
        steps = {
            "Accept the quest from Yebb Neblegear.",
            "Find an Anvil on the faire grounds.",
            "Use the Iron Stock at the Anvil to craft 4x Horseshoe.",
            "Find the Baby NPC and apply the horseshoes to it.",
            "Turn in to Yebb Neblegear for +2 Knowledge.",
        },
    },
    [2909] = {
        vendor = "Sayge", npcID = 14822,
        x = 0.4580, y = 0.4310, questID = 29510,
        provided = {},
        needed = {
            { name = "Discarded Weapon", itemID = 72018, count = 6, tip = "Pick up glowing items scattered on the faire grounds" },
        },
        steps = {
            "Accept the quest from Sayge.",
            "Collect 6x Discarded Weapon scattered around the faire grounds.",
            "Disenchant each weapon to produce Soothsayer's Dust.",
            "Turn in 6x Soothsayer's Dust to Sayge for +2 Knowledge.",
        },
    },
    [2910] = {
        vendor = "Rinling", npcID = 14841,
        x = 0.5590, y = 0.4710, questID = 29511,
        provided = { "Battered Wrench (quest tool)" },
        needed = {},
        steps = {
            "Accept the quest from Rinling.",
            "Use the Battered Wrench on 5x Damaged Tonk NPCs around the faire.",
            "Turn in to Rinling for +2 Knowledge.",
        },
    },
    [2912] = {
        vendor = "Chronos", npcID = 14833,
        x = 0.5170, y = 0.5110, questID = 29514,
        provided = {},
        needed = {
            { name = "Darkblossom", itemID = 72046, count = 6, tip = "Herb nodes on Darkmoon Island (or buy from AH)" },
        },
        steps = {
            "Accept the quest from Chronos.",
            "Gather 6x Darkblossom from herb nodes on Darkmoon Island.",
            "Turn in to Chronos for +2 Knowledge.",
        },
    },
    [2913] = {
        vendor = "Sayge", npcID = 14822,
        x = 0.4580, y = 0.4310, questID = 29515,
        provided = { "Bundle of Exotic Herbs", "5x Prophetic Ink" },
        needed = {
            { name = "Light Parchment", itemID = 39354, count = 5, tip = "Buy from any Inscription or trade goods vendor" },
        },
        steps = {
            "Accept the quest from Sayge.",
            "Buy 5x Light Parchment from a trade goods vendor.",
            "Use the Bundle of Exotic Herbs to create ink.",
            "Use Prophetic Ink + Light Parchment to make 5x Fortune.",
            "Turn in to Sayge for +2 Knowledge.",
        },
    },
    [2914] = {
        vendor = "Chronos", npcID = 14833,
        x = 0.5170, y = 0.5110, questID = 29516,
        provided = {},
        needed = {
            { name = "Bit of Glass", itemID = 72052, count = 5, tip = "Pick up glowing items scattered on the faire grounds" },
        },
        steps = {
            "Accept the quest from Chronos.",
            "Collect 5x Bit of Glass from around the faire grounds.",
            "Use Jewelcrafting to cut each into a Sparkling 'Gemstone'.",
            "Turn in 5x Sparkling 'Gemstone' to Chronos for +2 Knowledge.",
        },
    },
    [2915] = {
        vendor = "Rinling", npcID = 14841,
        x = 0.5590, y = 0.4710, questID = 29517,
        provided = { "Darkmoon Craftsman's Kit (quest tool)" },
        needed = {
            { name = "Shiny Bauble",  itemID = 6529, count = 10, tip = "Buy from fishing supply vendor or AH" },
            { name = "Coarse Thread", itemID = 2320, count = 5,  tip = "Buy from trade goods or tailoring vendor" },
            { name = "Blue Dye",      itemID = 6260, count = 5,  tip = "Buy from trade goods or tailoring vendor" },
        },
        steps = {
            "Accept the quest from Rinling.",
            "Bring 10x Shiny Bauble, 5x Coarse Thread, 5x Blue Dye.",
            "Use the Darkmoon Craftsman's Kit to craft 5x Darkmoon Prize.",
            "Turn in to Rinling for +2 Knowledge.",
        },
    },
    [2916] = {
        vendor = "Rinling", npcID = 14841,
        x = 0.5590, y = 0.4710, questID = 29518,
        provided = {},
        needed = {
            { name = "Tonk Scrap", itemID = 71968, count = 6, tip = "Pick up near the Tonk Command game area at the faire" },
        },
        steps = {
            "Accept the quest from Rinling.",
            "Collect 6x Tonk Scrap from around the Tonk Command game area.",
            "Turn in to Rinling for +2 Knowledge.",
        },
    },
    [2917] = {
        vendor = "Chronos", npcID = 14833,
        x = 0.5170, y = 0.5110, questID = 29519,
        provided = {},
        needed = {},
        steps = {
            "Accept the quest from Chronos.",
            "Find 4x Staked Skin interactive objects around the faire grounds.",
            "Right-click each Staked Skin to skin it.",
            "Turn in to Chronos for +2 Knowledge.",
        },
    },
    [2918] = {
        vendor = "Selina Dourman", npcID = 10445,
        x = 0.5210, y = 0.4250, questID = 29520,
        provided = { "Darkmoon Banner Kit (quest tool)" },
        needed = {
            { name = "Red Dye",       itemID = 2604, count = 1, tip = "Buy from trade goods or tailoring vendor" },
            { name = "Blue Dye",      itemID = 6260, count = 1, tip = "Buy from trade goods or tailoring vendor" },
            { name = "Coarse Thread", itemID = 2320, count = 1, tip = "Buy from trade goods or tailoring vendor" },
        },
        steps = {
            "Accept the quest from Selina Dourman.",
            "Buy 1x Red Dye, 1x Blue Dye, 1x Coarse Thread.",
            "Use the Darkmoon Banner Kit to create banners.",
            "Place banners at Loose Stones locations around the faire.",
            "Turn in to Selina Dourman for +2 Knowledge.",
        },
    },
}
