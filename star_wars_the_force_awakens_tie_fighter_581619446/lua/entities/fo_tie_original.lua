ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "TIE Fighter (FO Legacy)"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: First Order"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/tie7/tie2.mdl"
ENT.Vehicle = "FOTieOriginal"

ENT.Allegiance = "First Order"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};
ENT.StartHealth = 3000;

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("fo_tie_original");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*150+self:GetUp()*137+self:GetRight()*-6,
		Left = self:GetPos()+self:GetForward()*150+self:GetUp()*137+self:GetRight()*-24,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2500; 
	self.ForwardSpeed = 1500;
	self.UpSpeed = 550; 
	self.AccelSpeed = 9;
	self.CanBack = true;
	
	self.CanShoot = true;
	self.CanStrafe = true;
	self.CanRoll = false;
	self.ExitModifier = {x=0,y=160,z=40};

	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	
	self.Bullet = CreateBulletStructure(80,"green");
	
	
	self.BaseClass.Initialize(self);
end

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles());
	end
end

end

if CLIENT then

	function ENT:Draw() self:DrawModel() end
	
	ENT.EnginePos = {}
	ENT.Sounds={
		--Engine=Sound("ambient/atmosphere/ambience_base.wav"),
		Engine=Sound("vehicles/tie/tie_fly3.wav"),
	}
	ENT.CanFPV = true;

	local Health = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWBool("Flying"..self.Vehicle);
		
		local IsDriver = p:GetNWEntity(self.Vehicle) == self.Entity;
		if(IsFlying and IsDriver) then
			Health = self:GetNWInt("Health");
		end		
	end

	--"ambient/atmosphere/ambience_base.wav"
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("FOTieOriginal", NULL)

		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*180+self:GetRight()*-15+self:GetForward()*35
			View = SWVehicleView(self,700,300,fpvPos);
			return View;
		end
	end
	hook.Add("CalcView", "FOTieOriginalView", CalcView)

	function FOTieOriginalReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingFOTieOriginal");
		local self = p:GetNWEntity("FOTieOriginal");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(3000);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "FOTieOriginalReticle", FOTieOriginalReticle)

end