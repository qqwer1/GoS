if GetObjectName(GetMyHero()) ~= "Katarina" then return end

if not pcall( require, "Inspired" ) then PrintChat("You are missing Inspired.lua - Go download it and save it Common!") return end
if not pcall( require, "Deftlib" ) then PrintChat("You are missing Deftlib.lua - Go download it and save it in Common!") return end
if not pcall( require, "DamageLib" ) then PrintChat("You are missing DamageLib.lua - Go download it and save it in Common!") return end

local KatarinaMenu = MenuConfig("Katarina", "Katarina")
KatarinaMenu:Menu("Combo", "Combo")
KatarinaMenu.Combo:Boolean("Q", "Use Q", true)
KatarinaMenu.Combo:Boolean("W", "Use W", true)
KatarinaMenu.Combo:Boolean("E", "Use E", true)
KatarinaMenu.Combo:Boolean("R", "Use R", true)
KatarinaMenu.Combo:Key("WardJumpkey", "Ward Jump!", string.byte("G"))

KatarinaMenu:Menu("Harass", "Harass")
KatarinaMenu.Harass:Boolean("Q", "Use Q", true)
KatarinaMenu.Harass:Boolean("W", "Use W", true)
KatarinaMenu.Harass:Boolean("E", "Use E", true)
KatarinaMenu.Harass:Boolean("AutoQ", "Auto Q", false)
KatarinaMenu.Harass:Boolean("AutoW", "Auto W", true)

KatarinaMenu:Menu("Killsteal", "Killsteal")
KatarinaMenu.Killsteal:Boolean("SmartKS", "Smart KS", true)
KatarinaMenu.Killsteal:Boolean("UseWards", "Use Wards", true)

KatarinaMenu:Menu("Misc", "Misc")
KatarinaMenu.Misc:Boolean("Autoignite", "Auto Ignite", true)
KatarinaMenu.Misc:Boolean("Autolvl", "Auto level", true)
KatarinaMenu.Misc:DropDown("Autolvltable", "Priority", 1, {"Q-W-E", "W-Q-E", "Q-E-W"})

KatarinaMenu:Menu("JungleClear", "JungleClear")
KatarinaMenu.JungleClear:Boolean("Q", "Use Q", true)
KatarinaMenu.JungleClear:Boolean("W", "Use W", true)
KatarinaMenu.JungleClear:Boolean("E", "Use E", true)

KatarinaMenu:Menu("Lasthit", "Lasthit")
KatarinaMenu.Lasthit:Boolean("Q", "Lasthit with Q", false)
KatarinaMenu.Lasthit:Boolean("W", "Lasthit with W", false)
KatarinaMenu.Lasthit:Boolean("E", "Lasthit with E", false)

KatarinaMenu:Menu("Laneclear", "Laneclear")
KatarinaMenu.Laneclear:Boolean("Q", "Use Q", false)
KatarinaMenu.Laneclear:Boolean("W", "Use W", false)
KatarinaMenu.Laneclear:Boolean("E", "Use E", false)

KatarinaMenu:Menu("Drawings", "Drawings")
KatarinaMenu.Drawings:Boolean("Q", "Draw Q Range", true)
KatarinaMenu.Drawings:Boolean("W", "Draw W Range", true)
KatarinaMenu.Drawings:Boolean("E", "Draw E Range", true)
KatarinaMenu.Drawings:Boolean("R", "Draw R Range", true)
KatarinaMenu.Drawings:ColorPick("color", "Color Picker", {255,255,255,0})
KatarinaMenu.Drawings:Boolean("Text", "Draw Damage Text", true)

OnDraw(function(myHero)
local col = KatarinaMenu.Drawings.color:Value()
if KatarinaMenu.Drawings.Q:Value() then DrawCircle(myHeroPos(),675,1,0,col) end
if KatarinaMenu.Drawings.W:Value() then DrawCircle(myHeroPos(),375,1,0,col) end
if KatarinaMenu.Drawings.E:Value() then DrawCircle(myHeroPos(),700,1,0,col) end
if KatarinaMenu.Drawings.R:Value() then DrawCircle(myHeroPos(),550,1,0,col) end
  if KatarinaMenu.Drawings.Text:Value() then
    for _, enemy in pairs(GetEnemyHeroes()) do
      if ValidTarget(enemy) then
      local enemyPos = GetOrigin(enemy)
      local drawpos = WorldToScreen(1,enemyPos.x, enemyPos.y, enemyPos.z)
      local enemyText, color = GetDrawText(enemy)
      DrawText(enemyText, 20, drawpos.x, drawpos.y, color)
      end
    end
  end
end)

local jumpTarget
local wardLock
local mousePos
local wardpos
local maxPos 
local spellObj
local objectList = {}

