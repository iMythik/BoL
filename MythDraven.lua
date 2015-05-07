local version = "1.00"

----------------------
--   Auto Updater   --
----------------------

if myHero.charName ~= "Draven" then return end


local mythdraven = {}
local autoupdate = true
local UPDATE_NAME = "MythDraven"
local UPDATE_FILE_PATH = SCRIPT_PATH..UPDATE_NAME..".lua"
local UPDATE_URL = "http://raw.github.com/iMythik/BoL/master/MythDraven.lua"

function printChat(msg) print("<font color='#009DFF'>[MythDraven]</font><font color='#FFFFFF'> "..msg.."</font>") end

function update()
    local netdata = GetWebResult("raw.github.com", "/iMythik/BoL/master/MythDraven.lua")
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
spells.q = {name = myHero:GetSpellData(_Q).name, ready = false, range = 700, width = 410}
spells.w = {name = myHero:GetSpellData(_E).name, ready = false, range = 700, width = 145}
spells.e = {name = myHero:GetSpellData(_E).name, ready = false, range = 950, width = 130}
spells.r = {name = myHero:GetSpellData(_R).name, ready = false, range = 1500, width = 160}

-- Spell cooldown check
function mythdraven:readyCheck()
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

local epred = LineSS(1400, 950, 130, 0.250, math.huge)
local rpred = LineSS(2000, 1500, 160, 0.50, math.huge)

function mythdraven:CastQ(unit)
	if ValidTarget(unit, spells.q.range) and spells.q.ready then
		CastSpell(_Q)
	end
end

-- Cast W
function mythdraven:CastW(unit)
	if ValidTarget(unit, spells.q.range) and spells.q.ready then
		CastSpell(_W)
	end
end

function mythdraven:CastE(unit)
	if settings.pred == 1 then
    	local castPos, chance, pos = pred:GetLineCastPosition(unit, 0.250, 130, 950, 1400, myHero, false)
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

function mythdraven:CastR(unit)
	if settings.pred == 1 then
    	local castPos, chance, pos = pred:GetLineCastPosition(unit, 0.50, 160, 1500, 2000, myHero, false)
   	 	if ValidTarget(unit, spells.r.range) and spells.r.ready and chance >= 2 then
     	   CastSpell(_R, castPos.x, castPos.z)
    	end
    elseif settings.pred == 2 then
    	local targ = DPTarget(unit)
    	local state,hitPos,perc = dp:predict(targ, rpred)
    	if ValidTarget(unit, spells.r.range) and spells.r.ready and state == SkillShot.STATUS.SUCCESS_HIT then
       		CastSpell(_R, hitPos.x, hitPos.z)
      	end
	elseif settings.pred == 3 then
		local pos, chance = HPred:GetPredict("R", unit, myHero)
		if ValidTarget(unit, spells.r.range) and spells.r.ready and chance >= 2 then
			CastSpell(_R, pos.x, pos.z)
		end
	end
end


-- Full Combo
function mythdraven:shoot(unit)
	if SACLoaded then
		AutoCarry.Orbwalker:Orbwalk(unit)
	elseif MMALoaded then
		_G.MMA_ForceTarget = unit
	else 
		SxOrb:ForceTarget(unit)
	end
	if settings.combo.autow then
		mythdraven:CastW(unit)
	end
	if settings.combo.autoq then
		mythdraven:CastQ(unit)
	end
	if settings.combo.autoe then
		mythdraven:CastE(unit)
	end
	if settings.combo.autoR then
		if settings.combo.kill and getDmg("R", unit, myHero) <= unit.health then return end
		mythdraven:CastR(unit)
	end
end

function mythdraven:Harass(unit)
	if not settings.harass.harassKey then return end

	if settings.harass.q and ValidTarget(unit, spells.q.range) then
		mythdraven:CastQ(unit)
	end

	if settings.harass.e and ValidTarget(unit, spells.e.range) then
		mythdraven:CastE(unit)
	end

	if settings.harass.autoe and ValidTarget(unit, spells.e.range) then
		mythdraven:CastQ(unit)
	end
