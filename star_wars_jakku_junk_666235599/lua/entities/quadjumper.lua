--HOW TO PROPERLY MAKE AN ADDITIONAL SHIP ADDON OFF OF MINE.
 
--Do not copy everything out of my addon. You don't need it. Shall explain later.
 
--Leave this stuff the same
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base";
ENT.Type = "vehicle";
 
--Edit appropriatly. I'd prefer it if you left my name (Since I made the base, and this template)
ENT.PrintName = "Quadjumper";
ENT.Author = "Liam0102";
 
-- Leave the same
ENT.Category = "Star Wars Vehicles: Other"; -- Techincally you could change this, but personally I'd leave it so they're all in the same place (Looks more proffesional).
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminSpawnable = false;
ENT.AdminOnly = false; --Set to true for an Admin vehicle.
 
ENT.EntModel = "models/starwars/lordtrilobite/ships/quadjumper/quadjumper.mdl"; --The oath to the model you want to use.
ENT.Vehicle = "Quadjumper" --The internal name for the ship. It cannot be the same as a different ship.
ENT.StartHealth = 4500; --How much health they should have.
ENT.Allegiance = "Neutral"; -- Options are "Republic", "Rebels", "CIS", "Empire" and "Neutral"
list.Set("SWVehicles", ENT.PrintName, ENT);
    
if SERVER then
 
ENT.FireSound = Sound("weapons/template_shoot.wav"); -- The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; --Leave this alone for the most part.

 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("quadjumper"); -- This should be the same name as the file
	local spawn_height = 15; -- How high above the ground the vehicle spawns. Change if it's spawning too high, or spawning in the ground.
	
    e:SetPos(tr.HitPos + Vector(0,0,spawn_height));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
 
 
    self:SetNWInt("Health",self.StartHealth); -- Set the ship health, to the start health as made earlier
   
    --The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
    self.WeaponLocations = {
        Right = self:GetPos() + self:GetForward() * -30 + self:GetRight() * 432 + self:GetUp() * -17.25,
        TopRight = self:GetPos() + self:GetForward() * -30 + self:GetRight() * 432 + self:GetUp() * -17.25,
        TopLeft = self:GetPos() + self:GetForward() * -30 + self:GetRight() * -432 + self:GetUp() * -17.25,
        Left = self:GetPos() + self:GetForward() * -30 + self:GetRight() * -432 + self:GetUp() * -17.25,
    }
    self.WeaponsTable = {}; -- IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 2250; -- The speed we go when holding SHIFT
    self.ForwardSpeed = 1500; -- The forward speed 
    self.UpSpeed = 850; -- Up/Down Speed
    self.AccelSpeed = 8; -- How fast we get to our previously set speeds
    self.CanBack = true; -- Can we move backwards? Set to true if you want this.
	self.CanStrafe = true; -- Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.GearOpen = true;
	
	self.ExitModifier = {x=0;y=-300,z=10}

	self.HasLookaround = true;
	

	self.SeatPos = {
		self:GetPos()+self:GetUp()*227.5+self:GetForward()*157+self:GetRight()*-20,
		self:GetPos()+self:GetUp()*227.5+self:GetForward()*157+self:GetRight()*20,
	}
	self:SpawnSeats();
	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=200,z=220}
    self.BaseClass.Initialize(self); -- Ignore, needed to work
end

function ENT:Tractor()
	

	local min = self:GetPos()+self:GetForward()*160+self:GetRight()*250+self:GetUp()*50;
	local max = self:GetPos()+self:GetForward()*-200+self:GetRight()*-250+self:GetUp()*-130;
	for k,v in pairs(ents.FindInBox(min,max)) do
		local whitelisted = {
			"a-wing",
			"eta2",
			"delta",
			"delta7",
			"snowspeeder",
			"rey_speeder",
			"x-wing_tfa",
			"x-wing_poe",
			"speeder_bike",
			"landspeeder",
			"republic_speeder",
			"imp_speeder",
			"stap",
			"sith_speeder",
			"eta2y",
		}
		if(v != self and IsValid(v)) then
			if(v.IsSWVehicle) then
				for l,w in pairs(whitelisted) do
					if(v:GetClass() == w) then
						return v;
					end
				end
			else
				if(!IsValid(v:GetParent())) then
					return v;
				end	
			end	
		end	
	end
	return NULL;
end

function ENT:IHardlyKnowHer(grab)

	if(grab) then
		self.LeftSideObject = self:Tractor();
		if(IsValid(self.LeftSideObject)) then
			if(!IsValid(self.LeftSideObject:GetParent())) then
				self.LeftSideObject:SetParent(self);
				self.LeftSideObject.ShouldStandby = false;
				self.LeftSideObject.Land = false;
				self.LeftSideObject.TakeOff = false;
				self.LeftSideObject.Docked = true;
				self.LeftSideObject.Tractored = true;
				self.HoldingLeft = true;
				
			end
		end
	else
		if(IsValid(self.LeftSideObject)) then
			self.LeftSideObject:SetParent(NULL);
			self.LeftSideObject.ShouldStandby = true;
			self.LeftSideObject.Tractored = false;
			self.LeftSideObject.Docked = false;
			local phys = self.LeftSideObject:GetPhysicsObject();
			if(IsValid(phys)) then
				phys:Wake();
			end
		end
		self.HoldingLeft = false;
	end

end

function ENT:Think()

	self.BaseClass.Think(self);
	
	if(IsValid(self.LeftPassenger)) then
		local p = self.LeftPassenger;
		if(p:KeyDown(IN_ATTACK) and !self.HoldingLeft) then
			self:IHardlyKnowHer(true);
		elseif(p:KeyDown(IN_ATTACK2)) then
			self:IHardlyKnowHer(false);
		end
	end
