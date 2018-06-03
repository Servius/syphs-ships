ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";

ENT.PrintName = "Upsilon Shuttle";
ENT.Author = "Liam0102, Syphadias, and spartanmark6 for properly rigging the model";
ENT.Category = "Star Wars Vehicles: First Order"; 
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.EntModel = "models/upsilon_shuttle/syphadias/upsilon_shuttle.mdl" 
ENT.Vehicle = "UpsilonS" 
ENT.StartHealth = 3500;
ENT.Allegiance = "First Order"
 
list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then
 
ENT.FireSound = Sound("vehicle/upsilon_shuttle/kylo_turbo_laser.wav"); // The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; //Leave this alone for the most part.

 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("upsilon_shuttle"); // This should be the same name as the file
	local spawn_height = 200; // How high above the ground the vehicle spawns. Change if it's spawning too high, or spawning in the ground.
	
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
        Right = self:GetPos() + self:GetForward() * 800 + self:GetRight() * 297.75 + self:GetUp() * -98.4,
        TopRight = self:GetPos() + self:GetForward() * 800 + self:GetRight() * 318.75 + self:GetUp() * -80,
        TopLeft = self:GetPos() + self:GetForward() * 800 + self:GetRight() * -318.75 + self:GetUp() * -81,
        Left = self:GetPos() + self:GetForward() * 800 + self:GetRight() * -297.75 + self:GetUp() * -100,
    }
    self.WeaponsTable = {}; // IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 1400; // The speed we go when holding SHIFT
    self.ForwardSpeed = 875; // The forward speed 
    self.UpSpeed = 600; // Up/Down Speed
    self.AccelSpeed = 5; // How fast we get to our previously set speeds
    self.CanBack = true; // Can we move backwards? Set to true if you want this.
	self.CanRoll = false; // Set to true if you want the ship to roll, false if not
	self.CanStrafe = false; // Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = false; // Set to true if you want the ship to hover when not inflight
	self.HasWings = true;
	self.CanShoot = true; // Set to true if you want the ship to be able to shoot, false if not
	self.AlternateFire = true // Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	self.FireGroup = {"Right","Left","TopLeft","TopRight"} // In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	self.OverheatAmount = 50 //The amount a ship can fire consecutively without overheating. 50 is standard.
	self.DontOverheat = false; // Set this to true if you don't want the weapons to ever overheat. Mostly only appropriate on Admin vehicles.
	self.MaxIonShots = 30; // The amount of Ion shots a vehicle can take before being disabled. 20 is the default.
	self.LockOnOverride = Vector(0,0,0)
	self.FireDelay = 1.15

	
	//self:TestLoc(self:GetPos() + self:GetForward() * 800 + self:GetRight() * -297.75 + self:GetUp() * -96.75)
	
	self.LandOffset = Vector(0,0,205); // Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
	self.ExitModifier = {x=0,y=550,z=-180};

    self.Bullet = CreateBulletStructure(150,"green",false); // The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits). The final one is for splash damage. Set to true if you don't want splashdamage.
	
    self.BaseClass.Initialize(self); // Ignore, needed to work
end

function ENT:Think()

	if(self.Inflight) then
		if(self.Wings) then
			self.CanShoot = true;
		else
			self.CanShoot = false;
		end
		self:SetPlaybackRate(1.5);
	end
	self.BaseClass.Think(self);
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

end
 
if CLIENT then

	ENT.CanFPV = false; // Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
        //Engine=Sound("ambient/atmosphere/ambience_base.wav"),
        Engine=Sound("vehicle/upsilon_shuttle/kylo_shuttle_fly.wav"), // This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
    }

 
    //This is where we set how the player sees the ship when flying
    local View = {}
    local function CalcView()      
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("UpsilonS", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos(); // This is the position of the first person view if you have it
			View = SWVehicleView(self,1750,200,fpvPos);		// 700 is distance from vehicle, 200 is the height.
			return View;
		end
    end
    hook.Add("CalcView", "UpsilonSView", CalcView) // This is very important. Make sure the middle arguement is unique. In this case the ship name + view
	
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
	self.EnginePos = {
		self:GetPos()+self:GetForward()*-183+self:GetUp()*-47.8+self:GetRight()*-52.5,
		self:GetPos()+self:GetForward()*-183+self:GetUp()*-47.8+self:GetRight()*52.5,
	}
	
	for k,v in pairs(self.EnginePos) do
	
		local red = self.FXEmitter:Add("sprites/orangecore1",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal) //Set direction we made earlier
		red:SetDieTime(0.08) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(100) // How visible it is at the end
		red:SetStartSize(40) // Start size. Just play around to find the right size.
		red:SetEndSize(15) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(255,200,200) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

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

	local function UpsilonSReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingUpsilonS");
		local self = p:GetNWEntity("UpsilonS");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(3500); // Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
    hook.Add("HUDPaint", "UpsilonSReticle", UpsilonSReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 