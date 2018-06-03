ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "Interplanetary Transport"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/airbus/syphadias/airbus.mdl"
ENT.Vehicle = "Airbus"
ENT.StartHealth = 3000;
ENT.Allegiance = "Republic"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),LightSpeed=CurTime(),Switch=CurTime(),};
ENT.HyperDriveSound = Sound("vehicles/hyperdrive.mp3");

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("airbus");
	e:SetPos(tr.HitPos + Vector(0,0,120));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*125+self:GetUp()*75+self:GetRight()*-154,
		Right = self:GetPos()+self:GetForward()*125+self:GetUp()*75+self:GetRight()*160,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1200;
	self.ForwardSpeed = 700;
	self.UpSpeed = 350;
	self.AccelSpeed = 4;
	self.LandOffset = Vector(0,0,125)
	self.CanStandby = true;
	self.CanBack = true;
	self.CanRoll = false;
	self.CanStrafe = true;
	self.Cooldown = 2;
	self.CanShoot = false;
	self.Bullet = CreateBulletStructure(75,"green");
	self.FireDelay = 0.2;
	self.AlternateFire = false;
	self.FireGroup = {"Left","Right",};
	self.HasWings = false;
	self.WarpDestination = Vector(0,0,0);
	if(WireLib) then
		Wire_CreateInputs(self, { "Destination [VECTOR]", })
	else
		self.DistanceMode = true;
	end
	
	self.OGBoost = 2500;
	self.OGForward = 1000;
	self.OGUp = 600;
	
	self.ExitModifier = {x=0,y=-550,z=5};
	//self:TestLoc(self:GetPos()+self:GetForward()*200+self:GetUp()*100);
	self.SeatPos = {
		{self:GetPos()+self:GetUp()*50,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*50,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*-50,self:GetAngles()},
		
		{self:GetPos()+self:GetUp()*50+self:GetForward()*-50,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*50+self:GetForward()*-50,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*-50+self:GetForward()*-50,self:GetAngles()},
		
		{self:GetPos()+self:GetUp()*50+self:GetForward()*-100,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*50+self:GetForward()*-100,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*-50+self:GetForward()*-100,self:GetAngles()},
		
		{self:GetPos()+self:GetUp()*50+self:GetForward()*-150,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*50+self:GetForward()*-150,self:GetAngles()},
		{self:GetPos()+self:GetUp()*50+self:GetRight()*-50+self:GetForward()*-150,self:GetAngles()},
	
	}
	self:SpawnSeats();
	
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
		e:SetUseType(USE_OFF);
		e:GetPhysicsObject():EnableCollisions(false);
		e.IsAirbusSeat = true;
		e.Airbus = self;

		self.Seats[k] = e;
	end

end

hook.Add("PlayerEnteredVehicle","AirbusSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsAirbusSeat) then
			p:SetNetworkedEntity("Airbus",v:GetParent());
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "AirbusSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsAirbusSeat) then
			local e = v.Airbus;
			if(IsValid(e)) then
				p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
			end
			p:SetNetworkedEntity("Airbus",NULL);
		end
	end
end);

function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetDriver() == NULL) then
			p:EnterVehicle(v);
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

function ENT:OnTakeDamage(dmg) --########## Shuttle's aren't invincible are they? @RononDex

	if(dmg:GetAttacker() != self) then
		local health=self:GetNetworkedInt("Health")-(dmg:GetDamage()/2)

		self:SetNWInt("Health",health);
		
		if(health<=(self.StartHealth*0.33)) then
			self.HyperdriveDisabled = true;
		end
		
		if(health<=(self.StartHealth*0.1)) then
			self.CriticalDamage = true;
		end
		
		if((health)<=0) then
			self:Bang() -- Go boom
		end
	end
end

function ENT:Think()
	self.BaseClass.Think(self);
	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
		
				if(self.Pilot:KeyDown(IN_WALK) and self.NextUse.LightSpeed < CurTime()) then
					if(!self.LightSpeed and !self.HyperdriveDisabled) then
						self.LightSpeed = true;
						self.LightSpeedTimer = CurTime() + 3;
						self.NextUse.LightSpeed = CurTime() + 20;
						
					end
				end
			
			if(WireLib) then
				if(self.Pilot:KeyDown(IN_RELOAD) and self.NextUse.Switch < CurTime()) then
					if(!self.DistanceMode) then
						self.DistanceMode = true;
						self.Pilot:ChatPrint("LightSpeed Mode: Distance");
					else
						self.DistanceMode = false;
						self.Pilot:ChatPrint("LightSpeed Mode: Destination");
					end
					self.NextUse.Switch = CurTime() + 1;
				end
			end
			
		end
		if(self.LightSpeed) then
			if(self.DistanceMode) then
				self:PunchingIt(self:GetPos()+self:GetForward()*20000);
			else
				self:PunchingIt(self.WarpDestination);
			end
		end
		
	end

end

