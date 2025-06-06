#define LING_FAKEDEATH_TIME					400 //40 seconds
#define LING_DEAD_GENETICDAMAGE_HEAL_CAP	50	//The lowest value of geneticdamage handle_changeling() can take it to while dead.
#define LING_ABSORB_RECENT_SPEECH			8	//The amount of recent spoken lines to gain on absorbing a mob

/// Helper to format the text that gets thrown onto the chem hud element.
#define FORMAT_CHEM_CHARGES_TEXT(charges) MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#dd66dd'>[round(charges)]</font></div>")

/datum/antagonist/changeling
	name = "Changeling"
	roundend_category  = "changelings"
	antagpanel_category = "Changeling"
	job_rank = ROLE_CHANGELING
	antag_moodlet = /datum/mood_event/focused
	threat = 10
	var/you_are_greet = TRUE
	var/give_objectives = TRUE
	var/team_mode = FALSE //Should assign team objectives ?

	//Changeling Stuff

	var/list/stored_profiles = list() //list of datum/changelingprofile
	var/datum/changelingprofile/first_prof = null
	var/absorbedcount = 0
	/// did we get succed by another changeling
	var/hostile_absorbed = FALSE
	var/trueabsorbs = 0//dna gained using absorb, not dna sting
	var/chem_charges = 20
	var/chem_storage = 75
	var/chem_recharge_rate = 1
	var/chem_recharge_slowdown = 0
	var/sting_range = 2
	var/changelingID = "Changeling"
	var/geneticdamage = 0
	var/isabsorbing = 0
	var/islinking = 0
	var/geneticpoints = 10
	var/maxgeneticpoints = 10
	var/purchasedpowers = list()

	var/mimicing = ""
	var/can_respec = FALSE//set to TRUE in absorb.dm
	var/changeling_speak = 0
	var/loudfactor = 0 //Used for blood tests. This is is the average loudness of the ling's abilities calculated with the below two vars
	var/loudtotal = 0 //Used to keep track of the sum of the ling's loudness
	var/totalpurchases = 0 //Used to keep track of how many purchases the ling's made after free abilities have been added
	var/datum/dna/chosen_dna
	var/datum/action/changeling/sting/chosen_sting
	var/datum/cellular_emporium/cellular_emporium
	var/datum/action/innate/cellular_emporium/emporium_action

	var/static/list/all_powers = typecacheof(/datum/action/changeling,TRUE)

	reminded_times_left = 2 // BLUEMOON ADD

/datum/antagonist/changeling/Destroy()
	QDEL_NULL(cellular_emporium)
	QDEL_NULL(emporium_action)
	. = ..()

/datum/antagonist/changeling/proc/generate_name()
	var/honorific
	if(owner.current.gender == FEMALE)
		honorific = "Ms."
	else if(owner.current.gender == MALE)
		honorific = "Mr."
	else
		honorific = "Mx."
	if(GLOB.possible_changeling_IDs.len)
		changelingID = pick(GLOB.possible_changeling_IDs)
		GLOB.possible_changeling_IDs -= changelingID
		changelingID = "[honorific] [changelingID]"
	else
		changelingID = "[honorific] [rand(1,999)]"

/datum/antagonist/changeling/proc/create_actions()
	cellular_emporium = new(src)
	emporium_action = new(cellular_emporium)
	emporium_action.Grant(owner.current)

/datum/antagonist/changeling/on_gain()
	generate_name()
	create_actions()
	reset_powers()
	create_initial_profile()
	if(give_objectives)
		forge_objectives()
	owner.current.get_language_holder().omnitongue = TRUE
	remove_clownmut()
	. = ..()

/datum/antagonist/changeling/on_removal()
	//We'll be using this from now on
	var/mob/living/carbon/C = owner.current
	if(istype(C))
		var/obj/item/organ/brain/B = C.getorganslot(ORGAN_SLOT_BRAIN)
		if(B && (B.decoy_override != initial(B.decoy_override)))
			B.organ_flags |= ORGAN_VITAL
			B.decoy_override = FALSE
	remove_changeling_powers()
	owner.special_role = null
	owner.current.hud_used?.lingchemdisplay?.invisibility = INVISIBILITY_ABSTRACT
	. = ..()

/datum/antagonist/changeling/proc/remove_clownmut()
	if (owner)
		var/mob/living/carbon/human/H = owner.current
		if(istype(H) && owner.assigned_role == "Clown")
			to_chat(H, "You have evolved beyond your clownish nature, allowing you to wield weapons without harming yourself.")
			H.dna.remove_mutation(CLOWNMUT)

