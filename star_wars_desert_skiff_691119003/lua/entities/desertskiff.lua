ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "Desert Skiff"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.Vehicle = "DesertSkiff";
ENT.EntModel = "models/starwars/syphadias/ships/desert_skiff/desert_skiff.mdl";
ENT.StartHealth = 3000;
 
list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("desertskiff");
    e:SetPos(tr.HitPos + Vector(0,0,50));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
 
    self.BaseClass.Initialize(self);
    local driverPos = self:GetPos()+self:GetUp()*104+self:GetForward()*-105+self:GetRight()*0;
    local driverAng = self:GetAngles()+Angle(0,-90,0);
    self:SpawnChairs(driverPos,driverAng,false);
    self.CanBack = true;
    self.ForwardSpeed = 400;
    self.BoostSpeed = 550
    self.AccelSpeed = 6;
    self.SpeederClass = 2
    self.StartHover = 50;
    self.StandbyHoverAmount = 50;
    self.PitchMod = Angle(0,0,0)
   
    self.SeatPos = {
        {self:GetPos()+self:GetUp()*96+self:GetRight()*-19.5+self:GetForward()*-5,self:GetAngles()},
        {self:GetPos()+self:GetUp()*96+self:GetRight()*-19.5+self:GetForward()*45,self:GetAngles()},
        {self:GetPos()+self:GetUp()*96+self:GetRight()*-19.5+self:GetForward()*95,self:GetAngles()},
        {self:GetPos()+self:GetUp()*96+self:GetRight()*19.5+self:GetForward()*-5,self:GetAngles()},
        {self:GetPos()+self:GetUp()*96+self:GetRight()*19.5+self:GetForward()*45,self:GetAngles()},
        {self:GetPos()+self:GetUp()*96+self:GetRight()*19.5+self:GetForward()*95,self:GetAngles()},
    }
    self:SpawnSeats();
   
    self.ExitModifier = {x=0,y=-110,z=125}
   
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
        e:SetVehicleClass("sypha_seat");
        e:SetUseType(USE_OFF);
        //e:GetPhysicsObject():EnableMotion(false);
        //e:GetPhysicsObject():EnableCollisions(false);
        e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        e.IsDesertSkiffSeat = true;
        e.DesertSkiff = self;
 
        self.Seats[k] = e;
    end
 
end
 
function ENT:PassengerEnter(p)
    if(self.NextUse.Use > CurTime()) then return end;
    for k,v in pairs(self.Seats) do
        if(v:GetPassenger(1) == NULL) then
            p:EnterVehicle(v);
            return;        
        end
    end
end
 
function ENT:Use(p)
    if(not self.Inflight) then
        if(!p:KeyDown(IN_WALK)) then
            self:Enter(p,true);
        else
            self:PassengerEnter(p);
        end
    else
        if(p != self.Pilot) then
            self:PassengerEnter(p);
        end
    end
end
 
hook.Add("PlayerEnteredVehicle","DesertSkiffSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsDesertSkiffSeat) then
            p:SetNetworkedEntity("DesertSkiff",v:GetParent());
            p:SetNetworkedEntity("DesertSkiffSeat",v);
			p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "DesertSkiffSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsDesertSkiffSeat) then
            local e = v.DesertSkiff;
            if(IsValid(e)) then
                //p:SetPos(e:GetPos() + e:GetRight()*e.ExitModifier.x + e:GetForward() * e.ExitModifier.y + e:GetUp() * e.ExitModifier.z);
                //p:SetPos(e:GetPos()+e:GetUp()*110)
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("DesertSkiffSeat",NULL);
            p:SetNetworkedEntity("DesertSkiff",NULL);
        end
    end
end);
 
function ENT:OnTakeDamage(dmg) --########## Shuttle's aren't invincible are they? @RononDex
 
    local health=self:GetNetworkedInt("Health")-(dmg:GetDamage()/2)
 
    self:SetNWInt("Health",health);
   
    if(health<100) then
        self.CriticalDamage = true;
        self:SetNWBool("CriticalDamage",true);
    end
   
   
    if((health)<=0) then
        self:Bang() -- Go boom
    end
end
 
local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate( phys, deltatime )
    self.BackPos = self:GetPos()+self:GetForward()*-300+self:GetUp()*100;
    self.FrontPos = self:GetPos()+self:GetForward()*300+self:GetUp()*100;
    self.MiddlePos = self:GetPos()+self:GetUp()*100;
    if(self.Inflight) then
        local UP = ZAxis;
        self.RightDir = self.Entity:GetForward():Cross(UP):GetNormalized();
        self.FWDDir = self.Entity:GetForward();
 
 
       
        self:RunTraces();
 
        self.ExtraRoll = Angle(0,0,self.YawAccel / 2*-.25);
    end
   
   
    self.BaseClass.PhysicsSimulate(self,phys,deltatime);
   
 