local wardItems = {        
        { id = 3340, spellName = "TrinketTotemLvl1"},
        { id = 3350, spellName = "TrinketTotemLvl2"},
        { id = 3361, spellName = "TrinketTotemLvl3"},
        { id = 3362, spellName = "TrinketTotemLvl3B"},
        { id = 2045, spellName = "ItemGhostWard"},
        { id = 2049, spellName = "ItemGhostWard"},
        { id = 2050, spellName = "ItemMiniWard"},
        { id = 2044, spellName = "sightward"},
        { id = 2043, spellName = "VisionWard"}
}

local function IsInDistance2(r, p1, p2, fast)
		local fast = fast or false
		if fast then
		local p1y = p1.z or p1.y
		local p2y = p2.z or p2.y
		return (p1.x + r >= p2.x) and (p1.x - r <= p2.x) and (p1y + r >= p2y) and (p1y - r <= p2y)
		else
    	return GetDistanceSqr(p1, p2) < r*r
    end
end

local function calcMaxPos(pos)
	local origin = GetOrigin(myHero)
	local vectorx = pos.x-origin.x
	local vectory = pos.y-origin.y
	local vectorz = pos.z-origin.z
	local dist= math.sqrt(vectorx^2+vectory^2+vectorz^2)
	return {x = origin.x + 600 * vectorx / dist ,y = origin.y + 600 * vectory / dist, z = origin.z + 600 * vectorz / dist}
end

local function ValidTarget2( object )
	local objType = GetObjectType(object)
	return (objType == Obj_AI_Hero or objType == Obj_AI_Minion) and IsVisible(object)
end

local findWardSlot = function ()
	local slot = 0
	for i,wardItem in pairs(wardItems) do
	slot = GetItemSlot(myHero,wardItem.id)
	if slot > 0 and IsReady(slot) then return slot end
	end
end

local function putWard(pos0)	
	local slot = findWardSlot()

	local pos = pos0
	if not IsInDistance2(600, pos) then
	pos = calcMaxPos(pos)
	end

	if slot and slot > 0 then
	CastSkillShot(slot,pos)
	end
end

local spellLock = nil

function wardJump( pos )
	if not spellLock and IsReady(_E) then
		if jumpTarget then
		CastTargetSpell(jumpTarget, _E)
		spellLock = GetTickCount()
		elseif not wardLock then
		wardLock = GetTickCount()
		putWard(pos)
		end
	end
end

local function GetJumpTarget()
	local pos = mousePos
	if not IsInDistance2(600, mousePos, GetOrigin(myHero)) then
	pos = maxPos
	end
	for _,object in pairs(objectList) do
	  if ValidTarget2(object) and IsInDistance2(200, GetOrigin(object), pos) then
	  return object
	  end
	end
	return nil
end

local CastingR = false
local lastlevel = GetLevel(myHero)-1

