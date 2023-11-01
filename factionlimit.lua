local PLUGIN = PLUGIN

PLUGIN.name = "Faction Limit"
PLUGIN.author = "Khall"
PLUGIN.description = "Setup limit for factions like classes."
PLUGIN.readme = [[

To setup a limit in your faction just put :

FACTION.limit = 1 <--- Change the number to whatever number you want to be the max person in the faction

Finally it should look like this :


FACTION.name = "Test Faction"
FACTION.description = ""
FACTION.weapons = {}
FACTION.models = {"models/player/Group01/male_03.mdl"}
FACTION.limit = 1 <--------
FACTION.color = Color(131, 131, 131)
FACTION.isDefault = true 
FACTION_TEST = FACTION.index

]]

function PLUGIN:CanPlayerUseCharacter(client, character)
    local faction = ix.faction.Get(character:GetFaction())

    if (faction.limit and team.NumPlayers(faction.index) >= faction.limit) then
        return false, L("There is too much person in the faction "..faction.name, client, faction.name)
    end
end