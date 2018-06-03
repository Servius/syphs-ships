

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "Naboo Royal Starfighter"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/starwars/syphadias/ships/naboors.mdl"
ENT.Vehicle = "NabRS"
ENT.StartHealth = 4000;
ENT.Allegiance = "Republic"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("nabooroyal");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*685+self:GetUp()*140+self:GetRight()*-65,
		Right = self:GetPos()+self:GetForward()*685+self:GetUp()*140+self:GetRight()*65,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 3000;
	self.ForwardSpeed = 1500;
	self.UpSpeed = 550;
	self.AccelSpeed = 9;
	self.CanStandby = false;
	self.CanBack = true;
	self.CanRoll = true;
	self.Cooldown = 2;

	self.CanShoot = true;
	self.Bullet = CreateBulletStructure(125,"red");
	self.FireDelay = 0.40;
	self.AlternateFire = false;
	self.FireGroup = {"Left","Right",};
	
	self.ExitModifier = {x=300,y=150,z=50};
	
	--self:TestLoc(self:GetPos() + self:GetForward() * -375 + self:GetRight() * -260.75 + self:GetUp() * 123)
	
	self.BaseClass.Initialize(self);
	self:SpawnLandingGear();
end

function ENT:Think()

	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
			if(self.Pilot:KeyDown(IN_ATTACK2)) then
				local pos = self:GetPos()+self:GetForward()*220+self:GetUp()*60;
				--self:FireBlast(pos,false,8,600,false,20);
			end
		end
	end
	self.BaseClass.Think(self);
end

function ENT:Enter(p)
    self:RemoveLandingGear();
    self.BaseClass.Enter(self,p);
end
 
function ENT:Exit(kill)
    self.BaseClass.Exit(self,kill);
    if(self.TakeOff or self.Land) then
        self:SpawnLandingGear();
    end
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles());
	end
end

function ENT:SpawnLandingGear()
 
    local e = ents.Create("prop_physics");
    e:SetModel("models/starwars/syphadias/ships/naboors_landinggear.mdl")
    e:SetPos(self:GetPos()+self:GetUp()*-2.5);
    e:SetAngles(self:GetAngles());
    e:Spawn();
    e:Activate();
   
    local phys = e:GetPhysicsObject();
    phys:EnableGravity(false);
    phys:EnableDrag(false);
    phys:SetMass(self.Mass);
    constraint.Weld(self,e,0,0,0,true);
    self.LandingGear = e;
 
end

function ENT:RemoveLandingGear()
   
    if(IsValid(self.LandingGear)) then
        self.LandingGear:Remove();
    end
 
end
 
function ENT:OnRemove()
   
    self.BaseClass.OnRemove(self);
    if(IsValid(self.LandingGear)) then
        self.LandingGear:Remove();
    end
 
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("ambient/atmosphere/ambience_base.wav"),
	}
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("NabRS", NULL)
		if(IsValid(self)) then
			View = SWVehicleView(self,1250,300,fpvPos);		
			return View;
		end
	end
	hook.Add("CalcView", "NabRSView", CalcView)
	
	function ENT:Effects()
	
		self.ThrusterLocations = {
			self:GetPos() + self:GetForward() * -375 + self:GetRight() * -286.75 + self:GetUp() * 123,
			self:GetPos() + self:GetForward() * -375 + self:GetRight() * 238.75 + self:GetUp() * 123,
		}
		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.ThrusterLocations) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.2);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(50);
			heatwv:SetEndSize(20);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.1)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(100)
			blue:SetStartSize(50)
			blue:SetEndSize(15)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v+FWD*25;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 100;
			dynlight.G = 100;
			dynlight.B = 255;
			dynlight.DieTime = CurTime()+1;

		end
	end
	
	function ENT:Think()
	
		self.BaseClass.Think(self)
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		if(Flying) then
			if(!TakeOff and !Land) then
				self:Effects();
			end
		end
		
	end
	
	local HUD = surface.GetTextureID("vgui/tie_cockpit");
	function NabRSReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingNabRS");
		local self = p:GetNWEntity("NabRS");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(4000); -- Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "NabRSReticle", NabRSReticle)

end