OnTick(function(myHero)
  local target = GetCurrentTarget()
  
  if IOW:Mode() == "Combo" then

      if IsReady(_Q) and KatarinaMenu.Combo.Q:Value() and ValidTarget(target, 675) and not CastingR then
      CastTargetSpell(target, _Q)
      end
	  
      if IsReady(_W) and KatarinaMenu.Combo.W:Value() and ValidTarget(target, 375) and not CastingR then
      CastSpell(_W)
      end
	  
      if IsReady(_E) and KatarinaMenu.Combo.E:Value() and ValidTarget(target, 700) and not CastingR then
      CastTargetSpell(target, _E)
      end
	  
      if KatarinaMenu.Combo.R:Value() and CanUseSpell(myHero, _Q) ~= READY and CanUseSpell(myHero, _W) ~= READY and CanUseSpell(myHero, _E) ~= READY and CanUseSpell(myHero, _R)  ~= ONCOOLDOWN and ValidTarget(target, 550) and GetCastLevel(myHero,_R) > 0 then
      IOW.movementEnabled = false
      IOW.attacksEnabled = false
      CastSpell(_R)
      end
  end

  if IOW:Mode() == "Harass" then
 
      if IsReady(_Q) and KatarinaMenu.Harass.Q:Value() and ValidTarget(target, 675) then
      CastTargetSpell(target, _Q)
      end
	  
      if IsReady(_W) and KatarinaMenu.Harass.W:Value() and ValidTarget(target, 375) then
      CastSpell(_W)
      end
	  
      if IsReady(_E) and KatarinaMenu.Harass.E:Value() and ValidTarget(target, 700) then
      CastTargetSpell(target, _E)
      end
  end

if KatarinaMenu.Harass.AutoQ:Value() and ValidTarget(target, 675) and not CastingR then
CastTargetSpell(target, _Q)
end

if KatarinaMenu.Harass.AutoW:Value() and ValidTarget(target, 375) and not CastingR then
CastSpell(_W)
end

    for i,enemy in pairs(GetEnemyHeroes()) do
       if KatarinaMenu.Killsteal.SmartKS:Value() then
				
		if Ignite and KatarinaMenu.Misc.Autoignite:Value() then
                  if IsReady(Ignite) and 20*GetLevel(myHero)+50 > GetHP(enemy)+GetHPRegen(enemy)*2.5 and ValidTarget(enemy, 600) then
                  CastTargetSpell(enemy, Ignite)
                  end
                end
		
                if IsReady(_W) and GetHP2(enemy) < getdmg("W",enemy) and ValidTarget(enemy, 375) then 
		CastSpell(_W)
	        end		
	
		if IsReady(_Q) and GetHP2(enemy) < getdmg("Q",enemy) and ValidTarget(enemy, 675) then 
		CastTargetSpell(enemy, _Q)
		end	
		
		if IsReady(_E) and GetHP2(enemy) < getdmg("E",enemy) and ValidTarget(enemy, 700) then 
		CastTargetSpell(enemy, _E)
	        end		
		
		if IsReady(_Q) and IsReady(_W) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("W",enemy) and ValidTarget(enemy, 375) then 
		CastSpell(_W)
                DelayAction(function() CastTargetSpell(enemy, _Q) end, 250)
		end
	
	        if IsReady(_E) and IsReady(_W) and GetHP2(enemy) < getdmg("W",enemy) + getdmg("W",enemy) and ValidTarget(enemy, 700) then 
		CastTargetSpell(enemy, _E)
		DelayAction(function() CastSpell(_W) end, 250)
				
		if IsReady(_Q) and IsReady(_W) and IsReady(_E) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("W",enemy) + getdmg("E",enemy) and ValidTarget(enemy, 700) then 
		CastTargetSpell(enemy, _E)
		DelayAction(function() CastTargetSpell(enemy, _Q) end, 250)
		DelayAction(function() CastSpell(_W) end, 250)
		end
				
	        if KatarinaMenu.Killsteal.UseWards:Value() and ValidTarget(enemy, 1275) and GetDistance(enemy) > 700 and IsReady(_Q) and GetHP2(enemy) < getdmg("Q",enemy) then
		wardJump(GetOrigin(enemy))
		DelayAction(function() CastTargetSpell(enemy, _Q) end, 250)
	        end
				
	end
     end



        if IOW:Mode() == "LaneClear" then
          for _,mobs in pairs(minionManager.objects) do
            if GetTeam(mobs) == MINION_ENEMY then
		if IsReady(_Q) and KatarinaMenu.Laneclear.Q:Value() and ValidTarget(mobs, 675) then
		CastTargetSpell(mobs, _Q)
		end
		
		if IsReady(_W) and KatarinaMenu.Laneclear.W:Value() and ValidTarget(mobs, 375) then
		CastSpell(_W)
		end
		
		if IsReady(_E) and KatarinaMenu.Laneclear.E:Value() and ValidTarget(mobs, 700) then
		CastTargetSpell(mobs, _E)
                end
            
	    elseif GetTeam(mobs) == 300 then
	        if IsReady(_Q) and KatarinaMenu.JungleClear.Q:Value() and ValidTarget(mobs, 675) then
		CastTargetSpell(mobs, _Q)
		end
		
		if IsReady(_W) and KatarinaMenu.JungleClear.W:Value() and ValidTarget(mobs, 375) then
		CastSpell(_W)
		end
		
	        if IsReady(_E) and KatarinaMenu.JungleClear.E:Value() and ValidTarget(mobs, 700) then
		CastTargetSpell(mobs, _E)
	        end
	    end
          end
   
	end
	
	if IOW:Mode() == "LastHit" then
	  for _,mobs in pairs(minionManager.objects) do
            if GetTeam(mobs) == MINION_ENEMY then
	        if IsReady(_W) and KatarinaMenu.Lasthit.W:Value() and ValidTarget(mobs, 375) and GetCurrentHP(mobs) < getdmg("W",mobs) then
		CastSpell(_W)
		elseif IsReady(_Q) and KatarinaMenu.Lasthit.Q:Value() and ValidTarget(mobs, 675) and GetCurrentHP(mobs) < getdmg("Q",mobs) then
		CastTargetSpell(mobs, _Q)
		elseif IsReady(_E) and KatarinaMenu.Lasthit.E:Value() and ValidTarget(mobs, 700) and GetCurrentHP(mobs) < getdmg("E",mobs) then
		CastTargetSpell(mobs, _E)
		end
            end
          end
	end

end

        mousePos = GetMousePos()
	maxPos = calcMaxPos(mousePos)
	jumpTarget = GetJumpTarget()

	if not spellLock and wardLock and jumpTarget and IsReady(_E) then
	CastTargetSpell(jumpTarget, _E)
	spellLock = GetTickCount()
	end

	if KatarinaMenu.Combo.WardJumpkey:Value() then
	wardJump(mousePos)
	MoveToXYZ(mousePos.x, mousePos.y, mousePos.z)
	end
	
	if wardLock and (wardLock + 500) < GetTickCount()  then
	wardLock = nil
	end
	
	if spellLock and (spellLock + 500) < GetTickCount()  then
	spellLock = nil
	end

	jumpTarget = nil
	spellObj = nil
	wardpos = nil

if KatarinaMenu.Misc.Autolvl:Value() then
 if GetLevel(myHero) > lastlevel then
   if KatarinaMenu.Misc.Autolvltable:Value() == 1 then leveltable = {_Q, _W, _E, _Q, _Q , _R, _Q, _W, _Q , _W, _R, _W, _W, _E, _E, _R, _E, _E}
   elseif KatarinaMenu.Misc.Autolvltable:Value() == 2 then leveltable = {_Q, _W, _E, _W, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E}
   elseif KatarinaMenu.Misc.Autolvltable:Value() == 3 then leveltable = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W,}
   end
   DelayAction(function() LevelSpell(leveltable[GetLevel(myHero)]) end, math.random(1000,3000))
   lastlevel = GetLevel(myHero)
 end
