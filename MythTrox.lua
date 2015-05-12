local version = "1.2"

----------------------
--   Auto Updater   --
----------------------

if myHero.charName ~= "Aatrox" then return end

local mythtrox = {}
local autoupdate = true
local UPDATE_NAME = "MythTrox"
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://raw.github.com/iMythik/BoL/master/MythTrox.lua"

function printChat(msg) print("<font color='#009DFF'>[MythTrox]</font><font color='#FFFFFF'> "..msg.."</font>") end

function update()
    local netdata = GetWebResult("raw.github.com", "/iMythik/BoL/master/MythTrox.lua")
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

require("VPrediction") --vpred
require("DivinePred") -- divinepred
require("HPrediction") -- hpred

local processTime  = os.clock()*1000
local enemyChamps = {}
local dp = DivinePred()
local minHitDistance = 50
local pred = nil

----------------------
--     Variables    --
----------------------

local spells = {}
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 600, delay = 0.25, speed = 1800, width = 150}
spells.w = {name = myHero:GetSpellData(_E).name, ready = false, range = 200}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 975, delay = 0.25, speed = 1200, width = 140}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = 400}

-- Spell cooldown check
function mythtrox:readyCheck()
	spells.q.ready, spells.w.ready, spells.e.ready, spells.r.ready = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

-- Orbwalker check
function orbwalkCheck()
	if _G.AutoCarry then
		printChat("SA:C detected, support enabled.")
		SACLoaded = true
	elseif _G.MMA_Loaded then
		printChat("MMA detected, support enabled.")
		MMALoaded = true
	else
		printChat("SA:C/MMA not running, loading SxOrbWalk.")
		require("SxOrbWalk")
		SxMenu = scriptConfig("SxOrbWalk", "SxOrbb")
		SxOrb:LoadToMenu(SxMenu)
		SACLoaded = false
		MMALoaded = false
	end
end

function orbwalkPos(pos)
	if pos ~= nil then
		if SACLoaded then 
			AutoCarry.Orbwalker:OverrideOrbwalkLocation(pos)
		elseif MMALoaded then
			moveToCursor(pos)
		else
			SxOrb:DisableMove()
			myHero:MoveTo(pos.x, pos.z)
		end
	else
		if SACLoaded then 
			AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		elseif MMALoaded then
			moveToCursor()
		else
			SxOrb:EnableMove()
		end
	end
end


----------------------
--  Cast functions  --
----------------------

local qpred = CircleSS(spells.q.speed, spells.q.range, spells.q.width, spells.q.delay, math.huge)
local epred = LineSS(spells.e.speed, spells.e.range, spells.e.width, spells.e.delay, math.huge)


function mythtrox:CastQ(unit)
	if settings.pred == 1 then
    	local castPos, chance, pos = pred:GetCircularCastPosition(unit, spells.q.delay, spells.q.width, spells.q.range, math.huge, myHero, false)
    	if ValidTarget(unit, spells.q.range) and spells.q.ready and chance >= 2 then
    	    CastSpell(_Q, castPos.x, castPos.z)
    	end
    elseif settings.pred == 2 then
    	local targ = DPTarget(unit)
    	local state,hitPos,perc = dp:predict(targ, qpred)
    	if ValidTarget(unit, spells.q.range) and spells.q.ready and state == SkillShot.STATUS.SUCCESS_HIT then
       		CastSpell(_Q, hitPos.x, hitPos.z)
      	end
	elseif settings.pred == 3 then
		local pos, chance = HPred:GetPredict("Q", unit, myHero) 
		if ValidTarget(unit, spells.q.range) and spells.q.ready and chance >= 2 then
			CastSpell(_Q, pos.x, pos.z)
		end
	end
end

-- Cast W
function mythtrox:CastW(unit)
	local state = myHero:GetSpellData(_W).toggleState
	if ValidTarget(unit, spells.w.range) and spells.w.ready then
		if state == 1 then 
			CastSpell(_W)
		end
	end
end