/datum/antagonist/changeling/proc/reset_properties(hardReset = FALSE)
	changeling_speak = 0
	chosen_sting = null

	geneticpoints = maxgeneticpoints
	sting_range = initial(sting_range)
	chem_recharge_slowdown = initial(chem_recharge_slowdown)
	mimicing = ""

	if (hardReset)
		chem_storage = initial(chem_storage)
		chem_recharge_rate = initial(chem_recharge_rate)
		geneticpoints = initial(geneticpoints)
		maxgeneticpoints = initial(maxgeneticpoints)

	chem_charges = min(chem_charges, chem_storage)


/datum/antagonist/changeling/proc/remove_changeling_powers()
	if(ishuman(owner.current) || ismonkey(owner.current))
		reset_properties()
		QDEL_NULL(cellular_emporium)
		QDEL_NULL(emporium_action)
		for(var/datum/action/changeling/p in purchasedpowers)
			purchasedpowers -= p
			p.Remove(owner.current)

	//MOVE THIS
	if(owner.current.hud_used)
		owner.current.hud_used.lingstingdisplay.icon_state = null
		owner.current.hud_used.lingstingdisplay.invisibility = INVISIBILITY_ABSTRACT

/datum/antagonist/changeling/proc/reset_powers()
	if(purchasedpowers)
		remove_changeling_powers()
	create_actions()
	//Repurchase free powers.
	for(var/path in all_powers)
		var/datum/action/changeling/S = new path()
		if(!S.dna_cost)
			if(!has_sting(S))
				purchasedpowers += S
				S.on_purchase(owner.current,TRUE)
	loudfactor = 0
	loudtotal = 0
	totalpurchases = 0

/datum/antagonist/changeling/proc/regain_powers()//for when action buttons are lost and need to be regained, such as when the mind enters a new mob
	emporium_action.Grant(owner.current)
	for(var/power in purchasedpowers)
		var/datum/action/changeling/S = power
		if(istype(S) && S.needs_button)
			S.Grant(owner.current)

/datum/antagonist/changeling/proc/has_sting(datum/action/changeling/power)
	for(var/P in purchasedpowers)
		var/datum/action/changeling/otherpower = P
		if(initial(power.name) == otherpower.name)
			return TRUE
	return FALSE


/datum/antagonist/changeling/proc/purchase_power(sting_name)
	var/datum/action/changeling/thepower

	for(var/path in all_powers)
		var/datum/action/changeling/S = path
		if(initial(S.name) == sting_name)
			thepower = new path
			break

	if(!thepower)
		to_chat(owner.current, "This is awkward. Changeling power purchase failed, please report this bug to a coder!")
		return

	if(absorbedcount < thepower.req_dna)
		to_chat(owner.current, "We lack the energy to evolve this ability!")
		return

	if(has_sting(thepower))
		to_chat(owner.current, "We have already evolved this ability!")
		return

	if(thepower.dna_cost < 0)
		to_chat(owner.current, "We cannot evolve this ability.")
		return

	if(geneticpoints < thepower.dna_cost)
		to_chat(owner.current, "We have reached our capacity for abilities.")
		return

	if(HAS_TRAIT(owner.current, TRAIT_DEATHCOMA))//To avoid potential exploits by buying new powers while in stasis, which clears your verblist.
		to_chat(owner.current, "We lack the energy to evolve new abilities right now.")
		return

	geneticpoints -= thepower.dna_cost
	purchasedpowers += thepower
	thepower.on_purchase(owner.current)//Grant() is ran in this proc, see changeling_powers.dm
	loudtotal += thepower.loudness
	totalpurchases++
	var/oldloudness = loudfactor
	loudfactor = loudtotal/max(totalpurchases,1)
	if(loudfactor >= LINGBLOOD_DETECTION_THRESHOLD && oldloudness < LINGBLOOD_DETECTION_THRESHOLD)
		to_chat(owner.current, "<span class='warning'>Our blood has grown flammable. Our blood will now react violently to heat.</span>")
	else if(loudfactor < LINGBLOOD_DETECTION_THRESHOLD && oldloudness >= LINGBLOOD_DETECTION_THRESHOLD)
		to_chat(owner.current, "<span class='notice'>Our blood has stabilized, and will no longer react violently to heat.</span>")
	if(loudfactor > LINGBLOOD_EXPLOSION_THRESHOLD && oldloudness <= LINGBLOOD_EXPLOSION_THRESHOLD)
		to_chat(owner.current, "<span class='warning'>Our blood has grown extremely flammable. Our blood will now react explosively to heat.</span>")
	else if(loudfactor <= LINGBLOOD_EXPLOSION_THRESHOLD && oldloudness > LINGBLOOD_EXPLOSION_THRESHOLD)
		to_chat(owner.current, "<span class='notice'>Our blood has slightly stabilized, and will no longer explode when exposed to heat.</span>")

