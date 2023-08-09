PLUGIN.name = "Char Customization"
PLUGIN.author = "KhallG"
PLUGIN.desc = "Base character system for customizing your character."

ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")

if (SERVER) then
	util.AddNetworkString("ixSaveBodypart") -- Client -> Server
	util.AddNetworkString("ixLoadBodypart") -- Server -> Client
	util.AddNetworkString("ixCreateBodypart") -- Server -> Client
	util.AddNetworkString("ixResetBodypart") -- Server -> Client

	--nut.db.waitForTablesToLoad()
	--:next(function()
	--	nut.db.query("ALTER TABLE nut_characters ADD COLUMN _bodypart TEXT")
	--	:catch(function() end)
	--end)
end

ix.char.RegisterVar("bodypart", {
	field = "_bodypart",
	default = {},
	isLocal = true,
	index = 8,
	OnValidate = function(value, data, client)
		if (value != nil) then
			if (type(value) != "table") then
				return false, "unknownError"
			end
		end
	end,
	OnSet = function(character, key, model, bodygroup, skin, replace, exclude)
		if not ix.bodypart.get(key) then
			return false, "unknownError"
		end

		local client = character:GetPlayer()

		if table.HasValue(table.GetKeys(character:GetBodypart()), key) then
			if model == "" then
				model = character:GetBodypart()[key]["default"]
			end
		end

		bodypart = {}
		bodypart["model"] = model
		bodypart["bodygroup"] = bodygroup
		bodypart["skin"] = skin
		bodypart["replace"] = replace
		bodypart["exclude"] = exclude

		netstream.Start(player.GetAll(), "bodypartData", character:GetID(), key, bodypart)
	end,
	shouldDisplay = function(panel) return table.Count(ix.bodygroup.list) > 0 end
})

ix.command.Add("fixbodies", {
	adminOnly = true,
	OnRun = function(client, arguments)
		netstream.Start(player.GetAll(), "fixbodies")
	end
})

if (CLIENT) then
	netstream.Hook("bodypartData", function(id, key, value)
		local character = ix.char.loaded[id]

		if (character) then
			character.vars.bodypart = character.vars.bodypart or {}
			character:GetBodypart()[key] = value
		end
	end)

	netstream.Hook("fixbodies", function()
		for _, client in ipairs(player.GetAll()) do
			client:removeBodyparts()
		end
	end)
end