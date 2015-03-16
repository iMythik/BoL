if myHero.charName ~= "Darius" then return end

local mythdunk = {}
local creep

mythdunk.version = "v1.15"

-- Spell table
function mythdunk:loadVars()
	spells = {}
    spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 420, width = 410}
    spells.w = {name = myHero:GetSpellData(_E).name, ready = false, range = 145, width = 145}
    spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 540, width = 540}
    spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = 480, width = 480}
end

--Lag Free Circles
function mythdunk:DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function mythdunk:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8, self:Round(180 / math.deg((math.asin((chordlength / (2 * radius)))))))
	quality = 2 * math.pi / quality
	radius = radius * .92
	local points = {}
		
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)	
end

function mythdunk:Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end

-- Checks
function mythdunk:readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

function orbwalkCheck()
	if _G.AutoCarry then
		print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> SA:C detected, support enabled.</font>")
		SACLoaded = true
	else
		print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> SA:C not running, loading SxOrbWalk.</font>")
		require("SxOrbWalk")
		SxOrb:LoadToMenu(Menu)
		SACLoaded = false
	end
end

function mythdunk:CastQ(unit)
	if ValidTarget(unit, spells.q.range) and spells.q.ready then
		CastSpell(_Q, unit.x, unit.z)
	end	
end	

function mythdunk:CastW(unit)
	if ValidTarget(unit, 200) then
		CastSpell(_W)
	end	
end	

function mythdunk:CastE(unit)
	if ValidTarget(unit, spells.e.range) and spells.e.ready then
		CastSpell(_E, unit.x, unit.z)
	end	
end	

function mythdunk:CastR(unit)
	local dmg, hp = getDmg("R", unit, myHero) * 1.56, unit.health

	if ValidTarget(unit, spells.r.range) and dmg >= unit.health and spells.r.ready then
		Packet("S_CAST", {spellId = _R, targetNetworkId = unit.networkID}):send()
	end	
end	

function mythdunk:subUlt(unit)
	if ValidTarget(unit, spells.r.range) and spells.r.ready then
		Packet("S_CAST", {spellId = _R, targetNetworkId = unit.networkID}):send()
	end	
end	

function mythdunk:getTarg()
	ts:update()
	if SACLoaded and _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
		return _G.AutoCarry.Attack_Crosshair.target
	end
	return ts.target
end

function mythdunk:shoot(unit)
	if SACLoaded then
		AutoCarry.Orbwalker:Orbwalk(unit)
	else
		SxOrb:ForceTarget(unit)
	end
	if settings.combo.autor then
		mythdunk:CastR(unit)
	end
	if settings.combo.autoe then
		mythdunk:CastE(unit)
	end
	if settings.combo.autoq then
		mythdunk:CastQ(unit)
	end
	if settings.combo.autow then
		mythdunk:CastW(unit)
	end
end

function mythdunk:Farm()
	creep:update()
		
	for i, minion in pairs(creep.objects) do

		if not settings.farm.farmkey then return end

		if settings.farm.farmq then
			mythdunk:CastQ(minion)
		end

		if settings.farm.farmw then
			mythdunk:CastW(minion)
		end
	end
end


function OnLoad()
	print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>["..mythdunk.version.."]</font>")

	ts = TargetSelector(TARGET_LOW_HP, 600, DAMAGE_PHYSICAL, false, true)
	creep = minionManager(MINION_ENEMY, 200, myHero, MINION_SORT_HEALTH_ASC)

	mythdunk:loadVars()
	mythdunk:Menu()

	DelayAction(orbwalkCheck,5)
end

function OnTick()
	mythdunk:readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100

	if settings.farm.farmkey then
		mythdunk:Farm()
	end

	if not ValidTarget(mythdunk:getTarg()) then return end

	local targ = mythdunk:getTarg()

	if settings.combo.comboKey then
		mythdunk:shoot(targ)
	end

	if settings.ks.r then
		mythdunk:CastR(targ)
	end

	if settings.ks.q and getDmg("R", targ, myHero) >= targ.health then
		mythdunk:CastQ(targ)
	end

	if settings.combo.ultHP and hp <= settings.combo.ultpct and settings.combo.ultpct ~= 0 then
		mythdunk:subUlt(targ)
	end

end

function OnDraw()

	if myHero.dead then return end

	if settings.draw.q and spells.q.ready then
		mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, spells.q.range, ARGB(255,0,255,0))
	end

	if settings.draw.w and spells.w.ready then
		mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, spells.w.range, ARGB(255,255,255,0))
	end

	if settings.draw.e and spells.e.ready then
		mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, spells.e.range, ARGB(255,255,110,0))
	end

	if settings.draw.r and spells.r.ready then
		mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, spells.r.range, ARGB(255,255,0,0))
	end

	if settings.draw.target and ValidTarget(mythdunk:getTarg()) then
		local targ = mythdunk:getTarg()
		mythdunk:DrawCircle(targ.x, targ.y, targ.z, 100, ARGB(255,255,120,0))
	end

end

function mythdunk:Menu()
	settings = scriptConfig("MythDunk", "mythik")
	TargetSelector.name = "MythDunk"
	settings:addTS(ts)

	settings:addSubMenu("Combo", "combo")
	settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combo:addParam("autoq", "Auto Q", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autow", "Auto W", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoe", "Auto E", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Farm", "farm")
	settings.farm:addParam("farmkey", "Farm Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
	settings.farm:addParam("farmq", "Farm with Q", SCRIPT_PARAM_ONOFF, true)
	settings.farm:addParam("farmw", "Farm with W", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Ultimate", "ult")
	settings.ult:addParam("autoR", "Use ult in combo", SCRIPT_PARAM_ONOFF, true)
	settings.ult:addParam("ultHP", "Ult on Low HP (You)", SCRIPT_PARAM_ONOFF, true)
	settings.ult:addParam("ultpct", "Use ult below health %", SCRIPT_PARAM_SLICE, 25, 0, 35, 0)

	settings:addSubMenu("Kill Steal", "ks")
	settings.ks:addParam("r", "Use R", SCRIPT_PARAM_ONOFF, true)
	settings.ks:addParam("q", "Use Q", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Drawing", "draw")
	settings.draw:addParam("q", "Draw Q", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("w", "Draw W", SCRIPT_PARAM_ONOFF, false)
	settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("r", "Draw R", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)
end