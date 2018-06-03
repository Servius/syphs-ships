ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"

ENT.PrintName = "AT-AT Prank"
ENT.Author = "Syphadias, Doctor Jew"
ENT.Category = "Star Wars Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/at-at.mdl"
ENT.Vehicle = "ATATPrank"
ENT.StartHealth = 6666;
ENT.Allegiance = "Neutral";

list.Set("SWVehicles", ENT.PrintName, ENT);
if SERVER then

ENT.FireSound = Sound("weapons/xwing_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("atat_prank");
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
		Left = self:GetPos()+self:GetRight()*-65+self:GetUp()*25+self:GetForward()*42,
		Right = self:GetPos()+self:GetRight()*65+self:GetUp()*25+self:GetForward()*42,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2500;
	self.ForwardSpeed = 1500;
	self.UpSpeed = 750;
	self.AccelSpeed = 10;
	self.CanStandby = true;
	self.CanShoot = false;
	self.HasWings = true;
	self.AlternateFire = true;
	self.FireGroup = {"Left","Right"};
	
	RunConsoleCommand("timeforaparty")
	
	self.Bullet = CreateBulletStructure(100,"red");

	self.BaseClass.Initialize(self)
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
			blue:SetDieTime(0)
			blue:SetStartAlpha(0)
			blue:SetEndAlpha(0)
			blue:SetStartSize(0)
			blue:SetEndSize(0)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local dynlight = DynamicLight(id + 4096 * k);
			dynlight.Pos = v+FWD*-5;
			dynlight.Brightness = 0;
			dynlight.Size = 0;
			dynlight.Decay = 0;
			dynlight.R = 00;
			dynlight.G = 0;
			dynlight.B = 0;
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
				self:GetPos()+self:GetForward()*-150+self:GetUp()*28+self:GetRight()*14.5,
				self:GetPos()+self:GetForward()*-150+self:GetUp()*28+self:GetRight()*-17,
			}
			if(!TakeOff and !Land) then
				self:FlightEffects();
			end
		end
	end
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("ATATPrank", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*500+self:GetForward()*-1000;
			View = SWVehicleView(self,1000,500,fpvPos);		
			return View;
		end
	end
	hook.Add("CalcView", "ATATPrankView", CalcView)
	
	local HUD = surface.GetTextureID("vgui/eta_cockpit");
	function ATATPrankReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingATATPrank");
		local self = p:GetNWEntity("ATATPrank");
		if(Flying and IsValid(self)) then
			
			//if(self:GetFPV()) then
			//	SW_HUD_FPV(HUD);
			//end

			SW_HUD_DrawHull(100);
			SW_WeaponReticles(self);
			SW_HUD_DrawOverheating(self);
			local x = ScrW()/4*0.4;
			local y = ScrH()/4*3.1;
			SW_HUD_Compass(self,x,y);
			SW_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "ATATPrankReticle", ATATPrankReticle)

end