ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "AT-TE"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "ATTE"; 
ENT.EntModel = "models/starwars/syphadias/ships/AT-TE/AT-TE.mdl"; 


ENT.StartHealth = 15000; // Starting Health

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("atte");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*200+self:GetForward()*225+self:GetRight()*12; // Position of the drivers seat
	local driverAng = self:GetAngles()+Angle(0,-90,0); // The angle of the drivers seat
	self:SpawnChairs(driverPos,driverAng,false)
	
	self.ForwardSpeed = 100; //Your speed
	self.BoostSpeed = 150; // Boost Speed
	self.AccelSpeed = 3; // Acceleration
	self.WeaponLocations = {
		Main = self:GetPos()+self:GetRight()*100+self:GetUp()*15, // Position of weapon
	}
	self:SpawnWeapons(); //Remove if you don't want weapons
	self.HoverMod = 1; // If you're vehicle keeps hitting the floor increase this	
	self.StartHover = 15; // How high you are at flat ground
	self.StandbyHoverAmount = 15; // How high the speeder is when no one is in it	
	self.SpeederClass = 2;
	self.CanBack = true;
	self.Bullet = CreateBulletStructure(200,"green"); // First number is damage, second is colour. red or green
	self.TurretLocation = self:GetPos()+self:GetUp()*60+self:GetForward()*-300;
	self:SpawnTurret(self:GetAngles()+Angle(0,0,0));
	
    self.SeatPos = {
		{self:GetPos()+self:GetUp()*15+self:GetRight()*-19.5+self:GetForward()*-105,self:GetAngles()},
        {self:GetPos()+self:GetUp()*15+self:GetRight()*-19.5+self:GetForward()*-55,self:GetAngles()},
		{self:GetPos()+self:GetUp()*15+self:GetRight()*-19.5+self:GetForward()*-5,self:GetAngles()},
        {self:GetPos()+self:GetUp()*15+self:GetRight()*-19.5+self:GetForward()*45,self:GetAngles()},
        {self:GetPos()+self:GetUp()*15+self:GetRight()*-19.5+self:GetForward()*95,self:GetAngles()},
		
		{self:GetPos()+self:GetUp()*15+self:GetRight()*19.5+self:GetForward()*-105,self:GetAngles()},
        {self:GetPos()+self:GetUp()*15+self:GetRight()*19.5+self:GetForward()*-55,self:GetAngles()},
		{self:GetPos()+self:GetUp()*15+self:GetRight()*19.5+self:GetForward()*-5,self:GetAngles()},
		{self:GetPos()+self:GetUp()*15+self:GetRight()*19.5+self:GetForward()*45,self:GetAngles()},
        {self:GetPos()+self:GetUp()*15+self:GetRight()*19.5+self:GetForward()*95,self:GetAngles()},
    }
    self:SpawnSeats();

	self.ExitModifier = {x=13,y=175,z=5}
	
end

function ENT:SpawnSeats()
    self.Seats = {};
    for k,v in pairs(self.SeatPos) do
        local e = ents.Create("prop_vehicle_prisoner_pod");
        e:SetPos(v[1]);
        e:SetAngles(v[2]+Angle(0,-90,0));
        e:SetParent(self);     
        e:SetModel("models/nova/airboat_seat.mdl");
        e:SetRenderMode(RENDERMODE_TRANSALPHA);
        e:SetColor(Color(255,255,255,0));  
        e:Spawn();
        e:Activate();
        //e:SetVehicleClass("sypha_seat");
        e:SetUseType(USE_OFF);
        //e:GetPhysicsObject():EnableMotion(false);
        //e:GetPhysicsObject():EnableCollisions(false);
        e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        e.IsATTESeat = true;
        e.ATTE = self;
 
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
 
hook.Add("PlayerEnteredVehicle","ATTESeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsATTESeat) then
            p:SetNetworkedEntity("ATTE",v:GetParent());
            p:SetNetworkedEntity("ATTESeat",v);
			p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "ATTESeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsATTESeat) then
            local e = v.ATTE;
            if(IsValid(e)) then
                //p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
                //p:SetPos(e:GetPos()+e:GetUp()*110)
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("ATTESeat",NULL);
            p:SetNetworkedEntity("ATTE",NULL);
        end
    end
end);

//Leave
function ENT:FireWeapons()

	if(self.NextUse.Fire < CurTime()) then
		local e = self.Turret;
		local WeaponPos = {
			e:GetPos()+e:GetRight()*45+e:GetForward()*-110,
			e:GetPos()+e:GetRight()*-45+e:GetForward()*-110,
		}
		for k,v in pairs(WeaponPos) do
			local tr = util.TraceLine({
				start = self:GetPos(),
				endpos = self:GetPos() + self.Turret:GetForward()*-10000,
				filter = {self,self.Turret},
			})
			self.Bullet.Src		= v:GetPos();
			self.Bullet.Attacker = self.Pilot or self;	
			self.Bullet.Dir = self.Pilot:GetAimVector():Angle():Forward();

			v:FireBullets(self.Bullet)
		end
		self:EmitSound(self.FireSound, 120, math.random(90,110));
		self.NextUse.Fire = CurTime() + 0.3;
	end
