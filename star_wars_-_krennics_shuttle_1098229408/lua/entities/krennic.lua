local addons = engine.GetAddons();
local hasSWV = false;
for k,v in pairs(addons) do
    if(v.wsid == "495762961") then
        hasSWV = true;
        break;
    end
end
if(!hasSWV) then return end;
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Type = "vehicle"
ENT.Base = "fighter_base"

ENT.PrintName = "Krennic's Shuttle"
ENT.Author = "Liam0102"
ENT.Category = "Star Wars Vehicles: Empire"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/starwars/lordtrilobite/ships/krennic_shuttle/krennic_shuttle_land.mdl";
ENT.FlyDownModel = "models/starwars/lordtrilobite/ships/krennic_shuttle/krennic_shuttle_up.mdl";
ENT.FlyUpModel = "models/starwars/lordtrilobite/ships/krennic_shuttle/krennic_shuttle_down.mdl";
ENT.Vehicle = "Krennic"
ENT.StartHealth = 4500;
ENT.Allegiance = "Empire";
list.Set("SWVehicles", ENT.PrintName, ENT);

if SERVER then
ENT.HyperDriveSound = Sound("vehicles/hyperdrive.mp3");
ENT.FireSound = Sound("weapons/tie_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),LightSpeed = CurTime(),Switch=CurTime()};


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("krennic");
	e:SetPos(tr.HitPos + Vector(0,0,5));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	
	self:SetNWInt("Health",self.StartHealth);
	self.CanRoll = true;
	self.WeaponLocations = {
		RightL = self:GetPos()+self:GetForward()*365+self:GetUp()*32.5+self:GetRight()*175,
		LeftR = self:GetPos()+self:GetForward()*365+self:GetUp()*32.5+self:GetRight()*-195,
		RightR = self:GetPos()+self:GetForward()*365+self:GetUp()*32.5+self:GetRight()*195,
		LeftL = self:GetPos()+self:GetForward()*365+self:GetUp()*32.5+self:GetRight()*-175,
	}
	self.WeaponsTable = {};
	//self:SpawnWeapons();
	self.BoostSpeed = 2500;
	self.ForwardSpeed = 1250;
	self.UpSpeed = 500;
	self.AccelSpeed = 8;
	self.CanStandby = false;
	self.Cooldown = 2;
	self.Overheat = 0;
	self.Overheated = false;
	self.CanShoot = true;
	self.CanRoll = false;
    self.CanStrafe = true;
	self.AlternateFire = true;
	self.FireGroup = {"RightR","RightL","LeftR","LeftL"}
    self.FireDelay = 0.4;
	self.HasWings = true;
	self.ExitModifier = {x = 0, y = 155, z = 125};
	self.HasLookaround = true;
	self.LandOffset = Vector(0,0,5);
	self.PilotVisible = true;
    self.PilotPosition = Vector(20, -22.5, 230);
	self.HasLightspeed = true;
	self.Bullet = CreateBulletStructure(70,"green");

    self.HasSeats = true;
    self.SeatPos = {
        {self:LocalToWorld(Vector(-57.25, -62.25, 135)),self:GetAngles()+Angle(0,0,0),Vector(-57.25, 0, 125)},
        {self:LocalToWorld(Vector(-90, -62.25, 135)),self:GetAngles()+Angle(0,0,0),Vector(-90, 0, 125)},
        {self:LocalToWorld(Vector(-122.25, -62.25, 135)),self:GetAngles()+Angle(0,0,0),Vector(-122.25, 0, 125)},
        {self:LocalToWorld(Vector(-155, -62.25, 135)),self:GetAngles()+Angle(0,0,0),Vector(-155, 0, 125)},
            
        {self:LocalToWorld(Vector(-57.25, 62.25, 135)),self:GetAngles()+Angle(0,180,0),Vector(-57.25, 0, 125)},
        {self:LocalToWorld(Vector(-90, 62.25, 135)),self:GetAngles()+Angle(0,180,0),Vector(-90, 0, 125)},
        {self:LocalToWorld(Vector(-122.25, 62.25, 135)),self:GetAngles()+Angle(0,180,0),Vector(-122.25, 0, 125)},
        {self:LocalToWorld(Vector(-155, 62.25, 135)),self:GetAngles()+Angle(0,180,0),Vector(-155, 0, 125)},

        StandingLeft = {self:LocalToWorld(Vector(30,80,105)),self:GetAngles()+Angle(0,90,0),Vector(30,0,125)},
        StandingRight = {self:LocalToWorld(Vector(30,-80,105)),self:GetAngles()+Angle(0,90,0),Vector(30,-0,125)},
        Cockpit = {self:LocalToWorld(Vector(-25, 17.5, 225)),self:GetAngles()+Angle(0,-90,0),Vector(-145,0,120)}
    };

	self.BaseClass.Initialize(self)

    self:SetStanding();
end
    
function ENT:SetStanding()
   self.Seats["StandingLeft"]:SetVehicleClass("krennic_seat"); 
   self.Seats["StandingRight"]:SetVehicleClass("krennic_seat"); 
end
    
function ENT:Use(p)
   
    local min = self:LocalToWorld(Vector(-150, -62.25, 130));
    local max = self:LocalToWorld(Vector(-160, 62.25, 155))
    for k,v in pairs(ents.FindInBox(min,max)) do
        if(v == p) then
            if(!self.Inflight and !p:KeyDown(IN_WALK)) then
                self:Enter(p);
                return;
            else
                self:EnterCockpit(p);
                return
            end
        end
    end
    if(p:KeyDown(IN_WALK)) then
       self:Passenger(p);     
    end
end
    
function ENT:EnterCockpit(p)
   
    local v = self.Seats["Cockpit"];
    if(IsValid(v)) then
        if(v:GetPassenger(1) == NULL) then
           p:EnterVehicle(v);
        else
            self:Passenger(p);
        end
    end
        
end
    
function ENT:Enter(p)
    self.BaseClass.Enter(self,p);     
    if(self.Inflight) then
        self:SetModel(self.FlyDownModel);
        self:RestartPhysics();
    end
end
    
function ENT:Exit(kill)
    if(self.TakeOff or self.Land) then
        self:SetModel(self.EntModel);
        self:RestartPhysics();
    end
    self.BaseClass.Exit(self,kill);
end
    
function ENT:ToggleWings()
    if(!IsValid(self)) then return end;
	if(self.NextUse.Wings < CurTime()) then
		if(self.Wings) then
			self:SetModel(self.FlyDownModel);
			self.Wings = false;
		else
			self.Wings = true;
			self:SetModel(self.FlyUpModel);
		end
        self:RestartPhysics();
		self:SetNWBool("Wings",self.Wings);
		if(IsValid(self.Pilot)) then
			self.Pilot:SetNWBool("SW_Wings",self.Wings);
		end
		self.NextUse.Wings = CurTime() + 1;
	end
end
    
function ENT:RestartPhysics()
    self:PhysicsInit(SOLID_VPHYSICS);
    if(self.Inflight) then
        if(IsValid(self:GetPhysicsObject())) then
            self:GetPhysicsObject():EnableMotion(true);
            self:GetPhysicsObject():SetMass(self.Mass);
            self:GetPhysicsObject():Wake();
        end
    end
    self:StartMotionController();     
end
    

end

if CLIENT then

	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicles/mf/mf_fly5.wav"),
	}
	
	local TakeOff;
	local Land;
	ENT.NextView = CurTime();
    local LightSpeed = 0;
	function ENT:Think()
		

		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local IsFlying = p:GetNWBool("Flying"..self.Vehicle);
		local Wings = self:GetNWBool("Wings");
		TakeOff = self:GetNWBool("TakeOff");
		Land = self:GetNWBool("Land");
        if(IsFlying) then
			LightSpeed = self:GetNWInt("LightSpeed");
		end
		if(Flying) then
            self.EnginePos = {
                self:GetPos()+self:GetForward()*-270+self:GetUp()*170+self:GetRight()*62.5,
                self:GetPos()+self:GetForward()*-266.25+self:GetUp()*163.125+self:GetRight()*67.8125,
                self:GetPos()+self:GetForward()*-262.5+self:GetUp()*156.25+self:GetRight()*73.125,
                self:GetPos()+self:GetForward()*-258.75+self:GetUp()*149.375+self:GetRight()*78.4375,
                self:GetPos()+self:GetForward()*-255+self:GetUp()*142.5+self:GetRight()*83.75,
                self:GetPos()+self:GetForward()*-251.25+self:GetUp()*135.625+self:GetRight()*89.0625,
                self:GetPos()+self:GetForward()*-247.5+self:GetUp()*128.75+self:GetRight()*94.375,
                self:GetPos()+self:GetForward()*-243.75+self:GetUp()*121.875+self:GetRight()*99.6875,
                self:GetPos()+self:GetForward()*-240+self:GetUp()*115+self:GetRight()*105,

                self:GetPos()+self:GetForward()*-270+self:GetUp()*170+self:GetRight()*-62.5,
                self:GetPos()+self:GetForward()*-266.25+self:GetUp()*163.125+self:GetRight()*-67.8125,
                self:GetPos()+self:GetForward()*-262.5+self:GetUp()*156.25+self:GetRight()*-73.125,
                self:GetPos()+self:GetForward()*-258.75+self:GetUp()*149.375+self:GetRight()*-78.4375,
                self:GetPos()+self:GetForward()*-255+self:GetUp()*142.5+self:GetRight()*-83.75,
                self:GetPos()+self:GetForward()*-251.25+self:GetUp()*135.625+self:GetRight()*-89.0625,
                self:GetPos()+self:GetForward()*-247.5+self:GetUp()*128.75+self:GetRight()*-94.375,
                self:GetPos()+self:GetForward()*-243.75+self:GetUp()*121.875+self:GetRight()*-99.6875,
                self:GetPos()+self:GetForward()*-240+self:GetUp()*115+self:GetRight()*-105,
            }
			if(!TakeOff and !Land) then
				self:FlightEffects();
			end

		end
		self.BaseClass.Think(self);
		
	end

    ENT.ViewDistance = 2000;
    ENT.ViewHeight = 550;
	ENT.CanFPV = true;
    ENT.FPVPos = Vector(-27.5, -17.5, 265);
	function KrennicReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingKrennic");
		local self = p:GetNWEntity("Krennic");
		

		if(Flying and IsValid(self)) then
            local x = ScrW()/4*0.1;
			local y = ScrH()/4*2.5;
			if(self:GetFPV()) then			
				SW_HUD_WingsIndicator("krennic",x,y);
			end
			SW_HUD_DrawHull(4500);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
            local pos = self:GetPos()+self:GetUp()*250;
            local x,y = SW_XYIn3D(pos);
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "KrennicReticle", KrennicReticle)

	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local id = self:EntIndex();
        local FWD = self:GetForward();
		for k,v in pairs(self.EnginePos) do

            local red = self.FXEmitter:Add("sprites/bluecore",v+FWD*-7.5)
            red:SetVelocity(normal)
            red:SetDieTime(FrameTime()*1.25)
            red:SetStartAlpha(255)
            red:SetEndAlpha(255)
            red:SetStartSize(25)
            red:SetEndSize(20)
            red:SetRoll(roll)
            red:SetColor(255,255,255)
				
		end
			
        
		for i=1,2 do
            local dynlight = DynamicLight(id + 4096*i);
            dynlight.Pos = self.EnginePos[9*i];
            dynlight.Brightness = 5;
            dynlight.Size = 200;
            dynlight.Decay = 1024;
            dynlight.R = 80;
            dynlight.G = 80;
            dynlight.B = 255;
            dynlight.DieTime = CurTime()+1;
        end
	end
	
    hook.Add("CalcVehicleView", "KrennicSeatView", function(veh,p,view)
        local IsPassenger  = IsValid(p:GetVehicle()) and IsValid(p:GetVehicle():GetParent()) and p:GetVehicle():GetParent().IsSWVehicle;
        if(IsPassenger and p:GetNWBool("KrennicPassenger") and veh:GetVehicleClass() == "krennic_seat") then
            local pos = view.origin + Vector(0,0,30);
            view.origin = pos;
            return view;
        end
    end)
end