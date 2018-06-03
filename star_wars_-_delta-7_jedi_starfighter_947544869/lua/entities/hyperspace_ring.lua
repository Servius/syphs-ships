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
ENT.Base = "base_anim"
ENT.Type = "vehicle"

ENT.PrintName = "Hyperspace Ring"
ENT.Author = "Liam0102"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
list.Set("SWVehicles", ENT.PrintName, ENT);

if SERVER then
    
AddCSLuaFile();
    
function ENT:SpawnFunction(p,tr,c)
    local e = ents.Create(c);
    e:SetPos(tr.HitPos + Vector(0,0,350));
    e:SetAngles(p:GetAngles());
    e:Spawn();
    e:Activate();
    return e;
end
    
function ENT:Initialize()
   
    self:SetModel("models/starwars/lordtrilobite/ships/delta7/hyperspacering.mdl");
	self:PhysicsInit(SOLID_VPHYSICS);
	self:SetMoveType(MOVETYPE_VPHYSICS);
	self:SetSolid(SOLID_VPHYSICS);
	self:SetUseType(SIMPLE_USE);
	self:SetRenderMode(RENDERMODE_TRANSALPHA);
    self.Clamped = false;
	self:StartMotionController()
	self.ShadowParams = {
        maxangular = 5000,
        maxangulardamp = 10000,
        maxspeed = 1000000,
        maxspeeddamp = 10000,
        dampfactor = 0.8,
        secondstoarrive = 0.5,
        teleportdistance = 1000,
    }
    self.NextClamp = CurTime();
	local phys = self:GetPhysicsObject();
	if(phys:IsValid()) then
        phys:EnableMotion(true);
		phys:Wake();
	end
end

function ENT:InBounds(e)
    local min,max = self:GetModelBounds();
    min = self:LocalToWorld(min);
    max = self:LocalToWorld(max);       
    for k,v in pairs(ents.FindInBox(min,max)) do
        if(e == v) then
            return true;
        end
    end
    return false;
end
    
function ENT:InRing(e)
    if(self.NextClamp > CurTime()) then return end;
    local ang = math.abs(self:WorldToLocalAngles(e:GetAngles()).y);
    if(self:InBounds(e) and self:WorldToLocal(e:GetPos()).z <= -15 and ang <= 30) then
        return true;  
    end
    return false;
end
    
function ENT:OnRemove()
   self:UnClamp();     
end

function ENT:Clamp()
   
    self.Clamped = true;
    self:SetParent(self.Delta);
    self:SetBodygroup(1,1);
    local e = self.Delta;
    e.HasLightspeed = true;
    e.CanShoot = false;
    e.CanRoll = false;
    e.CanStrafe = true;
    e.Tractored = false;
    e:GetPhysicsObject():EnableMotion(true);
    e:GetPhysicsObject():Wake();
    e.PreventLand = true;
    
	e.BoostSpeed = 2750;
	e.ForwardSpeed = 2000;
	e.UpSpeed = 400;
        
    self:SetNWBool("Flying",true);
    self.NextClamp = CurTime() + 10;

end
    
function ENT:UnClamp()
   
    local e = self.Delta;
    if(IsValid(e)) then
        e.HasLightspeed = false;
        e.CanShoot = true;
        e.CanRoll = true;
        e.CanStrafe = false;
        e.PreventLand = false;
        e.Ring = NULL;
        e.BoostSpeed = e.OGBoost;
        e.ForwardSpeed = e.OGForward;
        e.UpSpeed = e.OGUp;
    end
    self:SetNWBool("Flying",false);
    self.Clamped = false;
    self:SetBodygroup(1,0);
    self.HasShip = false;
    self:SetParent(NULL);
    self.Delta = NULL;
    self:GetPhysicsObject():AddVelocity(self:GetForward()*100000);
    self.NextClamp = CurTime() + 10;
    self.UnClamping = true;
    self.UnClampPos = self:GetPos() + self:GetForward()*500 + self:GetUp() * 50;
    self.UnClampAng = self:GetAngles();
    timer.Simple(3, function()
        if(IsValid(self)) then
           self:SetCollisionGroup(COLLISION_GROUP_NONE);         
        end
    end)
end

function ENT:PhysicsSimulate(phys, deltatime)
    if(self.Clamped) then return end;
    if(self.HasShip) then
        if(self.NextClamp > CurTime()) then return end;
        phys:Wake();
        if(!self.Clamped) then
            local pos = self.Delta:GetPos();
            self.ShadowParams.pos = pos;
            self.ShadowParams.angle = self.Delta:GetAngles();
            self.ShadowParams.deltatime = deltatime;

            phys:ComputeShadowControl( self.ShadowParams )
            
            if(self:GetPos() == pos or (pos - self:GetPos()):Length() <= 1) then
                self:Clamp();
            end
        end
    else
        phys:Wake();
        if(self.UnClamping) then
            self.ShadowParams.pos = self.UnClampPos;
            self.ShadowParams.angle = self.UnClampAng;
            if(self:GetPos() == self.UnClampPos or (self.UnClampPos - self:GetPos()):Length() <= 1) then
                self.UnClamping = false;
            end
        else               
            self.ShadowParams.pos = self:GetPos()+Vector(0,0,1);
            self.ShadowParams.angle = Angle(0,self:GetAngles().y,0);
        end
        self.ShadowParams.deltatime = deltatime;

        phys:ComputeShadowControl( self.ShadowParams )
    end
    
end
    
end

if CLIENT then
    function ENT:Initialize()
       self.FXEmitter = ParticleEmitter(self:GetPos()); 
    end
	function ENT:Think()
        local Flying = self:GetNWBool("Flying");
		if(Flying) then
            self:FlightEffects();
		end
	end
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();
		
		self.EnginePos = {
			self:LocalToWorld(Vector(-49,146.5,29)),
			self:LocalToWorld(Vector(-49,-146.5,29)),
		}
		for k,v in pairs(self.EnginePos) do
				
			local blue = self.FXEmitter:Add("sprites/orangecore1",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(FrameTime()*1.25)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(32.5)
			blue:SetEndSize(32.5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 250;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 225;
			dynlight.B = 75;
			dynlight.DieTime = CurTime()+1;
		end
	end
        
end