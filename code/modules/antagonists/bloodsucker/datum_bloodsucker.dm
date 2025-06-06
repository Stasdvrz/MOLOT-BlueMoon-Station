/datum/team/vampireclan
	name = "Clan" // Teravanni,

/datum/antagonist/bloodsucker
	name = "Bloodsucker"
	roundend_category = "bloodsuckers"
	antagpanel_category = "Bloodsucker"
	job_rank = ROLE_BLOODSUCKER
	threat = 5
	soft_antag = FALSE // BLUEMOON ADDITION
	// NAME
	var/bloodsucker_name						// My Dracula style name
	var/bloodsucker_title						// My Dracula style title
	var/bloodsucker_reputation					// My "Surname" or description of my deeds
	// CLAN
	var/datum/team/vampireclan/clan
	var/list/datum/antagonist/vassal/vassals = list()// Vassals under my control. Periodically remove the dead ones.
	var/datum/mind/creator				// Who made me? For both Vassals AND Bloodsuckers (though Master Vamps won't have one)
	// POWERS
	var/list/datum/action/powers = list()// Purchased powers
	var/poweron_feed = FALSE			// Am I feeding?
	var/poweron_masquerade = FALSE
	// STATS
	var/bloodsucker_level
	var/bloodsucker_level_unspent = 1
	var/regen_rate = 0.3				// How fast do I regenerate?
	var/additional_regen                // How much additional blood regen we gain from bonuses such as high blood.
	var/feed_amount = 15				// Amount of blood drawn from a target per tick.
	var/max_blood_volume = 600			// Maximum blood a Vamp can hold via feeding.
	// OBJECTIVES
	var/list/datum/objective/objectives_given = list()	// For removal if needed.
	var/area/lair
	var/obj/structure/closet/crate/coffin
	// TRACKING
	var/foodInGut 					// How much food to throw up later. You shouldn't have eaten that.
	var/warn_sun_locker				// So we only get the locker burn message once per day.
	var/warn_sun_burn 				// So we only get the sun burn message once per day.
	var/had_toxlover
	var/level_bloodcost
	var/passive_blood_drain = -0.1        //The amount of blood we loose each bloodsucker life() tick
	var/notice_healing                    //Var to see if you are healing for preventing spam of the chat message inform the user of such
	var/FinalDeath                  //Have we reached final death? Used to prevent spam.
	// LISTS
	var/static/list/defaultTraits = list (TRAIT_STABLEHEART, TRAIT_NOBREATH, TRAIT_SLEEPIMMUNE, TRAIT_NOCRITDAMAGE, TRAIT_RESISTCOLD, TRAIT_RADIMMUNE, TRAIT_NIGHT_VISION, TRAIT_NOTHIRST, \
										  TRAIT_NOSOFTCRIT, TRAIT_NOHARDCRIT, TRAIT_AGEUSIA, TRAIT_COLDBLOODED, TRAIT_NONATURALHEAL, TRAIT_NOMARROW, TRAIT_NOPULSE, TRAIT_VIRUSIMMUNE, TRAIT_NODECAP, TRAIT_NOGUT)

	reminded_times_left = 2 // BLUEMOON ADD

/datum/antagonist/bloodsucker/on_gain()
	SSticker.mode.bloodsuckers |= owner // Add if not already in here (and you might be, if you were picked at round start)
	SSticker.mode.check_start_sunlight()// Start Sunlight? (if first Vamp)
	SelectFirstName()// Name & Title
	SelectTitle(am_fledgling = TRUE) 	// If I have a creator, then set as Fledgling.
	SelectReputation(am_fledgling = TRUE)
	AssignStarterPowersAndStats()// Give Powers & Stats
	forge_bloodsucker_objectives()// Objectives & Team
	update_bloodsucker_icons_added(owner.current, "bloodsucker")	// Add Antag HUD
	. = ..()


/datum/antagonist/bloodsucker/on_removal()
	SSticker.mode.bloodsuckers -= owner
	SSticker.mode.check_cancel_sunlight()// End Sunlight? (if last Vamp)
	ClearAllPowersAndStats()// Clear Powers & Stats
	clear_bloodsucker_objectives()	// Objectives
	update_bloodsucker_icons_removed(owner.current)// Clear Antag HUD
	owner.special_role = null // BLUEMOON ADD
	. = ..()



