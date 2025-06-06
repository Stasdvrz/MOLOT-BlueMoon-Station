/*
Mineral Sheets
	Contains:
		- Sandstone
		- Sandbags
		- Diamond
		- Uranium
		- Plasma
		- Gold
		- Silver
		- Clown
		- Titanium
		- Plastitanium
	Others:
		- Adamantine
		- Mythril
		- Snow
		- Abductor
		- Coal
*/

/*
 * Sandstone
 */

GLOBAL_LIST_INIT(sandstone_recipes, list ( \
	new/datum/stack_recipe("pile of dirt", /obj/machinery/hydroponics/soil, 3, time = 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("sandstone door", /obj/structure/mineral_door/sandstone, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("aesthetic volcanic floor tile", /obj/item/stack/tile/basalt, 2, 2, 4, 20), \
	new/datum/stack_recipe("Breakdown into sand", /obj/item/stack/ore/glass, 1, one_per_turf = 0, on_floor = 1) \
	))

/obj/item/stack/sheet/mineral/sandstone
	name = "sandstone brick"
	desc = "This appears to be a combination of both sand and stone."
	singular_name = "sandstone brick"
	icon_state = "sheet-sandstone"
	item_state = "sheet-sandstone"
	throw_speed = 3
	throw_range = 5
	custom_materials = list(/datum/material/sandstone=MINERAL_MATERIAL_AMOUNT)
	sheettype = "sandstone"
	merge_type = /obj/item/stack/sheet/mineral/sandstone
	walltype = /turf/closed/wall/mineral/sandstone
	material_type = /datum/material/sandstone

/obj/item/stack/sheet/mineral/sandstone/get_main_recipes()
	. = ..()
	. += GLOB.sandstone_recipes

/obj/item/stack/sheet/mineral/sandstone/thirty
	amount = 30

/obj/item/stack/sheet/mineral/sandstone/twelve
	amount = 12

/*
 * Sandbags
 */

/obj/item/stack/sheet/mineral/sandbags
	name = "sandbags"
	icon_state = "sandbags"
	singular_name = "sandbag"
	layer = LOW_ITEM_LAYER
	novariants = TRUE
	merge_type = /obj/item/stack/sheet/mineral/sandbags

GLOBAL_LIST_INIT(sandbag_recipes, list ( \
	new/datum/stack_recipe("sandbags", /obj/structure/barricade/sandbags, 1, time = 25, one_per_turf = 1, on_floor = 1), \
	))

/obj/item/stack/sheet/mineral/sandbags/get_main_recipes()
	. = ..()
	. += GLOB.sandbag_recipes

/obj/item/emptysandbag
	name = "empty sandbag"
	desc = "A bag to be filled with sand."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "sandbag"
	w_class = WEIGHT_CLASS_TINY

/obj/item/emptysandbag/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/ore/glass))
		var/obj/item/stack/ore/glass/G = W
		to_chat(user, "<span class='notice'>You fill the sandbag.</span>")
		var/obj/item/stack/sheet/mineral/sandbags/I = new /obj/item/stack/sheet/mineral/sandbags(drop_location())
		qdel(src)
		if (Adjacent(user) && !issilicon(user))
			user.put_in_hands(I)
		G.use(1)
	else
		return ..()

/*
 * Diamond
 */
/obj/item/stack/sheet/mineral/diamond
	name = "diamond"
	icon_state = "sheet-diamond"
	item_state = "sheet-diamond"
	singular_name = "diamond"
	sheettype = "diamond"
	custom_materials = list(/datum/material/diamond=MINERAL_MATERIAL_AMOUNT)
	novariants = TRUE
	grind_results = list(/datum/reagent/carbon = 20)
	point_value = 25
	merge_type = /obj/item/stack/sheet/mineral/diamond
	material_type = /datum/material/diamond
	walltype = /turf/closed/wall/mineral/diamond

