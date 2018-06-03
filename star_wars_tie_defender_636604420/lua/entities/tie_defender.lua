ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "TIE Defender"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Empire" 
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.EntModel = "models/tie_def/syphadias/tie_def.mdl" 
ENT.Vehicle = "TieDef" 
ENT.Allegiance = "Empire"
 
list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then
 
ENT.FireSound = Sound("weapons/tie_shoot.wav"); // The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; //Leave this alone for the most part.
ENT.StartHealth = 2250; //How much health they should have.
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("tie_defender"); // This should be the same name as the file
    //You can ignore the rest
    e:SetPos(tr.HitPos + Vector(0,0,10));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
 
 
    self:SetNWInt("Health",self.StartHealth); // Set the ship health, to the start health as made earlier
   
    //The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
    self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*115+self:GetUp()*145+self:GetRight()*10, 
		Left = self:GetPos()+self:GetForward()*115+self:GetUp()*145+self:GetRight()*-10,
    }
    self.WeaponsTable = {}; // IGNORE
    self.BoostSpeed = 1900; // The speed we go when holding SHIFT
    self.ForwardSpeed = 1350; // The forward speed 
    self.UpSpeed = 600; // Up/Down Speed
    self.AccelSpeed = 8; // How fast we get to our previously set speeds
    self.CanBack = true; // Can we move backwards? Set to true if you want this.
	self.CanRoll = false; // Set to true if you want the ship to roll, false if not
	self.CanStrafe = false; // Set to true if you want the ship to strafe, false if not. You cannot have roll and strafe at the same time
	self.CanStandby = false; // Set to true if you want the ship to hover when not inflight
	self.CanShoot = true; // Set to true if you want the ship to be able to shoot, false if not
	
	self.AlternateFire = false // Set this to true if you want weapons to fire in sequence (You'll need to set the firegroups below)
	//self.FireGroup = {"Left","Right"} // In this example, the weapon positions set above will fire with Left and TopLeft at the same time. And Right and TopRight at the same time.
	
	self.ExitModifier = {x=0,y=-100,z=5};
	
	self.LandOffset = Vector(0,0,0); // Change the last 0 if you're vehicle is having trouble landing properly. (Make it larger)
 
    // Ignore these.
    self.Cooldown = 2;

    self.Bullet = CreateBulletStructure(80,"green"); // The first number is bullet damage, the second colour. green and red are the only options. (Set to blue for ion shot, the damage will be halved but ships will be disabled after consecutive hits).
	
	self.ChatterSounds = {
		Sound("vehicles/tie_def/chatter/TDP0101_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0102_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0103_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0104_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0105_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0106_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0107_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0108_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0109_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0110_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0111_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0112_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0113_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0114_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0115_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0201_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0202_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0203_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0204_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0205_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0206_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0207_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0208_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0209_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0210_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0211_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP2012_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0213_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0214_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0215_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0301_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0302_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0303_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0304_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0305_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0306_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0307_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0308_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0309_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0310_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0311_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0312_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0313_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0314_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0315_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0501_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0502_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0503_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0504_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0601_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0602_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0603_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0604_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0701_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0702_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0703_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0704_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0801_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0802_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0803_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP0804_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0901_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0902_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0903_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP0904_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP1001_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1002_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1003_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1004_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1101_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP1102_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1103_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1104_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1201_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1202_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP1203_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1204_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1301_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1302_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1303_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP1304_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1401_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1402_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1601_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1602_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP1603_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1604_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP1613_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP2901_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP2902_ENG.wav"),
		Sound("vehicles/tie_def/chatter/TDP3001_ENG.wav"), Sound("vehicles/tie_def/chatter/TDP3002_ENG.wav"),
	}
	timer.Create(self.Vehicle .. "ChatterTimer" .. self:EntIndex(), 30, 0, function()
	if(IsValid(self)) then
	local rand = math.random(1,51);
	self:EmitSound(self.ChatterSounds[rand],50,100,1);
	end
	end)
	
    self.BaseClass.Initialize(self); // Ignore, needed to work
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
 
    function ENT:Draw() self:DrawModel() end // Ignore
	ENT.CanFPV = true; // Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
        //Engine=Sound("ambient/atmosphere/ambience_base.wav"),
        Engine=Sound("vehicles/tie/tie_fly3.wav"), // This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
    }

 
    //This is where we set how the player sees the ship when flying
    local View = {}
    local function CalcView()
       
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("TieDef", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetForward()*3+self:GetUp()*185+self:GetRight()*0 // This is the position of the first person view if you have it
			View = SWVehicleView(self,700,400,fpvPos);		// 700 is distance from vehicle, 200 is the height.
			return View;
		end
    end
    hook.Add("CalcView", "TieDefView", CalcView) // This is very important. Make sure the middle arguement is unique. In this case the ship name + view
 
	local HUD = surface.GetTextureID("vgui/tie_cockpit");
	
    local function TieDefReticle() //Make this unique. Again Ship name + Reticle
       
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingTieDef");
		local self = p:GetNWEntity("TieDef");
		if(Flying and IsValid(self)) then
			if(SW_GetFPV()) then
				SW_HUD_FPV(HUD);
            end
			SW_HUD_DrawHull(2250); // Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
    end
    hook.Add("HUDPaint", "TieDefReticle", TieDefReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/