/datum/antagonist/bloodsucker/greet()
	var/fullname = ReturnFullName(TRUE)
	to_chat(owner, "<span class='userdanger'>Вы - [fullname], потомок одного из древних вампиров!</span><br>")
	owner.announce_objectives()
	/* BLUEMOON REMOVAL START
	to_chat(owner, "<span class='boldannounce'>* You regenerate your health slowly, you're weak to fire, and you depend on blood to survive. Allow your stolen blood to run too low, and you will find yourself at \
	risk of being discovered!</span><br>")
	//to_chat(owner, "<span class='boldannounce'>As an immortal, your power is linked to your age. The older you grow, the more abilities you will have access to.<span>")
	var/bloodsucker_greet
	bloodsucker_greet +=  "<span class='boldannounce'>* Other Bloodsuckers are not necessarily your friends, but your survival may depend on cooperation. Betray them at your own discretion and peril.</span><br>"
	bloodsucker_greet += "<span class='boldannounce'><i>* Use \",b\" to speak your ancient Bloodsucker language.</span><br>"
	bloodsucker_greet += "<span class='announce'>Bloodsucker Tip: Rest in a <i>Coffin</i> to claim it, and that area, as your lair.</span><br>"
	bloodsucker_greet += "<span class='announce'>Bloodsucker Tip: Fear the daylight! Solar flares will bombard the station periodically, and only your coffin can guarantee your safety.</span><br>"
	bloodsucker_greet += "<span class='announce'>Bloodsucker Tip: You wont loose blood if you are unconcious or sleeping. Use this to your advantage to conserve blood.</span><br>"
	/ BLUEMOON REMOVAL END */
	// BLUEMOON ADD START - адаптация предыдущего
	var/bloodsucker_greet
	bloodsucker_greet += "<span class='boldannounce'>* Вы медленно восстанавливаете своё здоровье, обладаете слабостью к огню и зависите от крови для выживания. Если крови останется слишком мало, станет невозможным поддерживать маскировку и вас раскроют!</span><br>"
	bloodsucker_greet += "<span class='boldannounce'>* Сородичи не обязательно ваши друзья, но выживание может зависить от кооперации с ними. Предавайте их на ваше усмотрение.</span><br>"
	bloodsucker_greet += "<span class='boldannounce'>* Будучи бессмертным существом, ваша сила зависит от поколения. Чтобы повысить его, должен пройти цикл. Становитесь сильнее, чтобы открывать в себе новые способности...<span><br>"
	bloodsucker_greet += "<span class='boldannounce'><i>* Используйте \",b\" для общения на древнем языке сородичей.</span><br>"
	bloodsucker_greet += "<span class='announce'>Подсказка: Спите в <i>гробу</i>, чтобы обозначить зону как своё логово.</span><br>"
//	bloodsucker_greet += "<span class='announce'>Подсказка: Бойтесь света дня! Солнечные вспышки периодически достигают станции. Единственное спасение от них - ваш гроб и шкафы.</span><br>"
	bloodsucker_greet += "<span class='announce'>Подсказка: Вы не теряете кровь, если спите или без сознания. Используйте это преимущество для сохранения крови.</span><br>"
	// BLUEMOON ADD END
	to_chat(owner, bloodsucker_greet)

	owner.current.playsound_local(null, 'sound/bloodsucker/BloodsuckerAlert.ogg', 100, FALSE, pressure_affected = FALSE)
	antag_memory += "Не смотря на то, что родились вы в смертном теле, в не-жизни вы носите имя <b>[fullname]</b>.<br>"


/datum/antagonist/bloodsucker/farewell()
	owner.current.visible_message("Кожа [owner.current] налилась цветом, глаза снова заблестели. Выглядит... живо.",\
			"<span class='userdanger'><FONT size = 3>Внезапно, ваше проклятье закончилось. Вы больше не кровосос. Вы снова живой.</FONT></span>")
	// Refill with Blood
	owner.current.blood_volume = max(owner.current.blood_volume,BLOOD_VOLUME_SAFE)

/datum/antagonist/bloodsucker/threat()
	return ..() + 3 * bloodsucker_level


/datum/antagonist/bloodsucker/proc/SelectFirstName()
	// Names (EVERYONE gets one))
	if(owner.current.gender == MALE)
		bloodsucker_name = pick("Десмонд","Рудольф","Дракул","Влад","Пётр","Грерог","Кристиан","Кристофф","Марку","Андрей","Константин","Георг","Грэгори","Илья","Якоб","Лука","Михаил","Павел","Василий","Октавий","Сорин", \
						"Свейн","Аурел","Алекси","Иустин","Теодор","Дмитрий","Октав","Дамиен","Магнус","Каин","Авель", // Romanian/Ancient
						"Люциус","Гай","Отто","Балбинус","Аркадиус","Романос","Алексиос","Виттелиус",  // Latin
						"Мелантус","Тевфрант","Орхам","Аминтор","Аксион",  // Greek
						"Тот","Тутмос","Осоркон,","Нофрет","Минмоту","Кафра", // Egyptian
						"Дио")

	else
		bloodsucker_name = pick("Ислана","Тирра","Греганна","Питра","Хильда","Андра","Крина","Виорела","Виорика","Анемона","Камелия","Нарциса","Сорина","Алессия","София","Гладда","Аркана","Моргана","Лассара","Иоанна","Елена", \
						"Алина","Родика","Теодора","Дениса","Михаэла","Светла","Стэфания","Диана","Келлса","Лилит", // Romanian/Ancient
						"Алексия","Антанасия","Каллиста","Карена","Нефеле","Сцилла","Урса",  // Latin
						"Алкестида","Дамарис","Елизавета","Ктхония","Тэодора",  // Greek
						"Нефрет","Анхнесмерира") // Egyptian

