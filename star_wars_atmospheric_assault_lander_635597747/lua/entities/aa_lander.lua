ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";
 
ENT.PrintName = "Atmospheric Assault Lander";
ENT.Author = "Liam0102, Syphadias";
ENT.Category = "Star Wars Vehicles: First Order"; 
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.EntModel = "models/ships/firstorder/transport_open.mdl"
ENT.Vehicle = "AALander" 
ENT.Allegiance = "First Order"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then
 
ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),Doors = CurTime(),};
ENT.StartHealth = 4000;
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("aa_lander");
	e:SetPos(tr.HitPos + Vector(0,0,20));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
 
 
  self:SetNWInt("Health",self.StartHealth);
 
  self.WeaponLocations = {
      TopRight = self:GetPos() + self:GetForward() * -53 + self:GetRight() * -29 + self:GetUp() * 190,
      TopLeft = self:GetPos() + self:GetForward() * -53 + self:GetRight() * -43 + self:GetUp() * 190,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1750;
	self.ForwardSpeed = 1100;
	self.UpSpeed = 600;
	self.AccelSpeed = 8;
	self.CanBack = true;
	self.CanRoll = false; 
	self.CanStrafe = true;
	self.CanStandby = false;
	self.CanShoot = true; 
	
	self.AlternateFire = true;
	self.FireDelay = 0.15;
    self.FireGroup = {"TopLeft","TopRight"};
    self.OverheatAmount = 50
    self.DontOverheat = false; 
	self.MaxIonShots = 20;
	
	self.Bullet = CreateBulletStructure(60,"green",false)
	
	self.SeatPos = {
        {self:GetPos()+self:GetUp()*54+self:GetRight()*-22+self:GetForward()*-85,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*-22+self:GetForward()*-5,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*-22+self:GetForward()*75,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*-22+self:GetForward()*155,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*22+self:GetForward()*-85,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*22+self:GetForward()*-5,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*22+self:GetForward()*75,self:GetAngles()},
        {self:GetPos()+self:GetUp()*54+self:GetRight()*22+self:GetForward()*155,self:GetAngles()},
	}
	
	self.ClosedModel = "models/ships/firstorder/transport_close.mdl"
	self.OpenModel = "models/ships/firstorder/transport_open.mdl"
	self:SetNWBool("Doors",true);
 
 	self:SpawnSeats();
	self.ExitModifier = {x=0,y=-100,z=70};
	
	self.PilotVisible = false;
	self.PilotPosition = {x=0,y=80,z=50};
 
	self.LandOffset = Vector(0,0,5);
	self.PilotOffset = {x=0,y=200,z=0}
 	
	///*
	//local pos = {
	//	self:GetPos()+self:GetUp()*125+self:GetRight()*20+self:GetForward()*-125,
	//	self:GetPos()+self:GetUp()*125+self:GetRight()*-20+self:GetForward()*-125,
	//}
	//for k,v in pairs(pos) do
	//	self:TestLoc(v);
	//end
	//*/
	
	//self.HasLookaround = false;
	self.BaseClass.Initialize(self);
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
       e:SetVehicleClass("sypha_seat");
       e:SetUseType(USE_OFF);
       e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
       e.IsAALanderSeat = true;
       e.AALander = self;
 
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
 
hook.Add("PlayerEnteredVehicle","AALanderSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsAALanderSeat) then
            p:SetNetworkedEntity("AALander",v:GetParent());
            p:SetNetworkedEntity("AALanderSeat",v);
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "AALanderSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsAALanderSeat) then
            local e = v.AALander;
            if(IsValid(e)) then
				//p:SetPos(v:GetPos()+v:GetUp()*10+v:GetRight()*0+v:GetForward()*0)
				timer.Simple(0.1, function()
					if IsValid(p) and IsValid(v) then
						p:SetPos(v:GetPos()+v:GetUp()*10+v:GetRight()*0+v:GetForward()*0)
					end
				end)
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("AALanderSeat",NULL);
            p:SetNetworkedEntity("AALander",NULL);	
        end
    end
end);
 
 
function ENT:ToggleDoor()
   if(self.Wings) then
       self:SetModel(self.ClosedModel);
       self.Wings = false;
       else
       self:SetModel(self.OpenModel);
       self.Wings = true;
   end
   self.NextUse.Wings = CurTime() + 1;
   self:SetNWBool("Doors",self.Wings);
   self:EmitSound(Sound("vehicle/aal/aal_door.wav"),50,100,1);
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
 
function ENT:Think()

	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
			if(self.Pilot:KeyDown(IN_WALK) and self.NextUse.Wings < CurTime()) then
				self:ToggleDoor();
			end
		end
        self.ExitPos = self:GetPos()+self:GetForward()*15+self:GetUp()*190
    end
    self.BaseClass.Think(self);
end

end
 
if CLIENT then
 
	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicle/aal/aal_engine_loop.wav"),
	}
	
	ENT.CanFPV = false; // Set to true if you want FPV
    ENT.ViewDistance = 1000; //Distance from the Ship
    ENT.ViewHeight = 200; //Height above the ship 300
    ENT.FPVPos = Vector(0,0,0); //Position relative to ship for first person view

	local View = {}
    function AALanderCalcView()
       
        local p = LocalPlayer();
        local self = p:GetNWEntity("AALander", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local AALanderSeat = p:GetNWEntity("AALanderSeat",NULL);
        local pass = p:GetNWEntity("AALanderSeat",NULL);
        local flying = p:GetNWBool("FlyingAALander");
        if(AALanderSeat) then
            if(IsValid(pass)) then
                if(AALanderSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*700+self:GetUp()*50;
                    //local face = self:GetAngles() + Angle(0,90,0);
                    local face = ((self:GetPos() + Vector(0,0,90))- pos):Angle();
                        View.origin = pos;
                        View.angles = face;
                    return View;
					else
						View.origin = AALanderSeat:GetPos()+AALanderSeat:GetUp()*70.75;
						View.angles = AALanderSeat:GetAngles()+p:EyeAngles();
					return View;
                end
            end
        end
    end
    hook.Add("CalcView", "AALanderView", AALanderCalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "AALanderDrawPlayerModel", function( p )
        local self = p:GetNWEntity("AALander", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local AALanderSeat = p:GetNWEntity("AALanderSeat",NULL);
        local pass = p:GetNWEntity("AALanderSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(AALanderSeat)) then
                if(AALanderSeat:GetThirdPersonMode()) then
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
	self:InteriorLights();
	local Door = self:GetNWBool("Doors");
	if(Door) then
		self:LandingLights();
	end
	self.BaseClass.Think(self);
end

function ENT:Effects()
	local normal = (self:GetForward() * -1):GetNormalized() // More or less the direction. You can leave this for the most part (If it's going the opposite way, then change it 1 not -1)
	local roll = math.Rand(-90,90) // Random roll so the effect isn't completely static (Useful for heatwave type)
	local p = LocalPlayer()	// Player (duh)
	local id = self:EntIndex(); //Need this later on.
	
	//Get the engine pos the same way you get weapon pos
	EngineSize1 = {		
		self:GetPos()+self:GetForward()*-396+self:GetUp()*141+self:GetRight()*-58, 		//TopLeftEng
		self:GetPos()+self:GetForward()*-396+self:GetUp()*137+self:GetRight()*-54,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*133+self:GetRight()*-50,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*129+self:GetRight()*-46,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*125+self:GetRight()*-42,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*121+self:GetRight()*-38,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*117+self:GetRight()*-34,
		
		self:GetPos()+self:GetForward()*-376+self:GetUp()*125+self:GetRight()*-87, 		//BottomLeftEng
		self:GetPos()+self:GetForward()*-376+self:GetUp()*121+self:GetRight()*-83,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*117+self:GetRight()*-79,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*113+self:GetRight()*-75,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*109+self:GetRight()*-71,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*105+self:GetRight()*-67,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*101+self:GetRight()*-63,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*97+self:GetRight()*-59,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*95+self:GetRight()*-57,
		
		self:GetPos()+self:GetForward()*-396+self:GetUp()*142+self:GetRight()*56,  		//TopRightEng
		self:GetPos()+self:GetForward()*-396+self:GetUp()*138+self:GetRight()*51,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*134+self:GetRight()*48,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*130+self:GetRight()*44,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*126+self:GetRight()*40,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*122+self:GetRight()*36,
		self:GetPos()+self:GetForward()*-396+self:GetUp()*118+self:GetRight()*32,
		
		self:GetPos()+self:GetForward()*-376+self:GetUp()*124+self:GetRight()*87,		//BottomRightEng
		self:GetPos()+self:GetForward()*-376+self:GetUp()*120+self:GetRight()*83,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*116+self:GetRight()*79,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*112+self:GetRight()*75,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*108+self:GetRight()*71,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*104+self:GetRight()*67,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*100+self:GetRight()*63,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*96+self:GetRight()*59,
		self:GetPos()+self:GetForward()*-376+self:GetUp()*94+self:GetRight()*57,
	}
	
	EngineSize2 = {
		self:GetPos()+self:GetForward()*-231.65+self:GetUp()*45+self:GetRight()*-105.5,
		self:GetPos()+self:GetForward()*-231.65+self:GetUp()*43.5+self:GetRight()*105.5,
		self:GetPos()+self:GetForward()*-197.25+self:GetUp()*45+self:GetRight()*-105.5,
		self:GetPos()+self:GetForward()*-197.25+self:GetUp()*43.5+self:GetRight()*105.5,
	}
	
	for k,v in pairs(EngineSize1) do
	
		local red = self.FXEmitter:Add("sprites/bluecore",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal) //Set direction we made earlier
		red:SetDieTime(0.04) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(200) // How visible it is at the end
		red:SetStartSize(15) // Start size. Just play around to find the right size.
		red:SetEndSize(5) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(100,255,255) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

		local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
		dynlight.Pos = v; // Position from the table
 		dynlight.Brightness = 6; // Brightness, Don't go above 10. It's blinding
		dynlight.Size = 100; // How far it reaches
		dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
		dynlight.R = 100; // Colour R
		dynlight.G = 255; // Colour G
		dynlight.B = 255; // Colour B
		dynlight.DieTime = CurTime()+1; // When the light should die

	end
	
		for k,v in pairs(EngineSize2) do
		
		local red = self.FXEmitter:Add("sprites/bluecore",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal) //Set direction we made earlier
		red:SetDieTime(0.0125) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(255) // How visible it is at the end
		red:SetStartSize(11) // Start size. Just play around to find the right size.
		red:SetEndSize(8) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(100,255,255) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

		local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
		dynlight.Pos = v; // Position from the table
 		dynlight.Brightness = 6; // Brightness, Don't go above 10. It's blinding
		dynlight.Size = 100; // How far it reaches
		dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
		dynlight.R = 100; // Colour R
		dynlight.G = 255; // Colour G
		dynlight.B = 255; // Colour B
		dynlight.DieTime = CurTime()+1; // When the light should die

	end
end

function ENT:InteriorLights()
    local id = self:EntIndex();
    local LightPos = {
		self:GetPos()+self:GetUp()*135+self:GetRight()*10+self:GetForward()*-100,
		self:GetPos()+self:GetUp()*135+self:GetRight()*-10+self:GetForward()*-100,
		self:GetPos()+self:GetUp()*135+self:GetRight()*10+self:GetForward()*-50,
		self:GetPos()+self:GetUp()*135+self:GetRight()*-10+self:GetForward()*-50,
		self:GetPos()+self:GetUp()*135+self:GetRight()*-10+self:GetForward()*50,
		self:GetPos()+self:GetUp()*135+self:GetRight()*10+self:GetForward()*50,
		self:GetPos()+self:GetUp()*135+self:GetRight()*10+self:GetForward()*150,
		self:GetPos()+self:GetUp()*135+self:GetRight()*-10+self:GetForward()*150,
		self:GetPos()+self:GetUp()*135+self:GetRight()*-10+self:GetForward()*250,
		self:GetPos()+self:GetUp()*135+self:GetRight()*10+self:GetForward()*250,
		
    }
    for k,v in pairs(LightPos) do
        local dynlight = DynamicLight(id*2 + 4096 * (k*10)); // Create the "glow"
        dynlight.Pos = v; // Position from the table
        dynlight.Brightness = 6; // Brightness, Don't go above 10. It's blinding
        dynlight.Size = (math.Rand(1, 100)); // How far it reaches
        dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
        dynlight.R = 0; // Colour R
        dynlight.G = 195; // Colour G
        dynlight.B = 255; // Colour B
        dynlight.DieTime = CurTime()+1; // When the light should die
    end
end

function ENT:LandingLights()
    local id = self:EntIndex();
    local LightPos = {
		self:GetPos()+self:GetForward()*-65+self:GetRight()*90,
		self:GetPos()+self:GetForward()*-65+self:GetRight()*-90,
		self:GetPos()+self:GetForward()*-290+self:GetRight()*-65,
		self:GetPos()+self:GetForward()*-290+self:GetRight()*65,
    }
    for k,v in pairs(LightPos) do
        local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
        dynlight.Pos = v; // Position from the table
        dynlight.Brightness = 8; // Brightness, Don't go above 10. It's blinding
        dynlight.Size = 100; // How far it reaches
        dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
        dynlight.R = 255; // Colour R
        dynlight.G = 255; // Colour G
        dynlight.B = 220; // Colour B
        dynlight.DieTime = CurTime()+1; // When the light should die
    end
end 
 
local function AALanderReticle() //Make this unique. Again Ship name + Reticle

   local p = LocalPlayer();
   local Flying = p:GetNWBool("FlyingAALander");
   local self = p:GetNWEntity("AALander");
   if(Flying and IsValid(self)) then
		SW_HUD_DrawHull(4000); // Replace 1000 with the starthealth at the top
		SW_WeaponReticles(self);
		SW_HUD_DrawOverheating(self);
		SW_HUD_Compass(self);
		SW_HUD_DrawSpeedometer();
	end
end
hook.Add("HUDPaint", "AALanderReticle", AALanderReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.

end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/