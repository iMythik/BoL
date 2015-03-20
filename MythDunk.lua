local version = "1.21"

if myHero.charName ~= "Darius" then return end

----------------------
--   Auto Updater   --
----------------------

local mythdunk = {}
local autoupdate = true
local UPDATE_NAME = "MythDunk"
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://raw.github.com/iMythik/BoL/master/MythDunk.lua"

function printChat(msg) print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> "..msg.."</font>") end

function update()
    local netdata = GetWebResult("raw.github.com", "/iMythik/BoL/master/MythDunk.lua")
    if netdata then
        local netver = string.match(netdata, "local version = \"%d+.%d+\"")
        netver = string.match(netver and netver or "", "%d+.%d+")
        if netver then
            netver = tonumber(netver)
            if tonumber(version) < netver then
                printChat("New version found, updating... don't press F9.")
                DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () printChat("Updated script ["..version.." to "..netver.."], press F9 twice to reload the script.") end)    
            else
                printChat("is running latest version!")
            end
        end
    end
end

----------------------
--     Variables    --
----------------------

local spells = {}
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 420, width = 410}
spells.w = {name = myHero:GetSpellData(_E).name, ready = false, range = 145, width = 145}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 540, width = 540}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = 480, width = 480}
   
local stacktbl = {
	[1] = "darius_Base_hemo_counter_01.troy",
	[2] = "darius_Base_hemo_counter_02.troy",
	[3] = "darius_Base_hemo_counter_03.troy",
	[4] = "darius_Base_hemo_counter_04.troy",
	[5] = "darius_Base_hemo_counter_05.troy",
}

-- Spell cooldown check
function mythdunk:readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

-- Orbwalker check
function orbwalkCheck()
	if _G.AutoCarry then
		printChat("SA:C detected, support enabled.")
		SACLoaded = true
	else
		printChat("SA:C not running, loading SxOrbWalk.")
		require("SxOrbWalk")
		SxOrb:LoadToMenu(Menu)
		SACLoaded = false
	end
end

----------------------
--  Cast functions  --
----------------------

-- Cast Q
function mythdunk:CastQ(unit)
	if ValidTarget(unit, spells.q.range) and spells.q.ready then
		if settings.combo.packets then
			Packet("S_CAST", {spellId = _Q}):send()
		else
			CastSpell(_Q, unit.x, unit.z)
		end
	end
	if settings.combo.qmax then
		if ValidTarget(unit,425) and myHero:GetDistance(unit) > 290 then
			if settings.combo.packets then
				Packet("S_CAST", {spellId = _Q}):send()
			else
				CastSpell(_Q, unit.x, unit.z)
			end
		end
	end
end	

-- Cast W
function mythdunk:CastW(unit)
	if ValidTarget(unit, 200) and spells.w.ready then
		if settings.combo.packets then
			Packet("S_CAST", {spellId = _W}):send()
		else
			CastSpell(_W)
		end
	end	
end	

-- Cast E
function mythdunk:CastE(unit)
	if ValidTarget(unit, spells.e.range-8) and spells.e.ready then
		if settings.combo.packets then
			Packet("S_CAST", {spellId = _E, targetNetworkId = unit.networkID}):send()
		else
			CastSpell(_E, unit.x, unit.z)
		end
	end	
end	

-- Cast ult
function mythdunk:CastR(unit)
	if ValidTarget(unit, spells.r.range) and getRdmg(unit) >= unit.health and spells.r.ready and ultcalc(unit) then
		Packet("S_CAST", {spellId = _R, targetNetworkId = unit.networkID}):send()
	end	
end	

-- Cast ult without finisher check
function mythdunk:subUlt(unit)
	if ValidTarget(unit, spells.r.range) and spells.r.ready then
		Packet("S_CAST", {spellId = _R, targetNetworkId = unit.networkID}):send()
	end	
end	