function ENT:PunchingIt(Dest)
	if(!self.PunchIt) then
		if(self.LightSpeedTimer > CurTime()) then
			self.ForwardSpeed = 0;
			self.BoostSpeed = 0;
			self.UpSpeed = 0;
			self.Accel.FWD = 0;
			self:SetNWInt("LightSpeed",1);
			if(!self.PlayedSound) then
				self:EmitSound(self.HyperDriveSound,100);
				self.PlayedSound = true;
			end
			//util.ScreenShake(self:GetPos()+self:GetForward()*-730+self:GetUp()*195+self:GetRight()*3,5,5,10,5000)
		else
			self.Accel.FWD = 4000;
			self.LightSpeedWarp = CurTime()+0.5;
			self.PunchIt = true;
			self:SetNWInt("LightSpeed",2);
		end
	
	else
		if(self.LightSpeedWarp < CurTime()) then
			
			self.LightSpeed = false;
			self.PunchIt = false;
			self.ForwardSpeed = self.OGForward;
			self.BoostSpeed = self.OGBoost;
			self.UpSpeed = self.OGUp;
			self:SetNWInt("LightSpeed",0);
			local fx = EffectData()
				fx:SetOrigin(self:GetPos())
				fx:SetEntity(self)
			util.Effect("propspawn",fx)
			self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
			self:SetPos(Dest);
			self.PlayedSound = false;
		end
	end
end

function ENT:TriggerInput(k,v)
	if(k == "Destination") then
		self.WarpDestination = v;
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
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("ambient/atmosphere/ambience_base.wav"),
	}
	
	function ENT:Draw() self:DrawModel() end;
	
	local LightSpeed = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWEntity("Airbus");
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(IsFlying) then
			LightSpeed = self:GetNWInt("LightSpeed");
		end
		
		if(Flying) then
			self:Effects();
		end
	end
	
	function ENT:Effects()
	local normal = (self:GetForward() * -1):GetNormalized() // More or less the direction. You can leave this for the most part (If it's going the opposite way, then change it 1 not -1)
	local roll = math.Rand(-90,90) // Random roll so the effect isn't completely static (Useful for heatwave type)
	local p = LocalPlayer()	// Player (duh)
	local id = self:EntIndex(); //Need this later on.
	
	//Get the engine pos the same way you get weapon pos
	self.EnginePos = {
		self:GetPos()+self:GetForward()*-1040+self:GetUp()*340+self:GetRight()*-558,
		self:GetPos()+self:GetForward()*-1040+self:GetUp()*340+self:GetRight()*0,
		self:GetPos()+self:GetForward()*-1040+self:GetUp()*340+self:GetRight()*558,
	}
	
	for k,v in pairs(self.EnginePos) do
	
		local red = self.FXEmitter:Add("sprites/orangecore1",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
		red:SetVelocity(normal) //Set direction we made earlier
		red:SetDieTime(0.03) //How quick the particle dies. Make it larger if you want the effect to hang around
		red:SetStartAlpha(255) // Self explanitory. How visible it is.
		red:SetEndAlpha(100) // How visible it is at the end
		red:SetStartSize(160) // Start size. Just play around to find the right size.
		red:SetEndSize(5) // End size
		red:SetRoll(roll) // They see me rollin. (They hatin')
		red:SetColor(255,170,0) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.

		local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
		dynlight.Pos = v; // Position from the table
 		dynlight.Brightness = 7; // Brightness, Don't go above 10. It's blinding
		dynlight.Size = 100; // How far it reaches
		dynlight.Decay = 1024; // Not really sure what this does, but I leave it in
		dynlight.R = 255; // Colour R
		dynlight.G = 170; // Colour G
		dynlight.B = 0; // Colour B
		dynlight.DieTime = CurTime()+1; // When the light should die

	end
	
	end
	
	local View = {}
	local lastpos, lastang;
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("Airbus")
		local pos,face;
		if(IsValid(self)) then
			
			if(LightSpeed == 2) then
				pos = lastpos;
				face = lastang;
			else
				pos = self:GetPos()+self:GetUp()*600+LocalPlayer():GetAimVector():GetNormal()*-2000;			
				face = ((self:GetPos() + Vector(0,0,200))- pos):Angle()
			end
			
			lastpos = pos;
			lastang = face;

			View.origin = pos;
			View.angles = face;
			return View;
		end
	end
	hook.Add("CalcView", "AirbusView", CalcView)
	
	function AirbusReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingAirbus");
		local self = p:GetNWEntity("Airbus");
		if(Flying and IsValid(self)) then
			SW_HUD_DrawHull(3000); // Replace 1000 with the starthealth at the top
			//SW_WeaponReticles(self);
			//SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
		
		if(IsValid(self)) then
			if(LightSpeed == 2) then
				DrawMotionBlur( 0.4, 20, 0.01 );
			end
		end
	end
	hook.Add("HUDPaint", "AirbusReticle", AirbusReticle)

end