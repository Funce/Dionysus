///these mob spawn subtypes do not trigger until attacked by a ghost.
/obj/effect/mob_spawn/ghost_role
	///a short, lowercase name for the mob used in possession prompt that pops up on ghost attacks. must be set.
	var/prompt_name = ""
	///if false, you won't prompt for this role. best used for replacing the prompt system with something else like a radial, or something.
	var/prompt_ghost = TRUE
	///how many times this spawner can be used (it won't delete unless it's out of uses)
	var/uses = 1

	/// For figuring out where the local cryostasis_pod computer is. Must be set for cryo computer announcements.
	var/area/computer_area

	////descriptions

	///This should be the declaration of what the ghost role is, and maybe a short blurb after if you want. Shown in the spawner menu and after spawning first.
	var/you_are_text = ""
	///This should be the actual instructions/description/context to the ghost role. This should be the really long explainy bit, basically.
	var/flavour_text = ""
	///This is critical non-policy information about the ghost role. Shown in the spawner menu and after spawning last.
	var/important_text = ""

	///Show these on spawn? Usually used for hardcoded special flavor
	var/show_flavor = TRUE

	////bans and policy

	///which role to check for a job ban
	var/role_ban = ROLE_GHOST_ROLE
	/// Typepath indicating the kind of job datum this ghost role will have. PLEASE inherit this with a new job datum, it's not hard. jobs come with policy configs.
	var/spawner_job_path = /datum/job/ghost_role

/obj/effect/mob_spawn/ghost_role/Initialize(mapload)
	. = ..()
	SSpoints_of_interest.make_point_of_interest(src)
	LAZYADD(GLOB.mob_spawners[name], src)

/obj/effect/mob_spawn/Destroy()
	var/list/spawners = GLOB.mob_spawners[name]
	LAZYREMOVE(spawners, src)
	if(!LAZYLEN(spawners))
		GLOB.mob_spawners -= name
	return ..()

/obj/effect/mob_spawn/ghost_role/create(mob/mob_possessor, newname)
	. = ..()
	handle_join(.)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/mob_spawn/ghost_role/attack_ghost(mob/user)
	if(!SSticker.HasRoundStarted() || !loc)
		return
	if(prompt_ghost)
		var/ghost_role = tgui_alert(usr, "Become [prompt_name]? (Warning, You can no longer be revived!)",, list("Yes", "No"))
		if(ghost_role != "Yes" || !loc || QDELETED(user))
			return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_SPAWNER) && !(flags_1 & ADMIN_SPAWNED_1))
		to_chat(user, span_warning("An admin has temporarily disabled non-admin ghost roles!"))
		return
	if(!uses) //just in case
		to_chat(user, span_warning("This spawner is out of charges!"))
		return
	if(is_banned_from(user.key, role_ban))
		to_chat(user, span_warning("You are banned from this role!"))
		return
	if(!allow_spawn(user, silent = FALSE))
		return
	if(QDELETED(src) || QDELETED(user))
		return
	log_game("[key_name(user)] became a [prompt_name]")
	create(user)

/obj/effect/mob_spawn/ghost_role/special(mob/living/spawned_mob, mob/mob_possessor)
	. = ..()
	if(mob_possessor)
		spawned_mob.PossessByPlayer(mob_possessor.ckey)
	if(show_flavor)
		var/output_message = span_big(span_bold(span_infoplain(you_are_text)))
		if(flavour_text != "")
			output_message += "\n[span_bold(span_infoplain(flavour_text))]"
		if(important_text != "")
			output_message += "\n[span_userdanger("[important_text]")]"
		to_chat(spawned_mob, output_message)
	var/datum/mind/spawned_mind = spawned_mob.mind
	if(spawned_mind)
		spawned_mob.mind.set_assigned_role(SSjob.GetJobType(spawner_job_path))
		spawned_mind.name = spawned_mob.real_name

/obj/effect/mob_spawn/ghost_role/proc/find_control_computer()
	if(!computer_area)
		return
	for(var/cryo_console in GLOB.cryopod_computers)
		var/obj/machinery/computer/cryostasis/console = cryo_console
		var/area/area = get_area(cryo_console) // Define moment
		if(area.type == computer_area)
			return console

	return

/obj/effect/mob_spawn/ghost_role/proc/handle_join(mob/living/spawned_mob)
	var/obj/machinery/computer/cryostasis/control_computer = find_control_computer()

	GLOB.ghost_records[WEAKREF(spawned_mob)] = name
	if(control_computer)
		control_computer.announce("CRYO_JOIN", spawned_mob, name)

//multiple use mob spawner functionality here- doesn't make sense on corpses
/obj/effect/mob_spawn/ghost_role/create(mob/mob_possessor, newname)
	. = ..()
	if(uses > 0)
		uses--
	if(!uses)
		qdel(src)

///override this to add special spawn conditions to a ghost role
/obj/effect/mob_spawn/ghost_role/proc/allow_spawn(mob/user, silent = FALSE)
	return TRUE

/obj/effect/mob_spawn/ghost_role/human
	//gives it a base sprite instead of a mapping helper. makes sense, right?
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	mob_type = /mob/living/carbon/human
