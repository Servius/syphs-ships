ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "Imperial Dropship"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/starwars/syphadias/ships/imperial_dropship/imperial_dropship_open.mdl"
ENT.Vehicle = "ImpDropShip"
ENT.Allegiance = "Empire";

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),Doors = CurTime(),};
ENT.StartHealth = 5000;

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("impdropship");
	e:SetPos(tr.HitPos + Vector(0,0,10));
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
	self.BoostSpeed = 1750;
	self.ForwardSpeed = 1000;
	self.UpSpeed = 500;
	self.AccelSpeed = 7;
	self.CanBack = true;
	self.CanShoot = true;
	self.CanStrafe = true;
	self.CanStandby = false;
	self.HasWings = false;
	self.AlternateFire = true;
	self.FireGroup = {"Right","Left"}
	
	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	self.MaxIonShots = 25;
	
	self.Bullet = CreateBulletStructure(70,"green");
	
	self.SeatPos = {
	
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*-22.5+self:GetForward()*15, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*23.5+self:GetForward()*15, self:GetAngles()+Angle(0,-180,0)},
		
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*-22.5+self:GetForward()*-15, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*23.5+self:GetForward()*-15, self:GetAngles()+Angle(0,-180,0)},
		
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*-22.5+self:GetForward()*-45, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*23.5+self:GetForward()*-45, self:GetAngles()+Angle(0,-180,0)},
		
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*-22.5+self:GetForward()*-75, self:GetAngles()+Angle(0,0,0)},
		{self:GetPos()+self:GetUp()*13.75+self:GetRight()*23.5+self:GetForward()*-75, self:GetAngles()+Angle(0,-180,0)},
	};
	
	self.NextBlast = 1;
	
	self.ClosedModel = "models/starwars/syphadias/ships/imperial_dropship/imperial_dropship_closed.mdl"
	self.OpenModel = "models/starwars/syphadias/ships/imperial_dropship/imperial_dropship_open.mdl"
	self:SetNWBool("Doors",true);
	
	self:SpawnSeats();
	self.ExitModifier = {x=0,y=20,z=20};

	self.PilotVisible = false;
	self.PilotPosition = {x=0,y=80,z=50};

	self.HasLookaround = false;
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
       e.IsImpDropShipSeat = true;
       e.ImpDropShip = self;
 
       self.Seats[k] = e;
   end
 
end
 
function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetPassenger(1) == NULL) then
			p:EnterVehicle(v);
			p:SetAllowWeaponsInVehicle( true )
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
 
hook.Add("PlayerEnteredVehicle","ImpDropShipSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsImpDropShipSeat) then
            p:SetNetworkedEntity("ImpDropShip",v:GetParent());
            p:SetNetworkedEntity("ImpDropShipSeat",v);
			p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "ImpDropShipSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsImpDropShipSeat) then
            local e = v.ImpDropShip;
            if(IsValid(e)) then
                //p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
                //p:SetPos(e:GetPos()+e:GetUp()*110)
				p:SetPos(v:GetPos()+v:GetUp()*10+v:GetRight()*0+v:GetForward()*0)
                p:SetEyeAngles(e:GetAngles()+Angle(0,90,0))
            end
            p:SetNetworkedEntity("ImpDropShipSeat",NULL);
            p:SetNetworkedEntity("ImpDropShip",NULL);
			p:SetAllowWeaponsInVehicle( false )			
        end
    end
end);
  
function ENT:ToggleDoor()
   if(self.Wings) then
       self:SetModel(self.OpenModel);
       self.Wings = false;
       else
       self:SetModel(self.ClosedModel);
       self.Wings = true;
   end
   self.NextUse.Wings = CurTime() + 1;
   self:SetNWBool("Doors",self.Wings);
   self:EmitSound(Sound("vehicles/impdropship/impdropship_door.wav"),50,100,1);
end

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles()+Angle(0,180,0));
	end
end

