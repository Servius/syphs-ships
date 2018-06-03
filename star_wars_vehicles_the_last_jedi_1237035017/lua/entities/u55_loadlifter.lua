ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "U-55 Load-Lifter"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Rebels"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/starwars/syphadias/ships/resistance_transport/resistance_transport.mdl"
ENT.Vehicle = "U55LoadLifter"
ENT.Allegiance = "Resistance";

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),Doors = CurTime(),};
ENT.StartHealth = 2000;

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("u55_loadlifter");
	e:SetPos(tr.HitPos + Vector(0,0,1));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*280+self:GetUp()*13+self:GetRight()*43,
		Left = self:GetPos()+self:GetForward()*280+self:GetUp()*13+self:GetRight()*-43,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 700;
	self.ForwardSpeed = 600;
	self.UpSpeed = 400;
	self.AccelSpeed = 5;
	self.CanBack = true;
	self.CanShoot = false;
	self.CanRoll = false;
	self.CanStrafe = true;
	self.CanStandby = true;
	
	self.MaxIonShots = 15;
	
	self.Bullet = CreateBulletStructure(70,"green");
	
	self.SeatPos = {
		//Glass Front LR
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-100+self:GetForward()*210, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*45+self:GetRight()*100+self:GetForward()*210, self:GetAngles()+Angle(0,-180,0)},
		//Glass Middle LR
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-122+self:GetForward()*105, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*45+self:GetRight()*122+self:GetForward()*105, self:GetAngles()+Angle(0,-180,0)},
		//Glass Back LR
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-122+self:GetForward()*5, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*45+self:GetRight()*122+self:GetForward()*5, self:GetAngles()+Angle(0,-180,0)},
		//Front LR
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-75+self:GetForward()*160, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*45+self:GetRight()*75+self:GetForward()*160, self:GetAngles()+Angle(0,-180,0)},
		//Back LR
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-75+self:GetForward()*55, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*45+self:GetRight()*75+self:GetForward()*55, self:GetAngles()+Angle(0,-180,0)},
		//Face Front
		{self:GetPos()+self:GetUp()*45+self:GetRight()*-60+self:GetForward()*230, self:GetAngles()+Angle(0,-90,0)},
	};
	
	self:SpawnSeats();
	self.ExitModifier = {x=92,y=320,z=75};

	self.PilotVisible = true;
	self.PilotPosition = {x=92,y=325,z=90};
	self.PilotAngle = Angle(-10,0,0);

	self.HasLookaround = true;
	self.BaseClass.Initialize(self);
end

function ENT:SpawnSeats()
   self.Seats = {};
   for k,v in pairs(self.SeatPos) do
       local e = ents.Create("prop_vehicle_prisoner_pod");
       e:SetPos(v[1]);
       e:SetAngles(v[2]+Angle(0,0,0));
       e:SetParent(self);    
       e:SetModel("models/nova/airboat_seat.mdl");
       e:SetRenderMode(RENDERMODE_TRANSALPHA);
       e:SetColor(Color(255,255,255,0));  
       e:Spawn();
       e:Activate();
       e:SetVehicleClass("sypha_seat");
       e:SetUseType(USE_OFF);
       e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
       //e:GetPhysicsObject():EnableCollisions(false); //Makes Players Get Stuck in nocollided seats.
       e.IsU55LoadLifterSeat = true;
       e.U55LoadLifter = self;
 
       self.Seats[k] = e;
   end
 
end
 
function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetPassenger(1) == NULL) then
			p:SetAllowWeaponsInVehicle( false )
			p:EnterVehicle(v);
			return;
		end
	end
end
 
function ENT:Use(p)
   if(not self.Inflight) then
       if(!p:KeyDown(IN_WALK)) then
           self:Enter(p);
       else
           self:Passenger(p);
       end
   else
       if(p != self.Pilot) then
           self:Passenger(p);
       end
   end
end
 
hook.Add("PlayerEnteredVehicle","U55LoadLifterSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsU55LoadLifterSeat) then
            p:SetNetworkedEntity("U55LoadLifter",v:GetParent());
            p:SetNetworkedEntity("U55LoadLifterSeat",v);
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "U55LoadLifterSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsU55LoadLifterSeat) then
            local e = v.U55LoadLifter;
            if(IsValid(e)) then
                //p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
                //p:SetPos(e:GetPos()+e:GetUp()*110)
				//p:SetPos(v:GetPos()+v:GetUp()*10+v:GetRight()*0+v:GetForward()*0)
				timer.Simple(0.1, function()
					if IsValid(p) and IsValid(v) then
						p:SetPos(v:GetPos()+v:GetUp()*10+v:GetRight()*0+v:GetForward()*0)
					end
				end)
                p:SetEyeAngles(e:GetAngles()+Angle(0,90,0))
            end
            p:SetNetworkedEntity("U55LoadLifterSeat",NULL);
            p:SetNetworkedEntity("U55LoadLifter",NULL);
        end
    end
end);

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles()+Angle(0,0,0));
	end
