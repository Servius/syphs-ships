ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";
 
ENT.PrintName = "Koro2 Exodrive Airspeeder";
ENT.Author = "Liam0102, Syphadias";
ENT.Category = "Star Wars Vehicles: Other"; 
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false; 
 
ENT.EntModel = "models/starwars/syphadias/ships/koro2_airspeeder/koro2_airspeeder.mdl" 
ENT.Vehicle = "Koro2" 
ENT.StartHealth = 1500;
ENT.Allegiance = "Neutral"; 

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then
 
ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; 

 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("koro2"); 
	local spawn_height = 20;
	
    e:SetPos(tr.HitPos + Vector(0,0,spawn_height));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
 
 
    self:SetNWInt("Health",self.StartHealth); 
   
    //The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
    self.WeaponLocations = {
        Right = self:GetPos() + self:GetForward() * -30 + self:GetRight() * 432 + self:GetUp() * -17.25,
        TopRight = self:GetPos() + self:GetForward() * -30 + self:GetRight() * 432 + self:GetUp() * -17.25,
        TopLeft = self:GetPos() + self:GetForward() * -30 + self:GetRight() * -432 + self:GetUp() * -17.25,
        Left = self:GetPos() + self:GetForward() * -30 + self:GetRight() * -432 + self:GetUp() * -17.25,
    }
    self.WeaponsTable = {}; // IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 2250; // The speed we go when holding SHIFT
    self.ForwardSpeed = 1600; // The forward speed 
    self.UpSpeed = 600; // Up/Down Speed
    self.AccelSpeed = 8; // How fast we get to our previously set speeds
    self.CanBack = false; // Can we move backwards? Set to true if you want this.
	self.CanRoll = false; // Set to true if you want the ship to roll, false if not
	self.CanStrafe = true; // Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = true; // Set to true if you want the ship to hover when not inflight
	self.CanShoot = false; // Set to true if you want the ship to be able to shoot, false if not
	
	self.AlternateFire = false // Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	self.FireGroup = {"Left","Right","TopLeft","TopRight"} // In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	self.OverheatAmount = 50 //The amount a ship can fire consecutively without overheating. 50 is standard.
	self.DontOverheat = false; // Set this to true if you don't want the weapons to ever overheat. Mostly only appropriate on Admin vehicles.
	self.MaxIonShots = 20; // The amount of Ion shots a vehicle can take before being disabled. 20 is the default.
	
	self.PilotVisible = true; // Set to true if you want a visible version of the pilot sat in the vehicle. Useful for ships with a glass cockpit.
	self.PilotPosition = {x=0,y=-22,z=20} // If the above is true, set the position here.
	self.PilotAnim = "sit_rollercoaster"; //Set this to the animation you want. Common ones are: "drive_jeep", "drive_airboat" and "sit_rollercoaster". If you remove this it will default to "sit_rollercoaster"
	self.PilotAngle = Angle(-35,0,0);
	
	self.StrafeSounds = {
    "vehicles/koro2/koro2_sfx1.wav",
	"vehicles/koro2/koro2_sfx2.wav",
	"vehicles/koro2/koro2_sfx3.wav",
	"vehicles/koro2/koro2_sfx4.wav",
	"vehicles/koro2/koro2_sfx5.wav",
	}
	self.SoundNum = 1;
	
	self.HasLookaround = true; //Set to true if the ship has 3D cockpit you want the player to be able to lookaround
	
	self.LandOffset = Vector(0,0,20); // Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
	self.ExitModifier = {x=-75,y=0,z=0}; // Change the position that you get out of the vehicle

    self.Bullet = CreateBulletStructure(60,"red",false); // The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits). The final one is for splash damage. Set to true if you don't want splashdamage.
	
    self.BaseClass.Initialize(self); // Ignore, needed to work
end

function ENT:SpawnPilot(pos)
	if(IsValid(self.Pilot)) then
	local e = ents.Create("prop_physics");
			e:SetModel(self.Pilot:GetModel());
			e:SetPos(pos)
	local ang = self:GetAngles();
	if(self.PilotAngle) then
		ang = self:GetAngles() + self.PilotAngle;
	end
	e:SetAngles(ang)
	e:SetParent(self);
	e:Spawn();
	e:Activate();

	local anim = "sit_rollercoaster";
	if(self.PilotAnim) then
		anim = self.PilotAnim;
	end
	e:SetSequence(e:LookupSequence(anim));

	self.PilotAvatar = e;
	self:SetNWEntity("PilotAvatar",e);
	end
end

function ENT:Think()
 
    self.BaseClass.Think(self);
   
    if(IsValid(self.Pilot)) then
        if(self.Pilot:KeyPressed(IN_MOVELEFT) or self.Pilot:KeyPressed(IN_MOVERIGHT)) then
            if(!self.PlayedStrafe) then
                local count = table.Count(self.StrafeSounds);
                local r = math.random(1,count);
                self:EmitSound(self.StrafeSounds[r]);
               
            end
        end  
    end
    if(self.Inflight) then
        self:NextThink(CurTime());
        return true;
    end
end
 
 
end
 
if CLIENT then

	ENT.CanFPV = true; // Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
        //Engine=Sound("ambient/atmosphere/ambience_base.wav"),
        Engine=Sound("vehicles/koro2/fly_koro2_base_loop.wav"), // This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
    }

    //This is where we set how the player sees the ship when flying
    local View = {}
    local function CalcView()      
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("Koro2", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*40+self:GetForward()*-35+self:GetRight()*0; // This is the position of the first person view if you have it
			View = SWVehicleView(self,500,200,fpvPos,true); // 700 is distance from vehicle, 200 is the height. The final argument is for lookaround, if you set it to true earlier do the same here.
			return View;
		end
    end
    hook.Add("CalcView", "Koro2View", CalcView) // This is very important. Make sure the middle arguement is unique. In this case the ship name + view
 
	hook.Add("ScoreboardShow","Koro2ScoreDisable", function()
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingKoro2");
		if(Flying) then
			return false;
		end
	end)
 
	local function Koro2Reticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingKoro2"); // Koro2 should be what you named your ship near the top
		local self = p:GetNWEntity("Koro2");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(1500); 
			//SW_WeaponReticles(self);
			//SW_HUD_DrawOverheating(self);
			
			local x = ScrW()/2; // The first person position of the compass. Set both x and y appropriatly
			local y = ScrH()/4*3.1;
			//SW_HUD_Compass(self,x,y); // Draw the compass/radar
			SW_HUD_DrawSpeedometer(); // Draw the speedometer
		end
	end
    hook.Add("HUDPaint", "Koro2Reticle", Koro2Reticle)
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/