/datum/antagonist/changeling/proc/readapt()
	if(!ishuman(owner.current))
		to_chat(owner.current, "<span class='danger'>We can't remove our evolutions in this form!</span>")
		return
	if(can_respec)
		to_chat(owner.current, "<span class='notice'>We have removed our evolutions from this form, and are now ready to readapt.</span>")
		reset_powers()
		playsound(get_turf(owner.current), 'sound/effects/lingreadapt.ogg', 75, TRUE, 5)
		can_respec = 0
		SSblackbox.record_feedback("tally", "changeling_power_purchase", 1, "Readapt")
		return TRUE
	else
		to_chat(owner.current, "<span class='danger'>You lack the power to readapt your evolutions!</span>")
		return FALSE

//Called in life()
/datum/antagonist/changeling/proc/regenerate()//grants the HuD in life.dm
	var/mob/living/carbon/the_ling = owner.current
	if(istype(the_ling))
		if(the_ling.stat == DEAD)
			chem_charges = min(max(0, chem_charges + chem_recharge_rate - chem_recharge_slowdown), (chem_storage*0.5))
			geneticdamage = max(LING_DEAD_GENETICDAMAGE_HEAL_CAP,geneticdamage-1)
		else //not dead? no chem/geneticdamage caps.
			chem_charges = min(max(0, chem_charges + chem_recharge_rate - chem_recharge_slowdown), chem_storage)
			geneticdamage = max(0, geneticdamage-1)
		owner.current.hud_used?.lingchemdisplay?.invisibility = 0
		owner.current.hud_used?.lingchemdisplay?.maptext = FORMAT_CHEM_CHARGES_TEXT(chem_charges)


/datum/antagonist/changeling/proc/get_dna(dna_owner)
	for(var/datum/changelingprofile/prof in stored_profiles)
		if(dna_owner == prof.name)
			return prof

/datum/antagonist/changeling/proc/has_dna(datum/dna/tDNA)
	for(var/datum/changelingprofile/prof in stored_profiles)
		if(tDNA.is_same_as(prof.dna))
			return TRUE
	return FALSE

