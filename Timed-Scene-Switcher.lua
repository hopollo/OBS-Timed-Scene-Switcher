local obs           	= obslua
local source_name   	= ""
local destination_name	= ""
local total_seconds 	= 0

local cur_seconds   	= 0
local activated     	= false

local hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

-- Function to set the time text
function set_time_actions()
	print("set_time_action => Called")
	local seconds       = math.floor(cur_seconds % 60)
	local total_minutes = math.floor(cur_seconds / 60)
	local minutes       = math.floor(total_minutes % 60)
	local hours         = math.floor(total_minutes / 60)

	if cur_seconds < 1 then
		local scenes = obs.obs_frontend_get_scenes()
		if scenes ~= nil then
			for _, scene in ipairs(scenes) do
				local name = obs.obs_source_get_name(scene)
				if (name == destination_name) then
					obs.obs_frontend_set_current_scene(scene)
				end
			end
		end
	end
end

function timer_callback()
	print("timer_callback => called")
	cur_seconds = cur_seconds - 1
	if cur_seconds < 0 then
		obs.remove_current_callback()
		cur_seconds = 0
	end

	set_time_actions()
end

function activate(activating)
	print("activate => called")
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		cur_seconds = total_seconds
		set_time_actions()
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

function activate_signal(activating)
	print("activate_signal")
	local current_scene = obs.obs_frontend_get_current_scene()
	if current_scene ~= nil then
		local name = obs.obs_source_get_name(current_scene)
		if (name == source_name) then
			print('OK')
			activate(activating)
		end
	end
end

function source_activated(activating)
	print("souce_activated => called")
	activate_signal(true)
end

function source_deactivated(activating)
	print("souce_deactivated => called")
	activate_signal(false)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate_signal(true)
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "duration", "Duration (minutes)", 1, 100000, 1)

  	local p = obs.obs_properties_add_list(props, "source", "Starting Scene", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
  	local s = obs.obs_properties_add_list(props, "destination", "Scenes to switch to", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)


	local scenes = obs.obs_frontend_get_scene_names()
	if scenes ~= nil then
		for _, scene in ipairs(scenes) do
			 obs.obs_property_list_add_string(s, scene, scene)
			 obs.obs_property_list_add_string(p, scene, scene)
		end
	end

	obs.obs_properties_add_button(props, "reset_button", "Reset Timer", reset_button_clicked)

	return props
end

function script_description()
	return "Switch automaticly to specified scene after starting cooldown.\n\nMade by MLJWare, Mastermarkus, @HoPolloTV"
end

function script_update(settings)
	activate(false)

	total_seconds = obs.obs_data_get_int(settings, "duration") * 5
	source_name = obs.obs_data_get_string(settings, "source")
	destination_name = obs.obs_data_get_string(settings, "destination")

	reset(true)
end

function script_defaults(settings)
  	obs.obs_data_set_default_int(settings, "duration", 1)
end

function script_save(settings)
	print("script_save => called")
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

function script_load(settings)
	print("script_load => called")
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Reset Timer", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end