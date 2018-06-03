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

ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Type = "vehicle"
ENT.Base = "fighter_base"

ENT.PrintName = "Delta-7"
ENT.Author = "Liam0102"
ENT.Category = "Star Wars Vehicles: Republic"; -- Techincally you could change this, but personally I'd leave it so they're all in the same place (Looks more proffesional).
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/starwars/lordtrilobite/ships/delta7/delta7_landed.mdl"
ENT.FlyModel = "models/starwars/lordtrilobite/ships/delta7/delta7_flying.mdl"
ENT.Vehicle = "Delta-7"
ENT.StartHealth = 2250;
ENT.Allegiance = "Republic";
list.Set("SWVehicles", ENT.PrintName, ENT);
util.PrecacheModel("models/starwars/lordtrilobite/ships/delta7/delta7_flying.mdl")

if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),FireMode = CurTime(),Storage=CurTime(),};


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("delta-7");
	e:SetPos(tr.HitPos + Vector(0,0,5));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	
	self:SetNWInt("Health",self.StartHealth);
	self.CanRoll = true;
	self.CanBack = true;
	self.WeaponLocations = {
		Left = self:LocalToWorld(Vector(20,29,35));
        Right = self:LocalToWorld(Vector(20,-29,35));
	}
    self.Storage = false;
    self.StorageEnts = {};
	self.WeaponsTable = {};
	self.BoostSpeed = 2500;
	self.ForwardSpeed = 1750;
	self.UpSpeed = 500;
	self.AccelSpeed = 8;
	self.ExitModifier = {x=50,y=-50,z=42.5}
	self.CanShoot = true;
	self.DontOverheat = false;
	self.FireDelay = 0.15
	self.AlternateFire = true;
	self.FireGroup = {"Left","Right"}
	self.Bullet = CreateBulletStructure(100,"green");
	self.HasLightspeed = false;
    self.HasLookaround = true;
    self.PilotVisible = true;
	self.PilotPosition = {x=0,y=-120,z=25};
	self.PilotAnim = "drive_jeep";
    self.LandOffset = Vector(0,0,5);
	self.BaseClass.Initialize(self)
    self:SetBodygroup(1,1);
    self:InitLightspeed();
end
    
function ENT:Think()
    self.BaseClass.Think(self);
    if(self.Inflight and IsValid(self.Pilot)) then
        if(self.Pilot:KeyDown(IN_ATTACK2)) then
           self:ToggleStorage();     
        end
        if(!IsValid(self.Ring) and (!self.TakeOff and !self.Land)) then
            for k,v in pairs(ents.FindByClass("hyperspace_ring")) do
                if(IsValid(v) and v:InRing(self)) then
                    self.Ring = v;
                    v.Delta = self;
                    v.HasShip = true;
                    self:StartRingPair();
                end
            end
        elseif(IsValid(self.Ring)) then
            if(self.Pilot:KeyDown(IN_JUMP) and self.Pilot:KeyDown(IN_DUCK)) then
                self:StopVehicle();
                self.Ring:UnClamp();
            end
        end
    end
end

function ENT:StopVehicle()
    while(self.Accel.FWD > 0) do
        self.Accel.FWD = math.Approach(self.Accel.FWD,0,1);
    end
    for k,v in pairs(self.Accel) do
        self.Accel[k] = 0;
    end
    for k,v in pairs(self.Throttle) do
        self.Throttle[k] = 0;
    end
    self.Roll = 0;
end

function ENT:StartRingPair()
   
    self:StopVehicle();
    self.Ring:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE);
    self.Tractored = true;
    self.Ring:GetPhysicsObject():Wake();
    self:GetPhysicsObject():EnableMotion(false);
end
    
function ENT:Use(p)
    local min = self:LocalToWorld(Vector(-150,55,0));
    local max = self:LocalToWorld(Vector(-250,-55,30));
    for k,v in pairs(ents.FindInBox(min,max)) do
        if(p == v) then
            self:ToggleStorage();
            return;
        end
    end
    if(!self.Inflight) then
        self:Enter(p);
    end
        