/datum/antagonist/changeling/proc/can_absorb_dna(mob/living/carbon/human/target, var/verbose=1)
	var/mob/living/carbon/user = owner.current
	if(!istype(user))
		return
	if(!target)
		return
	if(NO_DNA_COPY in target.dna.species.species_traits)
		if(verbose)
			to_chat(user, "<span class='warning'>[target] is not compatible with our biology.</span>")
		return
	if((HAS_TRAIT(target, TRAIT_NOCLONE)) || (HAS_TRAIT(target, TRAIT_NOCLONE)))
		if(verbose)
			to_chat(user, "<span class='warning'>DNA of [target] is ruined beyond usability!</span>")
		return
	if(!ishuman(target))//Absorbing monkeys is entirely possible, but it can cause issues with transforming. That's what lesser form is for anyway!
		if(verbose)
			to_chat(user, "<span class='warning'>We could gain no benefit from absorbing a lesser creature.</span>")
		return
	if(has_dna(target.dna))
		if(verbose)
			to_chat(user, "<span class='warning'>We already have this DNA in storage!</span>")
		return
	if(!target.has_dna() || HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD - генокрад не может поглощать ДНКа синтетиков
		if(verbose)
			to_chat(user, "<span class='warning'>[target] is not compatible with our biology.</span>")
		return
	return TRUE


/datum/antagonist/changeling/proc/create_profile(mob/living/carbon/human/H, protect = 0)
	var/datum/changelingprofile/prof = new

	H.dna.real_name = H.real_name //Set this again, just to be sure that it's properly set.
	var/datum/dna/new_dna = new H.dna.type
	H.dna.copy_dna(new_dna)
	prof.dna = new_dna
	prof.name = H.real_name
	prof.protected = protect

	prof.underwear = H.underwear
	prof.undie_color = H.undie_color
	prof.undershirt = H.undershirt
	prof.shirt_color = H.shirt_color
	prof.socks = H.socks
	prof.socks_color = H.socks_color

	var/datum/icon_snapshot/entry = new
	entry.name = H.name
	entry.icon = H.icon
	entry.icon_state = H.icon_state
	entry.overlays = H.get_overlays_copy(list(HANDS_LAYER, HANDCUFF_LAYER, LEGCUFF_LAYER))
	prof.profile_snapshot = entry

	for(var/slot in GLOB.slots)
		if(slot in H.vars)
			var/obj/item/I = H.vars[slot]
			if(!I)
				continue
			prof.name_list[slot] = I.name
			prof.appearance_list[slot] = I.appearance
			prof.flags_cover_list[slot] = I.flags_cover
			prof.item_state_list[slot] = I.item_state
			prof.exists_list[slot] = 1
		else
			continue

	return prof

/datum/antagonist/changeling/proc/add_profile(datum/changelingprofile/prof)

	if(!first_prof)
		first_prof = prof

	stored_profiles += prof
	absorbedcount++

/datum/antagonist/changeling/proc/add_new_profile(mob/living/carbon/human/H, protect = 0)
	var/datum/changelingprofile/prof = create_profile(H, protect)
	add_profile(prof)
	return prof

/datum/antagonist/changeling/proc/remove_profile(mob/living/carbon/human/H, force = 0)
	for(var/datum/changelingprofile/prof in stored_profiles)
		if(H.real_name == prof.name)
			if(prof.protected && !force)
				continue
			stored_profiles -= prof
			qdel(prof)

/datum/antagonist/changeling/proc/create_initial_profile()
	var/mob/living/carbon/C = owner.current	//only carbons have dna now, so we have to typecaste
	if(ishuman(C))
		add_new_profile(C)

/datum/antagonist/changeling/apply_innate_effects()
	//Brains optional.
	var/mob/living/carbon/C = owner.current
	if(istype(C))
		var/obj/item/organ/brain/B = C.getorganslot(ORGAN_SLOT_BRAIN)
		if(B)
			B.organ_flags &= ~ORGAN_VITAL
			B.decoy_override = TRUE
	update_changeling_icons_added()
	RegisterSignal(owner.current,COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(regenerate))
	return

/datum/antagonist/changeling/remove_innate_effects()
	update_changeling_icons_removed()
	UnregisterSignal(owner.current,COMSIG_LIVING_BIOLOGICAL_LIFE)
	return


/datum/antagonist/changeling/greet()
	if (you_are_greet)
		to_chat(owner.current, "<span class='boldannounce'>You are [changelingID], a changeling! You have absorbed and taken the form of a human.</span>")
	to_chat(owner.current, "<span class='boldannounce'>Use say \"[MODE_TOKEN_CHANGELING] message\" to communicate with your fellow changelings.</span>")
	to_chat(owner.current, "<b>You must complete the following tasks:</b>")
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/ling_aler.ogg', 100, FALSE, pressure_affected = FALSE)

	owner.announce_objectives()

/datum/antagonist/changeling/farewell()
	to_chat(owner.current, "<span class='userdanger'>You grow weak and lose your powers! You are no longer a changeling and are stuck in your current form!</span>")

/datum/antagonist/changeling/proc/forge_team_objectives()
	if(GLOB.changeling_team_objective_type)
		var/datum/objective/changeling_team_objective/team_objective = new GLOB.changeling_team_objective_type
		team_objective.owner = owner
		if(team_objective.prepare())//Setting up succeeded
			objectives += team_objective
		else
			qdel(team_objective)
	return

/datum/antagonist/changeling/proc/forge_objectives()
	//OBJECTIVES - random traitor objectives. Unique objectives "steal brain" and "identity theft".
	//No escape alone because changelings aren't suited for it and it'd probably just lead to rampant robusting
	//If it seems like they'd be able to do it in play, add a 10% chance to have to escape alone

	var/escape_objective_possible = TRUE

	//if there's a team objective, check if it's compatible with escape objectives
	for(var/datum/objective/changeling_team_objective/CTO in objectives)
		if(!CTO.escape_objective_compatible)
			escape_objective_possible = FALSE
			break
	var/changeling_objective = rand(1,3)
	var/generic_absorb_objective = FALSE
	var/multiple_lings = length(get_antag_minds(/datum/antagonist/changeling,TRUE)) > 1
	switch(changeling_objective)
		if(1)
			generic_absorb_objective = TRUE
		if(2)
			if(multiple_lings)
				var/datum/objective/absorb_changeling/ac = new
				ac.owner = owner
				objectives += ac
			else
				generic_absorb_objective = TRUE
		if(3)
			if(multiple_lings)
				var/datum/objective/absorb_most/ac = new
				ac.owner = owner
				objectives += ac
			else
				generic_absorb_objective = TRUE

	if(generic_absorb_objective)
		var/datum/objective/absorb/absorb_objective = new
		absorb_objective.owner = owner
		absorb_objective.gen_amount_goal(6, 8)
		objectives += absorb_objective

	if(prob(60))
		if(prob(85))
			var/datum/objective/steal/steal_objective = new
			steal_objective.owner = owner
			steal_objective.find_target()
			objectives += steal_objective
		else
			var/datum/objective/download/download_objective = new
			download_objective.owner = owner
			download_objective.gen_amount_goal()
			objectives += download_objective

	var/list/active_ais = active_ais()
	if(active_ais.len && prob(100/GLOB.joined_player_list.len))
		var/datum/objective/destroy/destroy_objective = new
		destroy_objective.owner = owner
		destroy_objective.find_target()
		objectives += destroy_objective
	else
		var/datum/objective/assassinate/once/kill_objective = new
		kill_objective.owner = owner
		if(team_mode) //No backstabbing while in a team
			kill_objective.find_target_by_role(role = ROLE_CHANGELING, role_type = 1, invert = 1)
		else
			kill_objective.find_target()
		objectives += kill_objective

		if(!(locate(/datum/objective/escape) in objectives) && escape_objective_possible && prob(50))
			var/datum/objective/escape/escape_with_identity/identity_theft = new
			identity_theft.owner = owner
			identity_theft.target = kill_objective.target
			identity_theft.update_explanation_text()
			objectives += identity_theft
			escape_objective_possible = FALSE

	if (!(locate(/datum/objective/escape) in objectives) && escape_objective_possible)
		if(prob(50))
			var/datum/objective/escape/escape_objective = new
			escape_objective.owner = owner
			objectives += escape_objective
		else
			var/datum/objective/escape/escape_with_identity/identity_theft = new
			identity_theft.owner = owner
			if(team_mode)
				identity_theft.find_target_by_role(role = ROLE_CHANGELING, role_type = 1, invert = 1)
			else
				identity_theft.find_target()
			objectives += identity_theft
		escape_objective_possible = FALSE

/datum/antagonist/changeling/proc/update_changeling_icons_added()
	var/datum/atom_hud/antag/hud = GLOB.huds[ANTAG_HUD_CHANGELING]
	hud.join_hud(owner.current)
	set_antag_hud(owner.current, "changeling")

/datum/antagonist/changeling/proc/update_changeling_icons_removed()
	var/datum/atom_hud/antag/hud = GLOB.huds[ANTAG_HUD_CHANGELING]
	hud.leave_hud(owner.current)
	set_antag_hud(owner.current, null)

/datum/antagonist/changeling/admin_add(datum/mind/new_owner,mob/admin)
	. = ..()
	to_chat(new_owner.current, "<span class='boldannounce'>Our powers have awoken. A flash of memory returns to us...we are [changelingID], a changeling!</span>")

/datum/antagonist/changeling/get_admin_commands()
	. = ..()
	if(stored_profiles.len && (owner.current.real_name != first_prof.name))
		.["Transform to initial appearance."] = CALLBACK(src,PROC_REF(admin_restore_appearance))

/datum/antagonist/changeling/proc/admin_restore_appearance(mob/admin)
	if(!stored_profiles.len || !iscarbon(owner.current))
		to_chat(admin, "<span class='danger'>Resetting DNA failed!</span>")
	else
		var/mob/living/carbon/C = owner.current
		first_prof.dna.transfer_identity(C, transfer_SE=1)
		C.real_name = first_prof.name
		C.updateappearance(mutcolor_update=1)
		C.domutcheck()

// Profile

/datum/changelingprofile
	var/name = "a bug"

	var/protected = 0

	var/datum/dna/dna = null
	var/list/name_list = list() //associative list of slotname = itemname
	var/list/appearance_list = list()
	var/list/flags_cover_list = list()
	var/list/exists_list = list()
	var/list/item_state_list = list()

	var/underwear
	var/undie_color
	var/undershirt
	var/shirt_color
	var/socks
	var/socks_color

	/// Icon snapshot of the profile
	var/datum/icon_snapshot/profile_snapshot

/datum/changelingprofile/Destroy()
	qdel(dna)
	. = ..()

/datum/changelingprofile/proc/copy_profile(datum/changelingprofile/newprofile)
	newprofile.name = name
	newprofile.protected = protected
	newprofile.dna = new dna.type
	dna.copy_dna(newprofile.dna)
	newprofile.name_list = name_list.Copy()
	newprofile.appearance_list = appearance_list.Copy()
	newprofile.flags_cover_list = flags_cover_list.Copy()
	newprofile.exists_list = exists_list.Copy()
	newprofile.item_state_list = item_state_list.Copy()
	newprofile.underwear = underwear
	newprofile.undershirt = undershirt
	newprofile.socks = socks
	newprofile.profile_snapshot = profile_snapshot

/datum/antagonist/changeling/xenobio
	name = "Xenobio Changeling"
	give_objectives = FALSE
	show_in_roundend = FALSE //These are here for admin tracking purposes only
	you_are_greet = FALSE
	antag_moodlet = FALSE

/datum/antagonist/changeling/roundend_report()
	var/list/parts = list()

	var/changelingwin = 1
	if(!owner.current)
		changelingwin = 0

	parts += printplayer(owner)

	//Removed sanity if(changeling) because we -want- a runtime to inform us that the changelings list is incorrect and needs to be fixed.
	parts += "<b>Changeling ID:</b> [changelingID]."
	parts += "<b>Genomes Extracted:</b> [absorbedcount]"
	parts += " "
	if(objectives.len)
		var/count = 1
		for(var/datum/objective/objective in objectives)
			if(objective.completable)
				var/completion = objective.check_completion()
				if(completion >= 1)
					parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='greentext'><B>Success!</B></span>"
				else if(completion <= 0)
					parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='redtext'>Fail.</span>"
					changelingwin = FALSE
				else
					parts += "<B>Objective #[count]</B>: [objective.explanation_text] <span class='yellowtext'>[completion*100]%</span>"
			else
				parts += "<B>Objective #[count]</B>: [objective.explanation_text]"
			count++

	if(changelingwin)
		parts += "<span class='greentext'>The changeling was successful!</span>"
	else
		parts += "<span class='redtext'>The changeling has failed.</span>"

	return parts.Join("<br>")

/datum/antagonist/changeling/antag_listing_name()
	return ..() + "([changelingID])"

/datum/antagonist/changeling/xenobio/antag_listing_name()
	return ..() + "(Xenobio)"

/**
 * Gives a passed changeling power datum to the player
 *
 * Is passed a path to a changeling power, and applies it to the user.
 * If successful, we return TRUE, otherwise not.
 *
 * Arguments:
 * * power_path - The path of the power we will be giving to our attached player.
 */

/datum/antagonist/changeling/proc/give_power(power_path)
	var/datum/action/changeling/new_action = new power_path()

	if(!new_action)
		to_chat(owner.current, "This is awkward. Changeling power purchase failed, please report this bug to a coder!")
		CRASH("Changeling give_power was unable to grant a new changeling action for path [power_path]!")

	purchasedpowers[power_path] = new_action
	new_action.on_purchase(owner.current) // Grant() is ran in this proc, see changeling_powers.dm.

	return TRUE

/datum/antagonist/changeling/space
	name = "\improper Space Changeling"

/datum/antagonist/changeling/space/get_preview_icon()
	var/icon/final_icon = render_preview_outfit(/datum/outfit/changeling_space)
	return finish_preview_icon(final_icon)

/datum/antagonist/changeling/space/greet()
	to_chat(src, span_changeling("Our mind stirs to life, from the depths of an endless slumber..."))

/datum/outfit/changeling
	name = "Changeling"

	head = /obj/item/clothing/head/helmet/changeling
	suit = /obj/item/clothing/suit/armor/changeling
	l_hand = /obj/item/melee/arm_blade

/datum/outfit/changeling_space
	name = "Changeling (Space)"

	head = /obj/item/clothing/head/helmet/space/changeling
	suit = /obj/item/clothing/suit/space/changeling
	l_hand = /obj/item/melee/arm_blade
