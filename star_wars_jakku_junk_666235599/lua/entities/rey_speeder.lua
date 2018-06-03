ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Rey's Speeder"
ENT.Author = "Liam0102"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.Vehicle = "ReySpeeder"; -- The unique name for the speeder.
ENT.EntModel = "models/starwars/lordtrilobite/ships/reys_speeder/reys_speeder.mdl"; -- The path to your model
list.Set("SWVehicles", ENT.PrintName, ENT);

ENT.StartHealth = 1000;
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime(),Net=CurTime()};
ENT.FireSound = Sound("vehicles/speeder_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("rey_speeder");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*53+self:GetForward()*60;
	local driverAng = self:GetAngles()+Angle(0,90,-45);
	self.SeatClass = "phx_seat3"
	self:SpawnChairs(driverPos,driverAng,false)
	
	self.ForwardSpeed = -700;
	self.BoostSpeed = -1000
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.HoverMod = 3;
	self.StartHover = 55;
	self.StandbyHoverAmount = 50;
	self.CanShoot = false;

	self.ExitModifier = {x=55,y=30,z=0}

end

function ENT:InNetZone(p)

	local min = self:GetPos()+self:GetUp()*55+self:GetRight()*15;
	local max = self:GetPos()+self:GetUp()*15+self:GetRight()*85+self:GetForward()*-60;
	for k,v in pairs(ents.FindInBox(min,max)) do
		if(IsValid(v) and v:IsPlayer() and v == p) then
			return true;
		end
	end
	return false;
end

function ENT:Use(p)

	local open = self:InNetZone(p);
	if(open) then
		self:ToggleNet();
	else
		if(not self.Inflight) then
			if(self.NetOpen) then
				self:ToggleNet();
			end
			self:Enter(p,true);
		end
	end
	
end

ENT.NetEntities = {};
function ENT:ToggleNet()

	if(self.NextUse.Net < CurTime()) then
		if(self.NetOpen) then
			self:SetBodygroup(1,0);
			self.NetOpen = false;
			local min = self:GetPos()+self:GetUp()*55+self:GetRight()*5;
			local max = self:GetPos()+self:GetUp()*15+self:GetRight()*30+self:GetForward()*-60;
			for k,v in pairs(ents.FindInBox(min,max)) do
				if(IsValid(v) and v:GetClass() == "prop_physics") then
					if(v:GetParent() == NULL) then
						self.NetEntities[k] = v;
						v:SetParent(self);
					end
				end
			end
		else
			self:SetBodygroup(1,1);
			self.NetOpen = true;
			for k,v in pairs(self.NetEntities) do
				if(IsValid(v)) then
					v:SetParent(NULL);
					v:SetPos(v:GetPos()+self:GetRight()*30)
					
				end
			end
			table.Empty(self.NetEntities);
		end
		self.NextUse.Net = CurTime() + 1;
	end
	
end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetForward()*70+self:GetUp()*10;
	self.FrontPos = self:GetPos()+self:GetForward()*-80+self:GetUp()*10;
	self.MiddlePos = self:GetPos()+self:GetUp()*10;
	if(self.Inflight) then
		local UP = ZAxis;
		self.FWDDir = self.Entity:GetForward();
		self.RightDir = self.FWDDir:Cross(UP):GetNormalized()*-1;	
		

		self:RunTraces();

		self.ExtraRoll = Angle(0,0,self.YawAccel / 2);
		if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
			self.PitchMod = Angle(math.Clamp(-(self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/2,0,0)
		else
			self.PitchMod = Angle(math.Clamp((self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/2,0,0)
		end
	end
	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	

end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("vehicles/landspeeder/t47_fly2.wav"),
	}
	
	local Health = 0;
	local Speed = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			local EnginePos = {
				self:GetPos()+self:GetForward()*71+self:GetUp()*24.5,
				self:GetPos()+self:GetForward()*71+self:GetUp()*41,
			}
			self:Effects(EnginePos);
			Speed = self:GetNWInt("Speed");
		end
		
	end
	
	function ENT:Effects(pos)
	
		local p = LocalPlayer();
		local roll = math.Rand(-15,15);
		local normal = self.Entity:GetForward():GetNormalized();
		local id = self:EntIndex();
		for k,v in pairs(pos) do

			local blue = self.FXEmitter:Add("sprites/rey_sprite",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(FrameTime()*1.25)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(7)
			blue:SetEndSize(4)
			blue:SetRoll(roll)
			blue:SetColor(255,200,200)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 3;
			dynlight.Size = 80;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 100;
			dynlight.B = 100;
			dynlight.DieTime = CurTime()+1;

		end
	end
    ENT.HasCustomCalcView = true;
	local View = {}
	local function ReySpeederCalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("ReySpeeder", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		
		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-250+self:GetUp()*100;
					--local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					--local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end

		end
	end
	hook.Add("CalcView", "ReySpeederView", ReySpeederCalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "ReySpeederDrawPlayerModel", function( p )
		local self = p:GetNWEntity("ReySpeeder", NULL);
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	local function ReySpeederReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingReySpeeder");
		local self = p:GetNWEntity("ReySpeeder");
		if(Flying and IsValid(self)) then

			SW_Speeder_DrawHull(1000)
			SW_Speeder_DrawSpeedometer()

		end
	end
	hook.Add("HUDPaint", "ReySpeederReticle", ReySpeederReticle)
	
	
end