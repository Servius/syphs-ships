ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "Nebulon-B Frigate"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Rebels"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = true;
ENT.EntModel = "models/mfrigate/medicalfrigate.mdl"
ENT.Vehicle = "MedFrig"
ENT.StartHealth = 8000;
ENT.Allegiance = "Rebels"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),LightSpeed=CurTime(),Switch=CurTime(),};
ENT.HyperDriveSound = Sound("vehicles/hyperdrive.mp3");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("medfrigate");
	e:SetPos(tr.HitPos + Vector(0,0,1200));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*125+self:GetUp()*75+self:GetRight()*-154,
		Right = self:GetPos()+self:GetForward()*125+self:GetUp()*75+self:GetRight()*160,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1500;
	self.ForwardSpeed = 500;
	self.UpSpeed = 400;
	self.AccelSpeed = 4;
	self.CanStandby = true;
	self.CanBack = true;
	self.CanRoll = false;
	self.CanStrafe = true;
	self.Cooldown = 2;
	self.CanShoot = false;
	self.Bullet = CreateBulletStructure(75,"green");
	self.FireDelay = 0.2;
	self.AlternateFire = false;
	self.FireGroup = {"Left","Right",};
	self.HasWings = false;
	self.WarpDestination = Vector(0,0,0);
	if(WireLib) then
		Wire_CreateInputs(self, { "Destination [VECTOR]", })
	else
		self.DistanceMode = true;
	end
	
	self.OGForward = 500;
	self.OGBoost = 1500;
	self.OGUp = 400;
	
	self.LandOffset = Vector(0,0,1500);
	self.LandDistance = 1000;
	//self.LandTracePos = self:GetPos()+self:GetUp()*-2000;

	self.ExitModifier = {x=0,y=-325,z=-1200};
	
	self.BaseClass.Initialize(self);
end

function ENT:Think()
	self.BaseClass.Think(self);
	if(self.Inflight) then
		self.LandTracePos = self:GetPos()+self:GetUp()*-2000;
		if(IsValid(self.Pilot)) then
		
			if(self.Pilot:KeyDown(IN_WALK) and self.NextUse.LightSpeed < CurTime()) then
				if(!self.LightSpeed and !self.HyperdriveDisabled) then
					self.LightSpeed = true;
					self.LightSpeedTimer = CurTime() + 3;
					self.NextUse.LightSpeed = CurTime() + 20;
					
				end
			end
			
			if(WireLib) then
				if(self.Pilot:KeyDown(IN_RELOAD) and self.NextUse.Switch < CurTime()) then
					if(!self.DistanceMode) then
						self.DistanceMode = true;
						self.Pilot:ChatPrint("LightSpeed Mode: Distance");
					else
						self.DistanceMode = false;
						self.Pilot:ChatPrint("LightSpeed Mode: Destination");
					end
					self.NextUse.Switch = CurTime() + 1;
				end
			end
			
		end
		if(self.LightSpeed) then
			if(self.DistanceMode) then
				self:PunchingIt(self:GetPos()+self:GetForward()*20000);
			else
				self:PunchingIt(self.WarpDestination);
			end
		end
	end
	for k,v in pairs(ents.FindInSphere(self:GetPos(),1500)) do
		if(self:IsStarWarsShip(v:GetClass()) and v != self) then
			local health = v:GetNWInt("Health");
			if(health < v.StartHealth) then
				v:SetNWInt("Health",health+1);
			end
		end
	end
end

function ENT:PunchingIt(Dest)
	if(!self.PunchIt) then
		if(self.LightSpeedTimer > CurTime()) then
			self.ForwardSpeed = 0;
			self.BoostSpeed = 0;
			self.UpSpeed = 0;
			self.Accel.FWD = 0;
			self:SetNWInt("LightSpeed",1);
			if(!self.PlayedSound) then
				self:EmitSound(self.HyperDriveSound,100);
				self.PlayedSound = true;
			end
			//util.ScreenShake(self:GetPos()+self:GetForward()*-730+self:GetUp()*195+self:GetRight()*3,5,5,10,5000)
		else
			self.Accel.FWD = 4000;
			self.LightSpeedWarp = CurTime()+0.5;
			self.PunchIt = true;
			self:SetNWInt("LightSpeed",2);
		end
	
	else
		if(self.LightSpeedWarp < CurTime()) then
			
			self.LightSpeed = false;
			self.PunchIt = false;
			self.ForwardSpeed = self.OGForward;
			self.BoostSpeed = self.OGBoost;
			self.UpSpeed = self.OGUp;
			self:SetNWInt("LightSpeed",0);
			local fx = EffectData()
				fx:SetOrigin(self:GetPos())
				fx:SetEntity(self)
			util.Effect("propspawn",fx)
			self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
			self:SetPos(Dest);
			self.PlayedSound = false;
		end
	end
end

function ENT:TriggerInput(k,v)
	if(k == "Destination") then
		self.WarpDestination = v;
	end
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
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("ambient/atmosphere/ambience_base.wav"),
	}
	
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();
		
		self.EnginePos = {
			self:GetPos()+self:GetUp()*482.5+self:GetForward()*-1780+self:GetRight()*160,
			self:GetPos()+self:GetUp()*603+self:GetForward()*-1780+self:GetRight()*217.5,
			self:GetPos()+self:GetUp()*603+self:GetForward()*-1780+self:GetRight()*132.5,
			
			self:GetPos()+self:GetUp()*482.5+self:GetForward()*-1780+self:GetRight()*-160,
			self:GetPos()+self:GetUp()*603+self:GetForward()*-1780+self:GetRight()*-215,
			self:GetPos()+self:GetUp()*603+self:GetForward()*-1780+self:GetRight()*-130,
			
			self:GetPos()+self:GetUp()*342.5+self:GetForward()*-1780+self:GetRight()*3.5,

		}
		for k,v in pairs(self.EnginePos) do
				
			local blue = self.FXEmitter:Add("sprites/bluecore",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.03)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(100)
			blue:SetStartSize(79)
			blue:SetEndSize(30)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 250;
			dynlight.Decay = 1024;
			dynlight.R = 100;
			dynlight.G = 100;
			dynlight.B = 255;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end
	
	local LightSpeed = 0;
	function ENT:Think()
		local Flying = self:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			self:FlightEffects();
			LightSpeed = self:GetNWInt("LightSpeed");
		end
		self.BaseClass.Think(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("MedFrig")
		local pos,face;
		if(IsValid(self)) then
			
			if(LightSpeed == 2) then
				pos = lastpos;
				face = lastang;
			else
				pos = self:GetPos()+self:GetUp()*700+LocalPlayer():GetAimVector():GetNormal()*-3000;			
				face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
			end
			
			lastpos = pos;
			lastang = face;

			View.origin = pos;
			View.angles = face;
			return View;
		end
	end
	hook.Add("CalcView", "MedFrigView", CalcView)
	
	function MedFrigReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingMedFrig");
		local self = p:GetNWEntity("MedFrig");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(8000); // Replace 1000 with the starthealth at the top
			//SW_WeaponReticles(self);
			//SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "MedFrigReticle", MedFrigReticle)

end