end

function ENT:ToggleLandingGear()

	if(self.GearOpen) then
		self:SetBodygroup(1,1);
		self.GearOpen = false;
	else
		self:SetBodygroup(1,0);
		self.GearOpen = true;
	end
end

function ENT:Use(p)
	if(p == self.Pilot or p == self.LeftPassenger or p == self.RightPassenger) then return end;
	if(self.NextUse.Use < CurTime()) then
		if(not self.Inflight) then
			if(!p:KeyDown(IN_WALK)) then
				self:Enter(p);
			else
				for k,v in pairs(self.Seats) do
					if(v:GetPassenger(1) == NULL) then
						p:EnterVehicle(v);
						return
					end
				end
			end
		else
			for k,v in pairs(self.Seats) do
				if(v:GetPassenger(1) == NULL) then
					p:EnterVehicle(v);
					return
				end
			end
		end
	end

end

function ENT:Enter(p)

	if(not self.Inflight and (self.Land or self.TakeOff)) then
		if(self.GearOpen) then
			self:ToggleLandingGear();
		end
	end
	self.BaseClass.Enter(self,p);
end

function ENT:OnRemove()
	
	self:IHardlyKnowHer(false);

	self.BaseClass.OnRemove(self);
end

function ENT:Exit(kill)

	if(self.Inflight and IsValid(self.Pilot) and (self.Land or self.TakeOff)) then
		if(!self.GearOpen) then
			self:ToggleLandingGear();
		end
	end
	self.BaseClass.Exit(self,kill);
end
 
function ENT:SpawnSeats()
	self.Seats = {};
	for k,v in pairs(self.SeatPos) do
		local e = ents.Create("prop_vehicle_prisoner_pod");
		e:SetPos(v);
		e:SetAngles(self:GetAngles()+Angle(0,-90,0));
		e:SetParent(self);		
		e:SetModel("models/nova/airboat_seat.mdl");
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetColor(Color(255,255,255,0));	
		e:Spawn();
		e:Activate();
		e:SetUseType(USE_OFF);
		e:GetPhysicsObject():EnableMotion(false);
		e:GetPhysicsObject():EnableCollisions(false);
		e.IsQuadjumperSeat = true;
		e.Quadjumper = self;
		self.Seats[k] = e;
		if(k == 1) then
			e.LeftSeat = true;
		else
			e.RightSeat = true;
		end
	end
end

hook.Add("PlayerEnteredVehicle","QuadjumperSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsQuadjumperSeat) then
			p:SetNetworkedEntity("QuadjumperSeat",v);
			p:SetNetworkedEntity("Quadjumper",v:GetParent());
			p:SetNetworkedBool("QuadjumperPassenger",true);
			local self = v:GetParent();
			if(v.LeftSeat) then
				self.LeftPassenger = p;
			elseif(v.RightSeat) then
				self.RightPassenger = p;
			end
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "QuadjumperSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsQuadjumperSeat) then
			local e = v.Quadjumper;
			p:SetNetworkedEntity("QuadjumperSeat",NULL);
			p:SetNetworkedEntity("Quadjumper",NULL);
			p:SetNetworkedBool("QuadjumperPassenger",false);
			p:SetPos(e:GetPos()+e:GetForward()*-300+e:GetUp()*10);

			if(v.LeftSeat) then
				e.LeftPassenger = NULL;
			elseif(v.RightSeat) then
				e.RightPassenger = NULL;
			end
		end
	end
end); 

 
end
 
if CLIENT then

	ENT.CanFPV = true; -- Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
		Engine=Sound("vehicles/mf/mf_fly5.wav"),
    }

 	hook.Add("ScoreboardShow","QuadjumperScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingQuadjumper");
		if(Flying) then
			return false;
		end
	end)
	
	function ENT:Think()
	
		self.BaseClass.Think(self);
		
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.EnginePos = {
				self:GetPos()+self:GetForward()*-232+self:GetUp()*120+self:GetRight()*85,
				self:GetPos()+self:GetForward()*-232+self:GetUp()*120+self:GetRight()*-85,
				self:GetPos()+self:GetForward()*-232+self:GetUp()*250+self:GetRight()*-121,
				self:GetPos()+self:GetForward()*-232+self:GetUp()*250+self:GetRight()*121,
			}
			self:FlightEffects();
		end
	end
	
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();

		for k,v in pairs(self.EnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/orangecore1",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(FrameTime()*1.25)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(35)
			blue:SetEndSize(30)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096*k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 225;
			dynlight.B = 75;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end
	
    ENT.ViewDistance = 1000;
    ENT.ViewHeight = 300;
    ENT.FPVPos = Vector(201,0,240);

 	hook.Add( "ShouldDrawLocalPlayer", "QuadjumperDrawPlayerModel", function( p )
		local self = p:GetNWEntity("Quadjumper", NULL);
		local DriverSeat = p:GetNWEntity("QuadjumperSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
 
	local function QuadjumperReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingQuadjumper");
		local self = p:GetNWEntity("Quadjumper");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(4500);
		
			local pos = self:GetPos()+self:GetUp()*227.5+self:GetForward()*230
			local x,y = SW_XYIn3D(pos)
			SW_HUD_Compass(self,x,y); -- Draw the compass/radar
			SW_HUD_DrawSpeedometer(); -- Draw the speedometer
		end
	end
    hook.Add("HUDPaint", "QuadjumperReticle", QuadjumperReticle);
 
end
