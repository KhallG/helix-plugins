ix.bodypart = ix.bodypart or {}
ix.bodypart.list = ix.bodypart.list or {}

function ix.bodypart.LoadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		BODYPART = ix.bodypart.list[niceName] or {}
			ix.util.Include(directory.."/"..v)

			if (PLUGIN) then
				BODYPART.plugin = PLUGIN.uniqueID
			end

			BODYPART.name = BODYPART.name or "Unknown"
			BODYPART.default = BODYPART.default or {}
			BODYPART.models = BODYPART.models or {}

			if #BODYPART.default > 0 then
				for _, model in ipairs(BODYPART.default) do
					if not table.HasValue(BODYPART.models, model) then
						table.insert(BODYPART.models, model)
					end
				end
			end

			ix.bodypart.list[niceName] = BODYPART
		BODYPART = nil
	end
end

function ix.bodypart.get(name)
	for _, bodypart in pairs(ix.bodypart.list) do
		if ix.util.StringMatches(name, bodypart.name) then
			return bodypart
		end
	end
end

--[[-------------------------------------------------------------------------
playerMeta
---------------------------------------------------------------------------]]
local playerMeta = FindMetaTable("Player")

function playerMeta:getBodypartEntity(name)
	if not self:GetCharacter():GetBodypart()[name] then return end
	
	--[[
	for _, entity in ipairs(ents.FindByModel(self:getBodypart()[name])) do
		if entity:GetParent() == client then
			return entity
		end
	end
	--]]

	for _, child in ipairs(self:GetChildren()) do
		if child:GetClass() == "class C_PhysPropClientside" then
			if child:GetNetworkedString("name") == name then
				return child
			end
		end
	end
end


function playerMeta:removeBodyparts()
	for _, child in ipairs(self:GetChildren()) do
		if child:GetClass() == "class C_PhysPropClientside" then
			child:Remove()
		end
	end

	for i=0, self:GetBoneCount() - 1 do
		self:ManipulateBoneScale(i, Vector(1, 1, 1))
	end
end

function playerMeta:saveBodypart(name, model, bodygroup, skin, replace, exclude)
	bodygroup = bodygroup or {
		{0, 0}
	}
	skin = skin or 0

	replace = replace or false
	exclude = exclude or {}

	net.Start("ixSaveBodypart")
	net.WriteEntity(self)
	net.WriteString(ix.bodypart.get(name).name)
	net.WriteString(model)
	net.WriteTable(bodygroup)
	net.WriteInt(skin, 6)
	net.WriteBool(replace)
	net.WriteTable(exclude)
	net.SendToServer()
end

