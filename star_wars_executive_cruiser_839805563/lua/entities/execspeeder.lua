ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Executive Cruiser"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "ExecSpeeder";
ENT.EntModel = "models/starwars/syphadias/ships/executive_cruiser/executive_cruiser.mdl";
ENT.StartHealth = 1500;

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("execspeeder");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+270,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.SeatClass = "phx_seat2";
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*25+self:GetRight()*35.5+self:GetForward()*-24;
	local driverAng = self:GetAngles();
	local passPos = self:GetPos()+self:GetUp()*25+self:GetRight()*35.5+self:GetForward()*23.75;
	self:SpawnChairs(driverPos,driverAng,true,passPos,driverAng);
	
	self.ForwardSpeed = -650;
	self.BoostSpeed = -1000
	self.AccelSpeed = 6;
	self.HoverMod = 3;
	self.CanBack = true;
	self.StartHover = 25;
	self.StandbyHoverAmount = 20;
	
    self.SeatPos = {
        {self:GetPos()+self:GetUp()*32+self:GetRight()*24+self:GetForward()*24,self:GetAngles()},
    }
    self:SpawnSeats();
	
	self.ExitModifier = {x=20,y=-115,z=20}

end

function ENT:SpawnSeats()
    self.Seats = {};
    for k,v in pairs(self.SeatPos) do
        local e = ents.Create("prop_vehicle_prisoner_pod");
        e:SetPos(v[1]);
        e:SetAngles(v[2]+Angle(0,0,15));
        e:SetParent(self);     
        e:SetModel("models/nova/airboat_seat.mdl");
        e:SetRenderMode(RENDERMODE_TRANSALPHA);
        e:SetColor(Color(255,255,255,0));  
        e:Spawn();
        e:Activate();
        //e:SetVehicleClass("");
        e:SetUseType(USE_OFF);
        //e:GetPhysicsObject():EnableMotion(false);
        //e:GetPhysicsObject():EnableCollisions(false);
        e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        e.IsPassengerSeat = true;
        e.ExecSpeeder = self;
 
        self.Seats[k] = e;
    end
 
end
 
function ENT:PassengerEnter(p)
    if(self.NextUse.Use > CurTime()) then return end;
    for k,v in pairs(self.Seats) do
        if(v:GetPassenger(1) == NULL) then
            p:EnterVehicle(v);
            return;        
        end
    end
end
 
function ENT:Use(p)
    if(not self.Inflight) then
        if(!p:KeyDown(IN_WALK)) then
            self:Enter(p,true);
        else
            self:PassengerEnter(p);
        end
    else
        if(p != self.Pilot) then
            self:PassengerEnter(p);
        end
    end
end
 
hook.Add("PlayerEnteredVehicle","PassengerSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsPassengerSeat) then
            p:SetNetworkedEntity("ExecSpeeder",v:GetParent());
            p:SetNetworkedEntity("PassengerSeat",v);
			p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "PassengerSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsPassengerSeat) then
            local e = v.ExecSpeeder;
            if(IsValid(e)) then
                //p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
                p:SetPos(e:GetPos()+e:GetForward()*115+e:GetRight()*11)
                p:SetEyeAngles(e:GetAngles()+Angle(0,90,0))
            end
            p:SetNetworkedEntity("PassengerSeat",NULL);
            p:SetNetworkedEntity("ExecSpeeder",NULL);
        end
    end
end);

function ENT:OnTakeDamage(dmg) --########## Shuttle's aren't invincible are they? @RononDex

	local health=self:GetNetworkedInt("Health")-(dmg:GetDamage()/2)

	self:SetNWInt("Health",health);
	
	if(health<100) then
		self.CriticalDamage = true;
		self:SetNWBool("CriticalDamage",true);
	end
	
	
	if((health)<=0) then
		self:Bang() -- Go boom
	end
end

local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetUp()*20+self:GetRight()*120+self:GetForward()*5;
	self.FrontPos = self:GetPos()+self:GetUp()*20+self:GetRight()*-120+self:GetForward()*5;
	self.MiddlePos = self:GetPos()+self:GetUp()*20+self:GetForward()*5;
	if(self.Inflight) then
		local UP = ZAxis;
		self.RightDir = self.Entity:GetForward();
		self.FWDDir = self.Entity:GetForward():Cross(UP):GetNormalized();	
		

		
		self:RunTraces();

		self.ExtraRoll = Angle(self.YawAccel / 2*-1,0,0);
		if(!self.WaterTrace.Hit) then
			if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
				self.PitchMod = Angle(0,0,math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/2*-1)
			else
				self.PitchMod = Angle(0,0,math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/2*-1)
			end
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
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			local EnginePos = {
				Left = 	self:GetPos()+self:GetRight()*125+self:GetForward()*-46+self:GetUp()*32.5,

				Right = self:GetPos()+self:GetRight()*125+self:GetForward()*46+self:GetUp()*32.5,
			}
			self:Effects(EnginePos,true);
		end
		
	end

		local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("ExecSpeeder", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-400+self:GetUp()*100;
					//local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					//local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
					else
						View.origin = DriverSeat:GetPos()+self:GetUp()*42+self:GetForward()*0+self:GetRight()*-5
						View.angles = face;
					return View;
				end
			elseif(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-400+self:GetUp()*100;
					//local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					//local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
					else
						View.origin = PassengerSeat:GetPos()+self:GetUp()*42+self:GetForward()*0+self:GetRight()*-5
						View.angles = face;
					return View;
				end
			end
		end
	end
	hook.Add("CalcView", "ExecSpeederView", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "ExecSpeederDrawPlayerModel", function( p )
		local self = p:GetNWEntity("ExecSpeeder", NULL);
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
	
	function ExecSpeederHUD()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingExecSpeeder");
		local self = p:GetNWEntity("ExecSpeeder");
		if(Flying and IsValid(self)) then

			SW_Speeder_DrawHull(1500)
			SW_Speeder_DrawSpeedometer()

		end
	end
	hook.Add("HUDPaint", "ExecSpeederHUD", ExecSpeederHUD)
	
end