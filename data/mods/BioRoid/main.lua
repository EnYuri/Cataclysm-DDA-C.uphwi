
local MOD = {}

mods["BioRoid"] = MOD

function MOD.on_turn_passed()
    if BioRoid.callback then
        BioRoid.callback()
    end
end
