ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "speeder_base"
ENT.Type = "vehicle"
ENT.PrintName = "V-4X-D Ski Speeder"
ENT.Author = "Liam0102, Syphadias"
ENT.Category = "Star Wars Vehicles: Rebels"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Vehicle = "SkiSpeeder"
ENT.EntModel = "models/starwars/syphadias/ships/skispeeder/skispeeder.mdl"
ENT.StartHealth = 2000
list.Set("SWVehicles", ENT.PrintName, ENT)

if SERVER then
	ENT.NextUse = {
		Use = CurTime(),
		Fire = CurTime()
	}

	ENT.FireSound = Sound("weapons/ski_speeder/sw02_s1_weapons_cannons_skispeeder_laser_close_var_02.wav")
	AddCSLuaFile()

	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("skispeeder")
		e:SetPos(tr.HitPos + Vector(0, 0, 10))
		e:SetAngles(Angle(0, pl:GetAimVector():Angle().Yaw + 270, 0))
		e:Spawn()
		e:Activate()

		return e
	end

	function ENT:Initialize()
		self.SeatClass = "phx_seat2"
		self.BaseClass.Initialize(self)
		local driverPos = self:GetPos() + self:GetUp() * 65 + self:GetRight() * -15 + self:GetForward() * -250
		local driverAng = self:GetAngles()
		local passPos = self:GetPos() + self:GetUp() * 25 + self:GetRight() * 40 + self:GetForward() * 20
		self:SpawnChairs(driverPos, driverAng, false, passPos, driverAng)

		self.WeaponLocations = {
			Left = self:GetPos() + self:GetForward() * 243 + self:GetRight() * -150 + self:GetUp() * 79,
			Right = self:GetPos() + self:GetForward() * 262 + self:GetRight() * -150 + self:GetUp() * 81.3
		}

		self.WeaponDir = self:GetAngles():Right()
		self:SpawnWeapons()
		self.ForwardSpeed = -900
		self.BoostSpeed = -1800
		self.AccelSpeed = 6
		self.HoverMod = 15
		self.CanBack = true
		self.StartHover = 67
		self.StandbyHoverAmount = 50
		self.CanShoot = true
		self.Bullet = CreateBulletStructure(100, "red")
		--self:TestLoc(self:GetPos() + self:GetForward() * 262 + self:GetRight() * -147 + self:GetUp() * 81.3)
		self:SpawnFan()
		self.FanInfo = {{"models/starwars/syphadias/ships/skispeeder/skispeeder_fan.mdl", self:GetPos() + self:GetForward() * 0 + self:GetRight() * 40.5 + self:GetUp() * 151.7, self:GetAngles()}}
		self:SpawnRudder(self:GetPos() + self:GetForward() * 0 + self:GetRight() * 178.5 + self:GetUp() * 113.5)

		self.ExitModifier = {
			x = -20,
			y = -330,
			z = 5
		}
	end

	function ENT:FireWeapons()
		if (self.NextUse.Fire < CurTime()) then
			for k, v in pairs(self.Weapons) do
				local tr = util.TraceLine({
					start = self:GetPos(),
					endpos = self:GetPos() + self:GetRight() * -10000,
					filter = {self}
				})

				local angPos = (tr.HitPos - v:GetPos())
				self.Bullet.Src = v:GetPos()
				self.Bullet.Attacker = self.Pilot or self
				self.Bullet.Dir = angPos
				v:FireBullets(self.Bullet)
			end

			self:EmitSound(self.FireSound, 120, math.random(90, 110))
			self.NextUse.Fire = CurTime() + (self.FireDelay or 0.3)
		end
	end

	function ENT:SpawnFan()
		self.Fan = {}

		if not (self.FanInfo) then
			self.FanInfo = {{"models/starwars/syphadias/ships/skispeeder/skispeeder_fan.mdl", self:GetPos() + self:GetForward() * 0 + self:GetRight() * 40.5 + self:GetUp() * 151.7, self:GetAngles()}}
		end

		for k, v in pairs(self.FanInfo) do
			Speed = self:GetNWInt("Speed")
			local e = ents.Create("prop_physics")
			self.FanBlade = e
			e:SetModel(v[1])
			e:SetPos(v[2])
			e:SetAngles(v[3])
			e:Spawn()
			e:Activate()
			constraint.Axis(e, self, 0, 0, Vector(0, 0, -100), Vector(0, 0, 0), 0, 0, 0, 0, Vector(0, 0, 100))
			e:SetCollisionGroup(COLLISION_GROUP_WORLD)
			e:SetFriction(10000)
			e:GetPhysicsObject():Wake()
			self.Fan[k] = e
		end
	end

	function ENT:SpawnRudder(pos)
		local e = ents.Create("prop_physics")
		e:SetPos(pos)
		e:SetAngles(self:GetAngles())
		e:SetModel("models/starwars/syphadias/ships/skispeeder/skispeeder_rudder.mdl")
		e:Spawn()
		e:Activate()
		e:GetPhysicsObject():Wake()
		e:SetParent(self)
		self.Rudder = e
	end

	function ENT:Boost()
		if (self.NextUse.Boost < CurTime()) then
			self.Accel.FWD = self.BoostSpeed
			self.Boosting = true
			self:EmitSound(Sound("vehicles/ski_speeder/boost.wav"), 85, 100, 1, CHAN_VOICE)
			self.BoostTimer = CurTime() + 7
			self.NextUse.Boost = CurTime() + 10
		end
	end

	function ENT:Think()
		self.BaseClass.Think(self)

		if (self.FanBlade) then
			self.FanBlade:GetPhysicsObject():AddAngleVelocity(Vector(0, 0, 10000))
		end
		--[[if(self.Pilot:KeyDown(IN_MOVERIGHT)) then
		self.Rudder = SetAngles(self:GetAngles())
	elseif(self.Pilot:KeyDown(IN_MOVELEFT)) then
		self.Rudder = SetAngles(self:GetAngles())
	else
		self.Rudder = SetAngles(self:GetAngles())
	end]]
	end

	function ENT:OnRemove()
		self.BaseClass.OnRemove(self)

		if (self.FanBlade) then
			self.FanBlade:Remove()
		end
	end

	--function ENT:TestLoc(pos)
	--
	--	local e = ents.Create("prop_physics");
	--	e:SetPos(pos);
	--	e:SetModel("models/props_junk/PopCan01a.mdl");
	--	e:Spawn();
	--	e:Activate();
	--	e:SetParent(self);
	--
	--end
	function ENT:OnTakeDamage(dmg)
		local health = self:GetNetworkedInt("Health") - (dmg:GetDamage() / 2)
		self:SetNWInt("Health", health)

		if (health < 100) then
			self.CriticalDamage = true
			self:SetNWBool("CriticalDamage", true)
		end

		if ((health) <= 0) then
			self:Bang() -- Go boom
		end
	end

	--########## Shuttle's aren't invincible are they? @RononDex
	local ZAxis = Vector(0, 0, 1)

	function ENT:PhysicsSimulate(phys, deltatime)
		self.BackPos = self:GetPos() + self:GetUp() * 20 + self:GetRight() * 120 + self:GetForward() * 0
		self.FrontPos = self:GetPos() + self:GetUp() * 20 + self:GetRight() * -120 + self:GetForward() * 0
		self.MiddlePos = self:GetPos() + self:GetUp() * 20 + self:GetForward() * 0

		if (self.Inflight) then
			local UP = ZAxis
			local rud = self.Rudder
			self.RightDir = self.Entity:GetForward()
			self.FWDDir = self.Entity:GetForward():Cross(UP):GetNormalized()
			self:RunTraces()
			self.ExtraRoll = Angle(self.YawAccel / 2 * -.8)

			if (not self.WaterTrace.Hit) then
				if (self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
					self.PitchMod = Angle(0, 0, math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z), -45, 45) / 2 * -1)
				else
					self.PitchMod = Angle(0, 0, math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z), -45, 45) / 2 * -1)
				end
			end
			--[[if(self.Pilot:KeyDown(IN_MOVERIGHT)) then
			rud:SetAngles(Angle(0,45,0))
		elseif(self.Pilot:KeyDown(IN_MOVELEFT)) then
			rud:SetAngles(Angle(0,-45,0))
		else
			rud:SetAngles(Angle:Forward())
		end]]
		end

		self.BaseClass.PhysicsSimulate(self, phys, deltatime)
	end