function playerMeta:createBodypart(name, model, bodygroup, skin, replace, exclude)
	bodygroup = bodygroup or {
		{0, 0}
	}
	skin = skin or 0
	if (CLIENT) then
		if not ix.bodypart.get(name) then return end

		if not table.HasValue(ix.bodypart.get(name).models, model) then
			Error("Error: Model ("..model..") does not exist in bodypart list ("..ix.bodypart.get(name).name..")\n")
		end

		local character = self:GetCharacter()

		-- Remove any pre-existing bodyparts
		if character:GetBodypart()[name] then
			self:resetBodypart(name)
		end

		for _, client in ipairs(player.GetAll()) do
			bodypart = ents.CreateClientProp()
			bodypart:SetModel(model)
			bodypart:SetPos(self:GetPos())
			bodypart:SetParent(self)
			bodypart:SetNetworkedString("name", name)

			for _, group in ipairs(bodygroup) do
				bodypart:SetBodygroup(group[1], group[2])
			end

			bodypart:SetSkin(skin)

			bodypart:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
			bodypart:Spawn()

			bodypart:SetupBones()

			if replace then
				for i=0, bodypart:GetBoneCount() - 1 do
					local bone = self:LookupBone(bodypart:GetBoneName(i))

					if exclude then
						if exclude[1] == "+" then
							if not table.HasValue(exclude, bodypart:GetBoneName(i)) then
								bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
								continue
							end
						else
							if table.HasValue(exclude, bodypart:GetBoneName(i)) then
								bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
								continue
							end
						end
					end

					if bone then
						self:ManipulateBoneScale(bone, Vector(0.1, 0.1, 0.1))
					end

					bodypart:ManipulateBoneScale(i, Vector(10, 10, 10))
				end
			end

			--[[
			if replace then
				for i=0, bodypart:GetBoneCount() - 1 do
					local bone = self:LookupBone(bodypart:GetBoneName(i))

					if exclude then
						if exclude[1] == "+" then
							if not table.HasValue(exclude, bodypart:GetBoneName(i)) then
								bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
								continue
							end
						else
							if table.HasValue(exclude, bodypart:GetBoneName(i)) then
								bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
								continue
							end
						end
					end

					if bone then
						self:ManipulateBoneScale(bone, Vector(0.1, 0.1, 0.1))
					end

					bodypart:ManipulateBoneScale(i, Vector(10, 10, 10))
				end
			end
			--]]
		end

		self:saveBodypart(ix.bodypart.get(name).name, model, bodygroup, skin, replace, exclude)
	else
		net.Start("ixCreateBodypart")
		net.WriteEntity(self)
		net.WriteString(name)
		net.WriteString(model)
		net.WriteTable(bodygroup)
		net.WriteInt(skin, 6)
		net.WriteBool(replace)
		net.WriteTable(exclude)
		net.Broadcast()
	end
end

function playerMeta:resetBodypart(name)
	if (CLIENT) then
		if not istable(self:GetCharacter():GetBodypart()[name]) then return end
		
		for _, client in ipairs(player.GetAll()) do
			if not self:GetCharacter():GetBodypart()[name]["default"] then
				if IsValid(client:getBodypartEntity(name)) then
					client:getBodypartEntity(name):Remove()
				end
			end

			if istable(self:GetCharacter():GetBodypart()[name]["exclude"]) then
				if #self:GetCharacter():GetBodypart()[name]["exclude"] > 0 then
					local exclude = self:GetCharacter():GetBodypart()[name]["exclude"]

					for i=0, self:GetBoneCount() - 1 do
						if exclude[1] == "+" then
							if not table.HasValue(exclude, self:GetBoneName(i)) then
								continue
							end
						elseif table.HasValue(exclude, self:GetBoneName(i)) then
							continue
						end

						self:ManipulateBoneScale(i, Vector(1, 1, 1)) 
					end
				end
			end

			self:saveBodypart(ix.bodypart.get(name).name, "")
		end
	else
		net.Start("ixResetBodypart")
		net.WriteEntity(self)
		net.WriteString(name)
		net.Broadcast()
	end
end

if (SERVER) then
	net.Receive("ixSaveBodypart", function()
		local client = net.ReadEntity()
		local name = net.ReadString()
		local model = net.ReadString()
		local bodygroup = net.ReadTable()
		local skin = net.ReadInt(6)
		local replace = net.ReadBool()
		local exclude = net.ReadTable()

		client:GetCharacter():SetBodypart(name, model, bodygroup, skin, replace, exclude)
	end)
else
	net.Receive("ixCreateBodypart", function()
		local client = net.ReadEntity()
		local name = net.ReadString()
		local model = net.ReadString()
		local bodygroup = net.ReadTable()
		local skin = net.ReadInt(6)
		local replace = net.ReadBool()
		local exclude = net.ReadTable()

		client:createBodypart(name, model, bodygroup, skin, replace, exclude)
	end)

	net.Receive("ixResetBodypart", function()
		local client = net.ReadEntity()
		local name = net.ReadString()

		client:resetBodypart(name)
	end)
end

hook.Add("DoPluginIncludes", "ixBodypartLib", function(path)
	ix.bodypart.LoadFromDir(path.."/bodypart")
end)