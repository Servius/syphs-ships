ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "TIE Fighter (First Order)"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: First Order"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/vehicles/star wars the force awakens/spartanmark6/FO_TIE_fighter.mdl" 
ENT.Vehicle = "FOTie" 

ENT.Allegiance = "First Order"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav"); -- The sound to make when firing the weapons. You do not need the sounds folder at the start
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),}; --Leave this alone for the most part.
ENT.StartHealth = 3000; --How much health they should have.

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("fo_tie_fighter"); -- This should be the same name as the file
	--You can ignore the rest
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end



function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth); -- Set the ship health, to the start health as made earlier
	
	--The locations of the weapons (Where we shoot out of), local to the ship. These largely just take a lot of tinkering.
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*65+self:GetUp()*152.5+self:GetRight()*16.25, 
		Left = self:GetPos()+self:GetForward()*65+self:GetUp()*152.5+self:GetRight()*-16.25,
	}
	self.WeaponsTable = {}; -- IGNORE
	self.BoostSpeed = 2500; -- The speed we go when holding SHIFT
	self.ForwardSpeed = 1750; -- The forward speed
	self.UpSpeed = 550; -- Up/Down Speed
	self.AccelSpeed = 10; -- How fast we get to our previously set speeds
	self.CanBack = true; -- Can we move backwards? Set to true if you want this.
	self.CanShoot = true 
	self.FireDelay = 0.15
	self.ExitModifier = {x=-6, y=0, z=0}
	
	-- Ignore these.
	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	
	self.Bullet = CreateBulletStructure(80,"green"); -- The first number is bullet damage, the second colour. green and red are the only options
	
	--self:TestLoc(self:GetPos()+self:GetForward()*65+self:GetUp()*152.5+self:GetRight()*-16.25)
	
	self.BaseClass.Initialize(self); -- Ignore, needed to work
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

	function ENT:Draw() self:DrawModel() end -- Ignore
	
	ENT.EnginePos = {}
	ENT.Sounds={
		--Engine=Sound("ambient/atmosphere/ambience_base.wav"),
		Engine=Sound("vehicles/tie/tie_fly3.wav"), -- This is the flight sound. These can get complicated, so I'd use the ones I've already put in the addon
	}

	--Ignore these variables and the function.
	local FPV = false;
	local Health = 0;
	local Overheat = 0;
	local Overheated = false;
	ENT.NextView = CurTime();
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWBool("Flying"..self.Vehicle);
		
		local IsDriver = p:GetNWEntity(self.Vehicle) == self.Entity;
		if(IsFlying and IsDriver) then
			Health = self:GetNWInt("Health");
			Overheat = self:GetNWInt("Overheat");
			Overheated = self:GetNWBool("Overheated");
			--if(p:KeyDown(IN_WALK)) then
			--	if(self.NextView < CurTime()) then
			--		if(FPV) then
			--			FPV = false;
			--		else
			--			FPV = true;
			--		end
			--		self.NextView = CurTime() + 1;
			--	end
			--end
		end
		
		
		
		
	end

	--"ambient/atmosphere/ambience_base.wav"
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("FOTie", NULL) -- Set the first arguement to what we named the ship earlier.
		local pos;
		local face;
		
		if(IsValid(self)) then
			if(FPV) then
				pos = self:GetPos()+self:GetUp()*180+self:GetRight()*-15+self:GetForward()*35;
				face = self:GetAngles();
			else
				pos = self:GetPos()+self:GetUp()*300+LocalPlayer():GetAimVector():GetNormal()*-700;			
				face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
			end
			View.origin = pos;
			View.angles = face;
			return View;
		end
	end
	hook.Add("CalcView", "FOTieView", CalcView) -- This is very important. Make sure the middle arguement is unique. In this case the ship name + view

	function FOTieReticle() --Make this unique. Again Ship name + Reticle
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingFOTie"); -- This should be "Flying" + Your ship name
		local self = p:GetNWEntity("FOTie"); -- Should be your ship name
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(3000); -- Replace 1000 with the starthealth at the top
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "FOTieReticle", FOTieReticle) -- Here you need to make the middle argument something unique again. I've set it as what the function is called. Could be anything. And the final arguement should be the function just made.
	
end

/*
Put this file in lua/entities/
Then package up the addon like normal and upload. 
Now you need to set your addon on the upload page, to require my addon.
This way the only thing in your addon is the unique files, and should I make any changes to fighter_base and the sounds etc. you'll get those changes.

Make sure this is the only file in lua/entities/

*/