ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "XJ-2 Airspeeder"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "XJ2";
ENT.EntModel = "models/starwars/syphadias/ships/organa_xj2/organa_xj2.mdl";
ENT.StartHealth = 1000;
ENT.Allegiance = "Neutral"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("xj2");
	e:SetPos(tr.HitPos + Vector(0,0,5));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetUp()*90+self:GetForward()*200+self:GetRight()*180,
		Left = self:GetPos()+self:GetUp()*90+self:GetForward()*200+self:GetRight()*-180,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2250;
	self.ForwardSpeed = 1500;
	self.UpSpeed = 500;
	self.AccelSpeed = 9;
	self.CanBack = true;
	self.HasLookaround = true;
	self.CanShoot = false;
	self.CanStandby = true;
	self.CanStrafe = true;
	
	self.SeatPos = self:GetPos()+self:GetRight()*15+self:GetUp()*36.5+self:GetForward()*-12;
	
	self.ExitModifier = {x=-90,y=0,z=5};
	
	self:SpawnSeats();
	
	self.PilotVisible = true;
	self.PilotPosition = {x=-15.5,y=-26,z=35}
	self.PilotAnim = "drive_jeep"
	
	self.TraceFilter = {self,self.Seat}
	self.LandOffset = Vector(0,0,5)
	
	self.BaseClass.Initialize(self);
end

function ENT:SpawnSeats()

	local e = ents.Create("prop_vehicle_prisoner_pod");
	e:SetPos(self.SeatPos);
	e:SetAngles(self:GetAngles()+Angle(0,-90,18));
	e:SetParent(self);		
	e:SetModel("models/nova/airboat_seat.mdl");
	e:SetRenderMode(RENDERMODE_TRANSALPHA);
	e:SetColor(Color(255,255,255,0));	
	e:Spawn();
	e:Activate();
	e:GetPhysicsObject():EnableMotion(false);
	e:GetPhysicsObject():EnableCollisions(false);
	e.IsXJ2Seat = true;
	e.XJ2 = self;
	
	self.Seat = e;


end

function ENT:Enter(p)

	self.BaseClass.Enter(self,p);
	self.StartPos = self:GetPos();
	self.LandPos = self:GetPos()+Vector(0,0,10);
	
end

hook.Add("PlayerEnteredVehicle","XJ2SeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsXJ2Seat) then
			p:SetNetworkedEntity("XJ2Seat",v);
			p:SetNetworkedEntity("XJ2",v:GetParent());
			p:SetNetworkedBool("XJ2Passenger",true);
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "XJ2SeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsXJ2Seat) then
			local e = v.XJ2;
			p:SetNetworkedEntity("XJ2Seat",NULL);
			p:SetNetworkedEntity("XJ2",NULL);
			p:SetNetworkedBool("XJ2Passenger",false);
			p:SetPos(e:GetPos()+e:GetUp()*5+e:GetRight()*90);
		end
	end
end);

function ENT:Bang()

	local driver = self.Seat:GetPassenger(1);

	self.BaseClass.Bang(self);
	
	if(IsValid(driver)) then
		if(driver:IsPlayer()) then
			driver:Kill();
		end
	end
end

function ENT:Use(p)

	if(not self.Inflight and !p:KeyDown(IN_WALK)) then
		self:Enter(p);
	end
	if(self.Inflight and p != self.Pilot or p:KeyDown(IN_WALK)) then
		p:EnterVehicle(self.Seat);
	end
end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("vehicles/landspeeder/t47_fly2.wav"),
	}
	
	ENT.CanFPV = true;

	hook.Add("ScoreboardShow","XJ2ScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingXJ2");
		if(Flying) then
			return false;
		end
	end)
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingXJ2");
		local Sitting = p:GetNWBool("XJ2Passenger");
		local pos, face;
		
		
		if(Flying) then
			local self = p:GetNetworkedEntity("XJ2", NULL)
			if(IsValid(self)) then				
				local pos = self:GetPos()+self:GetRight()*-16+self:GetUp()*68+self:GetForward()*-18;
				View = SWVehicleView(self,350,100,pos,true)
				return View;
			end
		elseif(Sitting) then
			local v = p:GetNWEntity("XJ2Seat");
			local self = p:GetNWEntity("XJ2");
			if(IsValid(v) and IsValid(self)) then
				if(v:GetThirdPersonMode()) then
					local fpvPos = self:GetPos()+self:GetForward()*370+self:GetUp()*20+self:GetRight()*23;
					View = SWVehicleView(self,350,100,fpvPos)
					return View;
				end
			end
		end
		
	end
	hook.Add("CalcView", "XJ2View", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "XJ2DrawPlayerModel", function( p )
		local self = p:GetNWEntity("XJ2", NULL);
		local DriverSeat = p:GetNWEntity("XJ2Seat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	local function XJ2Reticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingXJ2");
		local self = p:GetNWEntity("XJ2");
		
		if(IsValid(self)) then
			SW_HUD_DrawHull(1000);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "XJ2Reticle", XJ2Reticle)
	
end