/datum/antagonist/bloodsucker/proc/SelectTitle(am_fledgling = 0, forced = FALSE)
	// Already have Title
	if(!forced && bloodsucker_title != null)
		return
	// Titles [Master]
	if(!am_fledgling)
		if(owner.current.gender == MALE)
			bloodsucker_title = pick ("Граф","Барон","Виконт","Принц","Герцог","Царь","Повелитель Ужаса","Лорд","Хозяин","Целователь Мальчиков")
		else
			bloodsucker_title = pick ("Графиня","Баронесса","Виконтесса","Принцесса","Герцогиня","Царица","Леди Ужаса","Леди","Хозяйка","Профурсетка")
		to_chat(owner, "<span class='announce'>Вы заслужили титул! Теперь вы известны как <i>[ReturnFullName(TRUE)]</i>!</span>")
	// Titles [Fledgling]
	else
		bloodsucker_title = null

/datum/antagonist/bloodsucker/proc/SelectReputation(am_fledgling = 0, forced=FALSE)
	// Already have Reputation
	if(!forced && bloodsucker_reputation != null)
		return
	// Reputations [Master]
	if(!am_fledgling)
		bloodsucker_reputation = pick("Мясник","Кровавый изверг","Алый","Красный","Черный","Ужасный","Ночной житель","Страшный","Ненасытный","Изверг","Злобный","Безумный","Древний","Чумной","Зловещий","Забытый","Несчастный","Губительный", \
							"Инквизитор","Поборник","Оскорбительный","Робустный","Предатель","Разрушитель","Проклятый","Ненавистный","Ужасный","Жестокий","Нечистивый","Мерзкий","Развратный","Плохой","Убийца","Человекоубийца","Суверенный","Расчленитель", \
							"Отрекшийся","Безумный","Дракон","Дикий","Злодейский","Гнусный","Инквизитор","Мародёр","Отвратительный","Бессмертный","Неумирающий","Повелитель","Испорченый","Адское Порождение","Тиран","Кровавый")
		if(owner.current.gender == MALE)
			if(prob(10)) // Gender override
				bloodsucker_reputation = pick("Король Проклятых", "Кровавый Король", "Император Клинков", "Лорд Греха", "Бог-Король")
		else if(owner.current.gender == FEMALE)
			if(prob(10)) // Gender override
				bloodsucker_reputation = pick("Королева Проклятых", "Кровавая Королева", "Императрица Клинков", "Леди Греха", "Бог-Королева")

		to_chat(owner, "<span class='cult'>Вы заслужили титул! Теперь вы известны как <i>[ReturnFullName(TRUE)]</i>!</span>")

	// Reputations [Fledgling]
	else
		bloodsucker_reputation = pick ("Сырой","Бескрылый","Неопытный","Неофиь","Новичек","Невыдержанный","Птенец","Молодой","Новорожденный","Срочник","Неиспытанный","Непроверенный","Неизвестный","Ново-восставший","Рожденный","Поберушка","Незнающий",\
							   "Неиспорченный","Опавший","Лишенный","Опозоренный","Кроткий","Робкий","Сломанный")//,"Fresh")


/datum/antagonist/bloodsucker/proc/AmFledgling()
	return !bloodsucker_title

/datum/antagonist/bloodsucker/proc/ReturnFullName(var/include_rep=0)

	var/fullname
	// Name First
	fullname = (bloodsucker_name ? bloodsucker_name : owner.current.name)
	// Title
	if(bloodsucker_title)
		fullname = bloodsucker_title + " " + fullname
	// Rep
	if(include_rep && bloodsucker_reputation)
		fullname = fullname + " " + bloodsucker_reputation

	return fullname


/datum/antagonist/bloodsucker/proc/BuyPower(datum/action/cooldown/bloodsucker/power)//(obj/effect/proc_holder/spell/power)
	powers += power
	power.Grant(owner.current)// owner.AddSpell(power)

/datum/antagonist/bloodsucker/proc/AssignStarterPowersAndStats()
	// Blood/Rank Counter
	add_hud()
	update_hud(TRUE) 	// Set blood value, current rank
	// Powers
	BuyPower(new /datum/action/cooldown/bloodsucker/feed)
	BuyPower(new /datum/action/cooldown/bloodsucker/masquerade)
	BuyPower(new /datum/action/cooldown/bloodsucker/veil)
//	BuyPower(new /datum/action/cooldown/bloodsucker/levelup) // BLUEMOON REMOVAL - возвращаем фазы дня и убираем форсированную эволюцию
	BuyPower(new /datum/action/cooldown/bloodsucker/tutorial) // BLUEMOON ADD - обучение для самых маленьких неофит

	// Traits
	for(var/T in defaultTraits)
		ADD_TRAIT(owner.current, T, BLOODSUCKER_TRAIT)
	if(HAS_TRAIT(owner.current, TRAIT_TOXINLOVER)) //No slime bonuses here, no thank you
		had_toxlover = TRUE
		REMOVE_TRAIT(owner.current, TRAIT_TOXINLOVER, SPECIES_TRAIT)
	// Traits: Species
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		var/datum/species/S = H.dna.species
		S.species_traits |= DRINKSBLOOD
	// Clear Addictions
	owner.current.reagents.addiction_list = list() // Start over from scratch. Lucky you! At least you're not addicted to blood anymore (if you were)
	// Stats
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		var/datum/species/S = H.dna.species
		// Make Changes
		H.physiology.brute_mod *= 0.8
		H.physiology.cold_mod = 0
		H.physiology.stun_mod *= 0.5
		H.physiology.siemens_coeff *= 0.75 	//base electrocution coefficient  1
		S.punchdamagelow += 1       //lowest possible punch damage   0
		S.punchdamagehigh += 1      //highest possible punch damage	 9
		if(istype(H) && owner.assigned_role == "Clown")
			H.dna.remove_mutation(CLOWNMUT)
			to_chat(H, "Будучи вампирским клоуном, вы больше не опасность для самого себя. Ваша клоунская натура подчинена.")
	// Physiology
	CheckVampOrgans() // Heart, Eyes
	// Language
	owner.current.grant_language(/datum/language/vampiric, source = LANGUAGE_BLOODSUCKER)
	owner.hasSoul = FALSE 		// If false, renders the character unable to sell their soul.
	owner.isholy = FALSE 		// is this person a chaplain or admin role allowed to use bibles
	// Disabilities
	CureDisabilities()

