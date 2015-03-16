if myHero.charName ~= "Darius" then return end

local mythdunk = {}

mythdunk.version = "v1.0"

-- Spell table
function mythdunk:loadVars()
	spells = {}
    spells.q = {
        name = myHero:GetSpellData(_Q).name,
        ready = false,
        range = 420,
        width = 410,
    }
    spells.w = {
        name = myHero:GetSpellData(_E).name,
        ready = false,
        range = 145,
        width = 145,
    }
    spells.e = {
        name = myHero:GetSpellData(_E).name,
        ready = false,
        range = 540,
        width = 540,
    }
    spells.r = {
        name = myHero:GetSpellData(_R).name,
        ready = false,
        range = 480,
        width = 480,
    }
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

function mythdunk:CastQ(unit)
	if GetDistance(unit) <= spells.q.range and spells.q.ready then
		CastSpell(_Q, ts.target.x, ts.target.z)
	end	
end	

function mythdunk:CastW(unit)
	if GetDistance(unit) <= 200 then
		CastSpell(_W)
	end	
end	

function mythdunk:CastE(unit)
	if ValidTarget(unit, spells.e.range) and spells.e.ready then
		CastSpell(_E, ts.target.x, ts.target.z)
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

function mythdunk:shoot(unit)
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

function OnLoad()
	print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>["..mythdunk.version.."]</font>")

	ts = TargetSelector(TARGET_LOW_HP, 600, DAMAGE_PHYSICAL, false, true)

	mythdunk:loadVars()
	mythdunk:Menu()
end

function OnTick()
	mythdunk:readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100

	if not ValidTarget(ts.target) then return end

	if settings.combo.comboKey then
		mythdunk:shoot(ts.target)
	end

	if settings.ks.r then
		mythdunk:CastR(ts.target)
	end

	if settings.ks.q and getDmg("R", ts.target, myHero) >= ts.target.health then
		mythdunk:CastQ(ts.target)
	end

	if settings.combo.ultHP and hp <= settings.combo.ultpct and settings.combo.ultpct ~= 0 then
		mythdunk:subUlt(ts.target)
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

	if settings.draw.target and ts.target ~= nil then
		mythdunk:DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, ARGB(255,255,120,0))
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

	settings:addSubMenu("Ultimate", "ult")
	settings.ult:addParam("autoR", "Use ult in combo", SCRIPT_PARAM_ONOFF, true)
	settings.ult:addParam("ultHP", "Ult on Low HP", SCRIPT_PARAM_ONOFF, true)
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