-- Full Combo
function mythdunk:shoot(unit)
	if SACLoaded then
		AutoCarry.Orbwalker:Orbwalk(unit)
	else
		SxOrb:ForceTarget(unit)
	end
	if settings.ult.autoR then
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

function mythdunk:Harass(unit)
	if settings.harass.q and ValidTarget(unit, spells.q.range) then
		mythdunk:CastQ(unit)
	end

	if settings.harass.w and ValidTarget(unit, 200) then
		mythdunk:CastW(unit)
	end
end

-- Minion farm
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

----------------------
--   Calculations   --
----------------------

-- Target Calculation
function mythdunk:getTarg()
	ts:update()
	if SACLoaded and _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
		return _G.AutoCarry.Attack_Crosshair.target
	end
	return ts.target
end

-- Hemmorage stack calculation
function OnCreateObj(object)
	if GetDistance(myHero, object) >= 300 then return end
	for k, v in pairs(stacktbl) do
		if object.name == v then
			for i, e in pairs(GetEnemyHeroes()) do
				if mythdunk:getTarg() == e then
	           	 	e.stack = k
	           	end
	        end
	    end
	end
end

-- R damage calculation
function getRdmg(unit)
	for i, e in pairs(GetEnemyHeroes()) do
		if e == unit then
			if e.stack == nil then e.stack = 0 end
			local dmg = getDmg("R", unit, myHero)
	        local totaldmg = dmg + e.stack * dmg * 20 / 100
	        return totaldmg
		end
	end
end

-- Invulnerable check
function ultcalc(unit)
	if not TargetHaveBuff("JudicatorIntervention", unit) or TargetHaveBuff("Undying Rage", unit) then
		return true
	end
end

----------------------
--      Hooks       --
----------------------

-- Init hook
function OnLoad()
	print("<font color='#009DFF'>[MythDunk]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")

	if autoupdate then
		update()
	end

	ts = TargetSelector(TARGET_LOW_HP, 600, DAMAGE_PHYSICAL, false, true)
	creep = minionManager(MINION_ENEMY, 200, myHero, MINION_SORT_HEALTH_ASC)

	mythdunk:Menu()

	DelayAction(orbwalkCheck,7)
end

-- Tick hook
function OnTick()
	mythdunk:readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100

	if settings.farm.farmkey then
		mythdunk:Farm()
	end

	if not ValidTarget(mythdunk:getTarg()) then return end

	local targ = mythdunk:getTarg()

	if settings.harass.harassKey then
		mythdunk:Harass(targ)
	end

	if settings.combo.comboKey then
		mythdunk:shoot(targ)
	end

	if settings.ks.r then
		mythdunk:CastR(targ)
	end

	if settings.ks.q and getDmg("Q", targ, myHero) >= targ.health then
		mythdunk:CastQ(targ)
	end

	if settings.ult.ultHP and hp <= settings.ult.ultpct and settings.ult.ultpct ~= 0 then
		mythdunk:subUlt(targ)
	end

end

-- Drawing hook
function OnDraw()

	if myHero.dead then return end

	if settings.draw.q and spells.q.ready then
		mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, spells.q.range, ARGB(255,0,255,0))
		if settings.combo.qmax then
			mythdunk:DrawCircle(myHero.x, myHero.y, myHero.z, 290, ARGB(255,0,255,0))
		end
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

-- Menu creation
function mythdunk:Menu()
	settings = scriptConfig("MythDunk", "mythik")
	TargetSelector.name = "MythDunk"
	settings:addTS(ts)

	settings:addSubMenu("Combo", "combo")
	settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combo:addParam("autoq", "Auto Q", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autow", "Auto W", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoe", "Auto E", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("qmax", "Only Q in max range", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("packets", "Use packet casting", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Harass", "harass")
	settings.harass:addParam("harassKey", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, 67)
	settings.harass:addParam("q", "Harass with Q", SCRIPT_PARAM_ONOFF, true)
	settings.harass:addParam("w", "Harass with W", SCRIPT_PARAM_ONOFF, true)

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