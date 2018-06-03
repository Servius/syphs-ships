if(game.SinglePlayer()) then
    local addons = engine.GetAddons();
    local hasSWV = false;
    for k,v in pairs(addons) do
        if(v.wsid == "495762961") then
            hasSWV = true;
            break;
        end
    end
    if(!hasSWV) then return end;
end

ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Type = "vehicle"
ENT.Base = "base_anim"

ENT.PrintName = "Delta-7 (Random Skin)"
ENT.Author = "Liam0102"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

list.Set("SWVehicles", ENT.PrintName, ENT);

if SERVER then

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("delta-7_rand");
	e:SetPos(tr.HitPos + Vector(0,0,5));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
    e.Owner = pl;
	e:Spawn();
	e:Activate();
    
	return e;
end

function ENT:Initialize()
    local e = ents.Create("delta-7");
    e:SetPos(self:GetPos());
    e:SetAngles(self:GetAngles());
    e:Spawn();
    e:Activate();
	cleanup.Add(self.Owner, "vehicles", e)
    undo.Create( "Delta-7 (Random Skin)" )
        undo.AddEntity( e )
        undo.SetPlayer( self.Owner )
    undo.Finish()
    e:SetSkin(math.Round(math.random(0,10)));
    self:Remove();
end


end