end

-- Minion farm
function mythdraven:Farm()
	creep:update()
		
	for i, minion in pairs(creep.objects) do

		if not settings.farm.farmkey then return end

		if settings.farm.farmq and getDmg("Q", minion, myHero) >= minion.health then
			mythdraven:CastQ(minion)
		end

		if settings.farm.farme and getDmg("E", minion, myHero) >= minion.health then
			mythdraven:Caste(minion)
		end
	end
end

----------------------
--   Calculations   --
----------------------

function OnCreateObj(object)
	if settings.axeKey or settings.axeToggle then
		if GetDistance(object) < 500 and object.name == "Draven_Base_Q_reticle.troy" then
			local pos = Vector(object.x, 0, object.z)
			orbwalkPos(pos)
		end
	end
end

function OnDeleteObj(object)
	if GetDistance(object) < 500 and object.name == "Draven_Base_Q_reticle.troy" then
		orbwalkPos(nil)
	end
end

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
function mythdraven:getTarg()
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
	print("<font color='#009DFF'>[MythDraven]</font><font color='#FFFFFF'> has loaded!</font> <font color='#2BFF00'>[v"..version.."]</font>")

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

	mythdraven:Menu()

	DelayAction(orbwalkCheck,7)

	if hpload then

 	 Spell_E.delay['Draven'] = 0.250
 	 Spell_E.range['Draven'] = 950
 	 Spell_E.speed['Draven'] = 1400
 	 Spell_E.type['Draven'] = "DelayLine"
 	 Spell_E.width['Draven'] = 130
 	 Spell_R.delay['Draven'] = 0.50
 	 Spell_R.range['Draven'] = 1500
 	 Spell_R.speed['Draven'] = 2000
 	 Spell_R.type['Draven'] = "DelayLine"
 	 Spell_R.width['Draven'] = 160
 	 
  	end
end

-- Tick hook
function OnTick()
	mythdraven:readyCheck()

	ts:update()

	local hp = myHero.health / myHero.maxHealth * 100

	if settings.farm.farmkey then
		mythdraven:Farm()
	end

	if settings.ks.r or settings.ks.q then
		for k, v in pairs(GetEnemyHeroes()) do
			if settings.ks.r then
				if ValidTarget(v, spells.r.range) and getDmg("R", v, myHero) >= v.health then
					mythdraven:CastR(v)
				end
			end
		end
	end

	if not ValidTarget(mythdraven:getTarg()) then return end

	local targ = mythdraven:getTarg()

	if settings.harass.harassKey then
		mythdraven:Harass(targ)
	end

	if settings.harass.autoe then
		if ValidTarget(targ, spells.e.range) then
			mythdraven:CastE(targ)
		end
	end

	if settings.combo.comboKey then
		mythdraven:shoot(targ)
	end

end

-- thank you bilbao <3

function GetHPBarPos(enemy)
	enemy.barData = {PercentageOffset = {x = -0.05, y = 0}}
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = -50
	local BarPosOffsetY = 46
	local CorrectionY = 39
	local StartHpPos = 31

	barPos.x = math.floor(barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos)
	barPos.y = math.floor(barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY)

	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos = Vector(barPos.x + 108 , barPos.y , 0)
	