end

if CLIENT then
	ENT.Sounds = {
		Engine = Sound("vehicles/ski_speeder/sw02_s1_vehicles_skispeeder_rear_close_01.wav")
	}

	local Health = 0

	function ENT:Think()
		self.BaseClass.Think(self)
		local p = LocalPlayer()
		local Flying = p:GetNWBool("Flying" .. self.Vehicle)

		if (Flying) then
			Health = self:GetNWInt("Health")
			local EnginePos = {self:GetPos() + self:GetUp() * -55 + self:GetRight() * 150 + self:GetForward() * 0}
			--self:GetPos()+self:GetRight()*85+self:GetForward()*-64+self:GetUp()*30,
			--self:GetPos()+self:GetRight()*85+self:GetForward()*75+self:GetUp()*32,
			self:Effects(EnginePos, true)
			Speed = self:GetNWInt("Speed")
		end
	end

	function ENT:Effects(pos)
		if (spd > 901) then
			local p = LocalPlayer()
			local roll = math.Rand(-15, 15)
			local normal = self.Entity:GetForward():GetNormalized()
			local id = self:EntIndex()

			for k, v in pairs(pos) do
				local blue = self.FXEmitter:Add("particles/smokey", v)
				blue:SetVelocity(normal)
				blue:SetDieTime(2) --FrameTime()*9)
				blue:SetStartAlpha(255)
				blue:SetEndAlpha(1)
				blue:SetStartSize(15)
				blue:SetEndSize(175)
				blue:SetRoll(roll)
				blue:SetColor(138, 7, 7)
				local dynlight = DynamicLight(id + 4096 * k)
				dynlight.Pos = v
				dynlight.Brightness = 3
				dynlight.Size = 80
				dynlight.Decay = 1024
				dynlight.R = 0
				dynlight.G = 0
				dynlight.B = 0
				dynlight.DieTime = CurTime() + 1
			end
		end
	end

	ENT.HasCustomCalcView = true
	local View = {}

	function CalcView()
		local p = LocalPlayer()
		local self = p:GetNWEntity("SkiSpeeder", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat", NULL)
		local PassengerSeat = p:GetNWEntity("PassengerSeat", NULL)

		if (IsValid(self)) then
			if (IsValid(DriverSeat)) then
				if (DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos() + LocalPlayer():GetAimVector():GetNormal() * -400 + self:GetUp() * 200
					--local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					local face = self:GetAngles() + Angle(0, -90, 0)
					local face = ((self:GetPos() + Vector(0, 0, 100)) - pos):Angle()
					View.origin = pos
					View.angles = face

					return View
				else
					View.origin = DriverSeat:GetPos() + self:GetUp() * 42 + self:GetForward() * 0 + self:GetRight() * -5
					View.angles = face

					return View
				end
				--local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
				--local face = self:GetAngles() + Angle(0,-90,0);
			elseif (IsValid(PassengerSeat)) then
				if (PassengerSeat:GetThirdPersonMode()) then
					local pos = self:GetPos() + LocalPlayer():GetAimVector():GetNormal() * -400 + self:GetUp() * 100
					local face = ((self:GetPos() + Vector(0, 0, 100)) - pos):Angle()
					View.origin = pos
					View.angles = face

					return View
				end
			end
		end
	end

	hook.Add("CalcView", "SkiSpeederView", CalcView)

	hook.Add("ShouldDrawLocalPlayer", "SkiSpeederDrawPlayerModel", function(p)
		local self = p:GetNWEntity("SkiSpeeder", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat", NULL)
		local PassengerSeat = p:GetNWEntity("PassengerSeat", NULL)

		if (IsValid(self)) then
			if (IsValid(DriverSeat)) then
				if (DriverSeat:GetThirdPersonMode()) then return true end
			elseif (IsValid(PassengerSeat)) then
				if (PassengerSeat:GetThirdPersonMode()) then return true end
			end
		end
	end)

	function V4XDSpeederHUD()
		local p = LocalPlayer()
		local Flying = p:GetNWBool("FlyingSkiSpeeder")
		local self = p:GetNWEntity("SkiSpeeder")

		if (Flying and IsValid(self)) then
			local WeaponsPos = {self:GetPos()}
			--SW_Speeder_Reticles(self,WeaponsPos)
			SW_Speeder_DrawHull(2000)
			SW_Speeder_DrawSpeedometer()
		end
	end

	hook.Add("HUDPaint", "V4XDSpeederHUD", V4XDSpeederHUD)
end