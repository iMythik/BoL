--[[
	running on
    __  ___        __   __     _  __      ______                                                     __      ___      ____ 
   /  |/  /__  __ / /_ / /_   (_)/ /__   / ____/_____ ____ _ ____ ___   ___  _      __ ____   _____ / /__   |__ \    / __ \
  / /|_/ // / / // __// __ \ / // //_/  / /_   / ___// __ `// __ `__ \ / _ \| | /| / // __ \ / ___// //_/   __/ /   / / / /
 / /  / // /_/ // /_ / / / // // ,<    / __/  / /   / /_/ // / / / / //  __/| |/ |/ // /_/ // /   / ,<     / __/ _ / /_/ / 
/_/  /_/ \__, / \__//_/ /_//_//_/|_|  /_/    /_/    \__,_//_/ /_/ /_/ \___/ |__/|__/ \____//_/   /_/|_|   /____/(_)\____/  
        /____/                                                                                                             

	We've come a long way :) 

	Mythik Framework is usable by anyone, if you wish to use it, please do not change the credits or remove the header.
--]]

ver = 1.1

if myHero.charName ~= "Kalista" then return end

--[[=======================================================
   Localization
=========================================================]]

local update        = true
local me 			= _G.myHero -- LocalPlayer
local CastSpell 	= _G.CastSpell -- Cast func
local ValidTarget 	= _G.ValidTarget -- Valid target check
local damage 		= _G.getDmg -- damage calc

-- base table of all things that are holy
local myth = {
	name = "MythKalista", -- script name
	ver = ver, -- script version
	foes = GetEnemyHeroes(), -- enemy champs
	pred = {"VPred", "DivinePred", "HPred"}, -- prediction table
	modules = {"VPrediction", "DivinePred", "HPrediction"}, --libs to load
	url = "http://raw.github.com/iMythik/BoL/master/MythKalista.lua", --update url
	ts = TargetSelector(TARGET_LOW_HP, 1500, DAMAGE_PHYSICAL, false, true), --target selector
	creep = minionManager(MINION_ENEMY, 200, me, MINION_SORT_HEALTH_ASC), --creep selection
	skill = {
		q = {range=1200,del=0.25,speed=1750,w=70},
		w = {},
		e = {},
		r = {},
	}
}

--[[=======================================================
   Updater
=========================================================]]

function myth:printChat(msg) -- chat message with prefix
	print("<font color='#D40000'>["..myth.name.."]</font><font color='#FFFFFF'> "..msg.."</font>") 
end

function myth:update() -- updater func
    local result = GetWebResult("raw.github.com", "/iMythik/BoL/master/"..myth.name..".lua")

    if not result or result == nil then return end

    local netv = string.match(result, "ver = \"%d+.%d+\"")
    netv = string.match(netv and netv or "", "%d+.%d+")

    if not netv or netv == nil then return end

    netv = tonumber(netv)
    if tonumber(myth.ver) < netv then
        myth:printChat("New version found, updating... don't press F9.")
        DownloadFile(myth.url, SCRIPT_PATH..myth.name..".lua", function() myth:printChat("Updated script ["..myth.ver.." to "..netv.."], press F9 twice to reload the script.") end)    
    else
        myth:printChat("is running latest version!")
    end
end

--[[=======================================================
   Module/Lib Loading
=========================================================]]

local loaded = {}
for k, v in pairs(myth.modules) do -- require modules
	if FileExist(LIB_PATH .. "/"..v..".lua") then
		require(v)
		table.insert(loaded, v)
	else
		myth:printChat("Library "..v.." not found")
	end
end

local function loadPred() -- load pred intergration
	for k, v in pairs(loaded) do
		if v == "DivinePred" then
			dpred = DivinePred()
			myth.skill.q.pred = LineSS(myth.skill.q.speed, myth.skill.q.range, myth.skill.q.w, myth.skill.q.del, 0)
		end
		if v == "VPrediction" then
			vpred = VPrediction()
		end
		if v == "HPrediction" then
			hpred = HPrediction()
			HP_Q = HPSkillshot({type = "DelayLine", delay = 0.25, range = 1200, collisionM = true, collisionH = true, width = 1750, speed = 1750})		end
	end
end

--[[=======================================================
   Orbwalker Intergration
=========================================================]]

local function getOrbwalk() -- return running orbwalk
	if _G.AutoCarry then
		return "sac"
	elseif _G.MMA_Loaded then
		return "mma"
	else
		return "none"
	end
end

