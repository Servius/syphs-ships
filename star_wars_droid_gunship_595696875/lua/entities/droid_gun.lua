ENT.RenderGroup = RENDERGROUP_OPAQUE;
ENT.Base = "fighter_base";
ENT.Type = "vehicle";
 
ENT.PrintName = "Droid Gunship";
ENT.Author = "Liam0102, Syphadias";
 
ENT.Category = "Star Wars Vehicles: CIS"; 
ENT.AutomaticFrameAdvance = true;
ENT.Spawnable = false;
ENT.AdminOnly = false; 
 
ENT.EntModel = "models/syphadias/starwars/gunship.mdl" 
ENT.Vehicle = "DGun" 
ENT.StartHealth = 3000; 
ENT.Allegiance = "CIS"
 
list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then
 
ENT.FireSound = Sound("weapons/xwing_shoot.wav"); -- The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; --Leave this alone for the most part.

 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("droid_gun"); -- This should be the same name as the file
	local spawn_height = 250; -- How high above the ground the vehicle spawns. Change if it's spawning too high, or spawning in the ground.
	
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
		Middle = self:GetPos() + self:GetForward() * 585 + self:GetRight() * 0 + self:GetUp() * -91.75,
        Left = self:GetPos() + self:GetForward() * -30 + self:GetRight() * -432 + self:GetUp() * -17.25,
    }
    self.WeaponsTable = {}; -- IGNORE. Needed to give players their weapons back
    self.BoostSpeed = 2000; -- The speed we go when holding SHIFT
    self.ForwardSpeed = 1500; -- The forward speed 
    self.UpSpeed = 600; -- Up/Down Speed
    self.AccelSpeed = 4; -- How fast we get to our previously set speeds
    self.CanBack = true; -- Can we move backwards? Set to true if you want this.
	self.CanRoll = false; -- Set to true if you want the ship to roll, false if not
	self.CanStrafe = true; -- Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = true; -- Set to true if you want the ship to hover when not inflight
	self.CanShoot = true; -- Set to true if you want the ship to be able to shoot, false if not
	
	self.AlternateFire = false -- Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	self.FireGroup = {"Left","Right","TopLeft","TopRight"} -- In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	self.OverheatAmount = 50 --The amount a ship can fire consecutively without overheating. 50 is standard.
	self.DontOverheat = false; -- Set this to true if you don't want the weapons to ever overheat. Mostly only appropriate on Admin vehicles.
	self.MaxIonShots = 25; -- The amount of Ion shots a vehicle can take before being disabled. 20 is the default.
	
	self.NextBlast = 1;
	
	self.LandOffset = Vector(0,0,125); -- Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
 

    self.Bullet = CreateBulletStructure(60,"red",false); -- The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits). The final one is for splash damage. Set to true if you don't want splashdamage.
	
    self.BaseClass.Initialize(self); -- Ignore, needed to work
end

function ENT:Think()
 
    if(self.Inflight) then
        --self.AccelSpeed = math.Approach(self.AccelSpeed,7,0.2);
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 300 + self:GetRight() * 181.75 + self:GetUp() * 9, --1
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -181.75 + self:GetUp() * 9, --1
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 218.75 + self:GetUp() * 9, --2
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -218.75 + self:GetUp() * 9, --2
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 237 + self:GetUp() * -30, --3
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -237 + self:GetUp() * -30, --3
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 255.75 + self:GetUp() * 9, --4
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -255.75 + self:GetUp() * 9, --4
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 276 + self:GetUp() * -30, --5
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -276 + self:GetUp() * -30, --5
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 293 + self:GetUp() * 9, --6
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -293 + self:GetUp() * 9, --6
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * 331.5 + self:GetUp() * 9, --7
						self:GetPos() + self:GetForward() * 300 + self:GetRight() * -331.5 + self:GetUp() * 9, --7
                    } --Table of the positions from which to fire
                    self:FireDroidBlast(self.BlastPositions[self.NextBlast], false, 100, 100, true, 8, Sound("weapons/n1_cannon.wav"));
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

--Added by Liam0102
function ENT:FireDroidBlast(pos,gravity,vel,dmg,white,size,snd)
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

	ENT.CanFPV = false; -- Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
        --Engine=Sound("ambient/atmosphere/ambience_base.wav"),
        Engine=Sound("vehicles/droidgs/droidgs_fly.wav"), -- This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
    }

 
    --This is where we set how the player sees the ship when flying
    local View = {}
    local function CalcView()      
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("DGun", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos(); -- This is the position of the first person view if you have it
			View = SWVehicleView(self,1500,250,fpvPos);		-- 700 is distance from vehicle, 200 is the height.
			return View;
		end
    end
    hook.Add("CalcView", "DGunView", CalcView) -- This is very important. Make sure the middle arguement is unique. In this case the ship name + view
 
	local function DGunReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingDGun");
		local self = p:GetNWEntity("DGun");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(3000); -- Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_BlastIcon(self,10);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
    hook.Add("HUDPaint", "DGunReticle", DGunReticle) -- Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/