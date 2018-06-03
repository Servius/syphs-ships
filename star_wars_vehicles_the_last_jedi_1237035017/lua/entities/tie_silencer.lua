//HOW TO PROPERLY MAKE AN ADDITIONAL SHIP ADDON OFF OF MINE.
 
//Do not copy everything out of my addon. You don't need it. Shall explain later.
 
//Leave this stuff the same
ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";
 
//Edit appropriatly. I'd prefer it if you left my name (Since I made the base, and this template)
ENT.PrintName = "TIE Silencer";
ENT.Author = "Liam0102, Syphadias";
 
// Leave the same
ENT.Category = "Star Wars Vehicles: First Order"; // Change "Your Category" to what category you want it to be under in the SWV tab
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false; //Set to true for an Admin vehicle.
 
ENT.EntModel = "models/starwars/syphadias/ships/tie_silencer/tie_silencer.mdl"  //The path to the model you want to use.
ENT.Vehicle = "TieSilencer" //The internal name for the ship. It cannot be the same as a different ship.
ENT.StartHealth = 4500; //How much health they should have.
ENT.Allegiance = "First Order"; // Options are "Republic", "Rebels", "CIS", "Empire" and "Neutral". Anything else will be treated as Neutral.
list.Set("SWVehicles", ENT.PrintName, ENT); // This is very important and is needed to add your vehicle to the Star Wars Vehicles tab 
 
if SERVER then
 
ENT.FireSound = Sound("weapons/tie_shoot.wav"); // The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; //Leave this alone for the most part.

 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr, ClassName)
    local e = ents.Create(ClassName);
	local spawn_height = 5; // How high above the ground the vehicle spawns. Change if it's spawning too high, or spawning in the ground.
	
    e:SetPos(tr.HitPos + Vector(0,0,spawn_height));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
 
 
    self:SetNWInt("Health",self.StartHealth); // Set the ship health, to the start health as made earlier
   
    //The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
    self.WeaponLocations = {
        Right = self:GetPos() + self:GetForward() * 40 + self:GetRight() * 182 + self:GetUp() * 75,
        TopRight = self:GetPos() + self:GetForward() * 40 + self:GetRight() * 182 + self:GetUp() * 115,
        TopLeft = self:GetPos() + self:GetForward() * 40 + self:GetRight() * -182 + self:GetUp() * 115,
        Left = self:GetPos() + self:GetForward() * 40 + self:GetRight() * -182 + self:GetUp() * 75,
    }
    self.WeaponsTable = {}; // IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 2700; // The speed we go when holding SHIFT
    self.ForwardSpeed = 1850; // The forward speed 
    self.UpSpeed = 700; // Up/Down Speed
    self.AccelSpeed = 11; // How fast we get to our previously set speeds
    self.CanBack = true; // Can we move backwards? Set to true if you want this.
	self.CanRoll = true; // Set to true if you want the ship to roll, false if not
	self.CanStrafe = true; // Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = true; // Set to true if you want the ship to hover when not inflight
	self.CanShoot = true; // Set to true if you want the ship to be able to shoot, false if not
	
	self.AlternateFire = true // Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	self.FireGroup = {"Left","Right","TopRight","TopLeft"} // In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	self.OverheatAmount = 60 //The amount a ship can fire consecutively without overheating. 50 is standard.
	self.DontOverheat = false; // Set this to true if you don't want the weapons to ever overheat. Mostly only appropriate on Admin vehicles.
	self.MaxIonShots = 30; // The amount of Ion shots a vehicle can take before being disabled. 20 is the default.
	
	self.PilotVisible = true; // Set to true if you want a visible version of the pilot sat in the vehicle. Useful for ships with a glass cockpit.
	self.PilotPosition = {x=0,y=47,z=82} // If the above is true, set the position here.
	self.PilotAnim = "sit_rollercoaster"; //Set this to the animation you want. Common ones are: "drive_jeep", "drive_airboat" and "sit_rollercoaster". If you remove this it will default to "sit_rollercoaster"
	self.PilotAngle = Angle(-20,0,0);
	
	self.HasLookaround = true; //Set to true if the ship has 3D cockpit you want the player to be able to lookaround
	
	self.LandOffset = Vector(0,0,1); // Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
	self.ExitModifier = {x=0,y=125,z=0}; // Change the position that you get out of the vehicle

	//self:TestLoc(self:GetPos() + self:GetForward() * 0 + self:GetRight() * 0 + self:GetUp() * 0)
	
	self.FireDelay = 0.1;
    self.Bullet = CreateBulletStructure(95,"green",false); // The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits). The final one is for splash damage. Set to true if you don't want splashdamage.
	self.NextBlast = 1;
	
    self.BaseClass.Initialize(self); // Ignore, needed to work
