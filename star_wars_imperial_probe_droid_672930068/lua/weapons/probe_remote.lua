
SWEP.PrintName = "Probe Remote"
SWEP.Author = "Liam0102"
SWEP.Purpose = "Take control of Probe Droids"
SWEP.Instructions = "Left Click to Enter"
SWEP.Category = "Star Wars"
SWEP.Base = "weapon_base"
SWEP.Slot = 3
SWEP.SlotPos = 5
SWEP.DrawAmmo	= false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.AnimPrefix = "python"
SWEP.HoldType = "pistol"
SWEP.Spawnable = true
SWEP.AdminSpawnable = false


SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true;
SWEP.Primary.Ammo	= "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:Deploy()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW); -- Animation

	return true
end

function SWEP:Initialize()
	self.Weapon:SetWeaponHoldType(self.HoldType)
end

if CLIENT then
	
	function SWEP:Initialize()
		surface.CreateFont( "CONTROL_Selection", {
			font = "Arial",
			size = 32,
			weight = 1000,
			blursize = 0,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = true,
		} )
		self.Weapon:SetWeaponHoldType(self.HoldType)
	end
	
	local function ProbeControlHUD()
		local p = LocalPlayer()
		if(!IsValid(p:GetActiveWeapon())) then return end;
		if(p:GetActiveWeapon():GetClass() == "probe_remote" and !p:InVehicle()) then
			
			local droid = p:GetNWEntity("SW_ControlDroid");
			if(IsValid(droid)) then
				surface.SetTextColor(255,255,255,255);
				surface.SetFont( "CONTROL_Selection" )
				surface.SetTextPos(ScrW()/10*8,ScrH()/10*9);
				surface.DrawText("Droid: " .. droid.PrintName);
				
				surface.SetTextPos(ScrW()/10*8,ScrH()/10*9.5);
				local n = p:GetNWInt("SW_ControlInt");
				surface.DrawText("Num: " .. n);
			end
		end
	end

	hook.Add("HUDPaint", "ProbeControlHUD", ProbeControlHUD)
end


if SERVER then

AddCSLuaFile()


function SWEP:Initialize()
	self:SetWeaponHoldType(self.HoldType)
	self:Reload();
	self:SecondaryAttack();
end
	
function SWEP:FindDroids()
	local droids = {};
	local n = 1;
	for k,v in pairs(ents.GetAll()) do
		if(IsValid(v)) then
			if(v.IsProbeDroid) then
				if(v.Owner == self.Owner) then
					//v:Enter(self.Owner,true);
					droids[n] = v;
					n = n + 1;
				end
			end
		end
	end
	return droids;
end

function SWEP:Reload()
	self.Droids = self:FindDroids();
	self.DroidNum = 1;
	self.CurrentDroid = self.Droids[self.DroidNum];
	self.Owner:SetNWEntity("SW_ControlDroid",self.CurrentDroid);
	self.Owner:SetNWInt("SW_ControlInt",self.DroidNum);
end

SWEP.DroidNum = 1;
SWEP.Droids = {};
SWEP.CurrentDroid = NULL;
function SWEP:SecondaryAttack()
	self.CurrentDroid = self.Droids[self.DroidNum];
	self.DroidNum = self.DroidNum + 1;
	if(self.DroidNum > table.Count(self.Droids)) then
		self.DroidNum = 1;
	end
	self.Owner:SetNWEntity("SW_ControlDroid",self.CurrentDroid);
	self.Owner:SetNWInt("SW_ControlInt",self.DroidNum);
end

function SWEP:PrimaryAttack()
	local p = self.Owner;
	if(IsValid(self.CurrentDroid)) then
		self.CurrentDroid.PilotExit = p:GetPos();
		self.Owner.ProbeExit = p:GetPos();
		self.CurrentDroid:Enter(self.Owner,true);
	end
	return true;
end


end