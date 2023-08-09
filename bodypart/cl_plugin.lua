function PLUGIN:CreateClientsideRagdoll(target, ragdoll)
	for _, client in ipairs(player.GetAll()) do
		target:removeBodyparts()

		for name, data in pairs(target:GetCharacter():GetBodypart()) do
			local bodypart = ents.CreateClientProp()
			bodypart:SetModel(data["model"])
			bodypart:SetPos(ragdoll:GetPos())
			for _, bodygroup in ipairs(data["bodygroup"]) do
				bodypart:SetBodygroup(bodygroup[1], bodygroup[2])
			end
			bodypart:SetSkin(data["skin"])
			bodypart:SetParent(ragdoll)
			bodypart:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
			bodypart:Spawn()
		end

		ragdoll:CallOnRemove("removeBodyparts", function(ent)
			for _, bodypart in ipairs(ents.FindByClass("class C_PhysPropClientside")) do
				if not bodypart:GetParent():IsValid() then
					bodypart:Remove()
				end
			end
		end)
	end
end

function PLUGIN:OnCharInfoSetup(infoPanel)
	-- Get the model entity from the F1 menu.
	if (not IsValid(infoPanel.model)) then return end
	local mdl = infoPanel.model
	local ent = mdl.Entity
	local client = LocalPlayer()

	-- If the player is alive with a weapon, add a weapon model to the
	-- character model in the F1 menu.
	if (not IsValid(client) or not client:Alive()) then return end

	ent.bodypart = {}

	for _, bodypartInfo in pairs(client:GetCharacter():getBodypart()) do
		if bodypartInfo.model == "" then continue end

		local bodypart = ClientsideModel(bodypartInfo.model, RENDERGROUP_BOTH)
		bodypart:SetParent(ent)

		for _, group in ipairs(bodypartInfo.bodygroup) do
			bodypart:SetBodygroup(group[1], group[2])
		end

		bodypart:SetSkin(bodypartInfo.skin)

		bodypart:SetupBones()

		if bodypartInfo.replace then
			for i=0, bodypart:GetBoneCount() - 1 do
				local bone = ent:LookupBone(bodypart:GetBoneName(i))

				if bodypartInfo.exclude then
					if bodypartInfo.exclude[1] == "+" then
						if not table.HasValue(bodypartInfo.exclude, bodypart:GetBoneName(i)) then
							bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
							continue
						end
					else
						if table.HasValue(bodypartInfo.exclude, bodypart:GetBoneName(i)) then
							bodypart:ManipulateBoneScale(i, Vector(0.1, 0.1, 0.1))
							continue
						end
					end
				end

				if bone then
					ent:ManipulateBoneScale(bone, Vector(0.1, 0.1, 0.1))
				end

				bodypart:ManipulateBoneScale(i, Vector(10, 10, 10))
			end
		end

		bodypart:AddEffects(EF_BONEMERGE)
		bodypart:SetNoDraw(true)

		table.insert(ent.bodypart, bodypart)
	end
end

function PLUGIN:DrawixModelView(panel, ent)
	if #ent.bodypart > 0 then
		for _, bodypart in ipairs(ent.bodypart) do
			bodypart:DrawModel()
		end
	end
end

function PLUGIN:ConfigureCharacterCreationSteps(panel)
	panel:addStep(vgui.Create("ixCharacterBodypart"), 99)
end

hook.Add("PostPlayerDraw", "observeFixTest", function(client)
	if IsValid(client) then
		for _, bodypart in ipairs(client:GetChildren()) do
			bodypart:SetNoDraw(client:GetNoDraw())
		end
	end
end)

net.Receive("ixLoadBodypart", function()
	local target = net.ReadEntity()

	for _, client in ipairs(player.GetAll()) do
		if target == client then
			target:removeBodyparts()

			for name, data in pairs(target:GetCharacter():getBodypart()) do
				target:createBodypart(name, data["model"], data["bodygroup"], data["skin"], data["replace"], data["exclude"])
			end
		end
	end
end)