/datum/antagonist/bloodsucker/proc/ClearAllPowersAndStats()
	// Blood/Rank Counter
	remove_hud()
	// Powers
	while(powers.len)
		var/datum/action/cooldown/bloodsucker/power = pick(powers)
		powers -= power
		power.Remove(owner.current)
		// owner.RemoveSpell(power)
	// Traits
	for(var/T in defaultTraits)
		REMOVE_TRAIT(owner.current, T, BLOODSUCKER_TRAIT)
	if(had_toxlover)
		ADD_TRAIT(owner.current, TRAIT_TOXINLOVER, SPECIES_TRAIT)

	// Traits: Species
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		H.set_species(H.dna.species.type)
	// Stats
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		H.set_species(H.dna.species.type)
		// Clown
		if(istype(H) && owner.assigned_role == "Clown")
			H.dna.add_mutation(CLOWNMUT)
	// Physiology
	owner.current.regenerate_organs()
	// Update Health
	owner.current.setMaxHealth(100)
	// Language
	owner.current.remove_language(/datum/language/vampiric, TRUE, TRUE, LANGUAGE_BLOODSUCKER)
	// Soul
	if (owner.soulOwner == owner) // Return soul, if *I* own it.
		owner.hasSoul = TRUE
//owner.current.hellbound = FALSE

/datum/antagonist/bloodsucker/proc/RankUp()
	set waitfor = FALSE
	if(!owner || !owner.current)
		return
	bloodsucker_level_unspent ++
	// Spend Rank Immediately?
	if(istype(owner.current.loc, /obj/structure/closet/crate/coffin))
		SpendRank()
	else
		to_chat(owner, "<EM><span class='cult'>Вы стали более древним! Выспитесь в гробу который вы назначили своим чтобы укрепить кровь и стать еще сильнее.</span></EM>")
		if(bloodsucker_level_unspent >= 2)
			to_chat(owner, "<span class='announce'>Напоминание: Если вы не можете найти или украсть гроб для использования, вы можете построить себе его из досок или листов металла.</span><br>")

/datum/antagonist/bloodsucker/proc/LevelUpPowers()
	for(var/datum/action/cooldown/bloodsucker/power in powers)
		power.level_current ++