end

end

if CLIENT then

	ENT.EnginePos = {}
	ENT.Sounds={
		//Engine=Sound("ambient/atmosphere/ambience_base.wav"),
		Engine=Sound("vehicles/resistance_transport/lightcruiser_engine_loop.wav"),
	}
	ENT.CanFPV = true; // Set to true if you want FPV
    ENT.ViewDistance = 1150; //Distance from the Ship
    ENT.ViewHeight = 300; //Height above the ship 300
    ENT.FPVPos = Vector(325,-92,120); //Position relative to ship for first person view

	hook.Add("ScoreboardShow","U55LoadLifterScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingU55LoadLifter");
		if(Flying) then
			return false;
		end
	end)
	
	//"ambient/atmosphere/ambience_base.wav"
	local View = {}
    function U55LoadLifterCalcView()
       
        local p = LocalPlayer();
        local self = p:GetNWEntity("U55LoadLifter", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local U55LoadLifterSeat = p:GetNWEntity("U55LoadLifterSeat",NULL);
        local pass = p:GetNWEntity("U55LoadLifterSeat",NULL);
        local flying = p:GetNWBool("FlyingU55LoadLifter");
        if(U55LoadLifterSeat) then
            if(IsValid(pass)) then
                if(U55LoadLifterSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-500+self:GetUp()*50;
                    //local face = self:GetAngles() + Angle(0,-90,0);
                    local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
                        View.origin = pos;
                        View.angles = face;
                    return View;
					else
						View.origin = U55LoadLifterSeat:GetPos()+U55LoadLifterSeat:GetUp()*70.75;
						View.angles = U55LoadLifterSeat:GetAngles()+p:EyeAngles();
					return View;
                end
            end
        end
    end
    hook.Add("CalcView", "U55LoadLifterView", U55LoadLifterCalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "U55LoadLifterDrawPlayerModel", function( p )
        local self = p:GetNWEntity("U55LoadLifter", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local U55LoadLifterSeat = p:GetNWEntity("U55LoadLifterSeat",NULL);
        local pass = p:GetNWEntity("U55LoadLifterSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(U55LoadLifterSeat:GetThirdPersonMode()) then
                    return true;
                end
            end
        end
    end);
	
function ENT:Think()
	local p = LocalPlayer();
	local Flying = self:GetNWBool("Flying"..self.Vehicle);
	if(Flying) then
		self:Effects(); //Call the effects when the ship is flying.
	end
	self.BaseClass.Think(self);
end

function ENT:Effects()
	local normal = (self:GetForward() * -1):GetNormalized() // More or less the direction. You can leave this for the most part (If it's going the opposite way, then change it 1 not -1)
	local roll = math.Rand(-90,90) // Random roll so the effect isn't completely static (Useful for heatwave type)
	local p = LocalPlayer()	// Player (duh)
	local id = self:EntIndex(); //Need this later on.
	
	//Get the engine pos the same way you get weapon pos
	self.EnginePos1 = {
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*0,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*20,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*-20,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*40,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*-40,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*60,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*-60,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*80,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*-80,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*95,
		self:GetPos()+self:GetForward()*-570+self:GetUp()*142.5+self:GetRight()*-95,
	}
	
	for k,v in pairs(self.EnginePos1) do
		local red = self.FXEmitter:Add("sprites/bluecore",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal*-80) //Set direction we made earlier
		//red:SetDieTime(0.04) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetDieTime(FrameTime()*1.5)
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(100) // How visible it is at the end
		red:SetStartSize(40) // Start size. Just play around to find the right size.
		red:SetEndSize(40) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(255,255,255) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

		local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
		dynlight.Pos = v; // Position from the table
 		dynlight.Brightness = 4; // Brightness, Don't go above 10. It's blinding
		dynlight.Size = 100; // How far it reaches
		dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
		dynlight.R = 255; // Colour R
		dynlight.G = 255; // Colour G
		dynlight.B = 255; // Colour B
		dynlight.DieTime = CurTime()+1; // When the light should die

	end
end

	function U55LoadLifterReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingU55LoadLifter");
		local self = p:GetNWEntity("U55LoadLifter");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(2000);		
			
			local pos = self:GetPos()+self:GetForward()*350+self:GetUp()*110+self:GetRight()*91.3;
			local x,y = SW_XYIn3D(pos);
			
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "U55LoadLifterReticle", U55LoadLifterReticle)

end