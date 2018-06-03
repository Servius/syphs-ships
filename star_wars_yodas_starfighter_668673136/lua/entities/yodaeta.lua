ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "Eta-2 (Yoda)"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/starwars/syphadias/ships/yoda_starfighter/yoda_starfighter_closed.mdl"
ENT.Vehicle = "YodaEta"
ENT.StartHealth = 1000;
ENT.Allegiance = "Republic"

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("yodaeta");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	self.CanRoll = true;
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetRight()*-38+self:GetUp()*28+self:GetForward()*105,
		Right = self:GetPos()+self:GetRight()*38+self:GetUp()*28+self:GetForward()*105,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2500;
	self.ForwardSpeed = 1500;
	self.UpSpeed = 750;
	self.AccelSpeed = 10;
	self.CanStandby = true;
	self.CanShoot = true;
	self.HasWings = true;
	self.AlternateFire = true;
	self.FireGroup = {"Left","Right"};
	
	self.OpenModel = "models/starwars/syphadias/ships/yoda_starfighter/yoda_starfighter_open.mdl"
	self.ClosedModel = "models/starwars/syphadias/ships/yoda_starfighter/yoda_starfighter_closed.mdl"
	
	self.ExitModifier = {x=0,y=60,z=5};
	
	self.Bullet = CreateBulletStructure(100,"green");

	self.BaseClass.Initialize(self)
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
   //self:EmitSound(Sound("vehicles/"),50,100,1);
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
	ENT.CanFPV = true;

	local matPlasma	= Material( "effects/strider_muzzle" )
	function ENT:Draw() 
		self:DrawModel()		
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		local vel = self:GetVelocity():Length();
		if(vel > 150) then
			if(Flying and !TakeOff and !Land) then
				for i=1,2 do
					local vOffset = self.EnginePos[i] 
					local scroll = CurTime() * -20
						
					render.SetMaterial( matPlasma )
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 24, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 20, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 24, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 20, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					scroll = scroll * 0.9
					
					render.StartBeam( 3 )
						render.AddBeam( vOffset, 24, scroll, Color( 0, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-5, 20, scroll + 0.01, Color( 255, 255, 255, 255) )
						render.AddBeam( vOffset + self:GetForward()*-40, 16, scroll + 0.02, Color( 0, 255, 255, 0) )
					render.EndBeam()
					
					
				end
			end
		end
	end
		
		
	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicles/eta/eta_fly.wav"),
	}

	function ENT:FlightEffects()
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		local p = LocalPlayer()		
		local FWD = self:GetForward();
		local id = self:EntIndex();

		for k,v in pairs(self.EnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*-5)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.025)
			blue:SetStartAlpha(255)
			blue:SetEndAlpha(100)
			blue:SetStartSize(8)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v+FWD*-5;
			dynlight.Brightness = 5;
			dynlight.Size = 150;
			dynlight.Decay = 1024;
			dynlight.R = 100;
			dynlight.G = 100;
			dynlight.B = 255;
			dynlight.DieTime = CurTime()+1;
			
		end
	
	end

	
	local Health = 0;
	local Overheat = 0;
	local Overheated = false;
	local FPV = false;
	function ENT:Think()
	
		self.BaseClass.Think(self)
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		local TakeOff = self:GetNWBool("TakeOff");
		local Land = self:GetNWBool("Land");
		if(Flying) then
			self.EnginePos = {
				self:GetPos()+self:GetForward()*-50+self:GetUp()*22+self:GetRight()*14.2,
				self:GetPos()+self:GetForward()*-50+self:GetUp()*22+self:GetRight()*-15,
			}
			if(!TakeOff and !Land) then
				self:FlightEffects();
			end
		end
		
	end
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("YodaEta", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*50+self:GetForward()*30;
			View = SWVehicleView(self,400,200,fpvPos);		
			return View;
		end
	end
	hook.Add("CalcView", "YodaEtaView", CalcView)
	
	local HUD = surface.GetTextureID("vgui/eta_cockpit");
	function YodaEtaReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingYodaEta");
		local self = p:GetNWEntity("YodaEta");
		if(Flying and IsValid(self)) then
			
			if(SW_GetFPV()) then
				SW_HUD_FPV(HUD);
			end

			SW_HUD_DrawHull(1000);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			SW_HUD_Compass(self);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "YodaEtaReticle", YodaEtaReticle)

end