return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function DrawLineHPBar(damage, line, text, unit, enemyteam)
	if unit.dead or not unit.visible then return end
	local p = WorldToScreen(D3DXVECTOR3(unit.x, unit.y, unit.z))
	if not OnScreen(p.x, p.y) then return end

	
	local thedmg = 0
	local linePosA = {x = 0, y = 0 }
	local linePosB = {x = 0, y = 0 }
	local TextPos =  {x = 0, y = 0 }
	
	
	if damage >= unit.maxHealth then
		thedmg = unit.maxHealth - 1
	else
		thedmg = damage
	end
	
	
	local StartPos, EndPos = GetHPBarPos(unit)
	local Real_X = StartPos.x + 24
	local Offs_X = (Real_X + ((unit.health - thedmg) / unit.maxHealth) * (EndPos.x - StartPos.x - 2))
	if Offs_X < Real_X then Offs_X = Real_X end	

	local r, r2 = 255, 255
	local g, g2 = 0, 255
	local b = 255

	if thedmg >= unit.health then g = 255 r = 0 g2 = 255 r2 = 0 b = 0 text = text.." (Killable!)" end

	if enemyteam then
		linePosA.x = Offs_X-150
		linePosA.y = (StartPos.y-(30+(line*15)))	
		linePosB.x = Offs_X-150
		linePosB.y = (StartPos.y-10)
		TextPos.x = Offs_X-148
		TextPos.y = (StartPos.y-(30+(line*15)))
	else
		linePosA.x = Offs_X-125
		linePosA.y = (StartPos.y-(30+(line*15)))	
		linePosB.x = Offs_X-125
		linePosB.y = (StartPos.y-15)
	
		TextPos.x = Offs_X-122
		TextPos.y = (StartPos.y-(30+(line*15)))
	end

	DrawLine(linePosA.x, linePosA.y, linePosB.x, linePosB.y , 2, ARGB(255, r, g, 0))
	DrawText(tostring(text),15,TextPos.x, TextPos.y - 10, ARGB(255, r2, g2, b))
	
end

-- Drawing hook
function OnDraw()
	if myHero.dead then return end

	if settings.draw.e and spells.q.ready then
		mythdraven:DrawCircle(myHero.x, myHero.y, myHero.z, spells.e.range, ARGB(255,0,255,0))
	end

	if settings.draw.r and spells.r.ready then
		mythdraven:DrawCircle(myHero.x, myHero.y, myHero.z, spells.r.range, ARGB(255,255,0,0))
	end

	if settings.draw.target and ValidTarget(mythdraven:getTarg()) then
		local targ = mythdraven:getTarg()
		mythdraven:DrawCircle(targ.x, targ.y, targ.z, 100, ARGB(255,255,120,0))
	end

	if ValidTarget(mythdraven:getTarg()) and settings.draw.rdmg and spells.r.ready then
		local targ = mythdraven:getTarg()
		DrawLineHPBar(getDmg("R", targ, myHero), 1, " R Damage: "..math.round(getDmg("R", targ, myHero)), targ, true)
	end
end

-- Menu creation
function mythdraven:Menu()
	settings = scriptConfig("MythDraven", "mythik")
	TargetSelector.name = "MythDraven"
	settings:addTS(ts)

	settings:addSubMenu("Combo", "combo")
	settings.combo:addParam("comboKey", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combo:addParam("autoq", "Auto Q", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autow", "Auto W", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoe", "Auto E", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("autoR", "Auto R", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("kill", "Only ult if killable", SCRIPT_PARAM_ONOFF, true)
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

	settings:addSubMenu("Drawing", "draw")
	settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, false)
	settings.draw:addParam("r", "Draw R", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("rdmg", "Draw R Damage", SCRIPT_PARAM_ONOFF, true)
	settings.draw:addParam("target", "Draw Target", SCRIPT_PARAM_ONOFF, true)

	settings:addParam("axeKey", "Catch Axe Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	settings:addParam("axeToggle", "Catch all axes toggle", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("H"))

    settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "DivinePred", "HPred"})
end


--Lag Free Circles
function mythdraven:DrawCircle(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
		
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
		self:DrawCircleNextLvl(x, y, z, radius, 1, color, 300) 
	end
end

function mythdraven:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
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

function mythdraven:Round(number)
	if number >= 0 then 
		return math.floor(number+.5) 
	else 
		return math.ceil(number-.5) 
	end
end
