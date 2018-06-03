ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";

ENT.PrintName = "T70 X-Wing";
ENT.Author = "Liam0102, Syphadias";
 
ENT.Category = "Star Wars Vehicles: Rebels"; // Change "Your Category" to what category you want it to be under in the SWV tab
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = true;
ENT.AdminOnly = false; //Set to true for an Admin vehicle.
 
ENT.EntModel = "models/starwars/syphadias/ships/t70_xwing/t70_xwing_landed.mdl"  //The path to the model you want to use.
ENT.Vehicle = "T70XWing" //The internal name for the ship. It cannot be the same as a different ship.
ENT.StartHealth = 1750; //How much health they should have.
ENT.Allegiance = "Resistance"; // Options are "Republic", "Rebels", "CIS", "Empire" and "Neutral". Anything else will be treated as Neutral.

ENT.WingsModel = "models/starwars/syphadias/ships/t70_xwing/t70_xwing_open.mdl"
ENT.ClosedModel = "models/starwars/syphadias/ships/t70_xwing/t70_xwing_closed.mdl"

list.Set("SWVehicles", ENT.PrintName, ENT); // This is very important and is needed to add your vehicle to the Star Wars Vehicles tab 
 
if SERVER then
 
ENT.FireSound = Sound("weapons/xwing_shoot.wav"); // The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; //Leave this alone for the most part.

ENT.BBBodies = {
	"models/prawnmodels/starwars/bb-8/body",
	"models/prawnmodels/starwars/bb-8/bodyblue",
	"models/prawnmodels/starwars/bb-8/bodygreen",
	"models/prawnmodels/starwars/bb-8/bodyred",
}

ENT.BBHeads = {
	"models/prawnmodels/starwars/bb-8/head",
	"models/prawnmodels/starwars/bb-8/headblue",
	"models/prawnmodels/starwars/bb-8/headgreen",
	"models/prawnmodels/starwars/bb-8/headred",
}
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr, ClassName)
    local e = ents.Create(ClassName);
	local spawn_height = 1; // How high above the ground the vehicle spawns. Change if it's spawning too high, or spawning in the ground.
	
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
        Right = self:GetPos() + self:GetForward() * 62 + self:GetRight() * 234.1 + self:GetUp() * -11.4,
        TopRight = self:GetPos() + self:GetForward() * 62 + self:GetRight() * 234.4 + self:GetUp() * 154,
        TopLeft = self:GetPos() + self:GetForward() * 62 + self:GetRight() * -234.4 + self:GetUp() * 154,
        Left = self:GetPos() + self:GetForward() * 62 + self:GetRight() * -234.1 + self:GetUp() * -11.4,
    }
    self.WeaponsTable = {}; // IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 1750; // The speed we go when holding SHIFT
    self.ForwardSpeed = 2500; // The forward speed 
    self.UpSpeed = 700; // Up/Down Speed
    self.AccelSpeed = 10; // How fast we get to our previously set speeds
	
	self.HasLookaround = true; //Set to true if the ship has 3D cockpit you want the player to be able to lookaround
	self.HasWings = true;
	
	self.CanBack = false; // Can we move backwards? Set to true if you want this.
	self.CanRoll = true; // Set to true if you want the ship to roll, false if not
	self.CanStrafe = false; // Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = false; // Set to true if you want the ship to hover when not inflight
	
	self.CanShoot = false; // Set to true if you want the ship to be able to shoot, false if not
	self.AlternateFire = true // Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	self.FireGroup = {"Left","Right","TopRight","TopLeft"} // In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	self.OverheatAmount = 50 //The amount a ship can fire consecutively without overheating. 50 is standard.
	self.DontOverheat = false; // Set this to true if you don't want the weapons to ever overheat. Mostly only appropriate on Admin vehicles.
	self.MaxIonShots = 20; // The amount of Ion shots a vehicle can take before being disabled. 20 is the default.
	self.FireDelay = 0.15;
    self.Bullet = CreateBulletStructure(60,"red",false); // The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits). The final one is for splash damage. Set to true if you don't want splashdamage.
	self.NextBlast = 1;	
	
	self.PilotVisible = true; // Set to true if you want a visible version of the pilot sat in the vehicle. Useful for ships with a glass cockpit.
	self.PilotPosition = {x=0,y=2.5,z=75} // If the above is true, set the position here.
	self.PilotAnim = "sit_rollercoaster"; //Set this to the animation you want. Common ones are: "drive_jeep", "drive_airboat" and "sit_rollercoaster". If you remove this it will default to "sit_rollercoaster"
	self.PilotAngle = Angle(-20,0,0);
	
	self.LandOffset = Vector(0,0,4); // Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
	self.ExitModifier = {x=-63,y=2.5,z=0}; // Change the position that you get out of the vehicle

	//self:TestLoc(self:GetPos() + self:GetForward() * 62 + self:GetRight() * 234.4 + self:GetUp() * 154)

	//BB8 Code
	self:SpawnBB8(self:GetPos()+self:GetForward()*-86+self:GetRight()*0+self:GetUp()*85);	
	self.BB8ColorIndex = self:SetBB8Color();
	
    self.BaseClass.Initialize(self); // Ignore, needed to work
end

function ENT:Enter(p)
    if(!IsValid(self.Pilot)) then
        self:SetModel(self.ClosedModel);
        self:PhysicsInit(SOLID_VPHYSICS);
        if(IsValid(self:GetPhysicsObject())) then
            self:GetPhysicsObject():EnableMotion(true);
            self:GetPhysicsObject():Wake();
        end
        self:StartMotionController();
    end
    self.BaseClass.Enter(self,p);
end