/datum/antagonist/bloodsucker/proc/SpendRank()
	set waitfor = FALSE
	if(bloodsucker_level_unspent <= 0 || !owner || !owner.current || !owner.current.client || !isliving(owner.current))
		return
	// BLUEMOON ADD START
	//if(bloodsucker_level >= 2)
		//if(vassals.len <= bloodsucker_level / 2) // для прогресса, вампиру необходимо набирать слуг, по 1 за каждые 2 уровня
			//to_chat(owner.current, span_warning("Нужно больше вассалов, чтобы повысить своё могущество!"))
			//return
	// BLUEMOON ADD END
	var/mob/living/L = owner.current
	level_bloodcost = max_blood_volume * 0.2
	//If the blood volume of the bloodsucker is lower than the cost to level up, return and inform the bloodsucker

	//TODO: Make this into a radial, or perhaps a tgui next UI
		// Purchase Power Prompt
	var/list/options = list()
	for(var/pickedpower in typesof(/datum/action/cooldown/bloodsucker))
		var/datum/action/cooldown/bloodsucker/power = pickedpower
		// If I don't own it, and I'm allowed to buy it.
		if(!(locate(power) in powers) && initial(power.bloodsucker_can_buy))
			options[initial(power.name)] = power // TESTING: After working with TGUI, it seems you can use initial() to view the variables inside a path?
	options["\[ Not Now \]"] = null
	// Abort?
	if(options.len > 1)
		var/choice = input(owner.current, "У вас есть возможность стать более древним ценой [level_bloodcost] единиц крови. Выберите силу чтобы продвинуть свой Ранг.", "Ваша кровь сгущается...") in options
		// Cheat-Safety: Can't keep opening/closing coffin to spam levels
		if(bloodsucker_level_unspent <= 0) // Already spent all your points, and tried opening/closing your coffin, pal.
			return
		if(!istype(owner.current.loc, /obj/structure/closet/crate/coffin))
			to_chat(owner.current, "<span class='warning'>Вернитесь в свой гроб чтобы продвинуть свой Ранг.</span>")
			return
		if(!choice || !options[choice] || (locate(options[choice]) in powers)) // ADDED: Check to see if you already have this power, due to window stacking.
			to_chat(owner.current, "<span class='warning'>Вы не позволили своей крови окрепнуть, но вы можете попробовать еще раз позже.</span>")
			return
		if(L.blood_volume < level_bloodcost)
			to_chat(owner.current, "<span class='warning'>У вас недостаточно крови чтобы укрепить её, вам нужно еще [level_bloodcost - L.blood_volume]!</span>")
			return
		// Buy New Powers
		var/datum/action/cooldown/bloodsucker/P = options[choice]
		AddBloodVolume(-level_bloodcost)
		BuyPower(new P)
		to_chat(owner.current, "<span class='cult'>Вы использовали [level_bloodcost] единиц крови и изучили [initial(P.name)]!</span>")
	else
		to_chat(owner.current, "<span class='cult'>Вы становитесь более древним порождением ночи!</span>")
	/////////
	// Advance Powers (including new)
	LevelUpPowers()
	////////
	// Advance Stats
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		var/datum/species/S = H.dna.species
		S.punchdamagelow += 0.5
		S.punchdamagehigh += 0.5    // NOTE: This affects the hitting power of Brawn.
	// More Health
	owner.current.setMaxHealth(owner.current.maxHealth + 10)
	// Vamp Stats
	regen_rate += 0.05			// Points of brute healed (starts at 0.3)
	feed_amount += 2				// Increase how quickly I munch down vics (15)
	max_blood_volume += 100		// Increase my max blood (600)
	/////////
	bloodsucker_level ++
	bloodsucker_level_unspent --

	// Assign True Reputation
	if(bloodsucker_level == 4)
		SelectReputation(am_fledgling = FALSE, forced = TRUE)
	to_chat(owner.current, "<span class='warning'>Вы теперь вампир [bloodsucker_level] поколения. Ваша сила, здоровье, скорость поедания, скорость регенерации повысились, можете иметь [bloodsucker_level - count_vassals(owner.current.mind)] вассалов, а максимум сгущаемой крови возрос!</span>")
	to_chat(owner.current, "<span class='warning'>Все ваши изученые способности так же усилились!</span>")
	update_hud(TRUE)
	owner.current.playsound_local(null, 'sound/effects/pope_entry.ogg', 25, TRUE, pressure_affected = FALSE)

	// BLUEMOON ADD START - вампир тратит все уровни без необходимости открыть-закрывать гроб
	if(bloodsucker_level_unspent)
		SpendRank()
	// BLUEMOON ADD END

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//This handles the application of antag huds/special abilities
/datum/antagonist/bloodsucker/apply_innate_effects(mob/living/mob_override)
	RegisterSignal(owner.current,COMSIG_LIVING_BIOLOGICAL_LIFE, PROC_REF(LifeTick))
	return

//This handles the removal of antag huds/special abilities
/datum/antagonist/bloodsucker/remove_innate_effects(mob/living/mob_override)
	UnregisterSignal(owner.current,COMSIG_LIVING_BIOLOGICAL_LIFE)
	return

//Assign default team and creates one for one of a kind team antagonists
/datum/antagonist/bloodsucker/create_team(datum/team/team)
	return

// Create Objectives
/datum/antagonist/bloodsucker/proc/forge_bloodsucker_objectives() // Fledgling vampires can have different objectives.

	// TEAM
	//clan = new /datum/team/vampireclan(owner)


	// Lair Objective:		Create a Lair
	var/datum/objective/bloodsucker/lair/lair_objective = new
	lair_objective.owner = owner
	lair_objective.generate_objective()
	add_objective(lair_objective)

	// BLUEMOON ADD START
	// Gain Vassals Objective
	var/datum/objective/bloodsucker/gain_vassals/gain_vassals_objective = new
	gain_vassals_objective.owner = owner
	gain_vassals_objective.generate_objective()
	add_objective(gain_vassals_objective)
	// BLUEMOON ADD END

	// Protege Objective
	var/datum/objective/bloodsucker/protege/protege_objective = new
	protege_objective.owner = owner
	protege_objective.generate_objective()
	add_objective(protege_objective)

	//if (rand(0,1) == 0)
		// Heart Thief Objective
	var/datum/objective/bloodsucker/heartthief/heartthief_objective = new
	heartthief_objective.owner = owner
	heartthief_objective.generate_objective()
	add_objective(heartthief_objective)
	/*
	else

		// Solars Objective, doesnt work due to TG updates.
		var/datum/objective/bloodsucker/solars/solars_objective = new
		solars_objective.owner = owner
		solars_objective.generate_objective()
		add_objective(solars_objective)
*/
	// Survive Objective
	var/datum/objective/bloodsucker/survive/survive_objective = new
	survive_objective.owner = owner
	survive_objective.generate_objective()
	add_objective(survive_objective)


/datum/antagonist/bloodsucker/proc/add_objective(var/datum/objective/O)
	objectives += O
	objectives_given += O

