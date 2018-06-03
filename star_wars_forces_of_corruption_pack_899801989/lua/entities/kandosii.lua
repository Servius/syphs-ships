ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "FOC Kandosii"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Other"
list.Set("SWVehicles", ENT.PrintName, ENT);
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;
ENT.AdminOnly = true;

ENT.EntModel = "models/starwars/syphadias/ships/kandosii/kandosii.mdl"
ENT.Vehicle = "FOCKandosii"
ENT.StartHealth = 15000;
ENT.IsCapitalShip = true;
ENT.Allegiance = "Neutral"

if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),LightSpeed=CurTime(),Switch=CurTime(),};
ENT.HyperDriveSound = Sound("vehicles/hyperdrive.mp3");

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("kandosii");
	e:SetPos(tr.HitPos + Vector(0,0,1650));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*100+self:GetUp()*70+self:GetRight()*-70,
		Right = self:GetPos()+self:GetForward()*100+self:GetUp()*70+self:GetRight()*70,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = -450;
	self.ForwardSpeed = -525;
	self.UpSpeed = 400;
	self.AccelSpeed = 8;
	self.CanStandby = true;
	self.CanBack = true;
	self.CanRoll = false;
	self.CanStrafe = false;
	self.Cooldown = 2;
	self.HasWings = false;
	self.CanShoot = false;
	self.Bullet = CreateBulletStructure(75,"green");
	self.FireDelay = 0.15;
	self.WarpDestination = Vector(0,0,0);
	if(WireLib) then
		Wire_CreateInputs(self, { "Destination [VECTOR]", })
	else
		self.DistanceMode = true;
	end
	
	self.OGForward = -100;
	self.OGBoost = -200;
	self.OGUp = 100;
	
	self.SeatPos = {
		{self:GetPos()+self:GetUp()*350+self:GetForward()*209+self:GetRight()*270, self:GetAngles()+Angle(0,180,0)},
		{self:GetPos()+self:GetUp()*350+self:GetForward()*209+self:GetRight()*-270, self:GetAngles()},
	}
	self.GunnerSeats = {};
	self:SpawnGunnerSeats();

	
	self.LeftWeaponLocations = {
		self:GetPos()+self:GetUp()*315+self:GetForward()*-220+self:GetRight()*365,
		self:GetPos()+self:GetUp()*315+self:GetForward()*-130+self:GetRight()*365,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*40+self:GetRight()*360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*120+self:GetRight()*360,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*290+self:GetRight()*360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*375+self:GetRight()*360,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*575+self:GetRight()*360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*650+self:GetRight()*360,	
	}
	
	self.RightWeaponLocations = {
		self:GetPos()+self:GetUp()*315+self:GetForward()*-220+self:GetRight()*-365,
		self:GetPos()+self:GetUp()*315+self:GetForward()*-140+self:GetRight()*-365,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*40+self:GetRight()*-360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*120+self:GetRight()*-360,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*290+self:GetRight()*-360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*375+self:GetRight()*-360,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*575+self:GetRight()*-360,
		self:GetPos()+self:GetUp()*315+self:GetForward()*650+self:GetRight()*-360,		
	}

	self.ExitModifier = {x=0,y=-275,z=-1625};
	
	self.EnginePos = {
		self:GetPos()+self:GetUp()*315+self:GetForward()*-220+self:GetRight()*-325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*-130+self:GetRight()*-325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*40+self:GetRight()*-325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*120+self:GetRight()*-325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*290+self:GetRight()*-325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*375+self:GetRight()*-325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*575+self:GetRight()*-325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*650+self:GetRight()*-325,	
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*-220+self:GetRight()*325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*-140+self:GetRight()*325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*40+self:GetRight()*325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*120+self:GetRight()*325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*290+self:GetRight()*325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*375+self:GetRight()*325,
		
		self:GetPos()+self:GetUp()*315+self:GetForward()*575+self:GetRight()*325,
		self:GetPos()+self:GetUp()*315+self:GetForward()*650+self:GetRight()*325,
	}
	for k,v in pairs(self.EnginePos) do
		//self:TestLoc(v);
	end
	
	self.NextBlast = 1;

	self.BaseClass.Initialize(self);