end

function ENT:SpawnTurret(ang)
	
	local e = ents.Create("prop_physics");
	e:SetPos(self:GetPos()+self:GetUp()*280+self:GetForward()*100+self:GetRight()*12);
	e:SetAngles(ang);
	e:SetModel("models/starwars/syphadias/ships/AT-TE/AT-TE_turret.mdl");
	e:SetParent(self);
	e:Spawn();
	e:Activate();
	e:GetPhysicsObject():EnableCollisions(false);
	e:GetPhysicsObject():EnableMotion(false);
	self.Turret = e;
	self:SetNWEntity("Turret",e);
	
end

//Leave
function ENT:Think()

	if(self.Inflight) then
		
		if(IsValid(self.Pilot)) then
			self.Turret.LastAng = self.Turret:GetAngles();
			
			local aim = self.Pilot:GetAimVector():Angle();
			local p = aim.p*1;
			if(p <= 200 and p >= 100) then
				p = 200;
			elseif(p >= 150 and p <= 200) then
				p = 150;
			end
			self.Turret:SetAngles(Angle(p,aim.y+0,0));
			if(self.Pilot:KeyDown(IN_ATTACK)) then
				self:FireBlast(self.Turret:GetPos()+self.Turret:GetForward()*300,true,2,self.Turret:GetAngles():Forward());
			end
		end
		
	end
	self.BaseClass.Think(self)
end

function ENT:Exit(driver,kill)
	
	self.BaseClass.Exit(self,driver,kill);
	if(IsValid(self.Turret)) then
		self.Turret:SetAngles(self.Turret.LastAng);
	end
end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	// You need three positions for speeders. Front middle and back
	self.BackPos = self:GetPos()+self:GetRight()*-70+self:GetUp()*15; // This is the back one
	self.FrontPos = self:GetPos()+self:GetRight()*100+self:GetUp()*15; // Front one
	self.MiddlePos = self:GetPos()+self:GetUp()*15; // Middle one
	// If you don't set them very well, you're speeder won't fly very well
	if(self.Inflight) then
		local UP = ZAxis; // Up direction. Leave
		self.RightDir = self.Entity:GetRight(); // Which way is right, local to the model
		self.FWDDir = self.Entity:GetForward(); // Forward Direction. Local to the model.	
		

		
		self:RunTraces(); // Ignore

		self.ExtraRoll = Angle(0,0,self.YawAccel / 2*-.1); // ignore
		if(!self.WaterTrace.Hit) then
			if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
				self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/3*-1,0,0)
			else
				self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/3*-1,0,0)
			end
		end

	end
	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	

end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("ambient/atmosphere/ambience_base.wav"),
	}
	
	//Ignore
	local Health = 0;
	local Speed = 0;
	local Target;
	local Turret;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			Speed = self:GetNWInt("Speed");
			Target = self:GetNWVector("Target");
			Turret = self:GetNWEntity("Turret");
		end
		
	end
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
        local self = p:GetNWEntity("ATTE", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local ATTESeat = p:GetNWEntity("ATTESeat",NULL);
        local pass = p:GetNWEntity("ATTESeat",NULL);
        if(IsValid(self)) then
 
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*-1400+self:GetUp()*600;
					local face = self:GetAngles() + Angle(0,0,0);
					//local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
       
 
            if(IsValid(pass)) then
                if(ATTESeat:GetThirdPersonMode()) then
                    //local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-1000+self:GetUp()*600;
                    //local face = self:GetAngles() + Angle(0,-90,0);
                    //local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View =  SWVehicleView(self,1000,600,fpvPos);
                    return View;
					else
					//	View.origin = ATTESeat:GetPos()+ATTESeat:GetUp()*70;
					//	View.angles = ATTESeat:GetAngles()+p:EyeAngles();
					View =  SWVehicleView(self,1000,600,fpvPos);
					return View;
                end
            end
        end
    end
    hook.Add("CalcView", "ATTEView", CalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "ATTEDrawPlayerModel", function( p )
        local self = p:GetNWEntity("ATTE", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local ATTESeat = p:GetNWEntity("ATTESeat",NULL);
        local pass = p:GetNWEntity("ATTESeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(ATTESeat:GetThirdPersonMode()) then
                    return false;
                end
            end
        end
    end);
	
	function ATTEReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingATTE");// Flying with your unique name
		local self = p:GetNWEntity("ATTE"); // Unique name
		if(Flying and IsValid(self)) then		
			local WeaponsPos = {self:GetPos()};
			
			SW_Speeder_Reticles(self,WeaponsPos)
			SW_Speeder_DrawHull(15000)
			SW_Speeder_DrawSpeedometer()

		end
	end
	hook.Add("HUDPaint", "ATTEReticle", ATTEReticle) //Unique names again
	
	
end