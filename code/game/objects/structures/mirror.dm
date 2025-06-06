//wip wip wup
/obj/structure/mirror
	name = "mirror"
	desc = "Mirror mirror on the wall, who's the most robust of them all?"
	icon = 'icons/obj/watercloset.dmi'
	icon_state = "mirror"
	plane = ABOVE_WALL_PLANE
	density = FALSE
	anchored = TRUE
	max_integrity = 200
	integrity_failure = 0.5

/obj/structure/mirror/directional/north //Pixel offsets get overwritten on New()
	dir = SOUTH
	pixel_y = 28

/obj/structure/mirror/directional/south
	dir = NORTH
	pixel_y = -28

/obj/structure/mirror/directional/east
	dir = WEST
	pixel_x = 28

/obj/structure/mirror/directional/west
	dir = EAST
	pixel_x = -28

/obj/structure/mirror/Initialize(mapload)
	. = ..()
	if(icon_state == "mirror_broke" && !broken)
		obj_break(null, mapload)

/obj/structure/mirror/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(broken || !Adjacent(user))
		return

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		//see code/modules/mob/dead/new_player/preferences.dm at approx line 545 for comments!
		//this is largely copypasted from there.

		//handle facial hair (if necessary)
		if(H.gender != FEMALE)
			var/new_style = tgui_input_list(user, "Select a facial hair style", "Grooming", GLOB.facial_hair_styles_list)
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return	//no tele-grooming
			if(new_style)
				H.facial_hair_style = new_style
		else
			H.facial_hair_style = "Shaved"

		//handle normal hair
		var/new_style = tgui_input_list(user, "Select a hair style", "Grooming", GLOB.hair_styles_list)
		if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
			return	//no tele-grooming
		if(new_style)
			H.hair_style = new_style

		H.update_mutant_bodyparts()
		H.update_hair()

/obj/structure/mirror/examine_status(mob/user)
	if(broken)
		return // no message spam
	..()

/obj/structure/mirror/attacked_by(obj/item/I, mob/living/user)
	if(broken || !istype(user) || !I.force)
		return ..()

	. = ..()
	if(broken) // breaking a mirror truly gets you bad luck!
		to_chat(user, "<span class='warning'>A chill runs down your spine as [src] shatters...</span>")
		user.AddComponent(/datum/component/omen, silent=TRUE) // we have our own message

/obj/structure/mirror/bullet_act(obj/item/projectile/P)
	if(broken || !isliving(P.firer) || !P.damage)
		return ..()

	. = ..()
	if(broken) // breaking a mirror truly gets you bad luck!
		var/mob/living/unlucky_dude = P.firer
		to_chat(unlucky_dude, "<span class='warning'>A chill runs down your spine as [src] shatters...</span>")
		unlucky_dude.AddComponent(/datum/component/omen, silent=TRUE) // we have our own message

/obj/structure/mirror/obj_break(damage_flag, mapload)
	if(broken || (flags_1 & NODECONSTRUCT_1))
		return
	icon_state = "mirror_broke"
	if(!mapload)
		playsound(src, "shatter", 70, TRUE)
	if(desc == initial(desc))
		desc = "Oh no, seven years of bad luck!"
	broken = TRUE

/obj/structure/mirror/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!disassembled)
			new /obj/item/shard( src.loc )
	qdel(src)

/obj/structure/mirror/welder_act(mob/living/user, obj/item/I)
	if(user.a_intent == INTENT_HARM)
		return FALSE

	if(!broken)
		return TRUE

	if(!I.tool_start_check(user, amount=0))
		return TRUE

	to_chat(user, "<span class='notice'>Вы начинаете чинить [src]...</span>")
	if(I.use_tool(src, user, 10, volume=50))
		to_chat(user, "<span class='notice'>Вы починили [src].</span>")
		broken = 0
		icon_state = initial(icon_state)
		desc = initial(desc)

	return TRUE

/obj/structure/mirror/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(src, 'sound/effects/hit_on_shattered_glass.ogg', 70, 1)
		if(BURN)
			playsound(src, 'sound/effects/hit_on_shattered_glass.ogg', 70, 1)


/obj/structure/mirror/magic
	name = "magic mirror"
	desc = "Turn and face the strange... face."
	icon_state = "magic_mirror"
	var/list/races_blacklist = list("skeleton", "agent", "military_synth", "memezombies", "clockwork golem servant", "android", "synth", "mush", "zombie", "memezombie")
	var/list/choosable_races = list()

/obj/structure/mirror/magic/Initialize(mapload)
	. = ..()
	if(!choosable_races.len)
		for(var/speciestype in subtypesof(/datum/species))
			var/datum/species/S = new speciestype()
			if(!(S.id in races_blacklist))
				choosable_races += S.id

/obj/structure/mirror/magic/lesser/Initialize(mapload)
	choosable_races = GLOB.roundstart_races.Copy()
	return ..()

/obj/structure/mirror/magic/badmin/Initialize(mapload)
	for(var/speciestype in subtypesof(/datum/species))
		var/datum/species/S = new speciestype()
		choosable_races += S.id
	return ..()