GLOBAL_LIST_INIT(diamond_recipes, list ( \
	new/datum/stack_recipe("diamond door", /obj/structure/mineral_door/transparent/diamond, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("diamond tile", /obj/item/stack/tile/mineral/diamond, 1, 4, 20),  \
	new/datum/stack_recipe("diamond ingot", /obj/item/ingot/diamond, 6, time = 100), \
    ))

/obj/item/stack/sheet/mineral/diamond/get_main_recipes()
	. = ..()
	. += GLOB.diamond_recipes

/*
 * Uranium
 */
/obj/item/stack/sheet/mineral/uranium
	name = "uranium"
	icon_state = "sheet-uranium"
	item_state = "sheet-uranium"
	singular_name = "uranium sheet"
	sheettype = "uranium"
	custom_materials = list(/datum/material/uranium=MINERAL_MATERIAL_AMOUNT)
	novariants = TRUE
	grind_results = list(/datum/reagent/uranium = 20)
	point_value = 20
	merge_type = /obj/item/stack/sheet/mineral/uranium
	material_type = /datum/material/uranium
	walltype = /turf/closed/wall/mineral/uranium

GLOBAL_LIST_INIT(uranium_recipes, list ( \
	new/datum/stack_recipe("uranium door", /obj/structure/mineral_door/uranium, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("uranium tile", /obj/item/stack/tile/mineral/uranium, 1, 4, 20), \
	new/datum/stack_recipe("uranium ingot", /obj/item/ingot/uranium, 6, time = 100), \
	))

/obj/item/stack/sheet/mineral/uranium/get_main_recipes()
	. = ..()
	. += GLOB.uranium_recipes

/obj/item/stack/sheet/mineral/uranium/five
	amount = 5

/*
 * Plasma
 */
/obj/item/stack/sheet/mineral/plasma
	name = "solid plasma"
	icon_state = "sheet-plasma"
	item_state = "sheet-plasma"
	singular_name = "plasma sheet"
	sheettype = "plasma"
	resistance_flags = FLAMMABLE
	max_integrity = 100
	custom_materials = list(/datum/material/plasma=MINERAL_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/toxin/plasma = 20)
	point_value = 20
	merge_type = /obj/item/stack/sheet/mineral/plasma
	material_type = /datum/material/plasma
	walltype = /turf/closed/wall/mineral/plasma

/obj/item/stack/sheet/mineral/plasma/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins licking \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return TOXLOSS//dont you kids know that stuff is toxic?

GLOBAL_LIST_INIT(plasma_recipes, list ( \
	new/datum/stack_recipe("plasma door", /obj/structure/mineral_door/transparent/plasma, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("plasma tile", /obj/item/stack/tile/mineral/plasma, 1, 4, 20), \
	new/datum/stack_recipe("plasma plant", /obj/item/kirbyplants/plasma, 15, time = 50, on_floor = TRUE), \
//	new/datum/stack_recipe("plasma ingot", /obj/item/ingot/plasma, 6, time = 100), \ no
	))

/obj/item/stack/sheet/mineral/plasma/get_main_recipes()
	. = ..()
	. += GLOB.plasma_recipes

/obj/item/stack/sheet/mineral/plasma/attackby(obj/item/W as obj, mob/user as mob, params)
	if(W.get_temperature() > 300)//If the temperature of the object is over 300, then ignite
		var/turf/T = get_turf(src)
		message_admins("Plasma sheets ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_admin("Plasma sheets ignited by [key_name(user)] in [AREACOORD(T)]")
		fire_act(W.get_temperature())
	else
		return ..()

/obj/item/stack/sheet/mineral/plasma/fire_act(exposed_temperature, exposed_volume)
	atmos_spawn_air("plasma=[amount*10];TEMP=[exposed_temperature]")
	qdel(src)

/obj/item/stack/sheet/mineral/plasma/five
	amount = 5

/obj/item/stack/sheet/mineral/plasma/thirty
	amount = 30

/*
 * Gold
 */
/obj/item/stack/sheet/mineral/gold
	name = "gold"
	icon_state = "sheet-gold"
	item_state = "sheet-gold"
	singular_name = "gold bar"
	sheettype = "gold"
	custom_materials = list(/datum/material/gold=MINERAL_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/gold = 20)
	point_value = 20
	merge_type = /obj/item/stack/sheet/mineral/gold
	material_type = /datum/material/gold
	walltype = /turf/closed/wall/mineral/gold

GLOBAL_LIST_INIT(gold_recipes, list ( \
	new/datum/stack_recipe("golden door", /obj/structure/mineral_door/gold, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("gold tile", /obj/item/stack/tile/mineral/gold, 1, 4, 20), \
	new/datum/stack_recipe("Simple Crown", /obj/item/clothing/head/crown, 5), \
	new/datum/stack_recipe("gold ingot", /obj/item/ingot/gold, 6, time = 100), \
	))

/obj/item/stack/sheet/mineral/gold/get_main_recipes()
	. = ..()
	. += GLOB.gold_recipes

/*
 * Silver
 */
/obj/item/stack/sheet/mineral/silver
	name = "silver"
	icon_state = "sheet-silver"
	item_state = "sheet-silver"
	singular_name = "silver bar"
	sheettype = "silver"
	custom_materials = list(/datum/material/silver=MINERAL_MATERIAL_AMOUNT)
	grind_results = list(/datum/reagent/silver = 20)
	point_value = 20
	merge_type = /obj/item/stack/sheet/mineral/silver
	material_type = /datum/material/silver
	tableVariant = /obj/structure/table/optable
	walltype = /turf/closed/wall/mineral/silver

GLOBAL_LIST_INIT(silver_recipes, list ( \
	new/datum/stack_recipe("silver door", /obj/structure/mineral_door/silver, 10, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("silver tile", /obj/item/stack/tile/mineral/silver, 1, 4, 20), \
	new/datum/stack_recipe("silver ingot", /obj/item/ingot/silver, 6, time = 100), \
	))

/obj/item/stack/sheet/mineral/silver/get_main_recipes()
	. = ..()
	. += GLOB.silver_recipes

/*
 * Clown
 */
/obj/item/stack/sheet/mineral/bananium
	name = "bananium"
	icon_state = "sheet-bananium"
	item_state = "sheet-bananium"
	singular_name = "bananium sheet"
	sheettype = "bananium"
	custom_materials = list(/datum/material/bananium=MINERAL_MATERIAL_AMOUNT)
	novariants = TRUE
	grind_results = list(/datum/reagent/consumable/banana = 20)
	point_value = 50
	merge_type = /obj/item/stack/sheet/mineral/bananium
	material_type = /datum/material/bananium
	walltype = /turf/closed/wall/mineral/bananium

/obj/item/stack/sheet/mineral/bananium/fifty
	amount = 50

GLOBAL_LIST_INIT(bananium_recipes, list ( \
	new/datum/stack_recipe("bananium tile", /obj/item/stack/tile/mineral/bananium, 1, 4, 20), \
	new/datum/stack_recipe("hilarious ingot", /obj/item/ingot/bananium, 6, time = 100), \
	))

/obj/item/stack/sheet/mineral/bananium/get_main_recipes()
	. = ..()
	. += GLOB.bananium_recipes

/*
 * Titanium
 */
/obj/item/stack/sheet/mineral/titanium
	name = "titanium"
	icon_state = "sheet-titanium"
	item_state = "sheet-titanium"
	singular_name = "titanium sheet"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 1
	throw_range = 3
	sheettype = "titanium"
	custom_materials = list(/datum/material/titanium=MINERAL_MATERIAL_AMOUNT)
	point_value = 20
	merge_type = /obj/item/stack/sheet/mineral/titanium
	material_type = /datum/material/titanium
	walltype = /turf/closed/wall/mineral/titanium

GLOBAL_LIST_INIT(titanium_recipes, list ( \
	new/datum/stack_recipe("titanium tile", /obj/item/stack/tile/mineral/titanium, 1, 4, 20), \
	new/datum/stack_recipe("titanic ingot", /obj/item/ingot/titanium, 6, time = 100), \
	new/datum/stack_recipe("shuttle seat", /obj/structure/chair/comfy/shuttle, 2, one_per_turf = TRUE, on_floor = TRUE), \
	))

/obj/item/stack/sheet/mineral/titanium/get_main_recipes()
	. = ..()
	. += GLOB.titanium_recipes

/obj/item/stack/sheet/mineral/titanium/fifty
	amount = 50


/*
 * Plastitanium
 */
/obj/item/stack/sheet/mineral/plastitanium
	name = "plastitanium"
	icon_state = "sheet-plastitanium"
	item_state = "sheet-plastitanium"
	singular_name = "plastitanium sheet"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 1
	throw_range = 3
	sheettype = "plastitanium"
	custom_materials = list(/datum/material/titanium=MINERAL_MATERIAL_AMOUNT, /datum/material/plasma=MINERAL_MATERIAL_AMOUNT)
	point_value = 45
	merge_type = /obj/item/stack/sheet/mineral/plastitanium
	walltype = /turf/closed/wall/mineral/plastitanium

/obj/item/stack/sheet/mineral/plastitanium/fifty
	amount = 50

GLOBAL_LIST_INIT(plastitanium_recipes, list ( \
	new/datum/stack_recipe("plastitanium tile", /obj/item/stack/tile/mineral/plastitanium, 1, 4, 20), \
	))

/obj/item/stack/sheet/mineral/plastitanium/get_main_recipes()
	. = ..()
	. += GLOB.plastitanium_recipes

/****************************** Others ****************************/

/*
 * Adamantine
 */
GLOBAL_LIST_INIT(adamantine_recipes, list(
	new /datum/stack_recipe("incomplete servant golem shell", /obj/item/golem_shell/servant, req_amount=1, res_amount=1),
	new/datum/stack_recipe("adamant ingot", /obj/item/ingot/adamantine, 6, time = 100), \
	))

/obj/item/stack/sheet/mineral/adamantine
	name = "adamantine"
	icon_state = "sheet-adamantine"
	item_state = "sheet-adamantine"
	singular_name = "adamantine sheet"
	custom_materials = list(/datum/material/adamantine=MINERAL_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/adamantine

/obj/item/stack/sheet/mineral/adamantine/get_main_recipes()
	. = ..()
	. += GLOB.adamantine_recipes

/*
 * Runite
 */

/obj/item/stack/sheet/mineral/runite
	name = "Runite"
	desc = "Rare material found in distant lands."
	singular_name = "runite bar"
	icon_state = "sheet-runite"
	item_state = "sheet-runite"
	custom_materials = list(/datum/material/runite=MINERAL_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/runite
	material_type = /datum/material/runite

/*
 * Mythril
 */
/obj/item/stack/sheet/mineral/mythril
	name = "mythril"
	icon_state = "sheet-mythril"
	item_state = "sheet-mythril"
	singular_name = "mythril sheet"
	novariants = TRUE
	custom_materials = list(/datum/material/mythril=MINERAL_MATERIAL_AMOUNT)
	merge_type = /obj/item/stack/sheet/mineral/mythril

/*
 * Snow
 */
/obj/item/stack/sheet/mineral/snow
	name = "snow"
	icon_state = "sheet-snow"
	item_state = "sheet-snow"
	custom_materials = list(/datum/material/snow = MINERAL_MATERIAL_AMOUNT)
	singular_name = "snow block"
	force = 1
	throwforce = 2
	grind_results = list(/datum/reagent/consumable/ice = 20)
	merge_type = /obj/item/stack/sheet/mineral/snow
	walltype = /turf/closed/wall/mineral/snow
	material_type = /datum/material/snow

GLOBAL_LIST_INIT(snow_recipes, list ( \
	new/datum/stack_recipe("Snow Wall", /turf/closed/wall/mineral/snow, 5, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("snow barricade", /obj/structure/deployable_barricade/snow, 2, one_per_turf = TRUE, on_floor = TRUE), \
	new/datum/stack_recipe("Snowman", /obj/structure/statue/snow/snowman, 5, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("Snowball", /obj/item/toy/snowball, 1), \
	))

/obj/item/stack/sheet/mineral/snow/get_main_recipes()
	. = ..()
	. += GLOB.snow_recipes

/*
 * Alien Alloy
 */
/obj/item/stack/sheet/mineral/abductor
	name = "alien alloy"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "sheet-abductor"
	item_state = "sheet-abductor"
	singular_name = "alien alloy sheet"
	sheettype = "abductor"
	merge_type = /obj/item/stack/sheet/mineral/abductor
	walltype = /turf/closed/wall/mineral/abductor

/obj/item/stack/sheet/mineral/abductor/fifty
	amount = 50

GLOBAL_LIST_INIT(abductor_recipes, list ( \
	new/datum/stack_recipe("alien bed", /obj/structure/bed/abductor, 2, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("alien locker", /obj/structure/closet/abductor, 2, time = 15, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("alien table frame", /obj/structure/table_frame/abductor, 1, time = 15, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("alien bar stool", /obj/item/chair/stool/bar/alien, 1, time = 20, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("alien stool", /obj/item/chair/stool/alien, 1, time = 20, one_per_turf = 1, on_floor = 1), \
	new/datum/stack_recipe("alien airlock assembly", /obj/structure/door_assembly/door_assembly_abductor, 4, time = 20, one_per_turf = 1, on_floor = 1), \
	null, \
	new/datum/stack_recipe("alien floor tile", /obj/item/stack/tile/mineral/abductor, 1, 4, 20), \
	))

/obj/item/stack/sheet/mineral/abductor/get_main_recipes()
	. = ..()
	. += GLOB.abductor_recipes

/*
 * Coal
 */

/obj/item/stack/sheet/mineral/coal
	name = "coal"
	desc = "Someone's gotten on the naughty list."
	icon = 'icons/obj/mining.dmi'
	icon_state = "slag"
	singular_name = "coal lump"
	merge_type = /obj/item/stack/sheet/mineral/coal
	grind_results = list(/datum/reagent/carbon = 20)

/obj/item/stack/sheet/mineral/coal/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300)//If the temperature of the object is over 300, then ignite
		var/turf/T = get_turf(src)
		message_admins("Coal ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
		log_game("Coal ignited by [key_name(user)] in [AREACOORD(T)]")
		fire_act(W.get_temperature())
		return TRUE
	else
		return ..()

/obj/item/stack/sheet/mineral/coal/fire_act(exposed_temperature, exposed_volume)
	atmos_spawn_air("co2=[amount*10];TEMP=[exposed_temperature]")
	qdel(src)

/obj/item/stack/sheet/mineral/coal/five
	amount = 5

/obj/item/stack/sheet/mineral/coal/ten
	amount = 10