function ENT:Think()

	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
			if(self.Pilot:KeyDown(IN_WALK) and self.NextUse.Wings < CurTime()) then
				self:ToggleDoor();
			end
		end
	end	

    if(self.Inflight) then
        //self.AccelSpeed = math.Approach(self.AccelSpeed,7,0.2);
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30,
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30,
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*30, 
						self:GetPos()+self:GetForward()*240+self:GetUp()*13+self:GetRight()*-30,
                    } //Table of the positions from which to fire
                    self:FireImpDropshipBlast(self.BlastPositions[self.NextBlast], false, 100, 100, true, 8, Sound("weapons/n1_cannon.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 15) then
						self.NextUse.FireBlast = CurTime()+10;
						self:SetNWBool("OutOfMissiles",true);
						self:SetNWInt("FireBlast",self.NextUse.FireBlast)
						self.NextBlast = 1;
					end
					
					
                end
			end
		end
		
		if(self.NextUse.FireBlast < CurTime()) then
			self:SetNWBool("OutOfMissiles",false);
		end
        self:SetNWInt("Overheat",self.Overheat);
        self:SetNWBool("Overheated",self.Overheated);
        self.ExitPos = self:GetPos()+self:GetForward()*15+self:GetUp()*190
    end
    self.BaseClass.Think(self);
end

function ENT:FireImpDropshipBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("cannon_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = size or 20;
	e.EndSize = size*0.75 or 15;
	
	local sound = snd or Sound("weapons/n1_cannon.wav");
	
	e:SetPos(pos);
	e:Spawn();
	e:Activate();
	e:Prepare(self,sound,gravity,vel);
	e:SetColor(Color(255,255,255,1));
	
end

end

if CLIENT then

	ENT.EnginePos = {}
	ENT.Sounds={
		//Engine=Sound("ambient/atmosphere/ambience_base.wav"),
		Engine=Sound("vehicles/laat/laat_fly2.wav"),
	}
	ENT.CanFPV = false;

	hook.Add("ScoreboardShow","ImpDropShipScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingImpDropShip");
		if(Flying) then
			return false;
		end
	end)
	
	//"ambient/atmosphere/ambience_base.wav"
	local View = {}
    function ImpDropShipCalcView()
       
        local p = LocalPlayer();
        local self = p:GetNWEntity("ImpDropShip", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local ImpDropShipSeat = p:GetNWEntity("ImpDropShipSeat",NULL);
        local pass = p:GetNWEntity("ImpDropShipSeat",NULL);
        local flying = p:GetNWBool("FlyingImpDropShip");
        if(flying) then
            if(IsValid(self)) then
				local fpvPos = self:GetPos(); // This is the position of the first person view if you have it
				return SWVehicleView(self,1000,200,fpvPos);      // 700 is distance from vehicle, 200 is the height.
            end
		else
            if(IsValid(pass)) then
                if(ImpDropShipSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-500+self:GetUp()*50;
                    //local face = self:GetAngles() + Angle(0,-90,0);
                    local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
                        View.origin = pos;
                        View.angles = face;
                    return View;
					else
						View.origin = ImpDropShipSeat:GetPos()+ImpDropShipSeat:GetUp()*70.75;
						View.angles = ImpDropShipSeat:GetAngles()+p:EyeAngles();
					return View;
                end
            end
        end
    end
    hook.Add("CalcView", "ImpDropShipView", ImpDropShipCalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "ImpDropShipDrawPlayerModel", function( p )
        local self = p:GetNWEntity("ImpDropShip", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local ImpDropShipSeat = p:GetNWEntity("ImpDropShipSeat",NULL);
        local pass = p:GetNWEntity("ImpDropShipSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(ImpDropShipSeat:GetThirdPersonMode()) then
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
		self:GetPos()+self:GetForward()*-225+self:GetUp()*127.8+self:GetRight()*.6,
	}
	self.EnginePos2 = {
		self:GetPos()+self:GetForward()*-232+self:GetUp()*30.2+self:GetRight()*-54.6,
		self:GetPos()+self:GetForward()*-232+self:GetUp()*28+self:GetRight()*-65.8,
		
		self:GetPos()+self:GetForward()*-232+self:GetUp()*30.2+self:GetRight()*54.72,
		self:GetPos()+self:GetForward()*-232+self:GetUp()*28+self:GetRight()*66.5,
	}
	
	for k,v in pairs(self.EnginePos1) do
		local size = 23;
		if(k > 1) then
			size = 18;
		end		
		local red = self.FXEmitter:Add("sprites/orangecore1",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal*-80) //Set direction we made earlier
		//red:SetDieTime(0.04) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetDieTime(FrameTime()*1.5)
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(100) // How visible it is at the end
		red:SetStartSize(size) // Start size. Just play around to find the right size.
		red:SetEndSize(size*0.75) // End size
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

	for k,v in pairs(self.EnginePos2) do
		local size = 6;
		if(k > 4) then
			size = 4;
		end	
		local red = self.FXEmitter:Add("sprites/orangecore1",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal) //Set direction we made earlier
		//red:SetDieTime(0.05) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetDieTime(FrameTime()*1.5)
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(100) // How visible it is at the end
		red:SetStartSize(size) // Start size. Just play around to find the right size.
		red:SetEndSize(size*0.75) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(255,255,255) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

		local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
		dynlight.Pos = v; // Position from the table
 		dynlight.Brightness = 4; // Brightness, Don't go above 10. It's blinding
		dynlight.Size = 50; // How far it reaches
		dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
		dynlight.R = 255; // Colour R
		dynlight.G = 255; // Colour G
		dynlight.B = 255; // Colour B
		dynlight.DieTime = CurTime()+1; // When the light should die

	end
end

	function ImpDropShipReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingImpDropShip");
		local self = p:GetNWEntity("ImpDropShip");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(5000);
			SW_WeaponReticles(self);
			SW_BlastIcon(self,10);			
			SW_HUD_DrawOverheating(self);
			
			local pos = self:GetPos()+self:GetForward()*240+self:GetUp()*147.5;
			local x,y = SW_XYIn3D(pos);
			
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "ImpDropShipReticle", ImpDropShipReticle)

end