local function loadOrbwalk() -- load orbwalk if one isnt loaded
	if getOrbwalk() == "sac" then
		myth:printChat("SA:C Intergration loaded.")
	elseif getOrbwalk() == "mma" then
		myth:printChat("MMA Intergration loaded.")
	else 
		myth:printChat("No orbwalker found, loading SxOrbWalk...")
		require("SxOrbWalk")
	end
end

local function target() -- target selection
	myth.ts:update()
	if getOrbwalk() == "sac" and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then return _G.AutoCarry.Crosshair:GetTarget() end		
	if getOrbwalk() == "mma" and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return myth.ts.target
end

--[[=======================================================
   Stack Calculation (thanks sida <3)
=========================================================]]

local unitStacks = {}
local m8 = nil
 
function OnUpdateBuff(Unit, Buff, Stacks)
   if Buff.name == "kalistaexpungemarker" then
      unitStacks[Unit.networkID] = Stacks
   end

   if Buff.name == "kalistavobindally" then
   		if unit ~= me.name then
   			myth:printChat(Unit.." is now binded as your support.")
   			m8 = Unit -- u fokin wot m8? 8/8 gr8 m8
   		end
   	end
end
 
function OnRemoveBuff(Unit, Buff)
   if Buff.name == "kalistaexpungemarker" then
      unitStacks[Unit.networkID] = nil
   end
end

function GetStacks(unit)
   return unitStacks[unit.networkID] or 0
end

--[[=======================================================
   Cast Functions
=========================================================]]

function myth:cast(spell, targ) -- dynamic cast func
	if spell == "q" then
		if not settings.combo.q or not qready or not ValidTarget(targ, myth.skill.q.range) then return end
		if settings.pred == 1 then
			local cP,chance,pos = vpred:GetLineCastPosition(targ, myth.skill.q.del, myth.skill.q.w, myth.skill.q.range, myth.skill.q.speed, me, true)
			if chance >= 2 then
    	    	CastSpell(_Q, cP.x, cP.z)
    		end
		elseif settings.pred == 2 then
			local dpt = DPTarget(targ)
    		local state,hitPos,perc = dpred:predict(dpt, myth.skill.q.pred)
    		if state == SkillShot.STATUS.SUCCESS_HIT then
       			CastSpell(_Q, hitPos.x, hitPos.z)
      		end
		elseif settings.pred == 3 then
			QPos, QHitChance = hpred:GetPredict(HP_Q, targ, me)
			if QHitChance >= 2 then
				CastSpell(_Q, cP.x, cP.z)
			end
		end
	end
	if spell == "w" then
		if not settings.combo.w or not wready then return end
	end
	if spell == "e" then
		if not settings.combo.e or not eready then return end
		CastSpell(_E)
	end
	if spell == "r" then
		if not settings.combo.r or not rready or not ValidTarget(targ, myth.skill.r.range) then return end
		CastSpell(_R)
	end
end

local function rendDamage(unit)
	if elvl == 1 then
		dmg = 20 + 0.6 * me.totalDamage + (0.3 * me.totalDamage + 10 * GetStacks(unit))
	end
	if elvl == 2 then
		dmg = 30 + 0.6 * me.totalDamage + (0.3 * me.totalDamage + 14 * GetStacks(unit))
	end		
	if elvl == 3 then
		dmg = 40 + 0.6 * me.totalDamage + (0.3 * me.totalDamage + 19 * GetStacks(unit))
	end	
	if elvl == 4 then
		dmg = 50 + 0.6 * me.totalDamage + (0.3 * me.totalDamage + 25 * GetStacks(unit))
	end	
	if elvl == 5 then
		dmg = 60 + 0.6 * me.totalDamage + (0.3 * me.totalDamage + 32 * GetStacks(unit))
	end	

	return dmg
end	

local function saveFriend()
	if m8 == nil then return end -- u fokin wot m8???

	if m8.health < 200 and rready then
		CastSpell(_R)
		myth:printChat("Saving your partner...")
	end
end

local function bang(unit) -- combo (bang bang skudda)
	myth:cast("q", unit)

	if unit == nil then return end

	if rendDamage(unit) > unit.health then
		myth:cast("e", unit)
	end
end

local function harass(unit) -- harass dat nigga
	if settings.harass.autoq then
		myth:cast("q", unit)
	end

	if settings.harass.key then
		if settings.harass.q then
			myth:cast("q", unit)
		end
	end
end

local function farm() -- minion farm
	myth.creep:update()
	
	for i, m in pairs(myth.creep.objects) do
		if settings.farm.q then
			myth:cast("q", m)
		end
	end
end

local function steal() -- killsteal
	for k, v in pairs(myth.foes) do
		if settings.ks.q and ValidTarget(v, myth.skill.q.range) and damage("Q", v, me) > v.health then
			myth:cast("q", unit)
		end
	end
