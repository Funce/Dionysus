///these mob spawn subtypes trigger immediately (New or Initialize) and are not player controlled... since they're dead, you know?
/obj/effect/mob_spawn/corpse
	///when this mob spawn should auto trigger.
	var/spawn_when = CORPSE_INSTANT

	////damage values (very often, mappers want corpses to be mangled)

	///brute damage this corpse will spawn with
	var/brute_damage = 0
	///oxy damage this corpse will spawn with
	var/oxy_damage = 0
	///burn damage this corpse will spawn with
	var/burn_damage = 0

/obj/effect/mob_spawn/corpse/Initialize(mapload)
	. = ..()
	switch(spawn_when)
		if(CORPSE_INSTANT)
			INVOKE_ASYNC(src, PROC_REF(create))
		if(CORPSE_ROUNDSTART)
			if(mapload || (SSticker && SSticker.current_state > GAME_STATE_SETTING_UP))
				INVOKE_ASYNC(src, PROC_REF(create))

/obj/effect/mob_spawn/corpse/special(mob/living/spawned_mob)
	. = ..()
	spawned_mob.death(TRUE)
	spawned_mob.adjustOxyLoss(oxy_damage)
	spawned_mob.adjustBruteLoss(brute_damage)
	spawned_mob.adjustFireLoss(burn_damage)

/obj/effect/mob_spawn/corpse/create(mob/mob_possessor, newname)
	. = ..()
	qdel(src)

/obj/effect/mob_spawn/corpse/human
	icon_state = "corpsehuman"
	mob_type = /mob/living/carbon/human
	///disables PDA and sensors. only makes sense on corpses because ghost roles could simply turn those on again.
	var/conceal_presence = TRUE
	///husks the corpse if true.
	var/husk = FALSE

/obj/effect/mob_spawn/corpse/human/special(mob/living/carbon/human/spawned_human)
	. = ..()
	if(husk)
		spawned_human.Drain()
	else //Because for some reason I can't track down, things are getting turned into husks even if husk = false. It's in some damage proc somewhere.
		spawned_human.cure_husk()

/obj/effect/mob_spawn/corpse/human/equip(mob/living/carbon/human/spawned_human)
	. = ..()
	if(conceal_presence)
		// We don't want corpse PDAs to show up in the messenger list.
		var/obj/item/modular_computer/tablet/pda/messenger = locate(/obj/item/modular_computer/tablet/pda/) in spawned_human
		if(messenger)
			messenger.invisible = TRUE
		// Or on crew monitors
		var/obj/item/clothing/under/sensor_clothes = spawned_human.w_uniform
		if(istype(sensor_clothes))
			sensor_clothes.sensor_mode = NO_SENSORS
			spawned_human.update_suit_sensors()

//don't use this in subtypes, just add 1000 brute yourself. that being said, this is a type that has 1000 brute. it doesn't really have a home anywhere else, it just needs to exist
/obj/effect/mob_spawn/corpse/human/damaged
	brute_damage = 1000