/obj/structure/mirror/magic/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	var/choice = tgui_input_list(user, "Something to change?", "Magical Grooming", list("name", "race", "gender", "hair", "eyes"))

	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return

	switch(choice)
		if("name")
			var/newname = reject_bad_name(stripped_input(H, "Who are we again?", "Name change", H.name, MAX_NAME_LEN))

			if(!newname)
				return
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			H.real_name = newname
			H.name = newname
			if(H.dna)
				H.dna.real_name = newname
			if(H.mind)
				H.mind.name = newname

		if("race")
			var/newrace
			var/racechoice = tgui_input_list(H, "What are we again?", "Race change", choosable_races)
			newrace = GLOB.species_list[racechoice]

			if(!newrace)
				return
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			H.set_species(newrace, icon_update=0)

			if(H.dna.species.use_skintones)
				var/list/choices = GLOB.skin_tones
				if(CONFIG_GET(flag/allow_custom_skintones))
					choices += "custom"
				var/new_s_tone = tgui_input_list(H, "Choose your skin tone:", "Race change", choices)
				if(new_s_tone)
					if(new_s_tone == "custom")
						var/default = H.dna.skin_tone_override || null
						var/custom_tone = input(user, "Choose your custom skin tone:", "Race change", default) as color|null
						if(custom_tone)
							var/temp_hsv = RGBtoHSV(new_s_tone)
							if(ReadHSV(temp_hsv)[3] >= ReadHSV(MINIMUM_MUTANT_COLOR)[3] || !CONFIG_GET(flag/character_color_limits)) //SPLURT edit
								to_chat(H,"<span class='danger'>Invalid color. Your color is not bright enough.</span>")
							else
								H.skin_tone = custom_tone
								H.dna.skin_tone_override = custom_tone
					else
						H.skin_tone = new_s_tone
						H.dna.update_ui_block(DNA_SKIN_TONE_BLOCK)

			if(MUTCOLORS in H.dna.species.species_traits)
				var/new_mutantcolor = input(user, "Choose your skin color:", "Race change","#"+H.dna.features["mcolor"]) as color|null
				if(new_mutantcolor)
					var/temp_hsv = RGBtoHSV(new_mutantcolor)

					if(ReadHSV(temp_hsv)[3] >= ReadHSV(MINIMUM_MUTANT_COLOR)[3] || !CONFIG_GET(flag/character_color_limits)) // mutantcolors must be bright //SPLURT edit
						H.dna.features["mcolor"] = sanitize_hexcolor(new_mutantcolor)

					else
						to_chat(H, "<span class='notice'>Invalid color. Your color is not bright enough.</span>")

			H.update_body()
			H.update_hair()
			H.update_body_parts()
			H.update_mutations_overlay() // no hulk lizard

		if("gender")
			if(!(H.gender in list("male", "female"))) //blame the patriarchy
				return
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			if(H.gender == "male")
				if(alert(H, "Become a Witch?", "Confirmation", "Yes", "No") == "Yes")
					H.gender = "female"
					to_chat(H, "<span class='notice'>Man, you feel like a woman!</span>")
				else
					return

			else
				if(alert(H, "Become a Warlock?", "Confirmation", "Yes", "No") == "Yes")
					H.gender = "male"
					to_chat(H, "<span class='notice'>Whoa man, you feel like a man!</span>")
				else
					return
			H.dna.update_ui_block(DNA_GENDER_BLOCK)
			H.update_body()
			H.update_mutations_overlay() //(hulk male/female)

		if("hair")
			var/hairchoice = alert(H, "Hair style or hair color?", "Change Hair", "Style", "Color")
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			if(hairchoice == "Style") //So you just want to use a mirror then?
				..()
			else
				var/new_hair_color = input(H, "Choose your hair color", "Hair Color","#"+H.hair_color) as color|null
				if(new_hair_color)
					H.hair_color = sanitize_hexcolor(new_hair_color)
					H.dna.update_ui_block(DNA_HAIR_COLOR_BLOCK)
				if(H.gender == "male")
					var/new_face_color = input(H, "Choose your facial hair color", "Hair Color","#"+H.facial_hair_color) as color|null
					if(new_face_color)
						H.facial_hair_color = sanitize_hexcolor(new_face_color)
						H.dna.update_ui_block(DNA_FACIAL_HAIR_COLOR_BLOCK)
				H.update_hair()

		if(BODY_ZONE_PRECISE_EYES)
			var/eye_type = tgui_input_list(H, "Choose the eye you want to color", "Eye Color", list("Both Eyes", "Left Eye", "Right Eye"))
			if(eye_type)
				var/input_color = H.left_eye_color
				if(eye_type == "Right Eye")
					input_color = H.right_eye_color
				var/new_eye_color = input(H, "Choose your eye color", "Eye Color","#"+input_color) as color|null
				if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
					return
				if(new_eye_color)
					var/n_color = sanitize_hexcolor(new_eye_color)
					var/obj/item/organ/eyes/eyes = H.getorganslot(ORGAN_SLOT_EYES)
					var/left_color = n_color
					var/right_color = n_color
					if(eye_type == "Left Eye")
						right_color = H.right_eye_color
					else
						if(eye_type == "Right Eye")
							left_color = H.left_eye_color
					if(eyes)
						eyes.left_eye_color = left_color
						eyes.right_eye_color = right_color
					H.left_eye_color = left_color
					H.right_eye_color = right_color
					H.dna.update_ui_block(DNA_LEFT_EYE_COLOR_BLOCK)
					H.dna.update_ui_block(DNA_RIGHT_EYE_COLOR_BLOCK)
					H.dna.species.handle_body()
	if(choice)
		curse(user)

/obj/structure/mirror/magic/proc/curse(mob/living/user)
	return
