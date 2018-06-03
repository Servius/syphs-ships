ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

//Edit appropriatly. I'd prefer it if you left my name
ENT.PrintName = "FOC Star Viper"
ENT.Author = "Liam0102, Syphadias"

// Leave the same
ENT.Category = "Star Wars" // Techincally you could change this, but personally I'd leave it so they're all in the same place (Looks more proffesional).
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/starwars/syphadias/ships/starviper/starviper_c.mdl" //The oath to the model you want to use.
ENT.Vehicle = "FOCSViper" //The internal name for the ship. It cannot be the same as a different ship.
ENT.StartHealth = 2000;
ENT.Allegiance = "Neutral"

if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav"); // The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; //Leave this alone for the most part.

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("starviper"); // This should be the same name as the file
	//You can ignore the rest
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth); // Set the ship health, to the start health as made earlier
	
	//The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
	self.WeaponLocations = {
		Right1 = self:GetPos()+self:GetForward()*85+self:GetUp()*110+self:GetRight()*66, 
		Right2 = self:GetPos()+self:GetForward()*85+self:GetUp()*110+self:GetRight()*72,
		Left1 = self:GetPos()+self:GetForward()*85+self:GetUp()*110+self:GetRight()*-66,
		Left2 = self:GetPos()+self:GetForward()*85+self:GetUp()*110+self:GetRight()*-72,
	}
	
	self.WeaponsTable = {}; // IGNORE
	self.BoostSpeed = 1500; // The speed we go when holding SHIFT
	self.ForwardSpeed = 2500; // The forward speed
	self.UpSpeed = 550; // Up/Down Speed
	self.AccelSpeed = 9; // How fast we get to our previously set speeds
	self.CanBack = true; // Can we move backwards? Set to true if you want this.
	self.CanStandby = true;
	self.CanShoot = false;
	self.HasWings = true;
	self.ClosedModel = "models/starwars/syphadias/ships/starviper/starviper_c.mdl"
	self.OpenModel = "models/starwars/syphadias/ships/starviper/starviper_o.mdl"
	// Ignore these.
	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	
	self.ChatterSounds = {
	Sound("vehicles/starviper/chatter/approach.wav"), Sound("vehicles/starviper/chatter/formation1.wav"), Sound("vehicles/starviper/chatter/moving4.wav"), Sound("vehicles/starviper/chatter/reporting2.wav"), 
	Sound("vehicles/starviper/chatter/attack1.wav"), Sound("vehicles/starviper/chatter/formation2.wav"), Sound("vehicles/starviper/chatter/moving5.wav"), Sound("vehicles/starviper/chatter/rightaway.wav"), 
	Sound("vehicles/starviper/chatter/attack2.wav"), Sound("vehicles/starviper/chatter/heading1.wav"), Sound("vehicles/starviper/chatter/orders1.wav"), Sound("vehicles/starviper/chatter/saythatagainplease.wav"), 
	Sound("vehicles/starviper/chatter/attack3.wav"), Sound("vehicles/starviper/chatter/heading2.wav"), Sound("vehicles/starviper/chatter/orders2.wav"), Sound("vehicles/starviper/chatter/speed.wav"), 
	Sound("vehicles/starviper/chatter/attack4.wav"), Sound("vehicles/starviper/chatter/heading3.wav"), Sound("vehicles/starviper/chatter/orders3.wav"), Sound("vehicles/starviper/chatter/targeting1.wav"), 
	Sound("vehicles/starviper/chatter/bringthemon.wav"), Sound("vehicles/starviper/chatter/heading4.wav"), Sound("vehicles/starviper/chatter/orders4.wav"), Sound("vehicles/starviper/chatter/targeting2.wav"), 
	Sound("vehicles/starviper/chatter/buzzdroids1.wav"), Sound("vehicles/starviper/chatter/heading5.wav"), Sound("vehicles/starviper/chatter/orders5.wav"), Sound("vehicles/starviper/chatter/targeting3.wav"), 
	Sound("vehicles/starviper/chatter/buzzdroids2.wav"), Sound("vehicles/starviper/chatter/icopy.wav"), Sound("vehicles/starviper/chatter/orders6.wav"), Sound("vehicles/starviper/chatter/thisway.wav"), 
	Sound("vehicles/starviper/chatter/fire1.wav"), Sound("vehicles/starviper/chatter/incoming.wav"), Sound("vehicles/starviper/chatter/overthere.wav"), Sound("vehicles/starviper/chatter/transmission.wav"), 
	Sound("vehicles/starviper/chatter/fire2.wav"), Sound("vehicles/starviper/chatter/keepgoing.wav"), Sound("vehicles/starviper/chatter/pleaserepeat.wav"), Sound("vehicles/starviper/chatter/weaponsarmed1.wav"), 
	Sound("vehicles/starviper/chatter/fire3.wav"), Sound("vehicles/starviper/chatter/moving1.wav"), Sound("vehicles/starviper/chatter/readyforaction1.wav"), Sound("vehicles/starviper/chatter/weaponsarmed2.wav"), 
	Sound("vehicles/starviper/chatter/fire4.wav"), Sound("vehicles/starviper/chatter/moving2.wav"), Sound("vehicles/starviper/chatter/readyforaction2.wav"), Sound("vehicles/starviper/chatter/weareonstation.wav"),
	Sound("vehicles/starviper/chatter/fire5.wav"), Sound("vehicles/starviper/chatter/moving3.wav"), Sound("vehicles/starviper/chatter/reporting1.wav"),
	}
	timer.Create(self.Vehicle .. "ChatterTimer" .. self:EntIndex(), 40, 0, function()
	if(IsValid(self)) then
	local rand = math.random(1,51);
	self:EmitSound(self.ChatterSounds[rand],50,100,1);
	end
	end)

	self.ExitModifier = {x=0,y=-200,z=15};
	
	self.Bullet = CreateBulletStructure(40,"green"); // The first number is bullet damage, the second colour. green and red are the only options
	
	
	self.BaseClass.Initialize(self); // Ignore, needed to work
