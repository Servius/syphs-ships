local Category = "Star Wars Vehicles"

local function PassiveStandAnimation( vehicle, player )
	return player:SelectWeightedSequence( ACT_HL2MP_IDLE ) 
end

local V = {
	Name = "Stand Seat for Krennic Shuttle",
	Model = "models/vehicles/prisoner_pod_inner.mdl",
	Class = "prop_vehicle_prisoner_pod",
	Category = Category,

	Author = "Syphadias, Liam0102",
	Information = "Seat for use in Krennic Shuttle",

	KeyValues = {
		vehiclescript = "scripts/vehicles/prisoner_pod.txt",
		limitview = "0"
	},
	Members = {
		HandleAnimation = PassiveStandAnimation,
	}
}
list.Set( "Vehicles", "krennic_seat", V )