end

function ENT:TestLoc(pos)

	local e = ents.Create("prop_physics");
	e:SetPos(pos);
	e:SetModel("models/props_borealis/bluebarrel001.mdl");
	e:Spawn();
	e:Activate();
	e:SetParent(self);
	
end

function ENT:Think()

	if(IsValid(self.LeftGunner)) then
		if(self.GunnerSeats[1]:GetThirdPersonMode()) then
			self.GunnerSeats[1]:SetThirdPersonMode(false);
		end
		if(self.LeftGunner:KeyDown(IN_ATTACK)) then
			self:FireLeft(self.LeftGunner:GetAimVector():Angle():Forward());
		end
	end
	
	if(IsValid(self.RightGunner)) then
		if(self.GunnerSeats[2]:GetThirdPersonMode()) then
			self.GunnerSeats[2]:SetThirdPersonMode(false);
		end
		if(self.RightGunner:KeyDown(IN_ATTACK)) then
			self:FireRight(self.RightGunner:GetAimVector():Angle():Forward());
		end
	end
	if(self.Inflight) then
	
		/*
		if(IsValid(self.Pilot)) then
		
			if(self.Pilot:KeyDown(IN_ATTACK) and self.Pilot:KeyDown(IN_ATTACK2)) then
				local p = self.Pilot;
				self:Exit(false);
				self.Pilot = NULL;
				if(!self.LeftGunner) then
					self:GunnerEnter(p,false);
				else
					self:GunnerEnter(p,true);
				end
			end
		end
		*/
		
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

    if(self.Inflight) then
        //self.AccelSpeed = math.Approach(self.AccelSpeed,7,0.2);
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1625, //1
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1575, //1
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1500, //2
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1450, //2
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1375, //3
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1325, //3
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1080, //4
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -1030, //4
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -955, //5
						self:GetPos() + self:GetForward() * 100 + self:GetRight() * 0 + self:GetUp() * -905, //5
                    } //Table of the positions from which to fire
                    self:FireKandosiiBlast(self.BlastPositions[self.NextBlast], true, 1, 3000, false, 50, Sound("weapons/n1_cannon.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 11) then
						self.NextUse.FireBlast = CurTime()+20;
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

function ENT:FireKandosiiBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("cannon_blast");
	
	e.Damage = dmg or 2000;
	e.IsWhite = white or false;
	e.StartSize = size or 20;
	e.EndSize = size*0.75 or 15;
	
	local sound = snd or Sound("weapons/n1_cannon.wav");
	
	e:SetPos(pos);
	e:Spawn();
	e:Activate();
	e:Prepare(self,sound,gravity,vel);
	e:SetColor(Color(255,0,0,1));
	
end

hook.Add("PlayerLeaveVehicle", "FOCKandosiiSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsRepGunnerSeat) then
			local e = v:GetParent();
			if(v.IsRight) then
				e:GunnerExit(true,p);
			else
				e:GunnerExit(false,p);
			end
		end
	end
end);

function ENT:FireLeft(angPos)

	if(self.NextUse.Fire < CurTime()) then
		for k,v in pairs(self.LeftWeapons) do

			self.Bullet.Attacker = self.Pilot or self;
			self.Bullet.Src		= v:GetPos();
			self.Bullet.Dir = angPos

			v:FireBullets(self.Bullet)
		end
		self:EmitSound(self.FireSound,100,math.random(80,120));
		self.NextUse.Fire = CurTime() + (self.FireDelay or 0.2);
	end
end

function ENT:FireRight(angPos)

	if(self.NextUse.Fire < CurTime()) then
		for k,v in pairs(self.RightWeapons) do

			self.Bullet.Attacker = self.Pilot or self;
			self.Bullet.Src		= v:GetPos();
			self.Bullet.Dir = angPos

			v:FireBullets(self.Bullet)
		end
		self:EmitSound(self.FireSound,100,math.random(80,120));
		self.NextUse.Fire = CurTime() + (self.FireDelay or 0.2);
	end
end

function ENT:SpawnWeapons()
	self.LeftWeapons = {};
	self.RightWeapons = {};
	for k,v in pairs(self.LeftWeaponLocations) do
		local e = ents.Create("prop_physics");
		e:SetModel("models/props_junk/PopCan01a.mdl");
		e:SetPos(v);
		e:Spawn();
		e:Activate();
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetSolid(SOLID_NONE);
		e:AddFlags(FL_DONTTOUCH);
		e:SetColor(Color(255,255,255,0));
		e:SetParent(self);
		e:GetPhysicsObject():EnableMotion(false);
		self.LeftWeapons[k] = e;
	end

	for k,v in pairs(self.RightWeaponLocations) do
		local e = ents.Create("prop_physics");
		e:SetModel("models/props_junk/PopCan01a.mdl");
		e:SetPos(v);
		e:Spawn();
		e:Activate();
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetSolid(SOLID_NONE);
		e:AddFlags(FL_DONTTOUCH);
		e:SetColor(Color(255,255,255,0));
		e:SetParent(self);
		e:GetPhysicsObject():EnableMotion(false);
		self.RightWeapons[k] = e;
	end
end

function ENT:SpawnGunnerSeats()
	
	for k,v in pairs(self.SeatPos) do
		local e = ents.Create("prop_vehicle_prisoner_pod");
		e:SetPos(v[1]);
		e:SetAngles(v[2]);
		e:SetParent(self);
		e:SetModel("models/nova/airboat_seat.mdl");
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetColor(Color(255,255,255,0));
		e:Spawn();
		e:Activate();
		e:SetThirdPersonMode(false);
		e:GetPhysicsObject():EnableMotion(false);
		e:GetPhysicsObject():EnableCollisions(false);
		e:SetUseType(USE_OFF);
		self.GunnerSeats[k] = e;
		if(k == 2) then
			e.IsRight = true;
		end
		e.IsRepGunnerSeat = true;
	end
end

function ENT:Use(p)

	if(p == self.Pilot or p == self.LeftGunner or p == self.RightGunner) then return end;

	if(!self.Inflight and !p:KeyDown(IN_WALK)) then
		if(p != self.LeftGunner and p != self.RightGunner) then
			self:Enter(p);
		end
	else
		if(!self.LeftGunner) then
			self:GunnerEnter(p,false);
		else
			self:GunnerEnter(p,true);
		end
	end

end

function ENT:GunnerEnter(p,right)
	if(p == self.Pilot) then return end;
	if(p == self.LeftGunner) then return end;
	if(p == self.RightGunner) then return end;
	if(self.NextUse.Use < CurTime()) then
		if(!right) then
			if(!IsValid(self.LeftGunner)) then
				p:SetNWBool("LeftGunner",true);
				self.LeftGunner = p;
				p:EnterVehicle(self.GunnerSeats[1]);
			end
		else
			if(!IsValid(self.RightGunner)) then
				p:SetNWBool("RightGunner",true);
				self.RightGunner = p;
				p:EnterVehicle(self.GunnerSeats[2]);
			end
		end
		p:SetNWEntity(self.Vehicle,self);
		self.NextUse.Use = CurTime() + 1;
	end
end

function ENT:GunnerExit(right,p)

	if(!right) then
		if(IsValid(self.LeftGunner)) then
			self.LeftGunner:SetNWBool("LeftGunner",false);
			self.LeftGunner = NULL;
		end
	else
		if(IsValid(self.RightGunner)) then
			self.RightGunner:SetNWBool("RightGunner",false);
			self.RightGunner = NULL;
		end
	end
	p:SetPos(self:GetPos()+self:GetForward()*-275+self:GetUp()*-1625+self:GetRight()*0);
	p:SetNWEntity(self.Vehicle,NULL);
	p:SetEyeAngles(self:GetAngles()+Angle(0,0,0))


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
			self.Accel.FWD = -4000;
			self.LightSpeedWarp = CurTime()+0.5;
			self.PunchIt = true;
			self:SetNWInt("LightSpeed",2);
		end
	
	else
		if(self.LightSpeedWarp < CurTime()) then
			
			self:ResetLightspeed();
			local fx = EffectData()
				fx:SetOrigin(self:GetPos())
				fx:SetEntity(self)
			util.Effect("propspawn",fx)
			self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
			self:SetPos(Dest);
			self.Accel.FWD = -500;
		end
	end
end

function ENT:ResetLightspeed()

	self.LightSpeed = false;
	self.PunchIt = false;
	self.ForwardSpeed = self.OGForward;
	self.BoostSpeed = self.OGBoost;
	self.UpSpeed = self.OGUp;
	self.PlayedSound = false;
	self:SetNWInt("LightSpeed",0);

			
end

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	self:ResetLightspeed();
	self.LightSpeedTimer = CurTime();
	self.NextUse.LightSpeed = CurTime();
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles());
	end
end

function ENT:TriggerInput(k,v)
	if(k == "Destination") then
		self.WarpDestination = v;
	end
end

local FlightPhys = {
	secondstoarrive	= 1;
	maxangular		= 5000;
	maxangulardamp	= 10000;
	maxspeed			= 1000000;
	maxspeeddamp		= 500000;
	dampfactor		= 0.8;
	teleportdistance	= 5000;
};
local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate(phys,delta)
	local FWD = self:GetForward()*-1;
	local UP = ZAxis;
	local RIGHT = FWD:Cross(UP):GetNormalized();
	if(self.Inflight) then
		phys:Wake();
		if(self.Pilot:KeyDown(IN_FORWARD) and (self.Wings or self.Pilot:KeyDown(IN_SPEED))) then
			self.num = self.BoostSpeed;
		elseif(self.Pilot:KeyDown(IN_FORWARD)) then
			self.num = self.ForwardSpeed;
		elseif(self.Pilot:KeyDown(IN_BACK) and self.CanBack) then
			self.num = (self.ForwardSpeed / 2)*-1;
		else
			self.num = 0;
		end

		self.Accel.FWD = math.Approach(self.Accel.FWD,self.num,self.Acceleration);
		
		if(self.Pilot:KeyDown(IN_MOVERIGHT)) then
			self.TurnYaw = Angle(0,-8,0);
		elseif(self.Pilot:KeyDown(IN_MOVELEFT)) then
			self.TurnYaw = Angle(0,8,0);
		else
			self.TurnYaw = Angle(0,0,0);
		end
		local ang = self:GetAngles() + self.TurnYaw;
		
		if(self.Pilot:KeyDown(IN_JUMP)) then
			self.num3 = self.UpSpeed;
		elseif(self.Pilot:KeyDown(IN_DUCK)) then
			self.num3 = -self.UpSpeed;
		else
			self.num3 = 0;
		end
		self.Accel.UP = math.Approach(self.Accel.UP,self.num3,self.Acceleration*0.9);
		
		--######### Do a tilt when turning, due to aerodynamic effects @aVoN
		local velocity = self:GetVelocity();
		local aim = self.Pilot:GetAimVector();
		//local ang = aim:Angle();
		
		
		local weight_roll = (phys:GetMass()/1000)/1.5
		local pos = self:GetPos()
		local ExtraRoll = math.Clamp(math.deg(math.asin(self:WorldToLocal(pos).y)),-25-weight_roll,25+weight_roll); -- Extra-roll - When you move into curves, make the shuttle do little curves too according to aerodynamic effects
		local mul = math.Clamp((velocity:Length()/1700),0,1); -- More roll, if faster.
		local oldRoll = ang.Roll;
		ang.Roll = (ang.Roll + self.Roll - ExtraRoll*mul) % 360;
		if (ang.Roll!=ang.Roll) then ang.Roll = oldRoll; end -- fix for nan values that cause despawing/crash.

	
		FlightPhys.angle = ang; --+ Vector(90 0, 0)
		FlightPhys.deltatime = deltatime;
		if(self.CanStrafe) then
			FlightPhys.pos = self:GetPos()+(FWD*self.Accel.FWD)+(UP*self.Accel.UP)+(RIGHT*self.Accel.RIGHT);
		else
			FlightPhys.pos = self:GetPos()+(FWD*self.Accel.FWD)+(UP*self.Accel.UP);
		end

		if(!self.CriticalDamage) then
			phys:ComputeShadowControl(FlightPhys);
		end
	else
		if(self.ShouldStandby and self.CanStandby) then
			FlightPhys.angle = self.StandbyAngles or Angle(0,self:GetAngles().y,0);
			FlightPhys.deltatime = deltatime;
			FlightPhys.pos = self:GetPos()+UP;
			phys:ComputeShadowControl(FlightPhys);		
		end
	end
		
end
end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("ambient/atmosphere/ambience_base.wav"),
	}
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	function ENT:Draw() self:DrawModel() end;
	local LightSpeed = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWEntity(self.Vehicle);
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(IsFlying) then
			LightSpeed = self:GetNWInt("LightSpeed");
		end
		
		if(Flying) then
			self.EnginePos = {
				self:GetPos()+self:GetForward()*-1570+self:GetUp()*559+self:GetRight()*-800,	//big L			1
				self:GetPos()+self:GetForward()*-1570+self:GetUp()*559+self:GetRight()*800, 	//big R			2
			}
			self.EnginePos2 = {
				self:GetPos()+self:GetForward()*-1430+self:GetUp()*430+self:GetRight()*-640,	//small L U T	3
				self:GetPos()+self:GetForward()*-1430+self:GetUp()*430+self:GetRight()*640,		//small R U T	4
				self:GetPos()+self:GetForward()*-1430+self:GetUp()*337+self:GetRight()*-530,	//small L L T	5
				self:GetPos()+self:GetForward()*-1430+self:GetUp()*337+self:GetRight()*530,		//small R L T	6
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-410+self:GetRight()*-390,	//small L U B
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-410+self:GetRight()*390,	//small R U B
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-500+self:GetRight()*-505,	//small
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-500+self:GetRight()*505,	//small
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-594+self:GetRight()*-618,	//small
				self:GetPos()+self:GetForward()*-1598+self:GetUp()*-594+self:GetRight()*618,	//small
			}
			self:Effects();
		end
	end	
	
	local View = {}
	local lastpos, lastang;
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("FOCKandosii")
		local Flying = p:GetNWBool("FlyingFOCKandosii");
		local pos,face;
		if(IsValid(self) and Flying) then
			
			if(LightSpeed == 2) then
				pos = lastpos;
				face = lastang;

				View.origin = pos;
				View.angles = face;
			else
				pos = self:GetPos()+self:GetUp()*350+LocalPlayer():GetAimVector():GetNormal()*-5000;			
				face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
				View =  SWVehicleView(self,5000,350,fpvPos);
			end
			
			lastpos = pos;
			lastang = face;
			
			return View;
		end
	end
	hook.Add("CalcView", "FOCKandosiiView", CalcView)
	
	function ENT:Effects()

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetForward() * 1):GetNormalized();
		local id = self:EntIndex();
		for k,v in pairs(self.EnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.1);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(200);
			heatwv:SetEndSize(10);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.Emitter:Add("sprites/bluecore",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(200)
			blue:SetEndSize(10)
			blue:SetRoll(roll)
			blue:SetColor(0,255,0)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 100;
			dynlight.G = 100;
			dynlight.B = 255;
			dynlight.DieTime = CurTime()+1;
			
		end

		for k,v in pairs(self.EnginePos2) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.1);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(100);
			heatwv:SetEndSize(10);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.Emitter:Add("sprites/bluecore",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(255)
			blue:SetStartSize(100)
			blue:SetEndSize(10)
			blue:SetRoll(roll)
			blue:SetColor(0,255,0)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 100;
			dynlight.G = 100;
			dynlight.B = 255;
			dynlight.DieTime = CurTime()+1;
			
		end
	end

	
	function FOCKandosiiReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingFOCKandosii");
		local self = p:GetNWEntity("FOCKandosii");
		local LeftGunner = p:GetNWBool("LeftGunner");
		local RightGunner = p:GetNWBool("RightGunner");
		
		if(IsValid(self)) then
			if(LightSpeed == 2) then
				DrawMotionBlur( 0.4, 20, 0.01 );
			end
		end
		
		if(Flying and IsValid(self)) then
			

			local x = ScrW()/10;
			local y = ScrH()/4*3.5;
			SW_HUD_DrawHull(15000,x,y);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_BlastIcon(self,20);
			
		elseif(LeftGunner and IsValid(self)) then

			local WeaponsPos = {
				self:GetPos()+self:GetUp()*860+self:GetForward()*-40+self:GetRight()*870,
				self:GetPos()+self:GetUp()*860+self:GetForward()*-70+self:GetRight()*870,
				
				self:GetPos()+self:GetUp()*895+self:GetForward()*455+self:GetRight()*920,
				self:GetPos()+self:GetUp()*895+self:GetForward()*485+self:GetRight()*940,
				
				self:GetPos()+self:GetUp()*930+self:GetForward()*970+self:GetRight()*1030,
				self:GetPos()+self:GetUp()*930+self:GetForward()*1000+self:GetRight()*1030,
				
				self:GetPos()+self:GetUp()*950+self:GetForward()*1440+self:GetRight()*1150,
				self:GetPos()+self:GetUp()*950+self:GetForward()*1470+self:GetRight()*1150,		
			}
			
			for i=1,8 do
				local tr = util.TraceLine( {
					start = WeaponsPos[i],
					endpos = WeaponsPos[i] + p:GetAimVector():Angle():Forward()*10000,
				} )

				surface.SetTextColor( 255, 255, 255, 255 );
				
				local vpos = tr.HitPos;
				
				local screen = vpos:ToScreen();
				
				surface.SetFont( "HUD_Crosshair" );	
				local tsW, tsH = surface.GetTextSize("+");
				
				local x,y;
				for k,v in pairs(screen) do
					if k=="x" then
						x = v - tsW/2;
					elseif k=="y" then
						y = v - tsH/2;
					end
				end
				
							
				surface.SetTextPos( x, y );
				surface.DrawText( "+" );
			end
		elseif(RightGunner and IsValid(self)) then
			local WeaponsPos = {
				self:GetPos()+self:GetUp()*860+self:GetForward()*-40+self:GetRight()*-870,
				self:GetPos()+self:GetUp()*860+self:GetForward()*-70+self:GetRight()*-870,
				
				self:GetPos()+self:GetUp()*895+self:GetForward()*455+self:GetRight()*-980,
				self:GetPos()+self:GetUp()*895+self:GetForward()*485+self:GetRight()*-980,
				
				self:GetPos()+self:GetUp()*930+self:GetForward()*970+self:GetRight()*-1080,
				self:GetPos()+self:GetUp()*930+self:GetForward()*1000+self:GetRight()*-1080,
				
				self:GetPos()+self:GetUp()*950+self:GetForward()*1440+self:GetRight()*-1200,
				self:GetPos()+self:GetUp()*950+self:GetForward()*1470+self:GetRight()*-1200,			
			}
			
			for i=1,8 do
				local tr = util.TraceLine( {
					start = WeaponsPos[i],
					endpos = WeaponsPos[i] + p:GetAimVector():Angle():Forward()*10000,
				} )

				surface.SetTextColor( 255, 255, 255, 255 );
				
				local vpos = tr.HitPos;
				
				local screen = vpos:ToScreen();
				
				surface.SetFont( "HUD_Crosshair" );	
				local tsW, tsH = surface.GetTextSize("+");
				
				local x,y;
				for k,v in pairs(screen) do
					if k=="x" then
						x = v - tsW/2;
					elseif k=="y" then
						y = v - tsH/2;
					end
				end
				
							
				surface.SetTextPos( x, y );
				surface.DrawText( "+" );
			end
		end
	end
	hook.Add("HUDPaint", "FOCKandosiiReticle", FOCKandosiiReticle)

end