end

function ENT:ToggleWings()
	if(self.Wings) then
		self:SetModel(self.ClosedModel);
		self.Wings = false;
		else
		self:SetModel(self.OpenModel);
		self.Wings = true;
	end
	self.NextUse.Wings = CurTime() + 1;
	self:EmitSound(Sound("vehicles/starviper/starviper_wing.wav"),100,100);
end

function ENT:Think()
	self.BaseClass.Think(self);
	if(self.Inflight) then
		if(!self.Wings) then
			self.CanShoot = false;
		else
			self.CanShoot = true;
		end
	end
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
	ENT.CanFPV = false; // Set to true if you want FPV
    ENT.EnginePos = {}
    ENT.Sounds={
        //Engine=Sound("ambient/atmosphere/ambience_base.wav"),
        Engine=Sound("vehicles/starviper/starviperfly_loop.wav"), // This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
    }

 
    //This is where we set how the player sees the ship when flying
    local View = {}
    local function CalcView()
       
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("FOCSViper", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos(); // This is the position of the first person view if you have it
			View = SWVehicleView(self,700,200,fpvPos);		// 700 is distance from vehicle, 200 is the height.
			return View;
		end
    end
    hook.Add("CalcView", "FOCSViperView", CalcView) // This is very important. Make sure the middle arguement is unique. In this case the ship name + view
 
    local function FOCSViperReticle() //Make this unique. Again Ship name + Reticle
       
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingFOCSViper");
		local self = p:GetNWEntity("FOCSViper");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(2000); // Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
        end
    end
    hook.Add("HUDPaint", "FOCSViperReticle", FOCSViperReticle) // Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
 
end
 
/*
Put this file in lua/entities/
Then package up the addon like normal and upload.
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.
 
Make sure this is the only file in lua/entities/
 
*/