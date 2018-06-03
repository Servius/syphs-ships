ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "fighter_base"
ENT.Type = "vehicle"
ENT.PrintName = "Y-Wing BTL-B"
ENT.Author = "Liam0102, Doctor Jew"
ENT.Category = "Star Wars Vehicles: Republic"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.EntModel = "models/ywing/ywing_btlb_test.mdl"
ENT.Vehicle = "YWingBtlB"
ENT.Allegiance = "Republic"
ENT.StartHealth = 900
ENT.HasLookaround = true
list.Set("SWVehicles", ENT.PrintName, ENT)
util.PrecacheModel("models/ywing/ywing_btlb_test_cockpit.mdl")

if SERVER then
	ENT.FireSound = "ywing_fire"

	ENT.NextUse = {
		Wings = CurTime(),
		Use = CurTime(),
		Fire = CurTime(),
		Repair = CurTime(),
		Torpedos = CurTime()
	}

	AddCSLuaFile()

	function ENT:SpawnFunction(pl, tr)
		local e = ents.Create("ywing_btlb")
		if not IsValid(e) then return end
		e:SetPos(tr.HitPos + Vector(100, -100, 100))
		e:SetAngles(Angle(0, pl:EyeAngles().Yaw, 0))
		e:Spawn()
		e:Activate()

		return e
	end

	function ENT:Initialize()
		self:SetNWInt("Health", self.StartHealth)
		self:SetNWBool("InShip", false)

		self.WeaponLocations = {
			Right = self:GetPos() + self:GetForward() * 520 + self:GetRight() * 25 + self:GetUp() * 40,
			Left = self:GetPos() + self:GetForward() * 520 + self:GetRight() * -25 + self:GetUp() * 40
		}

		self.BackWeaponLocation = {self:GetPos() + self:GetUp() * 115 + self:GetForward() * 195 + self:GetRight() * -18, self:GetPos() + self:GetUp() * 115 + self:GetForward() * 195 + self:GetRight() * 18}
		self.WeaponsTable = {}
		self.BoostSpeed = 1600
		self.ForwardSpeed = 1250
		self.UpSpeed = 600
		self.AccelSpeed = 7
		self.CanBack = false
		self.CanRoll = true
		self.CanStrafe = false
		self.CanStandby = true
		self.CanShoot = true
		self.FireDelay = 0.2
		self.AlternateFire = true
		self.FireGroup = {"Left", "Right"}
		self.OverheatAmount = 45
		self.DontOverheat = false
		self.MaxIonShots = 20
		self.Cooldown = 5
		self.Bullet = CreateBulletStructure(85, "blue_noion")
		self.GunnerBullet = CreateBulletStructure(30, "blue")
		self.NextUse.Count = 1
		self:SpawnTurretGuard()
		self:SpawnTurret()
		self.SeatPos = {{self:GetPos() + self:GetUp() * 85 + self:GetForward() * 255 + self:GetRight() * 0, self:GetAngles() + Angle(0, 90, 0)}}
		self.GunnerSeat = {}
		self:SpawnGunnerSeat()
		self.CanEject = true

		self.ExitModifier = {
			x = 0,
			y = -400,
			z = 0
		}

		self.PilotVisible = true

		self.PilotPosition = {
			x = 0,
			y = 300,
			z = 60
		}

		self.GunnerPosition = {
			x = 0,
			y = 300,
			z = 60
		}

		self.PilotAnim = "drive_jeep"
		self.GunnerAnim = "drive_jeep"
		self.BaseClass.Initialize(self) -- No touchy
	end

	function ENT:Enter(p)
		self:SetNWBool("InShip", true)
		self:SetNWEntity(self.Vehicle .. "Pilot", p)
		self.BaseClass.Enter(self, p)
	end

	function ENT:Exit(kill)
		self.IsFPV = false
		self:SetNWBool("InShip", false)
		self:SetNWEntity(self.Vehicle .. "Pilot", NULL)

		if (IsValid(self.Pilot)) then
			if (IsValid(self.Turret)) then
				self.Turret:SetAngles(self.Turret.LastAng or self.Turret:GetAngles())
			end

			if (IsValid(self.TurretGuard)) then
				self.TurretGuard:SetAngles(self.TurretGuard.LastAng or self.TurretGuard:GetAngles())
			end
		end

		self.BaseClass.Exit(self, kill)
	end

	function ENT:Remove()
		if IsValid(self.Turret) then
			self.Turret:Remove()
		end

		if IsValid(self.Turret) then
			self.TurretGuard:Remove()
		end

		self.BaseClass.Remove(self)
	end

	function ENT:SpawnTurret()
		local e = ents.Create("prop_dynamic")
		e:SetPos(self:GetPos() + self:GetUp() * 114 + self:GetForward() * 242)
		e:SetAngles(self:GetAngles())
		e:SetModel("models/ywing/ywing_btlb_guns.mdl")
		e:SetParent(self.TurretGuard)
		e:Spawn()
		e:Activate()
		e:GetPhysicsObject():EnableCollisions(false)
		e:GetPhysicsObject():EnableMotion(false)
		self.Turret = e
		self:SetNWEntity("Turret", e)
	end

	function ENT:SpawnTurretGuard()
		local e = ents.Create("prop_dynamic")
		e:SetPos(self:GetPos() + self:GetUp() * 105 + self:GetForward() * 256)
		e:SetAngles(self:GetAngles())
		e:SetModel("models/ywing/ywing_btlb_turret.mdl")
		e:SetParent(self)
		e:Spawn()
		e:Activate()
		e:GetPhysicsObject():EnableCollisions(false)
		e:GetPhysicsObject():EnableMotion(false)
		self.TurretGuard = e
	end

	function ENT:SpawnGunnerSeat()
		for k, v in pairs(self.SeatPos) do
			local e = ents.Create("prop_vehicle_prisoner_pod")
			e:SetPos(v[1])
			e:SetAngles(v[2])
			e:SetParent(self)
			e:SetModel("models/nova/airboat_seat.mdl")
			e:SetRenderMode(RENDERMODE_TRANSALPHA)
			e:SetColor(Color(255, 255, 255, 0))
			e:Spawn()
			e:Activate()
			e:SetThirdPersonMode(false)
			e:GetPhysicsObject():EnableMotion(false)
			e:GetPhysicsObject():EnableCollisions(false)
			e:SetUseType(USE_OFF)
			self.GunnerSeat[k] = e
			self:SetNWEntity("GunnerSeat", e)
			e.IsBackGunnerSeat = true
		end
	end

	function ENT:SpawnWeapons()
		self.BackWeapons = {}

		for k, v in pairs(self.BackWeaponLocation) do
			local e = ents.Create("prop_physics")
			e:SetModel("models/props_junk/PopCan01a.mdl")
			e:SetPos(v)
			e:Spawn()
			e:Activate()
			e:SetRenderMode(RENDERMODE_TRANSALPHA)
			e:GetPhysicsObject():EnableCollisions(false)
			e:GetPhysicsObject():EnableMotion(false)
			e:SetSolid(SOLID_NONE)
			e:AddFlags(FL_DONTTOUCH)
			e:SetColor(Color(255, 255, 255, 0))
			e:SetParent(self.Turret)
			e:GetPhysicsObject():EnableMotion(false)
			self.BackWeapons[k] = e
		end

		self.Weapons = {}

		for k, v in pairs(self.WeaponLocations) do
			local e = ents.Create("prop_physics")
			e:SetModel("models/props_junk/PopCan01a.mdl")
			e:SetPos(v)
			e:Spawn()
			e:Activate()
			e:SetRenderMode(RENDERMODE_TRANSALPHA)
			e:GetPhysicsObject():EnableCollisions(false)
			e:GetPhysicsObject():EnableMotion(false)
			e:SetSolid(SOLID_NONE)
			e:AddFlags(FL_DONTTOUCH)
			e:SetColor(Color(255, 255, 255, 0))
			e:SetParent(self)
			e:GetPhysicsObject():EnableMotion(false)
			self.Weapons[k] = e
		end
	end

	function ENT:SpawnGunner(pos)
		if (IsValid(self.BackGunner)) then
			local e = ents.Create("prop_physics")
			e:SetModel(self.BackGunner:GetModel())
			e:SetPos(pos)
			local ang = self:GetAngles()

			if (self.GunnerAngle) then
				ang = self:GetAngles() + self.GunnerAngle
			end

			e:SetAngles(ang)
			e:SetParent(self)
			e:SetNoDraw(true)
			e:Spawn()
			e:Activate()
			local anim = "sit_rollercoaster"

			if (self.GunnerAnim) then
				anim = self.GunnerAnim
			end

			e:SetSequence(e:LookupSequence(anim))
			self.GunnerAvatar = e
			self:SetNWEntity("GunnerAvatar", e)
		end
	end

	function ENT:Use(p)
		if (not self.Inflight) then
			if (not p:KeyDown(IN_WALK)) then
				self:Enter(p)
			else
				self:GunnerEnter(p)
			end
		else
			if (p ~= self.Pilot) then
				self:GunnerEnter(p)
			end
		end
	end

	function ENT:FireBack(angPos)
		if (self.NextUse.Fire < CurTime()) then
			for k, v in pairs(self.BackWeapons) do
				self.GunnerBullet.Attacker = self.BackGunner
				self.GunnerBullet.Src = v:GetPos()
				self.GunnerBullet.Dir = angPos
				v:FireBullets(self.GunnerBullet)
			end

			self:EmitSound(self.FireSound, 100, math.random(80, 120))
			self.NextUse.Fire = CurTime() + 0.2
		end
	end

	function ENT:ProtonTorpedos()
		if (self.NextUse.Torpedos < CurTime()) then
			local pos

			if (self.NextUse.Count == 1) then
				pos = self:GetPos() + self:GetUp() * 45 + self:GetForward() * 250 + self:GetRight() * -25
				self.NextUse.Torpedos = CurTime() + 0.25
			elseif (self.NextUse.Count == 2) then
				pos = self:GetPos() + self:GetUp() * 45 + self:GetForward() * 250 + self:GetRight() * 25
			end

			local e = self:FindTarget()
			SW_FireProton(self, pos, e, 1500, 600, Color(255, 50, 100, 255), 15, true, "proton_torpedo")
			self.NextUse.Count = self.NextUse.Count + 1

			if (self.NextUse.Count > 2) then
				self.NextUse.Count = 1
				self.NextUse.Torpedos = CurTime() + 15
				self:SetNWInt("FireBlast", self.NextUse.Torpedos)
			else
				self:ProtonTorpedos()
			end
		end
	end

	function ENT:Repair()
		local CurHealth = self.VehicleHealth or self:GetNWInt("Health")
		if (self.NextUse.Repair < CurTime() and CurHealth < self.StartHealth) then
			local Heal = self.StartHealth * 0.25

			if CurHealth < self.StartHealth * 0.75 then
				CurHealth = CurHealth + Heal
			else
				CurHealth = self.StartHealth
			end

			if self.CriticalDamage and CurHealth >= CurHealth / self.StartHealth * 10 then
				self.CriticalDamage = false
			end

			if CurHealth > self.StartHealth * 0.1 then
				self.CriticalDamage = false

				if IsValid(self.Pilot) then
					self.Pilot:SetNWBool("SW_Critical", self.CriticalDamage)
				end
			end

			if CurHealth > self.StartHealth * 0.2 then
				self.WeaponsDisabled = false
			end

			if CurHealth > (self.StartHealth * 0.33) then
				self.HyperdriveDisabled = false
			end

			self:SetNWInt("Health", CurHealth)
			self.VehicleHealth = CurHealth

			if IsValid(self.Pilot) then
				self.Pilot:SetNWInt("SW_Health", self.VehicleHealth)
			end

			self:EmitSound("r2_chatter_0" .. math.random(4))
			self:EmitSound("repair_effect")
			self.NextUse.Repair = CurTime() + 15
			self:SetNWInt("RepairTime", self.NextUse.Repair)
		end
	end

	function ENT:GunnerEnter(p, back)
		if (p == self.Pilot) then return end
		if (p == self.BackGunner) then return end

		if (self.NextUse.Use < CurTime()) then
			if not (back and IsValid(self.BackGunner)) then
				p:SetNWBool("BackGunner", true)
				self.BackGunner = p
				p:EnterVehicle(self.GunnerSeat[1])
				self:SetNWEntity(self.Vehicle .. "Gunner", p)
				local pos = self:GetPos() + self:GetRight() * self.GunnerPosition.x + self:GetForward() * self.GunnerPosition.y + self:GetUp() * self.GunnerPosition.z
				self:SpawnGunner(pos)
			end

			p:SetNWEntity(self.Vehicle, self)
			self.NextUse.Use = CurTime() + 1
		end
	end

	function ENT:GunnerExit(back, p)
		if not back and IsValid(self.BackGunner) then
			self.BackGunner:SetNWBool("BackGunner", false)
			self:SetNWEntity(self.Vehicle .. "Gunner", NULL)
			self.BackGunner = NULL
		end

		if (IsValid(self.PilotAvatar)) then
			self.GunnerAvatar:Remove()
			self:SetNWEntity("GunnerAvatar", NULL)
		end

		p:SetPos(self:GetPos() + self:GetForward() * -300 + self:GetUp() * 50)
		p:SetNWEntity(self.Vehicle, NULL)
	end

	hook.Add("PlayerLeaveVehicle", ENT.Vehicle .. "SeatExit", function(p, v)
		if IsValid(p) and IsValid(v) and v.IsBackGunnerSeat then
			local e = v:GetParent()

			if (v.IsBack) then
				e:GunnerExit(true, p)
			else
				e:GunnerExit(false, p)
			end
		end
	end)

	function ENT:Think()
		self.BaseClass.Think(self)

		if (IsValid(self.BackGunner)) then
			self.Turret.LastAng = self.Turret:GetAngles()
			self.TurretGuard.LastAng = self.TurretGuard:GetAngles()
			local aim = self.BackGunner:GetAimVector():Angle()
			local p = aim.p * -1
			local y = aim.y + 0

			if IsValid(self.Turret) then
				self.Turret:SetAngles(Angle(p, aim.y + 180, 0))
			end

			if IsValid(self.TurretGuard) then
				self.TurretGuard:SetAngles(Angle(self:GetAngles().p, y + 180, self:GetAngles().r))
			end

			if (self.BackGunner:KeyDown(IN_ATTACK)) then
				self:FireBack(self.BackGunner:GetAimVector():Angle():Forward())
			end
		end

		if self.Inflight and IsValid(self.Pilot) then
			if self.Pilot:KeyDown(IN_ATTACK2) then
				self:ProtonTorpedos()
			else
				if self.Pilot:KeyDown(IN_SPEED) then
					self:Repair()
				end
			end
		end

		if self:GetNWInt("Health", 0) <= 0 then
			self.Turret:SetColor(Color(0, 0, 0, 255))
			self.TurretGuard:SetColor(Color(0, 0, 0, 255))
		end

		self:NextThink(CurTime())

		return true
	end
