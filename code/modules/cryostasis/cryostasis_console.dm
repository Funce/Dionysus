//Main cryostasis console.

/obj/machinery/computer/cryostasis
	name = "cryostasis oversight console"
	desc = "An interface between crew and the cryostasis oversight systems."
	icon = 'icons/obj/cryostasis.dmi'
	icon_state = "cellconsole_1"
	icon_keyboard = null
	icon_screen = null
	use_power = FALSE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	interaction_flags_machine = INTERACT_MACHINE_OFFLINE
	req_one_access = list(ACCESS_MANAGEMENT, ACCESS_ARMORY) // Heads of staff or the warden can go here to claim recover items from their department that people went were cryodormed with.
	verb_say = "coldly states"
	verb_ask = "queries"
	verb_exclaim = "alarms"

	/// Used for logging people entering cryosleep and important items they are carrying.
	var/list/frozen_crew = list()
	/// The items currently stored in the cryostasis control panel.
	var/list/frozen_item = list()

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/computer/cryostasis, 32)

/obj/machinery/computer/cryostasis/Initialize(mapload)
	. = ..()
	GLOB.cryopod_computers += src

/obj/machinery/computer/cryostasis/Destroy()
	GLOB.cryopod_computers -= src
	return ..()

/obj/machinery/computer/cryostasis/update_icon_state()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "cellconsole"
		return ..()
	icon_state = "cellconsole_1"
	return ..()

/obj/machinery/computer/cryostasis/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return

	add_fingerprint(user)

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CryopodConsole", name)
		ui.open()

/obj/machinery/computer/cryostasis/ui_data(mob/user)
	var/list/data = list()
	data["frozen_crew"] = frozen_crew

	/// The list of references to the stored items.
	var/list/item_ref_list = list()
	/// The associative list of the reference to an item and its name.
	var/list/item_ref_name = list()

	for(var/obj/item/item in frozen_item)
		var/ref = REF(item)
		item_ref_list += ref
		item_ref_name[ref] = item.name

	data["item_ref_list"] = item_ref_list
	data["item_ref_name"] = item_ref_name

	// Check Access for item dropping.
	var/item_retrieval_allowed = allowed(user)
	data["item_retrieval_allowed"] = item_retrieval_allowed

	var/obj/item/card/id/id_card
	if(isliving(user))
		var/mob/living/person = user
		id_card = person.get_idcard()
	if(id_card?.registered_name)
		data["account_name"] = id_card.registered_name

	return data

/obj/machinery/computer/cryostasis/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("item_get")
			// This is using references, kinda clever, not gonna lie. Good work Zephyr
			var/item_get = params["item_get"]
			var/obj/item/item = locate(item_get)
			if(item in frozen_item)
				item.forceMove(drop_location())
				frozen_item.Remove(item_get, item)
				visible_message("[src] dispenses \the [item].")
				message_admins("[item] was retrieved from cryostorage at [ADMIN_COORDJMP(src)]")
			else
				CRASH("Invalid REF# for ui_act. Not inside internal list!")
			return TRUE

		else
			CRASH("Illegal action for ui_act: '[action]'")

/obj/machinery/computer/cryostasis/proc/announce(message_type, mob/living/user, rank)
	var/obj/machinery/announcement_system/announcer = pick_safe(GLOB.announcement_systems)
	if(!announcer)
		return

	announcer.announce(message_type, user, rank, list())

	if(message_type != "CRYO_LEAVE")
		return

	var/is_command = user?.mind?.assigned_role.departments_bitflags & DEPARTMENT_BITFLAG_COMPANY_LEADER
	var/last_of_command = length(SSjob.get_all_heads())
	if(is_command && last_of_command <= 1)
		minor_announce(message = "Your station's last member of management has entered cryogenic storage. \
		Please make sure that the station's essential operational supplies are secured.")

/// Returns any items inside of the `items_to_send` list to a cryo console on station.
/obj/machinery/computer/cryostasis/proc/store_items(mob/target, list/items_to_send)
	var/list/held_contents = target.get_contents()
	if(!held_contents || !items_to_send)
		return FALSE

	var/obj/machinery/computer/cryostasis/target_console
	for(var/obj/machinery/computer/cryostasis/cryo_console in GLOB.cryopod_computers)
		target_console = cryo_console
		var/turf/target_turf = get_turf(target_console)
		if(is_station_level(target_turf.z)) //If we find a cryo console on station, send items to it first and foremost.
			break

	if(!target_console)
		return FALSE

	for(var/obj/item/found_item in held_contents)
		if(!is_type_in_list(found_item, items_to_send))
			continue
		target.transferItemToLoc(found_item, target_console, force = TRUE, silent = TRUE)
		target_console.frozen_item += found_item

	return TRUE
