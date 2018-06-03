ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Yodas Hover Chair"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "YodaHChair"; 
ENT.EntModel = "models/starwars/syphadias/chairs/yoda_chair/yoda_hover_chair.mdl"; 
ENT.StartHealth = 1000; 

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("vehicles/speeder_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("yodahchair");
	e:SetPos(tr.HitPos + Vector(0,0,25));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*4+self:GetForward()*3.5; // Position of the drivers seat
	local driverAng = self:GetAngles()+Angle(0,90,0); // The angle of the drivers seat
	self:SpawnChairs(driverPos,driverAng,false)
	
	self.ForwardSpeed = -50; //Your speed
	self.BoostSpeed = -80 // Boost Speed
	self.AccelSpeed = 2; // Acceleration
	self.WeaponLocations = {
		Main = self:GetPos()+self:GetRight()*100+self:GetUp()*15, // Position of weapon
	}
	self.HoverMod = 50; // If you're vehicle keeps hitting the floor increase this	
	self.StartHover = 25; // How high you are at flat ground
	self.StandbyHoverAmount = -10; // How high the speeder is when no one is in it	
	self.Bullet = CreateBulletStructure(100,"red"); // First number is damage, second is colour. red or green
	
	self.SpeederClass = 2
	
	self.ExitModifier = {x=0,y=-50,z=0};

end

//function ENT:Enter(p)
//	self.BaseClass.Enter(self,p);
//	self:Rotorwash(false);
//end


//Leave
//function ENT:FireWeapons()
//
//	if(self.NextUse.Fire < CurTime()) then
//		for k,v in pairs(self.Weapons) do
//			self.Bullet.Src		= v:GetPos();
//			self.Bullet.Attacker = self.Pilot or self;	
//			self.Bullet.Dir = self.Pilot:GetAimVector():Angle():Forward();
//
//			v:FireBullets(self.Bullet)
//		end
//		self:EmitSound(self.FireSound, 120, math.random(90,110));
//		self.NextUse.Fire = CurTime() + 0.3;
//	end
//end

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles() + Angle(0,180,0));
	end
end

//Leave
function ENT:Think()

	if(self.Inflight) then
		
		if(IsValid(self.Pilot)) then
			self:Rotorwash(false);
		end
		
	end
	self.BaseClass.Think(self)
end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	// You need three positions for speeders. Front middle and back
	self.BackPos = self:GetPos()+self:GetForward()*5+self:GetUp()*0; // This is the back one
	self.FrontPos = self:GetPos()+self:GetForward()*-5+self:GetUp()*0; // Front one
	self.MiddlePos = self:GetPos()+self:GetUp()*0; // Middle one
	// If you don't set them very well, you're speeder won't fly very well
	if(self.Inflight) then
		local UP = ZAxis; // Up direction. Leave
		self.RightDir = self.Entity:GetRight(); // Which way is right, local to the model
		self.FWDDir = self.Entity:GetForward(); // Forward Direction. Local to the model.	
		

		
		self:RunTraces(); // Ignore

		self.ExtraRoll = Angle(1,0,0); // ignore

	end
	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	
end
end

if CLIENT then
	ENT.Sounds={
		Engine=Sound(""),
	}
	
	//Ignore
	local Health = 0;
	local Speed = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			Speed = self:GetNWInt("Speed");
		end
		
	end
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("YodaHChair", NULL) // Set YodaHChair to your unique name
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*150+self:GetUp()*40;
					local face = self:GetAngles() + Angle(0,180,0);
					//local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end

		end
	end
	hook.Add("CalcView", "YodaHChairView", CalcView) ///Make sure the middle string is unique

	
	hook.Add( "ShouldDrawLocalPlayer", "YodaHChairDrawPlayerModel", function( p )
		local self = p:GetNWEntity("YodaHChair", NULL); // Set this to the unique name and ignore the rest
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			elseif(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	function YodaHChairReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingYodaHChair");// Flying with your unique name
		local self = p:GetNWEntity("YodaHChair"); // Unique name
		if(Flying and IsValid(self)) then
			local WeaponsPos = self:GetPos()+self:GetRight()*100+self:GetUp()*15; // Position of your weapon
			SW_Speeder_DrawHull(1000)
			SW_Speeder_DrawSpeedometer()

		end
	end
	hook.Add("HUDPaint", "YodaHChairReticle", YodaHChairReticle) //Unique names again
	
	
end