function mythtrox:CastE(unit)
	if settings.pred == 1 then
    	local castPos, chance, pos = pred:GetLineCastPosition(unit, spells.e.delay, spells.e.width, spells.e.range, spells.e.speed, myHero, false)
   	 	if ValidTarget(unit, spells.e.range) and spells.e.ready and chance >= 2 then
     	   CastSpell(_E, castPos.x, castPos.z)
    	end
    elseif settings.pred == 2 then
    	local targ = DPTarget(unit)
    	local state,hitPos,perc = dp:predict(targ, epred)
    	if ValidTarget(unit, spells.e.range) and spells.e.ready and state == SkillShot.STATUS.SUCCESS_HIT then
       		CastSpell(_E, hitPos.x, hitPos.z)
      	end
	elseif settings.pred == 3 then
		local pos, chance = HPred:GetPredict("E", unit, myHero)
		if ValidTarget(unit, spells.e.range) and spells.e.ready and chance >= 2 then
			CastSpell(_E, pos.x, pos.z)
		end
	end
end

function mythtrox:CastR(unit)
	if ValidTarget(unit, spells.r.range) and spells.r.ready then
		CastSpell(_R)
	end
end


-- Full Combo
function mythtrox:shoot(unit) -- bang bang
	if SACLoaded then
		AutoCarry.Orbwalker:Orbwalk(unit)
	elseif MMALoaded then
		_G.MMA_ForceTarget = unit
	else 
		SxOrb:ForceTarget(unit)
	end
	if settings.combo.autoR then
		mythtrox:CastR(unit)
	end
	if settings.combo.autoe then
		mythtrox:CastE(unit)
	end
	if settings.combo.autoq then
		mythtrox:CastQ(unit)
	end
	if settings.combo.autow then
		mythtrox:CastW(unit)
	end
end

function mythtrox:Harass(unit)
	if not settings.harass.harassKey then return end

	if settings.harass.q and ValidTarget(unit, spells.q.range) then
		mythtrox:CastQ(unit)
	end

	if settings.harass.e and ValidTarget(unit, spells.e.range) then
		mythtrox:CastE(unit)
	end

	if settings.harass.autoe and ValidTarget(unit, spells.e.range) then
		mythtrox:CastQ(unit)
	end
end

-- Minion farm
function mythtrox:Farm()
	creep:update()
		
	for i, minion in pairs(creep.objects) do

		if not settings.farm.farmkey then return end

		if settings.farm.farmq then
			mythtrox:CastQ(minion)
		end

		if settings.farm.farme and getDmg("E", minion, myHero) >= minion.health then
			mythtrox:CastE(minion)
		end
	end
end

----------------------
--   Calculations   --
----------------------

-- Target Selection
function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN and settings.combo.focus then
		local dist = 0
		local Selecttarget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= dist or Selecttarget == nil then
					dist = GetDistance(enemy, mousePos)
					Selecttarget = enemy
				end
			end
		end
		if Selecttarget and dist < 300 then
			if SelectedTarget and Selecttarget.charName == SelectedTarget.charName then
				SelectedTarget = nil
				if settings.combo.focus then 
					printChat("Target unselected: "..Selecttarget.charName) 
				end
			else
				SelectedTarget = Selecttarget
				if settings.combo.focus then
					printChat("New target selected: "..Selecttarget.charName) 
				end
			end
		end
	end
end

-- Target Calculation
function mythtrox:getTarg()
	ts:update()
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(1200) return _G.AutoCarry.Crosshair:GetTarget() end		
	if ValidTarget(SelectedTarget) then return SelectedTarget end
	if MMALoaded and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return ts.target
end

----------------------
--      Hooks       --
----------------------

-- Init hook
function OnLoad()
	print("<font color='#009DFF'>[MythTrox]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")

	if autoupdate then
		update()
	end

	for i = 1, heroManager.iCount do
    	local hero = heroManager:GetHero(i)
		if hero.team ~= myHero.team then enemyChamps[""..hero.networkID] = DPTarget(hero) end
	end

	ts = TargetSelector(TARGET_LOW_HP, 2000, DAMAGE_PHYSICAL, false, true)
	creep = minionManager(MINION_ENEMY, 200, myHero, MINION_SORT_HEALTH_ASC)
	pred = VPrediction()
	HPred = HPrediction()
	hpload = true

	mythtrox:Menu()

	DelayAction(orbwalkCheck,7)

	if hpload then

 	 HPred:AddSpell("Q", 'Aatrox', {delay = spells.q.delay, radius = spells.q.width, range = spells.q.range, type = "PromptCircle"})
  	 HPred:AddSpell("E", 'Aatrox', {delay = spells.e.delay, range = spells.e.range, speed = spells.e.speed, type = "DelayLine", width = spells.e.width})
 	 
  	end
