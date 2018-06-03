ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"

ENT.PrintName = "Podracer Neva Kee"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.Vehicle = "PodNevaKee";
ENT.EntModel = "models/starwars/lordtrilobite/podracers/podracer_neva_kee.mdl";
ENT.StartHealth = 1200;

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("nevakee");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*90+self:GetForward()*98+self:GetRight()*0;
	local driverAng = self:GetAngles()+Angle(0,-90,0);
	self:SpawnChairs(driverPos,driverAng,false);

	//self:TestLoc(self:GetPos()+self:GetUp()*0+self:GetForward()*265+self:GetRight()*0)
	
	self.ForwardSpeed = 750;
	self.BoostSpeed = 1300
	self.AccelSpeed = 5.5;
	self.HoverMod = -2
	self.StartHover = 100
	
	self.ExitModifier = {x=0,y=80,z=120};
	
	self.OGForward = self.ForwardSpeed;
end

 function ENT:TestLoc(pos)

local e = ents.Create("prop_physics");
e:SetPos(pos);
e:SetModel("models/props_junk/PopCan01a.mdl");
e:Spawn();
e:Activate();
e:SetParent(self);

end

function ENT:Think()
    if(self.Inflight) then
        if(self.Pilot:KeyDown(IN_RELOAD)) then
            self.VehicleHealth = self.VehicleHealth + 5;
            self:SetNWInt("Health",self.VehicleHealth);
        end
    end
	self.BaseClass.Think(self)
end

function ENT:OnTakeDamage(dmg)
    self.ForwardSpeed = self.OGForward - (self.StartHealth - self.VehicleHealth)
    self.BaseClass.OnTakeDamage(self,dmg);
end

ENT.BoostTimer = CurTime();
function ENT:Boost()
	
	if(self.NextUse.Boost < CurTime()) then
		//self.Accel.FWD = self.BoostSpeed;
		//self.Boosting = true;
		self:EmitSound(Sound("podracer/pod_shift.wav"),100,100,1,CHAN_VOICE)
		//self.BoostTimer = CurTime()+5;
		//self.NextUse.Boost = CurTime() + 10;
	end

end

local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetUp()*0+self:GetForward()*-265+self:GetRight()*0;
	self.FrontPos = self:GetPos()+self:GetUp()*0+self:GetForward()*265+self:GetRight()*0;
	self.MiddlePos = self:GetPos()+self:GetUp()*0+self:GetForward()*0+self:GetRight()*0;
	if(self.Inflight) then
		local UP = ZAxis;
		self.RightDir = self.Entity:GetForward():Cross(UP):GetNormalized();
		self.FWDDir = self.Entity:GetForward();	


		
		self:RunTraces();

		self.ExtraRoll = Angle(0,0,self.YawAccel / 2*-1);
		if(!self.WaterTrace.Hit) then
			if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
				self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-0,0)/4,0,0)
			else
				self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-0,0)/4,0,0)
			end
		end
	end

	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	

end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("podracer/pod_loop.wav"),
	}
	//Engine=Sound("landspeeder_fly.wav"),
	local Health = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			self:Effects();
		end
		
	end

    function ENT:Effects()
        local normal = (self:GetForward() * -100):GetNormalized() // More or less the direction. You can leave this for the most part (If it's going the opposite way, then change it 1 not -1)
        local roll = math.Rand(-90,90) // Random roll so the effect isn't completely static (Useful for heatwave type)
        local p = LocalPlayer() // Player (duh)
        local id = self:EntIndex(); //Need this later on.
   
        //Get the engine pos the same way you get weapon pos
        self.EnginePos = {
            self:GetPos()+self:GetForward()*-155+self:GetUp()*89+self:GetRight()*-111.4,
            self:GetPos()+self:GetForward()*-155+self:GetUp()*89+self:GetRight()*111.4,
        }
		self.EnginePos2 = {
            self:GetPos()+self:GetForward()*110+self:GetUp()*89+self:GetRight()*-111.4,
            self:GetPos()+self:GetForward()*110+self:GetUp()*89+self:GetRight()*111.4,
        }
   
        for k,v in pairs(self.EnginePos) do
   
            local red = self.FXEmitter:Add("sprites/orangecore1",v) // This is where you add the effect. The ones I use are either the current or "sprites/bluecore"
            red:SetVelocity(normal) //Set direction we made earlier
            red:SetDieTime(.075) //How quick the particle dies. Make it larger if you want the effect to hang around
            red:SetStartAlpha(255) // Self explanitory. How visible it is.
            red:SetEndAlpha(255) // How visible it is at the end
            red:SetStartSize(30) // Start size. Just play around to find the right size.
            red:SetEndSize(4) // End size
            red:SetRoll(roll) // They see me rollin. (They hatin')
            red:SetColor(255,200,100) // Set the colour in RGB. This is more of an overlay colour effect and doesn't change the material source.
 
 			local heatwv = self.FXEmitter:Add("sprites/heatwave",v);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.075);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(32);
			heatwv:SetEndSize(5);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
 
            local dynlight = DynamicLight(id + 4096 * k); // Create the "glow"
            dynlight.Pos = v; // Position from the table
            dynlight.Brightness = 6; // Brightness, Don't go above 10. It's blinding
            dynlight.Size = 50; // How far it reaches
            dynlight.Decay = 500; // Not really sure what this does, but I leave it in
            dynlight.R = 255; // Colour R
            dynlight.G = 200; // Colour G
            dynlight.B = 200; // Colour B
            dynlight.DieTime = CurTime()+1; // When the light should die
        end
		
		for k,v in pairs(self.EnginePos2) do
 			
			local heatwv = self.FXEmitter:Add("sprites/heatwave",v);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(.1);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(70);
			heatwv:SetEndSize(50);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
		end
    end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("PodNevaKee", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*-550+self:GetUp()*225; //+self:GetRight()*115;
					//local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()+Angle(0,0,0);
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
		end
	end
	hook.Add("CalcView", "PodNevaKeeView", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "PodNevaKeeDrawPlayerModel", function( p )
		local self = p:GetNWEntity("PodNevaKee", NULL);
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	function PodNevaKeeReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingPodNevaKee");// Flying with your unique name
		local self = p:GetNWEntity("PodNevaKee"); // Unique name
		if(Flying and IsValid(self)) then
			SW_Speeder_DrawHull(1200)
			SW_Speeder_DrawSpeedometer()
		end
	end
	hook.Add("HUDPaint", "PodNevaKeeReticle", PodNevaKeeReticle) //Unique names again
end