end

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
 
function ENT:Think()

    if(self.Inflight) then
        //self.AccelSpeed = math.Approach(self.AccelSpeed,7,0.1);
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 15 + self:GetRight() * -182 + self:GetUp() * 95,
						self:GetPos() + self:GetForward() * 15 + self:GetRight() * 182 + self:GetUp() * 95,
                    } //Table of the positions from which to fire
                    self:FireTieSilencerBlast(self.BlastPositions[self.NextBlast], false, 100, 100, false, 20, Sound("weapons/n1_cannon.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 3) then
						self.NextUse.FireBlast = CurTime()+6;
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
        self.ExitPos = self:GetPos()+self:GetForward()*0+self:GetUp()*0
    end
    self.BaseClass.Think(self);
end
 
function ENT:FireTieSilencerBlast(pos,gravity,vel,dmg,white,size,snd)
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
	e:SetColor(Color(1,25,255,1));
	
end
 
end
 
if CLIENT then

	
    ENT.EnginePos = {}
    ENT.Sounds={
        //Engine=Sound("ambient/atmosphere/ambience_base.wav"), // This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
		//Engine=Sound("vehicles/tie_silencer/tiesilencerflyloop.wav"),
		Engine=Sound("vehicles/tie_silencer/tiesilencerflyloopquieter.wav"),
	}
	
	//Vehicle View Variables
	ENT.CanFPV = true; // Set to true if you want FPV
    ENT.ViewDistance = 700; //Distance from the Ship
    ENT.ViewHeight = 200; //Height above the ship 300
    ENT.FPVPos = Vector(42,0,110); //Position relative to ship for first person view
    
	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();
		
		self.EnginePos = {
			//left 1
			self:GetPos() + self:GetForward() * -205 + self:GetRight() * -15 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -200 + self:GetRight() * -20 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -195 + self:GetRight() * -25 + self:GetUp() * 96.5,	
			//left 2
			self:GetPos() + self:GetForward() * -185 + self:GetRight() * -48 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -180 + self:GetRight() * -53 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -177 + self:GetRight() * -58 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -174 + self:GetRight() * -63 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -171 + self:GetRight() * -68 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -168 + self:GetRight() * -75 + self:GetUp() * 96.5,
			//left 3
			self:GetPos() + self:GetForward() * -158 + self:GetRight() * -95 + self:GetUp() * 96.5,
			//right 1
			self:GetPos() + self:GetForward() * -205 + self:GetRight() * 15 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -200 + self:GetRight() * 20 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -195 + self:GetRight() * 25 + self:GetUp() * 96.5,
			//right 2
			self:GetPos() + self:GetForward() * -185 + self:GetRight() * 48 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -180 + self:GetRight() * 53 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -177 + self:GetRight() * 58 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -174 + self:GetRight() * 63 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -171 + self:GetRight() * 68 + self:GetUp() * 96.5,
			self:GetPos() + self:GetForward() * -168 + self:GetRight() * 75 + self:GetUp() * 96.5,
			//right 3
			self:GetPos() + self:GetForward() * -158 + self:GetRight() * 95 + self:GetUp() * 96.5,
		}

		for k,v in pairs(self.EnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*-5)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.02)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(25)
			blue:SetStartSize(20)
			blue:SetEndSize(20)
			blue:SetRoll(roll)
			blue:SetColor(255,25,15)
			
			local dynlight = DynamicLight(id + 4096*k);
			dynlight.Pos = v+FWD*-25;
			dynlight.Brightness = 5;
			dynlight.Size = 125;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 25;
			dynlight.B = 15;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end
	
	function ENT:Think()
	
		self.BaseClass.Think(self)
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		if(Flying) then
			if(!TakeOff and !Land) then
				self:FlightEffects();
			end
		end
		
	end
	
	local function TieSilencerReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingTieSilencer"); // TieSilencer should be what you named your ship near the top
		local self = p:GetNWEntity("TieSilencer");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(4500); // Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_BlastIcon(self,6);
			SW_HUD_DrawOverheating(self);
			
			local x = ScrW()/5.82; // The first person position of the compass. Set both x and y appropriatly
			local y = ScrH()/4.09*3.1;
			SW_HUD_Compass(self,x,y); // Draw the compass/radar
			SW_HUD_DrawSpeedometer(); // Draw the speedometer
		end
	end
    hook.Add("HUDPaint", "TieSilencerReticle", TieSilencerReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/