/datum/antagonist/bloodsucker/proc/clear_bloodsucker_objectives()

	var/datum/team/team = get_team()
	if(team)
		team.remove_member(owner)

	for(var/O in objectives_given)
		objectives -= O
		qdel(O)
	objectives_given = list() // Traitors had this, so I added it. Not sure why.


/datum/antagonist/bloodsucker/get_team()
	return clan

//Name shown on antag list
/datum/antagonist/bloodsucker/antag_listing_name()
	return ..() + "([ReturnFullName(TRUE)])"

//Whatever interesting things happened to the antag admins should know about
//Include additional information about antag in this part
/datum/antagonist/bloodsucker/antag_listing_status()
	if (owner && owner.AmFinalDeath())
		return "<font color=red>Окончательная Смерть</font>"
	return ..()



//Individual roundend report
/datum/antagonist/bloodsucker/roundend_report()
	// Get the default Objectives
	var/list/report = list()

	// Vamp Name
	report += "<br><span class='header'><b>\[[ReturnFullName(TRUE)]\]</b></span>"

	// Default Report
	report += ..()

	// Now list their vassals
	if (vassals.len > 0)
		report += "<span class='header'>И вассалами были...</span>"
		for (var/datum/antagonist/vassal/V in vassals)
			if (V.owner)
				var/jobname = V.owner.assigned_role ? "the [V.owner.assigned_role]" : ""
				report += "<b>[V.owner.name]</b> [jobname]"

	return report.Join("<br>")

//Displayed at the start of roundend_category section, default to roundend_category header
/datum/antagonist/bloodsucker/roundend_report_header()
	return 	"<span class='header'>Крадущимися в тенях, Кровососами были:</span><br>"





//  		2019 Breakdown of Bloodsuckers:

//					G A M E P L A Y
//
//	Bloodsuckers should be inherrently powerful: they never stay dead, and they can hide in plain sight
//  better than any other antagonist aboard the station.
//
//	However, only elder Bloodsuckers are the powerful creatures of legend. Ranking up as a Bloodsucker
//  should impart slight strength and health benefits, as well as powers that can grow over time. But
//  their weaknesses should grow as well, and not just to fire.


//					A B I L I T I E S
//
// 	* Bloodsuckers can FEIGN LIFE + DEATH.
//		Feigning LIFE:
//			- Warms up the body
//			- Creates a heartbeat
//			- Fake blood amount (550)
//		Feign DEATH: Not yet done
//			- When lying down or sitting, you appear "dead and lifeless"

//	* Bloodsuckers REGENERATE
//		- Brute damage heals rather rapidly. Burn damage heals slowly.
//		- Healing is reduced when hungry or starved.
//		- Burn does not heal when starved. A starved vampire remains "dead" until burns can heal.
//		- Bodyparts and organs regrow in Torpor (except for the Heart and Brain).
//
//	* Bloodsuckers are IMMORTAL
//		- Brute damage cannot destroy them (and it caps very low, so they don't stack too much)
//		- Burn damage can only kill them at very high amounts.
//		- Removing the head kills the vamp forever.
//		- Removing the heart kills the vamp until replaced.
//
//	* Bloodsuckers are DEAD
//		- They do not breathe.
//		- Cold affects them less.
//		- They are immune to disease (but can spread it)
//		- Food is useless and cause sickness.
//		- Nothing can heal the vamp other than his own blood.
//
//	* Bloodsuckers are PREDATORS
//		- They detect life/heartbeats nearby.
//		- They know other predators instantly (Vamps, Werewolves, and alien types) regardless of disguise.
//
//
//
// 	* Bloodsuckers enter Torpor when DEAD or RESTING in coffin
//		- Torpid vampires regenerate their health. Coffins negate cost and speed up the process.
//		** To rest in a coffin, either SLEEP or CLOSE THE LID while you're in it. You will be given a prompt to sleep until healed. Healing in a coffin costs NO blood!
//



// 					O B J E C T I V E S
//
//
//
//
//	1) GROOM AN HEIR:	Find a person with appropriate traits (hair, blood type, gender) to be turned as a Vampire. Before they rise, they must be properly trained. Raise them to great power after their change.
//
//	2) BIBLIOPHILE:		Research objects of interest, study items looking for clues of ancient secrets, and hunt down the clues to a Vampiric artifact of horrible power.
//
//	3) CRYPT LORD:		Build a terrifying sepulcher to your evil, with servants to lavish upon you in undeath. The trappings of a true crypt lord come at grave cost.
//
//	4) GOURMOND:		Oh, to taste all the delicacies the station has to offer! DRINK ## BLOOD FROM VICTIMS WHO LIVE, EAT ## ORGANS FROM VICTIMS WHO LIVE


//			Vassals
//
// - Loyal to (and In Love With) Master
// - Master can speak to, summon, or punish his Vassals, even while asleep or torpid.
// - Master may have as many Vassals as Rank
// - Vassals see their Master's speech emboldened!








// 			Dev Notes
//
// HEALING: Maybe Vamps metabolize specially? Like, they slowly drip their own blood into their system?
//			- Give Vamps their own metabolization proc, perhaps?
//			** shadowpeople.dm has rules for healing.
//
// KILLING: It's almost impossible to track who someone has directly killed. But an Admin could be given
//			an easy way to whip a Bloodsucker for cruel behavior, as a RP mechanic but not a punishment.
//			**
//
// HUNGER:  Just keep adjusting mob's nutrition to Blood Hunger level. No need to cancel nutrition from eating.
//			** mob.dm /set_nutrition()
//			** snacks.dm / attack()  <-- Stop food from doing anything?

