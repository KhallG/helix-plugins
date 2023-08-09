function PLUGIN:OnLoaded()
	for _, bodypart in pairs(ix.bodypart.list) do
		for _, model in ipairs(bodypart.models) do
			util.PrecacheModel(model)
		end
	end
end

function PLUGIN:PlayerLoadedChar(client, character, lastChar)
	net.Start("ixLoadBodypart")
	net.WriteEntity(client)
	net.Broadcast()
end