end

-- Tick hook
function OnTick()
	mythtrox:readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100

	if settings.farm.farmkey then
		mythtrox:Farm()
	end

	if settings.ks.r or settings.ks.q then
		for k, v in pairs(GetEnemyHeroes()) do
			if settings.ks.e then
				if ValidTarget(v, spells.e.range) and getDmg("E", v, myHero) >= v.health then
					mythtrox:CastR(v)
				end
			end
			if settings.ks.q then
				if ValidTarget(v, spells.q.range) and getDmg("Q", v, myHero) >= v.health then
					mythtrox:CastR(v)
				end
			end
			if settings.ks.r then
				if ValidTarget(v, spells.r.range) and getDmg("R", v, myHero) >= v.health then
					mythtrox:CastR(v)
				end
			end
		end
	end

	if settings.combo.autow then
		if myHero:GetSpellData(_W).toggleState == 2 then
			for k, v in pairs(GetEnemyHeroes()) do
				if GetDistance(v, myHero) > 1000 then
					CastSpell(_W)
				end
			end
		end
	end

	if not ValidTarget(mythtrox:getTarg()) then return end

	local targ = mythtrox:getTarg()

	if settings.harass.harassKey then
		mythtrox:Harass(targ)
	end

	if settings.harass.autoe then
		if ValidTarget(targ, spells.e.range) then
			mythtrox:CastE(targ)
		end
	end

	if settings.combo.comboKey then
		mythtrox:shoot(targ)
	end

end

-- Drawing hook
function OnDraw()
	if myHero.dead then return end

	if settings.draw.q and spells.q.ready then
		mythtrox:DrawCircle(myHero.x, myHero.y, myHero.z, spells.q.range, ARGB(255,0,255,255))
	end

	if settings.draw.e and spells.q.ready then
		mythtrox:DrawCircle(myHero.x, myHero.y, myHero.z, spells.e.range, ARGB(255,0,255,0))
	end

	if settings.draw.r and spells.r.ready then
		mythtrox:DrawCircle(myHero.x, myHero.y, myHero.z, spells.r.range, ARGB(255,255,0,0))
	end

	if settings.draw.target and ValidTarget(mythtrox:getTarg()) then
		local targ = mythtrox:getTarg()
		mythtrox:DrawCircle(targ.x, targ.y, targ.z, 100, ARGB(255,255,120,0))
	end

end

-- Menu creation
function mythtrox:Menu()
	settings = scriptConfig("MythTrox", "mythik")
	TargetSelector.name = "MythTrox"
	settings:addTS(ts)

	settings:addSubMenu("Combo", "combo")
	settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combo:addParam("autoq", "Auto Q", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoe", "Auto E", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoR", "Auto R", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autow", "Use smart W", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("focus", "Focus selected target", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Harass", "harass")
	settings.harass:addParam("harassKey", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, true, 67)
	settings.harass:addParam("autoe", "Auto E in range", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("T"))
	settings.harass:addParam("q", "Harass with Q", SCRIPT_PARAM_ONOFF, false)
	settings.harass:addParam("e", "Harass with E", SCRIPT_PARAM_ONOFF, false)

	settings:addSubMenu("Farm", "farm")
	settings.farm:addParam("farmkey", "Farm Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
	settings.farm:addParam("farmq", "Farm with Q", SCRIPT_PARAM_ONOFF, false)
	settings.farm:addParam("farme", "Farm with E", SCRIPT_PARAM_ONOFF, false)

	settings:addSubMenu("Kill Steal", "ks")
	settings.ks:addParam("r", "Use R", SCRIPT_PARAM_ONOFF, true)
	settings.ks:addParam("q", "Use Q", SCRIPT_PARAM_ONOFF, true)
	settings.ks:addParam("E", "Use E", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Drawing", "draw")
	settings.draw:addParam("q", "Draw Q", SCRIPT_PARAM_ONOFF, false)
	settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, false)
	settings.draw:addParam("r", "Draw R", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)

	settings.combo:permaShow("comboKey")
	settings.harass:permaShow("harassKey")
	settings.harass:permaShow("autoe")
	settings.farm:permaShow("farmkey")

    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred", "HPred"})
end


--Lag Free Circles
function mythtrox:DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function mythtrox:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
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

function mythtrox:Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end

assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("UHKJHKMGKOK") 