// ORGANS:  Liver
//			** life.dm /handle_liver()
//
// CORPSE:	Most of these effects likely go away when using "Masquerade" to appear alive.
//			** status_procs.dm /adjust_bodytemperature()
//			** traits.dm /TRAIT_NOBREATH /TRAIT_SLEEPIMMUNE /TRAIT_RESISTCOLD /TRAIT_RADIMMUNE  /TRAIT_VIRUSIMMUNE
//			*  MASQUERADE ON/OFF: /TRAIT_FAKEDEATH (M)
//			* /TRAIT_NIGHT_VISION
//			* /TRAIT_DEATHCOMA <-- This basically makes you immobile. When using status_procs /fakedeath(), make sure to remove Coma unless we're in Torpor!
//			* /TRAIT_NODEATH <--- ???
//			** species  /NOZOMBIE
//			* ADD: TRAIT_COLDBLOODED <-- add to carbon/life.dm /natural_bodytemperature_stabilization()
//
// MASQUERADE	Appear as human!
//				** examine.dm /examine() <-- Change "blood_volume < BLOOD_VOLUME_SAFE" to a new examine
//
// NOSFERATU ** human.add_trait(TRAIT_DISFIGURED, "insert_vamp_datum_here") <-- Makes you UNKNOWN unless your ID says otherwise.
// STEALTH   ** human_helpers.dm /get_visible_name()     ** shadowpeople.dm has rules for Light.
//
// FRENZY	** living.dm /update_mobility() (USED TO be update_canmove)
//
// PREDATOR See other Vamps!
//		    * examine.dm /examine()
//
// WEAKNESSES:	-Poor mood in Chapel or near Chaplain.  -Stamina damage from Bible



	//message_admins("DEBUG3: attempt_cast() [name] / [user_C.handcuffed] ")


// TODO:
//
// Death (fire, heart, brain, head)
// Disable Life: BLOOD
// Body Temp
// Spend blood over time (more if imitating life) (none if sleeping in coffin)
// Auto-Heal (brute to 0, fire to 99) (toxin/o2 always 0)
//
// Hud Icons
// UI Blood Counter
// Examine Name (+Masquerade, only "Dead and lifeless" if not standing?)
//
//
// Turn vamps
// Create vassals
//


// FIX LIST
//


/////////////////////////////////////

		// HUD! //

/datum/antagonist/bloodsucker/proc/update_bloodsucker_icons_added(datum/mind/m)
	var/datum/atom_hud/antag/vamphud = GLOB.huds[ANTAG_HUD_BLOODSUCKER]
	vamphud.join_hud(owner.current)
	set_antag_hud(owner.current, "bloodsucker") // "bloodsucker"
	owner.current.hud_list[ANTAG_HUD].icon = image('icons/mob/hud.dmi', owner.current, "bloodsucker")	//Check prepare_huds in mob.dm to see why.

/datum/antagonist/bloodsucker/proc/update_bloodsucker_icons_removed(datum/mind/m)
	var/datum/atom_hud/antag/vamphud = GLOB.huds[ANTAG_HUD_BLOODSUCKER]
	vamphud.leave_hud(owner.current)
	set_antag_hud(owner.current, null)

/datum/atom_hud/antag/bloodsucker  // from hud.dm in /datums/   Also see data_huds.dm + antag_hud.dm

/datum/atom_hud/antag/bloodsucker/add_to_single_hud(mob/M, atom/A)
	if (!check_valid_hud_user(M,A)) 	// FULP: This checks if the Mob is a Vassal, and if the Atom is his master OR on his team.
		return
	..()

/datum/atom_hud/antag/bloodsucker/proc/check_valid_hud_user(mob/M, atom/A) // Remember: A is being added to M's hud. Because M's hud is a /antag/vassal hud, this means M is the vassal here.
	// Ghost Admins always see Bloodsuckers/Vassals
	if (isobserver(M))
		return TRUE
	// GOAL: Vassals see their Master and his other Vassals.
	// GOAL: Vassals can BE seen by their Bloodsucker and his other Vassals.
	// GOAL: Bloodsuckers can see each other.
	if (!M || !A || !ismob(A) || !M.mind)// || !A.mind)
		return FALSE
	var/mob/A_mob = A
	if (!A_mob.mind)
		return FALSE
	// Find Datums: Bloodsucker
	var/datum/antagonist/bloodsucker/atom_B = A_mob.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	var/datum/antagonist/bloodsucker/mob_B = M.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	// Check 1) Are we both Bloodsuckers?
	if (atom_B && mob_B)
		return TRUE
	// Find Datums: Vassal
	var/datum/antagonist/vassal/atom_V = A_mob.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	var/datum/antagonist/vassal/mob_V = M.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	// Check 2) If they are a BLOODSUCKER, then are they my Master?
	if (mob_V && atom_B == mob_V.master)
		return TRUE
	// Check 3) If I am a BLOODSUCKER, then are they my Vassal?
	if (mob_B && atom_V && (atom_V in mob_B.vassals))
		return TRUE
	// Check 4) If we are both VASSAL, then do we have the same master?
	if (atom_V && mob_V && atom_V.master == mob_V.master)
		return TRUE
	return FALSE



		/////////////////////////////////////


		// BLOOD COUNTER & RANK MARKER ! //