end

--[[=======================================================
   Menu
=========================================================]]

local function menu()
	settings = scriptConfig("["..myth.name.."]", "mythik")

	TargetSelector.name = "Target Select"

	settings:addSubMenu("Full Combo", "combo")
	settings.combo:addParam("key", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	settings.combo:addParam("q", "Auto Q", SCRIPT_PARAM_ONOFF, true)
	settings.combo:addParam("e", "Use E when killable", SCRIPT_PARAM_ONOFF, true)

	settings:addSubMenu("Harass", "harass")
	settings.harass:addParam("key", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, 67)
	settings.harass:addParam("autoq", "Auto Q in range", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("T"))
	settings.harass:addParam("q", "Harass with Q", SCRIPT_PARAM_ONOFF, false)

	settings:addSubMenu("Kill Steal", "ks")
	settings.ks:addParam("q", "Kill steal with Q", SCRIPT_PARAM_ONOFF, false)
	settings.ks:addParam("e", "Kill steal with E", SCRIPT_PARAM_ONOFF, false)

	settings:addSubMenu("Farm", "farm")
	settings.farm:addParam("key", "Farm Key", SCRIPT_PARAM_ONKEYDOWN, false, 86)
	settings.farm:addParam("q", "Farm with Q", SCRIPT_PARAM_ONOFF, false)

	settings:addSubMenu("Drawing", "draw")

	if myth.skill.q.range ~= nil then
		settings.draw:addParam("q", "Draw Q", SCRIPT_PARAM_ONOFF, false)
	end
	if myth.skill.w.range ~= nil then
		settings.draw:addParam("w", "Draw W", SCRIPT_PARAM_ONOFF, false)
	end
	if myth.skill.e.range ~= nil then
		settings.draw:addParam("e", "Draw E", SCRIPT_PARAM_ONOFF, false)
	end
	if myth.skill.r.range ~= nil then
		settings.draw:addParam("r", "Draw R", SCRIPT_PARAM_ONOFF, false)
	end

	settings:addTS(myth.ts)
	settings:addParam("pred", "Prediction Type", SCRIPT_PARAM_LIST, 1, loaded)
end

--[[=======================================================
   Main Hooks
=========================================================]]

function OnLoad()
	myth:printChat("has loaded!<font color='#2BFF00'> ["..myth.ver.."]")

	if getOrbwalk() == "none" then -- Incase the script is reloaded, and sa:c/mma is already loaded
		DelayAction(loadOrbwalk, 7)
	else
		loadOrbwalk()
	end

	DelayAction(loadPred, 3) -- load prediction

	menu() -- load menu

	myth:update()
end

function OnTick()
	qready, wready, eready, rready = me:CanUseSpell(_Q) == READY, me:CanUseSpell(_W) == READY, me:CanUseSpell(_E) == READY, me:CanUseSpell(_R) == READY
	elvl = me:GetSpellData(_E).level

	myth.ts:update() --update target selection
	myth.creep:update() --update creep selection

	if settings.combo.key then -- combo
		bang(target())
	end

	harass(target()) -- harass
	
	if settings.farm.key then -- farm
		farm()
	end

	steal() -- kill stealer

	saveFriend()
end

function OnDraw()
	if myth.skill.q.range ~= nil and settings.draw.q and qready then
		DrawCircle(me.x, me.y, me.z, myth.skill.q.range, ARGB(125,0,150,255))
	end
	if myth.skill.w.range ~= nil and settings.draw.w and wready then
		DrawCircle(me.x, me.y, me.z, myth.skill.w.range, ARGB(125,0,150,255))
	end
	if myth.skill.e.range ~= nil and settings.draw.e and eready then
		DrawCircle(me.x, me.y, me.z, myth.skill.e.range, ARGB(125,0,150,255))
	end
	if myth.skill.r.range ~= nil and settings.draw.r and rready then
		DrawCircle(me.x, me.y, me.z, myth.skill.r.range, ARGB(125,0,150,255))
	end

	if ValidTarget(target()) and eready then
		local targ = target()
		DrawLineHPBar(rendDamage(targ), 1, " E Damage: "..math.round(rendDamage(targ)), targ, true)
	end
end

--[[=======================================================
   Draw Predicted E damage
=========================================================]]

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

--[[=======================================================
   Lag-Free Circles
=========================================================]]

local function round(num) 
	if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end

local function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
  	quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  	quality = 2 * math.pi / quality
	radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function DrawCircle(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 200) 
    end
end

assert(load(Base64Decode("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"), nil, "bt", _ENV))() ScriptStatus("PCFEDDHEJDC") 