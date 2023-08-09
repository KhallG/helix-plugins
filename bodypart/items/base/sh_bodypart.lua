ITEM.name = "Bodypart"
ITEM.desc = "A Bodypart Item Base."
ITEM.category = "Outfit"
ITEM.model = "models/props_c17/BriefCase001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "Head"
ITEM.outfitModel = "models/mossman.mdl"
ITEM.bodygroup = {{0, 0}}
ITEM.skin = 0
ITEM.replacement = false
ITEM.exclude = {}

-- Inventory drawing
if (CLIENT) then
	-- Draw camo if it is available.
	function ITEM:paintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:wearOutfit(client, isForLoadout)
	self.player:createBodypart(self.outfitCategory, self.outfitModel, self.bodygroup, self.skin, self.replacement, self.exclude)

	self:Call("onWear", client, nil, isForLoadout)
end

function ITEM:removeOutfit(client)
	local character = client:GetCharacter()

	self:SetData("equip", nil)

	client:resetBodypart(self.outfitCategory, false)

	self:Call("onTakeOff", client)
end



ITEM:Hook("drop", function(item)
	if (item:GetData("equip")) then
		item:removeOutfit(item.player)
	end
end)

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		local char = item.player:GetCharacter()
		local items = char:GetInventory():GetItems()

		for id, other in pairs(items) do
			if (
				item ~= other and
				item.outfitCategory == other.outfitCategory and
				other:GetData("equip")
			) then
				item.player:NotifyLocalized("Vous avez déja un ".. item.outfitCategory.." équipé.")
				return false
			end
		end

		item:SetData("equip", true)
		item:wearOutfit(item.player, false)

		return false
	end,
	OnCanRun = function(item)
		return not IsValid(item.entity) and item:GetData("equip") ~= true
	end
}

ITEM.functions.Unequip = {
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	OnRun = function(item)
		item:removeOutfit(item.player)
		return false
	end,
	OnCanRun = function(item)
		return not IsValid(item.entity) and item:GetData("equip") == true
	end
}

function ITEM:onCanBeTransfered(oldInventory, newInventory)
	if (newInventory and self:GetData("equip")) then
		return false
	end

	return true
end

function ITEM:onLoadout()
	if (self:GetData("equip")) then
		self:wearOutfit(self.player, true)
	end
end

function ITEM:onRemoved()
	local inv = ix.item.inventories[self.invID]
	if (IsValid(receiver) and receiver:IsPlayer()) then
		if (self:GetData("equip")) then
			self:removeOutfit(receiver)
		end
	end
end

function ITEM:onWear(isFirstTime)
end

function ITEM:onTakeOff()
end
