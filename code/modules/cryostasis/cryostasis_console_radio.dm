/obj/machinery/computer/cryostasis/radio_enabled
	name = "radio-enabled cryostasis oversight console"
	/// This is what the announcement system uses to make announcements. Make sure to set a radio that has the channel you want to broadcast on.
	var/obj/item/radio/headset/radio = /obj/item/radio/headset/silicon/pai
	/// The channel to be broadcast on, valid values are the values of any of the "RADIO_CHANNEL_" defines.
	var/announcement_channel = null // RADIO_CHANNEL_COMMON doesn't work here.

/obj/machinery/computer/cryostasis/radio_enabled/Initialize(mapload)
	. = ..()
	radio = new radio(src)

/obj/machinery/computer/cryostasis/radio_enabled/Destroy()
	. = ..()
	GLOB.cryopod_computers -= src

/obj/machinery/computer/cryostasis/radio_enabled/announce(message_type, mob/living/user, rank)
	switch(message_type)
		if("CRYO_JOIN")
			radio.talk_into(src, "[user.real_name][rank ? ", [rank]" : ""] has woken up from cryo storage.", announcement_channel)
		if("CRYO_LEAVE")
			radio.talk_into(src, "[user.real_name][rank ? ", [rank]" : ""] has been moved to cryo storage.", announcement_channel)