#define ui_sunlight_display "WEST:6,CENTER-0:0"  // 6 pixels to the right, zero tiles & 5 pixels DOWN.
#define ui_blood_display "WEST:6,CENTER-1:0"  	  // 1 tile down
#define ui_vamprank_display "WEST:6,CENTER-2:-5"   // 2 tiles down

/datum/hud
	var/atom/movable/screen/bloodsucker/blood_counter/blood_display
	var/atom/movable/screen/bloodsucker/rank_counter/vamprank_display
	var/atom/movable/screen/bloodsucker/sunlight_counter/sunlight_display

/datum/antagonist/bloodsucker/proc/add_hud()
	return

/datum/antagonist/bloodsucker/proc/remove_hud()
	// No Hud? Get out.
	if (!owner.current.hud_used)
		return
	owner.current.hud_used.blood_display.invisibility = INVISIBILITY_ABSTRACT
	owner.current.hud_used.vamprank_display.invisibility = INVISIBILITY_ABSTRACT
	owner.current.hud_used.sunlight_display.invisibility = INVISIBILITY_ABSTRACT

/datum/antagonist/bloodsucker/proc/update_hud(updateRank=FALSE)
	if(FinalDeath)
		return
	// No Hud? Get out.
	if(!owner.current.hud_used)
		return
	// Update Blood Counter
	if (owner.current.hud_used.blood_display)
		var/valuecolor = "#FF6666"
		if(owner.current.blood_volume > BLOOD_VOLUME_SAFE)
			valuecolor =  "#FFDDDD"
		else if(owner.current.blood_volume > BLOOD_VOLUME_BAD)
			valuecolor =  "#FFAAAA"
		owner.current.hud_used.blood_display.update_counter(owner.current.blood_volume, valuecolor)

	// Update Rank Counter
	if(owner.current.hud_used.vamprank_display)
		var/valuecolor = bloodsucker_level_unspent ? "#FFFF00" : "#FF0000"
		owner.current.hud_used.vamprank_display.update_counter(bloodsucker_level, valuecolor)
		if(updateRank) // Only change icon on special request.
			owner.current.hud_used.vamprank_display.icon_state = (bloodsucker_level_unspent > 0) ? "rank_up" : "rank"


/atom/movable/screen/bloodsucker
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/bloodsucker/proc/clear()
	invisibility = INVISIBILITY_ABSTRACT

/atom/movable/screen/bloodsucker/proc/update_counter(value, valuecolor)
	invisibility = 0

/atom/movable/screen/bloodsucker/blood_counter
	icon = 'icons/mob/actions/bloodsucker.dmi'
	name = "Blood Consumed"
	icon_state = "blood_display"
	screen_loc = ui_blood_display

/atom/movable/screen/bloodsucker/blood_counter/update_counter(value, valuecolor)
	..()
	maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[valuecolor]'>[round(value,1)]</font></div>")

/atom/movable/screen/bloodsucker/rank_counter
	name = "Bloodsucker Rank"
	icon = 'icons/mob/actions/bloodsucker.dmi'
	icon_state = "rank"
	screen_loc = ui_vamprank_display

/atom/movable/screen/bloodsucker/rank_counter/update_counter(value, valuecolor)
	..()
	maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='[valuecolor]'>[round(value,1)]</font></div>")

/atom/movable/screen/bloodsucker/sunlight_counter
	icon = 'icons/mob/actions/bloodsucker.dmi'
	name = "Solar Flare Timer"
	icon_state = "sunlight_night"
	screen_loc = ui_sunlight_display

/datum/antagonist/bloodsucker/proc/update_sunlight(value, amDay = FALSE)
	// No Hud? Get out.
	if(!owner.current.hud_used)
		return
	// Update Sun Time
	if(owner.current.hud_used.sunlight_display)
		var/valuecolor = "#BBBBFF"
		if(amDay)
			valuecolor =  "#FF5555"
		else if(value <= 25)
			valuecolor =  "#FFCCCC"
		else if(value < 10)
			valuecolor =  "#FF5555"
		var/value_string = (value >= 60) ? "[round(value / 60, 1)] m" : "[round(value, 1)] s"
		owner.current.hud_used.sunlight_display.update_counter( value_string, valuecolor )
		owner.current.hud_used.sunlight_display.icon_state = "sunlight_" + (amDay ? "day":"night")


/atom/movable/screen/bloodsucker/sunlight_counter/update_counter(value, valuecolor)
	..()
	maptext = MAPTEXT("<div align='center' valign='bottom' style='position:relative; top:0px; left:6px'><font color='[valuecolor]'>[value]</font></div>")

/datum/antagonist/bloodsucker/proc/count_vassals(datum/mind/master)
	var/datum/antagonist/bloodsucker/B = master.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	var/vassal_amount = B.vassals.len
	return vassal_amount