end

if CLIENT then
	function ENT:Initialize()
		self.ViewDistance = 1050
		self.ViewHeight = 375
		self.FPVPos = Vector(300, 0, 95)
		self:SpawnCockpit()
		self.BaseClass.Initialize(self)
	end

	function ENT:SpawnCockpit()
		self.Cockpit = ents.CreateClientProp("models/ywing/ywing_btlb_test_cockpit.mdl", RENDERGROUP_OPAQUE)
		self.Cockpit:SetPos(self:GetPos())
		self.Cockpit:SetAngles(self:GetAngles())
		self.Cockpit:SetParent(self)
		self.Cockpit:SetNoDraw(true)
		self.Cockpit:Spawn()
	end

	function ENT:Remove()
		if IsValid(self.Cockpit) then
			self.Cockpit:Remove()
		end

		self.BaseClass.Remove(self)
	end

	function ENT:Draw()
		local pilot = self:GetNWEntity(self.Vehicle .. "Pilot", NULL)

		if self.IsFPV and self:GetNWBool("InShip", false) and IsValid(pilot) and LocalPlayer() == pilot then
			self.Cockpit:DrawModel()
		else
			self:DrawModel()
		end

		local avatar = self:GetNWEntity("GunnerAvatar")
		local seat = self:GetNWEntity("GunnerSeat")
		local gunner = self:GetNWEntity(self.Vehicle .. "Gunner")
		if not (IsValid(avatar) and IsValid(gunner)) then return end

		if seat:GetThirdPersonMode() or LocalPlayer() ~= gunner then
			avatar:DrawModel()
			avatar:SetNoDraw(false)
		else
			avatar:SetNoDraw(true)
		end
	end

	ENT.CanFPV = true
	ENT.EnginePos = {}

	ENT.Sounds = {
		Engine = "ywing_engine_loop"
	}

	function ENT:FlightEffects()
		local normal = -self:GetForward()
		local roll = math.Rand(-90, 90)
		local id = self:EntIndex()
		self.EnginePos = {self:GetPos() + self:GetForward() * -630 + self:GetRight() * 240 + self:GetUp() * 60, self:GetPos() + self:GetForward() * -630 + self:GetRight() * -240 + self:GetUp() * 60}

		for k, v in pairs(self.EnginePos) do
			local heat = self.FXEmitter:Add("sprites/heatwave", v)
			heat:SetVelocity(normal)
			heat:SetDieTime(0.03)
			heat:SetStartAlpha(255)
			heat:SetEndAlpha(100)
			heat:SetStartSize(65)
			heat:SetEndSize(40)
			heat:SetRoll(roll)
			heat:SetColor(255, 204, 0)
			local blue = self.FXEmitter:Add("sprites/bluecore", v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.02)
			blue:SetStartAlpha(200)
			blue:SetEndAlpha(100)
			blue:SetStartSize(65)
			blue:SetEndSize(35)
			blue:SetRoll(roll)
			blue:SetColor(255, 0, 0)
			local dynlight = DynamicLight(id + 4096 * k)
			dynlight.Pos = v
			dynlight.Brightness = 5
			dynlight.Size = 200
			dynlight.Decay = 1024
			dynlight.R = 100
			dynlight.G = 100
			dynlight.B = 255
			dynlight.DieTime = CurTime() + 1
		end
	end

	function ENT:Think()
		self.BaseClass.Think(self)
		local Flying = self:GetNWBool("Flying" .. self.Vehicle)
		local TakeOff = self:GetNWBool("TakeOff")
		local Land = self:GetNWBool("Land")

		if Flying then
			if not (TakeOff or Land) then
				self:FlightEffects()
			end

			if LocalPlayer():KeyDown(IN_WALK) and self.NextView < CurTime() then
				self.IsFPV = not self.IsFPV
				self.NextView = CurTime() + 1
			end
		end
	end

	hook.Add("HUDPaint", "YWingBtlBReticle", function()
		local ship = LocalPlayer():GetNWEntity("YWingBtlB")

		if LocalPlayer():GetNWBool("FlyingYWingBtlB") and IsValid(ship) then
			SW_HUD_DrawHull(ship.StartHealth)
			SW_WeaponReticles(ship)
			SW_HUD_DrawOverheating(ship)
			SW_BlastIcon(ship, 15)
			SW_RepairIcon(ship, 15)
			SW_HUD_Compass(ship, ScrW() / 2, ScrH() * 0.775)
			SW_HUD_DrawSpeedometer()
		elseif LocalPlayer():GetNWBool("BackGunner") and IsValid(ship) then
			local WeaponsPos = {ship:GetPos() + ship:GetUp() * 115 + ship:GetForward() * 195 + ship:GetRight() * 0}

			for i = 1, 1 do
				local tr = util.TraceLine({
					start = WeaponsPos[i],
					endpos = WeaponsPos[i] + LocalPlayer():GetAimVector():Angle():Forward() * 10000
				})

				surface.SetTextColor(255, 255, 255, 255)
				local vpos = tr.HitPos
				local screen = vpos:ToScreen()
				surface.SetFont("CloseCaption_Bold")
				local tsW, tsH = surface.GetTextSize("[ + ]")
				local x, y

				for k, v in pairs(screen) do
					if k == "x" then
						x = v - tsW / 2
					elseif k == "y" then
						y = v - tsH / 2
					end
				end

				surface.SetTextPos(x, y)
				surface.DrawText("[ + ]")
			end
		end
	end)
else
	return
end