end
            
function ENT:ToggleStorage()
    if(self.NextUse.Storage > CurTime()) then return end;
    local tooBig = false;
    if(self.Storage) then
        self:SetBodygroup(2,0);
        
        local min = self:LocalToWorld(Vector(-140,15,57.5));
        local max = self:LocalToWorld(Vector(-172.5,-15,47.5));
        for k,v in pairs(ents.FindInBox(min,max)) do
            if(!v:IsPlayer() and IsValid(v) and !IsValid(v:GetParent()) and v != self and v:IsSolid()) then
                local x,y = v:GetModelBounds();
                local n = y - x;
                if(n.x >= 32 or n.y >= 32 or n.z >= 32) then
                    tooBig = true;
                    break;
                end
                v:SetParent(self);
                self.StorageEnts[k] = v;
            end
        end
    else
        self:SetBodygroup(2,1);
        for k,v in pairs(self.StorageEnts) do
            if(IsValid(v)) then
                v:SetParent(NULL);
            end
        end
        self.StorageEnts = {};
    end
    self.Storage = !self.Storage;
    if(tooBig) then
        self:EmitSound("physics/metal/metal_solid_impact_hard4.wav",100,math.random(80,120));
        self:ToggleStorage();     
    end
    self.NextUse.Storage = CurTime() + 1;
    
end


function ENT:Enter(p)

	self:SetModel(self.FlyModel);
    self:PhysicsInit(6);
    self:SetBodygroup(1,0);
	self.BaseClass.Enter(self,p);

end

function ENT:Exit(kill)
    self.BaseClass.Exit(self,kill);
	self:SetBodygroup(1,1);
	if(self.TakeOff) then
		self:SetModel(self.EntModel);
        self:PhysicsInit(6);
    else
        if(IsValid(self.Ring)) then
            self:GetPhysicsObject():Sleep();
        end
	end		
end


end

if CLIENT then

	function ENT:Draw() self:DrawModel() end
	
	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicles/mf/mf_fly5.wav"),
	}
	
	local Health = 0;
	ENT.NextView = CurTime();
	ENT.CanFPV = true;
	function ENT:Think()
		self.BaseClass.Think(self);
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local IsFlying = p:GetNWBool("Flying"..self.Vehicle);
		local Wings = self:GetNWBool("Wings");
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		
		if(Flying) then
			if(!TakeOff and !Land) then
				self:FlightEffects();
			end
			Health = self:GetNWInt("Health");

		end
		
		
	end
	
    ENT.ViewDistance = 550;
    ENT.ViewHeight = 100;
    ENT.FPVPos = Vector(-110,0,62.5);
	
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();
		
		self.EnginePos = {
			self:LocalToWorld(Vector(-128.5,21,23));
            self:LocalToWorld(Vector(-128.5,-21,23));
		}
		for k,v in pairs(self.EnginePos) do
				
			local blue = self.FXEmitter:Add("sprites/orangecore1",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(FrameTime()*1.25)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(12)
			blue:SetEndSize(10)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v+FWD*-15;
			dynlight.Brightness = 4;
			dynlight.Size = 100;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 225;
			dynlight.B = 75;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end
	
	local HUD = surface.GetTextureID("vgui/falcon_cockpit")
	local Glass = surface.GetTextureID("models/props_c17/frostedglass_01a_dx60")
	hook.Add("HUDPaint", "Delta-7Reticle", function()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingDelta-7");
		local self = p:GetNWEntity("Delta-7");
		

		if(Flying and IsValid(self)) then

			local FPV = self:GetFPV();

			
			SW_HUD_DrawHull(self.StartHealth);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			local pos = self:LocalToWorld(Vector(-85,0,55));
            local x,y = SW_XYIn3D(pos);
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end)
	

end