ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Probe Droid"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "ProbeDroid"; -- The unique name for the speeder.
ENT.EntModel = "models/starwars/syphadias/ships/probe_droid/probe_droid.mdl"; -- The path to your model
ENT.Allegiance = "Empire"
ENT.IsProbeDroid = true;

ENT.StartHealth = 1000; -- Starting Health

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("vehicle/probe_droid/probe_droid_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("probedroid");
	e:SetPos(tr.HitPos + Vector(0,0,25));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
	e:Spawn();
	e:Activate();
	e.Owner = pl;
	pl:Give("probe_remote");
	pl:SelectWeapon("probe_remote");
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*40+self:GetForward()*5; -- Position of the drivers seat
	local driverAng = self:GetAngles()+Angle(0,-90,0); -- The angle of the drivers seat
	self:SpawnChairs(driverPos,driverAng,false)
	
	self.ForwardSpeed = 150; --Your speed
	self.BoostSpeed = 215 -- Boost Speed
	self.AccelSpeed = 2; -- Acceleration
	self.WeaponLocations = {
		Main = self:GetPos()+self:GetRight()*0+self:GetUp()*63.5+self:GetForward()*22, -- Position of weapon
	}
	self:SpawnWeapons();
	self.HoverMod = 15; -- If you're vehicle keeps hitting the floor increase this	
	self.StartHover = 35; -- How high you are at flat ground
	self.StandbyHoverAmount = -10; -- How high the speeder is when no one is in it	
	self.Bullet = CreateBulletStructure(80,"red"); -- First number is damage, second is colour. red or green
	self.CanShoot = true;
	self.FireDelay = 0.5;
	self.SpeederClass = 2;
	self.CanBack = true;
	self.ChatterSounds = {
		Sound("vehicle/probe_droid/probe_droid_chat_1.wav"), 
		Sound("vehicle/probe_droid/probe_droid_chat_2.wav"), 
		Sound("vehicle/probe_droid/probe_droid_chat_3.wav"), 
		Sound("vehicle/probe_droid/probe_droid_chat_4.wav"), 
		Sound("vehicle/probe_droid/probe_droid_chat_5.wav"),
		Sound("vehicle/probe_droid/probe_droid_chat_6.wav"),
		Sound("vehicle/probe_droid/probe_droid_chat_7.wav")
	}
	timer.Create(self.Vehicle .. "ChatterTimer" .. self:EntIndex(), 18, 0, function()
		if(IsValid(self)) then
			local rand = math.random(1,7);
			self:EmitSound(self.ChatterSounds[rand],80,100,1);
		end
	end)

end

function ENT:SpawnPilot(pos)

	if(IsValid(self.Pilot) and !IsValid(self.PilotAvatar)) then
		local e = ents.Create("prop_physics");
		e:SetModel(self.Pilot:GetModel());
		e:SetPos(pos)
		e:SetAngles(self:GetAngles())
		e:Spawn();
		e:Activate();
		e.ProbeAvatar = true;
		local anim = "sit_rollercoaster";
		if(self.PilotAnim) then	
			anim = self.PilotAnim;
		end
		e:SetSequence(e:LookupSequence(anim));
		
		self.PilotAvatar = e;
		self:SetNWEntity("PilotAvatar",e);
		
		local phys = e:GetPhysicsObject();
		if(IsValid(phys)) then
			phys:Sleep();
			phys:EnableMotion(false);
			
		end
	end
end

ENT.StartTime = CurTime();
function ENT:Think()

	self.BaseClass.Think(self);
	if(IsValid(self.Pilot)) then
		if(self.Pilot:KeyDown(IN_WALK)) then
			if(!self.StartedDetonation) then
				self.StartedDetonation = true;
				self.StartTime = CurTime()+3;
			else
				if(self.StartTime <= CurTime()) then
					self:SelfDestruct();
				end
			end
		elseif(self.Pilot:KeyReleased(IN_WALK)) then
			self.StartedDetonation = false;
		end
	
	end
	
end

function ENT:SelfDestruct()

	self:Exit(true,false);
	self:Bang();
	for k,v in pairs(ents.FindInSphere(self:GetPos(),100)) do
		if(IsValid(v) and v != self) then
			v:TakeDamage(100);
		end
	end
end

function SWProbeAvatarPickup(p,e)
	if(IsValid(e) and e.ProbeAvatar) then
		return false;
	end
end
hook.Add( "PhysgunPickup", "SWProbeAvatarPickup", SWProbeAvatarPickup )

function ENT:Use(p)

	if(not self.Inflight) then
		self.PilotExit = p:GetPos();
		p.ProbeExit = p:GetPos();
		self:Enter(p,true);
	end

end

function ENT:Enter(p,driver)

	if(!self.Inflight) then
		self.BaseClass.Enter(self,p,driver);
		self.PilotAnim = "ACT_HL2MP_IDLE_PASSIVE";
		self:SpawnPilot(self.PilotExit);
		
	end
end

hook.Add("PlayerLeaveVehicle", "ProbeSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v:GetParent().IsProbeDroid) then
			local e = v:GetParent();
			p:SetPos(p.ProbeExit);
		end
	end
end);

function ENT:Exit(driver,kill)
	--if(driver) then
		if(IsValid(self.Pilot)) then
			self.Pilot:SetNetworkedBool("Flying"..self.Vehicle,false);
			self.Pilot:SetNetworkedEntity(self.Vehicle,NULL);
			self.Pilot:SetNWEntity("DriverSeat",NULL);
			
		--	if (kill) then self.Pilot:Kill(); end
			if(driver) then
				self.Pilot:ExitVehicle(self.DriverChair);
			end
			self.Pilot:SetPos(self.Pilot.ProbeExit);
		end

		self.Pilot = NULL;
		self:Rotorwash(false);
		self.Inflight = false;
		self:SetNWEntity(self.Vehicle,nil);
		self:SetNWBool("Flying" .. self.Vehicle,false);
		self.Accel.FWD = 0;
		
		if(IsValid(self.PilotAvatar)) then
			self.PilotAvatar:Remove();
		end
	--end
	self.NextUse.Use = CurTime() + 1;
end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	-- You need three positions for speeders. Front middle and back
	self.BackPos = self:GetPos()+self:GetForward()*-5+self:GetUp()*0; -- This is the back one
	self.FrontPos = self:GetPos()+self:GetForward()*5+self:GetUp()*0; -- Front one
	self.MiddlePos = self:GetPos()+self:GetUp()*0; -- Middle one
	-- If you don't set them very well, you're speeder won't fly very well
	if(self.Inflight) then
		local UP = ZAxis; -- Up direction. Leave
		self.RightDir = self.Entity:GetRight(); -- Which way is right, local to the model
		self.FWDDir = self.Entity:GetForward(); -- Forward Direction. Local to the model.	

		self.ExtraRoll = Angle(0,0,0); -- ignore
		
		/*
		This was pointless. You were literally doing nothing
		if(self.EngineOn) then
			if(self.Boosting) then
				self.num = self.BoostSpeed;
				util.ScreenShake(self.DriverChair:GetPos(),0,0,0,0)
			end
		end
		*/
	end
	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	
end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("vehicle/probe_droid/probe_droid_hover_loop.wav"),
	}
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("ProbeDroid", NULL) -- Set ProbeDroid to your unique name
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*-200+self:GetUp()*85;
					local face = self:GetAngles() + Angle(0,0,0);
					--local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end

		end
	end
	hook.Add("CalcView", "ProbeDroidView", CalcView) --/Make sure the middle string is unique

	
	hook.Add( "ShouldDrawLocalPlayer", "ProbeDroidDrawPlayerModel", function( p )
		local self = p:GetNWEntity("ProbeDroid", NULL); -- Set this to the unique name and ignore the rest
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return false;
				end
			end
		end
	end);
	
	function ProbeDroidReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingProbeDroid");-- Flying with your unique name
		local self = p:GetNWEntity("ProbeDroid"); -- Unique name
		if(Flying and IsValid(self)) then
			local WeaponsPos = {self:GetPos()};
			
			SW_Speeder_Reticles(self,WeaponsPos)
			SW_Speeder_DrawHull(1000)
			SW_Speeder_DrawSpeedometer()
		end
	end
	hook.Add("HUDPaint", "ProbeDroidReticle", ProbeDroidReticle) --Unique names again
	
	
end