end

end)

OnProcessSpell(function(unit,spell)
  if unit == myHero and spell.name:lower():find("katarinar") then
  CastingR = true
  IOW.movementEnabled = false
  IOW.attacksEnabled = false
  end

  if unit == myHero and not spell.name:lower():find("katarina") then
  spellObj = spell
  wardpos = spellObj.endPos
  end
end)

OnCreateObj(function(object)
  local objType = GetObjectType(object)
  if objType == Obj_AI_Hero or objType == Obj_AI_Minion then
  objectList[object] = object
  end
end)

OnDeleteObj(function(object)
  local objType = GetObjectType(object)
  if objType == Obj_AI_Hero or objType == Obj_AI_Minion then
  objectList[object] = nil
  end
end)

OnUpdateBuff(function(unit,buff)
  if unit == myHero and buff.Name == "katarinarsound" then
  CastingR = true
  IOW.movementEnabled = false
  IOW.attacksEnabled = false
  end
end)

OnRemoveBuff(function(unit,buff)
  if unit == myHero and buff.Name == "katarinarsound" then
  CastingR = false
  IOW.movementEnabled = true
  IOW.attacksEnabled = true
  end
end)

function GetDrawText(enemy)
	local IgniteDmg = 0
	if Ignite and IsReady(Ignite) then
	IgniteDmg = IgniteDmg + 20*GetLevel(myHero)+50
	end
	
	if IsReady(_Q) and GetHP2(enemy) < getdmg("Q",enemy) then
		return 'Q = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_W) and GetHP2(enemy) < getdmg("W",enemy) then
		return 'W = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_E) and GetHP2(enemy) < getdmg("E",enemy) then
		return 'E = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_Q) and IsReady(_W) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("W",enemy) then
		return 'W + Q = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_W) and IsReady(_E) and GetHP2(enemy) < getdmg("W",enemy) + getdmg("E",enemy) then
		return 'E + W = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_Q) and IsReady(_W) and IsReady(_E) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("W",enemy) + getdmg("E",enemy) then
		return 'Q + W + E = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_Q) and IsReady(_W) and IsReady(_E) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("Q",enemy,myHero,2) + getdmg("W",enemy) + getdmg("E",enemy) then
		return '(Q + Passive) + W +E = Kill!', ARGB(255, 200, 160, 0)
	elseif IgniteDmg > 0 and IsReady(_Q) and IsReady(_W) and IsReady(_E) and GetHP2(enemy) < IgniteDmg + getdmg("Q",enemy) + getdmg("Q",enemy,myHero,2) + getdmg("W",enemy) + getdmg("E",enemy) then
		return '(Q + Passive) + W + E + Ignite = Kill!', ARGB(255, 200, 160, 0)
	elseif IsReady(_Q) and IsReady(_W) and IsReady(_E) and IsReady(_R) and GetHP2(enemy) < getdmg("Q",enemy) + getdmg("W",enemy) + getdmg("E",enemy) + getdmg("R",enemy,myHero,3) then
		return 'Q + W + E + Ult ('.. string.format('%4.1f', (GetHP2(enemy) - getdmg("Q",enemy) - getdmg("W",enemy) - getdmg("E",enemy) - getdmg("R",enemy,myHero,3))/4) .. ' Secs) = Kill!', ARGB(255, 255, 69, 0)
	else
		return 'Cant Kill Yet', ARGB(255, 200, 160, 0)
	end
end