end
 
function ENT:SpawnChairs(pos,ang,pass,pos2,ang2,pod)
 
    local e = ents.Create("prop_vehicle_prisoner_pod");
    e:SetPos(pos);
    e:SetAngles(ang);
    e:SetParent(self);
    if(!pod) then
        e:SetModel("models/nova/airboat_seat.mdl");
    else
        e:SetModel("models/vehicles/prisoner_pod_inner.mdl");
    end
    e:SetRenderMode(RENDERMODE_TRANSALPHA);
    e:SetColor(Color(255,255,255,0));
    e:Spawn();
    e:Activate();
    //e:GetPhysicsObject():EnableMotion(false);
    //e:GetPhysicsObject():EnableCollisions(false);
    e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    if("sypha_seat") then
        e:SetVehicleClass("sypha_seat");
    end
    e:SetUseType(USE_OFF);
    e.DrivingAnimType = 2;
    e.IsSpeederChair = true;
    self.DriverChair = e;  
   
   
    //if(pass) then
    //  local e = ents.Create("prop_vehicle_prisoner_pod");
    //  e:SetPos(pos2);
    //  e:SetAngles(ang2);
    //  e:SetParent(self);
    //  e:SetModel("models/nova/airboat_seat.mdl");
    //  e:SetUseType(USE_OFF);
    //  e:SetRenderMode(RENDERMODE_TRANSALPHA);
    //  e:SetColor(Color(255,255,255,0));
    //  e:Spawn();
    //  e:Activate();
    //  e:GetPhysicsObject():EnableMotion(false);
    //  e:GetPhysicsObject():EnableCollisions(false);
    //  self.PassengerChair = e;
    //  e.SpeederPassenger = true;
    //end
end
 
end
 
if CLIENT then
    ENT.Sounds={
        Engine=Sound("vehicles/landspeeder/t47_fly2.wav"),
    }
   
    local Health = 0;
    function ENT:Think()
        self.BaseClass.Think(self);
        local p = LocalPlayer();
        local Flying = p:GetNWBool("Flying"..self.Vehicle);
        if(Flying) then
            Health = self:GetNWInt("Health");
            local EnginePos = {
                Left =  self:GetPos()+self:GetRight()*-106+self:GetUp()*96,
                Right = self:GetPos()+self:GetRight()*96+self:GetUp()*96,
            }
            //self:Effects(EnginePos);
        end
       
    end
 
    local View = {}
    function CalcView()
       
        local p = LocalPlayer();
        local self = p:GetNWEntity("DesertSkiff", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local DesertSkiffSeat = p:GetNWEntity("DesertSkiffSeat",NULL);
        local pass = p:GetNWEntity("DesertSkiffSeat",NULL);
        if(IsValid(self)) then
 
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-600+self:GetUp()*250;
                    //local face = self:GetAngles() + Angle(0,-90,0);
                    local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
                        View.origin = pos;
                        View.angles = face;
                    return View;
					else
						View.origin = DriverSeat:GetPos()+self:GetUp()*74.5+self:GetForward()*0+self:GetRight()*0
						View.angles = face;
					return View;
                end
            end
       
 
            if(IsValid(pass)) then
                if(DesertSkiffSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-300+self:GetUp()*300;
                    //local face = self:GetAngles() + Angle(0,-90,0);
                    local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
                        View.origin = pos;
                        View.angles = face;
                    return View;
					else
						View.origin = DesertSkiffSeat:GetPos()+DesertSkiffSeat:GetUp()*70;
						View.angles = DesertSkiffSeat:GetAngles()+p:EyeAngles();
					return View;
                end
            end
        end
    end
    hook.Add("CalcView", "DesertSkiffView", CalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "DesertSkiffDrawPlayerModel", function( p )
        local self = p:GetNWEntity("DesertSkiff", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local DesertSkiffSeat = p:GetNWEntity("DesertSkiffSeat",NULL);
        local pass = p:GetNWEntity("DesertSkiffSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return true;
                end
            end
            if(IsValid(pass)) then
                if(DesertSkiffSeat:GetThirdPersonMode()) then
                    return true;
                end
            end
        end
    end);
   
    local function DesertSkiffHUD()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingDesertSkiff");
        local self = p:GetNWEntity("DesertSkiff");
        if(Flying and IsValid(self)) then
 
            SW_Speeder_DrawHull(3000)
            SW_Speeder_DrawSpeedometer()
 
        end
    end
    hook.Add("HUDPaint", "DesertSkiffHUD", DesertSkiffHUD)
end