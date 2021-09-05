PAM.extension_handler = {}
PAM.extensions = {}
local extension_indices = {}
PAM_EXTENSION = {}

local function DisableExtension(extension)
	extension.enabled = false

	if not extension.OnDisable then return end

	extension:OnDisable()
end

local function EnableExtension(extension)
	extension.enabled = true

	if not extension.OnEnable then return end

	extension:OnEnable()
end

local function RegisterExtension(extension)
	local extension = PAM_EXTENSION

	-- cache name
	local extension_name = extension.name

	-- calculate id and set it
	local id = extension_indices[extension_name] or #PAM.extensions + 1
	extension.id = id

	-- Setting creation
	local enabled_setting = PAM.setting_namespace:AddChild(extension.name):AddSetting("enabled", pacoman.TYPE_BOOLEAN, extension.enabled)

	extension.enabled = enabled_setting:GetActiveValue()

	enabled_setting:AddCallback("extension handler", function(value)
		if value then
			EnableExtension(extension)
		end

		DisableExtension(extension)
	end)

	-- add extension to table of extensions
	PAM.extensions[id] = extension
	extension_indices[extension_name] = id

	if extension.Initialize then
		extension:Initialize()
	end

	print('[PAM] Registered extension "' .. extension_name .. '" ('.. (extension.enabled and "enabled" or "disabled") .. ")")
end

function PAM.extension_handler.RunEvent(event_name, ...)
	for i = 1, #PAM.extensions do
		local extension = PAM.extensions[i]

		if extension.enabled and extension[event_name] then
			extension[event_name](extension, ...)
		end
	end
end

function PAM.extension_handler.RunReturningEvent(event_name, ...)
	for i = 1, #PAM.extensions do
		local extension = PAM.extensions[i]

		if extension.enabled and extension[event_name] then
			local result = extension[event_name](extension, ...)

			if result then
				return result
			end
		end
	end
end

function PAM.extension_handler.RunAvalanchingEvent(event_name, combine, ...)
	local combined_result

	for i = 1, #PAM.extensions do
		local extension = PAM.extensions[i]

		if extension.enabled and extension[event_name] then
			local result = extension[event_name](extension, ...)
			combined_result = combined_result and combine(combined_result, result) or result
		end
	end

	return combined_result
end

hook.Add("Initialize", "PAM_Initialize_Extensions", function()
	PAM.extension_handler.RunEvent("OnInitialize")
end)

if SERVER then
	local sv_extensions, _ = file.Find("pam/server/extensions/*.lua", "LUA")
	local cl_extensions, _ = file.Find("pam/client/extensions/*.lua", "LUA")
	for i = 1, #sv_extensions do
		PAM_EXTENSION = {}
		include("pam/server/extensions/" .. sv_extensions[i])
		if PAM_EXTENSION.name then
			RegisterExtension()
		end
	end

	for i = 1, #cl_extensions do
		AddCSLuaFile("pam/client/extensions/" .. cl_extensions[i])
	end
else
	local cl_extensions, _ = file.Find("pam/client/extensions/*.lua", "LUA")
	for i = 1, #cl_extensions do
		PAM_EXTENSION = {}
		include("pam/client/extensions/" .. cl_extensions[i])
		if PAM_EXTENSION.name then
			RegisterExtension()
		end
	end
end