function ENT:Exit(kill)
    local p = self.Pilot;
    self.BaseClass.Exit(self,kill);
    if(self.Land or self.TakeOff) then
        self:SetModel(self.EntModel);
        self:PhysicsInit(SOLID_VPHYSICS);
        if(IsValid(self:GetPhysicsObject())) then
            self:GetPhysicsObject():EnableMotion(true);
            self:GetPhysicsObject():Wake();
        end
        self:StartMotionController();
        if(IsValid(p)) then
            p:SetEyeAngles(self:GetAngles()+Angle(0,0,0));
        end
    end
end
 
function ENT:ToggleWings()
if(!IsValid(self)) then return end;
	if(self.NextUse.Wings < CurTime()) then
		if(self.Wings) then
			self:SetModel(self.ClosedModel);
			self.Wings = false;
            self.CanShoot = false;
		else
			self.Wings = true;
			self:SetModel(self.WingsModel);
            self.CanShoot = true;
		end
		self:PhysicsInit(SOLID_VPHYSICS);
        if(IsValid(self:GetPhysicsObject())) then
            self:GetPhysicsObject():EnableMotion(true);
            self:GetPhysicsObject():Wake();
        end
        self:StartMotionController();
		self:SetNWBool("Wings",self.Wings);
		if(IsValid(self.Pilot)) then
			self.Pilot:SetNWBool("SW_Wings",self.Wings);
		end
		self.NextUse.Wings = CurTime() + 1;
	end
end 

function ENT:SpawnBB8(pos)

	local e = ents.Create("prop_physics");
	e:SetPos(pos);
	e:SetAngles(self:GetAngles());
	e:SetModel("models/prawnmodels/starwars/bb-8.mdl");
	e:Spawn();
	e:Activate();
	e:SetParent(self);
	self.BB8 = e;
end

function ENT:SetBB8Color(c)
	
	local n;
	if(!c) then
		n = math.random(1,4);
	else
		n = c;
	end
	self.BB8:SetSubMaterial(0,self.BBBodies[n]);
	self.BB8:SetSubMaterial(2,self.BBHeads[n]);
	return n;
end
 
function ENT:Think()

    if(self.Inflight) then
        //self.AccelSpeed = math.Approach(self.AccelSpeed,7,0.1);
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 60 + self:GetRight() * -75 + self:GetUp() * 60,
						self:GetPos() + self:GetForward() * 60 + self:GetRight() * 75 + self:GetUp() * 60,
                    } //Table of the positions from which to fire
                    self:FireT70XWingBlast(self.BlastPositions[self.NextBlast], false, 100, 100, false, 20, Sound("weapons/n1_cannon.wav"));
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
 
function ENT:FireT70XWingBlast(pos,gravity,vel,dmg,white,size,snd)
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
		Engine=Sound("vehicles/t70_xwing/t70_engine_loop.wav"),
	}
	
	//Vehicle View Variables
	ENT.CanFPV = true; // Set to true if you want FPV
    ENT.ViewDistance = 700; //Distance from the Ship
    ENT.ViewHeight = 200; //Height above the ship 300
    ENT.FPVPos = Vector(2,0,105); //Position relative to ship for first person view
	
	function ENT:FlightEffects()

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetForward() * -1):GetNormalized();
		local id = self:EntIndex();
		for k,v in pairs(self.ThrusterLocations) do

			
			local blue = self.FXEmitter:Add("sprites/orangecore1",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.015)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(100)
			blue:SetStartSize(14)
			blue:SetEndSize(10)
			blue:SetRoll(roll)
			blue:SetColor(255,100,100)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 255;
			dynlight.G = 100;
			dynlight.B = 100;
			dynlight.DieTime = CurTime()+1;

		end
	end
	
	local matPlasma	= Material( "sprites/t70_xwing_red" )
	function ENT:Draw() 
		self:DrawModel()		
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		local vel = self:GetVelocity():Length();
		if(vel > 150) then
			if(Flying and !TakeOff and !Land) then
				for i=1,4 do
					local vOffset = self.ThrusterLocations[i] 
					local scroll = CurTime() * -20
						
					render.SetMaterial( matPlasma )
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 32, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 24, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
						render.AddBeam( vOffset + self:GetForward()*-40, 8, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 32, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 24, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
						render.AddBeam( vOffset + self:GetForward()*-40, 8, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 32, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 24, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
						render.AddBeam( vOffset + self:GetForward()*-40, 8, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					
				end
			end
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
				local Wings = self:GetNWBool("Wings");
				if(Wings) then
					self.ThrusterLocations = {
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * 69.15 + self:GetUp() * 115,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * -69.15 + self:GetUp() * 115,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * 69.15 + self:GetUp() * 26.8,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * -69.15 + self:GetUp() * 26.8,
					}
				else
					self.ThrusterLocations = {
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * 79 + self:GetUp() * 98,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * -79 + self:GetUp() * 98,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * 79 + self:GetUp() * 45.5,
						self:GetPos() + self:GetForward() * -273 + self:GetRight() * -79 + self:GetUp() * 45.5,
					}
				end
				self:FlightEffects();
			end
		end
	end
	
	local function T70XWingReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingT70XWing"); // T70XWing should be what you named your ship near the top
		local self = p:GetNWEntity("T70XWing");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(1750); // Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_BlastIcon(self,6);
			SW_HUD_DrawOverheating(self);
			
			local pos = self:GetPos()+self:GetForward()*15+self:GetUp()*101.5+self:GetRight()*0;
			local x,y = SW_XYIn3D(pos);
			
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer(); // Draw the speedometer
		end
	end
    hook.Add("HUDPaint", "T70XWingReticle", T70XWingReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/