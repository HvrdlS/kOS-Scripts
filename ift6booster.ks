clearscreen.
set n to time:seconds-missiontime.
set t to time:seconds-n.
on ag9 {
  set sstatus to "Catch abort, T+ " + round(t,1) + " Seconds".
  set landingZone to latlng(-5.46, -83.86).
  set targetaltit to 0.
  set Catch to false.
  if boostbackcalc = 0 {
    set tarerror to 0.
  }

  preserve.
}

settings().
boostback().
entry().
landing().


function settings {
  unlock all.
  set ship:control:pilotmainthrottle to 0.
  ship:partsdubbed("FirstStageControl")[0]:controlfrom().  /// vehicle`s unique thing with hotstage ring as rootpart causing problems later
  set errorScalling to 1.
  set landingZone to latlng(-5.46928365429311, -84.0277023880855). 
  set gm to 1.   /// enables opportunity to use math calculated trajectory prediction if Trajectories is not available
  set oldTime to time:seconds.
  set grav to body:mu / body:radius^2.
  set AccelCoef to 1. 
  set targetaltit to 32. /// catch altitude
  set engswitchalt to 100.  /// engine number switch altitude during landing burn
  set tarerror to 300.  /// target undershoot in M
  lock targetheading to heading(232,0):vector.  /// hardcoded heading value for grid fins to align with Mechazilla
  set h to 35. /// vessel height
  set altit to alt:radar - h - targetaltit. 
  set P to 1.
  set I to 0.
  set D to 0.
  set throttpid to pidloop(P,I,D,-0.05, 1).
  set boostbackcalc to 0.
  set landingburncalculated to 0.
  set landingburn to 0.
  set plannedengnum to 13.
  set Catch to true.
  set FAR to addons:FAR.
  set dragcoef to 0.45.
  
  set fte to ship:partstagged("fte").  /// fuel dumper parts
  set bt to ship:partsdubbed("bts")[0].  /// booster landing burn tank
  set firesupresslist to ship:partstagged("FireSupress").  /// fire supression system imitation with SRBs
  set rb1 to bt:resources.
  set rb2 to rb1[0].
  set rb3 to rb1[1].
  set rb2:enabled to false.
  set rb3:enabled to false.
  set engList to list().
  set i to -1.
  until i >= 32 {
    set i to i + 1.
    engList:add(ship:partstagged("Vector" + i)[0]).
  }

  set innerEngines to list().
  set i to 2.
  until i >= 12 {
    set i to i + 1.
    innerEngines:add(ship:partsdubbed("Vector" + i)[0]).
  }

  set outerEngines to list().
  set i to 12.
  until i >= 32 {
    set i to i + 1.
    outerEngines:add(ship:partsdubbed("Vector" + i)[0]).
  }

  for eng in outerEngines { eng:shutdown. }
  for eng in outerEngines { set eng:thrustlimit to 0. }
  for eng in innerEngines { eng:shutdown. }
  for eng in innerEngines { set eng:thrustlimit to 0. }
  engnumcheck().
  sas off.
  rcs on.
}


function overshootTargetError {
  set overshootTarget to landingZone:position-vxcl(up:vector,ship:velocity:surface):normalized*tarerror.  /// despite its naming undershoots landingZone on targeted value
  return (getImpact():position+getImpact():position:normalized*targetaltit) - (overshootTarget+overshootTarget:normalized*targetaltit).   /// lifts all impact related vectors on targetaltit
}


function statedetect {
  for eng in engList {
    if eng:thrustlimit < 0.1 {
      eng:shutdown.
    }

    if eng:thrustlimit > 0.1 {
      eng:activate.
    }
  }
}


function engnumcheck {
    set curthr to 0.
    for eng in engList { set curthr to curthr + eng:possiblethrust. }
    if activeengine() > 0 {
        set currentengnum to round(curthr/activeengine(),0).
    } else {
        set currentengnum to 0.
    }

    return currentengnum.
}


function activeengine {
    local i is 0.
    set testeng to engList[i]:possiblethrust.
    until testeng > 0 or i = 32 {
        set i to min(32, i + 1).
        set testeng to engList[i]:possiblethrust.
    }

    return testeng.
}


function boosterengines {
  if ign = 1 {
    for eng in innerEngines { set eng:thrustlimit to 0. }
    if landingburncalculated = 1 {
      set command to time:seconds.
      set commandtime to time:seconds - command.
      until commandtime > 1.8 {
        printing().
        update().
        statedetect().
        landingburncalc(engnumcheck(), plannedengnum).
        set commandtime to time:seconds - command.
        set sealim to (commandtime-0.3)*320.
        if commandtime < 0.3 {
          set sealim to 1.
        }

        set ship:partstagged("Vector0")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector1")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector2")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector11")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector7")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector5")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector3")[0]:thrustlimit to sealim-150.
        set ship:partstagged("Vector9")[0]:thrustlimit to sealim-150.
        set ship:partstagged("Vector4")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector6")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector8")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector10")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector12")[0]:thrustlimit to sealim-300.
      }

      for eng in innerEngines { set eng:thrustlimit to 100. }
      statedetect().
    } else if boostbackcalc = 1 {
      set command to time:seconds.
      set commandtime to time:seconds - command.
      until commandtime > 2 {
        printing().
        update().
        statedetect().
        set commandtime to time:seconds - command.
        set sealim to (commandtime-0.3)*320.
        if commandtime < 0.3 {
          set sealim to 1.
        }
        
        set ship:partstagged("Vector0")[0]:thrustlimit to 50+sealim.
        set ship:partstagged("Vector1")[0]:thrustlimit to 50+sealim.
        set ship:partstagged("Vector2")[0]:thrustlimit to 50+sealim.
        set ship:partstagged("Vector11")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector6")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector10")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector5")[0]:thrustlimit to sealim-100.
        set ship:partstagged("Vector8")[0]:thrustlimit to sealim-200.
        set ship:partstagged("Vector3")[0]:thrustlimit to sealim-200.
        set ship:partstagged("Vector9")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector4")[0]:thrustlimit to sealim-300.
        set ship:partstagged("Vector12")[0]:thrustlimit to sealim-400.
        set ship:partstagged("Vector7")[0]:thrustlimit to sealim-400.
      }

      for eng in innerEngines { set eng:thrustlimit to 100. }
      statedetect().
    }
  } else if ign = 0 {
    if boostbackcalc = 1 {
      set command to time:seconds.
      set commandtime to time:seconds - command.
      until commandtime > 2 {
        printing().
        update().
        statedetect().
        set commandtime to time:seconds - command.
        set sealim to 100-commandtime*320.
        set ship:partstagged("Vector4")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector6")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector8")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector10")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector12")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector3")[0]:thrustlimit to sealim+160.
        set ship:partstagged("Vector7")[0]:thrustlimit to sealim+160.
        set ship:partstagged("Vector9")[0]:thrustlimit to sealim+160.
        set ship:partstagged("Vector11")[0]:thrustlimit to sealim+160.
        set ship:partstagged("Vector5")[0]:thrustlimit to sealim+200.
      }

      for eng in innerEngines { set eng:thrustlimit to 0. }
    }

    if landingburncalculated = 1 and boostbackcalc = 0  {
      set command to time:seconds.
      set commandtime to time:seconds - command.
      until commandtime > 2 {
        printing().
        update().
        statedetect().
        landingburncalc(engnumcheck(), plannedengnum).
        set commandtime to time:seconds - command.
        set sealim to 100-commandtime*180.
        set ship:partstagged("Vector9")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector11")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector5")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector4")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector6")[0]:thrustlimit to sealim+60.
        set ship:partstagged("Vector7")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector10")[0]:thrustlimit to sealim.
        set ship:partstagged("Vector12")[0]:thrustlimit to sealim.
      }
     
    } else if landingburncalculated = 0 and boostbackcalc = 0 {
      set command to time:seconds.
      set commandtime to time:seconds - command.
      until commandtime > 0.45 {
        printing().
        update().
        set commandtime to time:seconds - command.
        set sealim to 100-commandtime*320.
        set ship:partstagged("Vector1")[0]:thrustlimit to max(3,sealim).
        set ship:partstagged("Vector2")[0]:thrustlimit to max(3,sealim+60).
        set ship:partstagged("Vector0")[0]:thrustlimit to max(3,sealim).
        set ship:partstagged("Vector3")[0]:thrustlimit to max(3,sealim).
        set ship:partstagged("Vector8")[0]:thrustlimit to max(3,sealim).
      }

      set ship:partstagged("Vector1")[0]:thrustlimit to 3.
      set ship:partstagged("Vector2")[0]:thrustlimit to 3.
      set ship:partstagged("Vector0")[0]:thrustlimit to 3.
      for eng in innerEngines { set eng:thrustlimit to 0. }
    }
  }
}


function boostback {
  set sstatus to "Boostback burn starting, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 0.8.
  set boostbackcalc to 1.
  lock steering to -vxcl(up:vector, overshootTargetError()).
  lock throttle to 0.5.
  wait 1.
  until vang(facing:vector, -vxcl(up:vector, overshootTargetError()))<125 {
    printing().
    update().
    overshootTargetError().
  }

  set ign to 1.
  boosterengines().
  until vang(facing:vector, -vxcl(up:vector, overshootTargetError()))<15 {
    printing().
    update().
    overshootTargetError().
  }

  set ti1 to time:seconds.
  lock ti2 to time:seconds-ti1.
  lock throttle to max(0.5, ti2+0.5).
  until ti2 > 1 {
    printing().
    update().
    overshootTargetError().
  } 
  
  lock throttle to 1.
  until abs(overshootTargetError():mag) < 10000 {
    printing().
    update().
    overshootTargetError().
  }

  set sstatus to "Boostback burn is ending, three Raptors are on".
  set ign to 0.
  boosterengines().
  set olderror to overshootTargetError():mag.
  wait 0.1.
  set newerror to overshootTargetError():mag.
  until newerror > olderror {
    set olderror to overshootTargetError():mag.
    wait 0.1.
    set newerror to overshootTargetError():mag.
    printing().
    update().
  }

  set sstatus to "Boostback burn shutdown, T+ " + round(t,1) + " Seconds".
  set boostbackcalc to 0.
  set ti1 to time:seconds.
  lock ti2 to time:seconds-ti1.
  lock throttle to min(1, 1-ti2*2).
  unlock steering.
  set ringdec to time:seconds + 10.
  print firesupresslist:length.
  wait 1.
  set i to 0.
  until i = (firesupresslist:length - 1) { 
    firesupresslist[i]:getmodule("ModuleEnginesFX"):doevent("activate engine"). 
    set i to i+1.
  }

  wait 2.
  brakes on.
  rcs on.
  set tarerror to 10.
  set sstatus to "Coast, grid fins are enabled, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 0.1.
  lock steering to heading(232,90).
  set now1 to time:seconds + 10.
  until time:seconds > now1 {
    printing().
    update().
  }

  ship:partstagged("ringdec")[0]:getmodule("ModuleDecouple"):doevent("decouple").  /// hotstage ring decoupler
  set sstatus to "Hot-Stage ring separation, AG9 for catch abort T+ " + round(t,1) + " Seconds".
  set ship:control:fore to -1.
  wait 0.5.
  set ship:control:fore to 0.
  if ship:liquidfuel > 3100 {
    fte[0]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    fte[1]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    set sstatus to "Draining fuel, T+ " + round(t,1) + " Seconds".
  }

}


function entry {
  when ship:verticalspeed <= 0 then {
    set sstatus to "Superheavy has reached apoapsis, T+ " + round(t,1) + " Seconds".
  }

  when ship:liquidfuel < 3100 and altit > 25000 then {
    fte[0]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    fte[1]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    print "Fuel is drained, activating landing tank".
    set rb2:enabled to true.
    set rb3:enabled to true.
    wait 1.
  }
  
  until vang(up:vector, ship:facing:vector) < 3 and ship:verticalspeed < -20 {
    printing().
    update().
  }

  set sstatus to "Superheavy has reached apoapsis, orienting retrograde, T+ " + round(t,1) + " Seconds".
  lock steering to lookdirup(-ship:velocity:surface, targetheading).
  until altit < 30000 {
    printing().
    update().
  }

  set sstatus to "Controlled descent, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 5.
  set aoa to -7.  /// with FAR all my crafts started working better with negative aoa for aerodynamic descent for some reason
  lock steering to Steer().
  set plannedengnum to 13.
  set landingburncalculated to 1.
  set targetaltit to targetaltit + engswitchalt.
  landingburncalc(engnumcheck(), plannedengnum).
  until altit < LBAlt+abs(verticalspeed) and altit < 3000 {
    printing().
    update().
    landingburncalc(currentengnum, plannedengnum).
  }
}


function landing {
  set steeringManager:maxstoppingtime to 1.
  set tarerror to 0.
  set landingburn to 1.
  set plannedengnum to 5.
  lock steering to Steer().
  set ship:partstagged("Vector0")[0]:thrustlimit to 1.
  set ship:partstagged("Vector1")[0]:thrustlimit to 1.
  set ship:partstagged("Vector2")[0]:thrustlimit to 1.
  lock throttle to thrott.
  set ign to 1.
  boosterengines().
  landingburncalc(engnumcheck(), plannedengnum).
  print "Superheavy Landing Burn has started.".
  until verticalspeed > TargetVelocityPlanned-10 and altit < 100 {
    printing().
    update().
    landingburncalc(engnumcheck(), plannedengnum).
  }

  set targetaltit to targetaltit - engswitchalt.
  set ign to 0.
  boosterengines().
  set sstatus to "Five engines switch, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 0.15.
  until impactTime <= 3 and altit < 100 {
    printing().
    update().
    landingburncalc(engnumcheck(), plannedengnum).
  }

  if Catch = true {
    vessel("Ship 31 + Booster 13 Base"):connection:sendmessage(Catch).  /// sending OLM catch command
    set sstatus to "Chopstick are closing, T+ " + round(t,1) + " Seconds".
  }

  until verticalspeed > -1.5 or ship:status = "Landed" or ship:status = "Splashed" {  
    printing().
    update().
    landingburncalc(engnumcheck(), plannedengnum).
  }

  print "Error(M): " + errorVector():mag.
  lock steering to lookdirUp(up:vector,targetheading).
  set ign to 0.
  set landingburncalculated to 0.
  lock throttle to 0.75.
  boosterengines().
  set t to t.
  unlock steering.
  set sstatus to "Landing confirmed, T+ " + round(t,1) + " Seconds".
  if Catch = true {
    vessel("Ship 31 + Booster 13 Base"):connection:sendmessage("Deluge off").
  }

  print sstatus.
  wait 3.
  lock throttle to 0.
  for eng in engList { eng:shutdown. }
  for eng in engList { set eng:thrustlimit to 100. }
  print "Superheavy, landing confirmed, getting ready for post landing procedures, draining fuel, T+ " + round(t,1) + " Seconds".
  fte[0]:getmodule("ModuleResourceDrain"):doaction("drain",true).
  fte[1]:getmodule("ModuleResourceDrain"):doaction("drain",true).
  when ship:liquidfuel < 1 then {
    fte[0]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    fte[1]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    print "Fuel is drained".
    wait 1.
  }

  set sstatus to "Shutting down all systems, unlocking controls, T+ " + round(t,1) + " Seconds".
  print sstatus.
  unlock throttle.
  sas off.
  rcs off.
  brakes off.
}
  

function abortofscript {
  clearscreen.
  print "Program aborted".
  shutdown.
}


function update {
  set t to time:seconds - n.
  set myvel to ship:velocity:surface.
  set altit to alt:radar - h - targetaltit.  
}

function printing {
  clearscreen.
  print "Welcome to Superheavy Landing Software".
  print "Status: " + sstatus.
  print "Catch True/False: " + Catch.
  print "T+ since start of script to landing: " + round(t,1) + " Seconds".
  print "Error(M): " + round(errorVector():mag,1).
  print "One engine thrust: "  + round(activeengine(),2) + " kN".
  print "Possible thrust: "  + round(currentengnum*activeengine(),1) + " kN".
  print "Overshoot(M): " + round(tarerror,1).
  print "OvershootError(M) " + round(overshootTargetError():mag,1).
  if landingburncalculated = 1 {
    print "Landing Burn Altitude: " + round(LBAlt,1) + " Meters".
    print "Altitude: " + round(altit, 1) + " Meters".
    print "Angle to target steering: " + round(steeringManager:angleerror,2) + " Degrees".
    print "AoA: " + round(aoa,2) + " Degrees".
    print "Target velocity: " + round(TargetVelocity, 2) + " M/S".
    print "Target velocity Planned: " + round(TargetVelocityPlanned, 2) + " M/S".
    print "Drag Acceleration: " + round(dragAccel,2) + " M/S^2".
    print "MaxAccelCurrent: " + round(maxAccelcurrent, 2) + "M/S^2".
    print "MaxAccelPlanned: " + round(maxAccelplanned, 2) + "M/S^2".
    print "HoverThr: " + round(hoverThr,2).
    print "PidThr: " + round(thrott,2).
  }

  print "Press 10 to abort current program".
}


function landingburncalc {
  parameter currentengnum, plannedengnum.
  if verticalspeed > -250 {
    set dragAccel to 0.
  } else {
    set dragAccel to (max(0, vdot(up:vector, FAR:aeroforce)) / ship:mass).
  }

  set maxAccelcurrent to max(grav+0.1,(currentengnum*activeengine()) / ship:mass)*max(0.1,cos(vang(facing:vector,up:vector))) + (dragAccel*dragCoef) - grav.
  set maxAccelplanned to max(grav+0.1,(plannedengnum*activeengine()) / ship:mass) + (dragAccel*dragCoef) - grav.	
  set LBAlt to ship:verticalspeed^2 / (2 * maxAccelplanned).		
  set hoverThr to grav * ship:mass / (currentengnum*activeengine()).	

  set TargetAccelCurrent to maxAccelcurrent * AccelCoef.
  set TargetVelocityCurrent to -sqrt(2*max(0.01,TargetAccelCurrent)*(max(0.01, altit))).

  set TargetAccelPlanned to maxAccelplanned * AccelCoef.
  set TargetVelocityPlanned to -sqrt(2*max(0.01,TargetAccelPlanned)*(max(0.01, altit))).
  set TargetVelocity to TargetVelocityCurrent.

  set impactTime to (-verticalSpeed + sqrt(max(0.1,verticalSpeed^2-2*maxAccelcurrent*altit)))/max(0.01,maxAccelcurrent).
  set P to min(2, max(0.25, abs(verticalSpeed/TargetVelocityCurrent))).
  set throttpid:kp to P.
  set throttpid:setpoint to TargetVelocity.
  set thrott to throttpid:update(time:seconds, ship:verticalspeed)+hoverThr.

  if landingburn = 1 {
    if currentengnum <= 5 {
      set maxAoA to min(15, altit/2.5). 
      set aoa to -min(maxAoA, errorVector():mag/1).
    } else {
      set maxAoa to min(20,errorVector():mag/9).
      set aoa to -min(maxAoA, errorVector():mag/6).
    }
  }
}


function errorVector {
 return (getImpact():position+getImpact():position:normalized*targetaltit) - (landingZone:position+landingZone:position:normalized*targetaltit).
}

function Steer {
  if velocity:surface:mag < 60 {
    set errorVec to errorVector().
    local result is up:vector + errorVec*errorScalling.

    if vang(result, up:vector) > aoa
    {
      set result to up:vector:normalized + tan(aoa)*errorVec:normalized.
    }

    return lookdirup(result, targetheading).
  } else {
    set errorVec to overshootTargetError().
    local velVector is -ship:velocity:surface.
    local result is velVector + errorVec*errorScalling.

    if vang(result, velVector) > aoa
    {
      set result to velVector:normalized + tan(aoa)*errorVec:normalized.
    }

    return lookdirup(result, targetheading).
  }
  
}

function getImpact {
  if addons:tr:hasimpact { 
    return addons:tr:impactpos.
  } else {
    if gm = 1 {
      local localTime is time:seconds.
      local impactData is impact_UTs().
      local impactLatLng is ground_track(POSITIONAT(SHIP,impactData["time"]),impactData["time"]).
      local oldTime is localTime.
      return impactLatLng.
    }
  }
}


function impact_UTs {
	parameter minError is 1.
	if not (defined impact_UTs_impactHeight) { global impact_UTs_impactHeight is 0. }
	local startTime is TIME:SECONDS.
	local craftOrbit is SHIP:ORBIT.
	local sma is craftOrbit:SEMIMAJORAXIS.
	local ecc is craftOrbit:ECCENTRICITY.
	local craftTA is craftOrbit:TRUEANOMALY.
	local orbitPeriod is craftOrbit:PERIOD.
	local ap is craftOrbit:APOAPSIS.
	local pe is craftOrbit:PERIAPSIS.
	local impactUTs is time_betwene_two_ta(ecc,orbitPeriod,craftTA,alt_to_ta(sma,ecc,SHIP:BODY,MAX(MIN(impact_UTs_impactHeight,ap - 1),pe + 1))[1]) + startTime.
	local newImpactHeight is ground_track(POSITIONAT(SHIP,impactUTs),impactUTs):TERRAINHEIGHT.
	set impact_UTs_impactHeight to (impact_UTs_impactHeight + newImpactHeight) / 2.
	return lex("time",impactUTs,
	"impactHeight",impact_UTs_impactHeight,
	"converged",((abs(impact_UTs_impactHeight - newImpactHeight) * 2) < minError)).
}

function alt_to_ta {
	parameter sma,ecc,bodyIn,altIn.
	local rad is altIn + bodyIn:RADIUS.
	local taOfAlt is arccos((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	return list(taOfAlt,360-taOfAlt).
}

function time_betwene_two_ta {
	parameter ecc,periodIn,taDeg1,taDeg2.
	
	local maDeg1 is ta_to_ma(ecc,taDeg1).
	LOCAL maDeg2 is ta_to_ma(ecc,taDeg2).
	
	local timeDiff is periodIn * ((maDeg2 - maDeg1) / 360).
	
	return mod(timeDiff + periodIn, periodIn).
}

function ta_to_ma {
	parameter ecc,taDeg.
	local eaDeg is arctan2(sqrt(1-ecc^2) * sin(taDeg), ecc + cos(taDeg)).
	local maDeg is eaDeg - (ecc * sin(eaDeg) * constant:RADtoDEG).
	return mod(maDeg + 360,360).
}

function ground_track {	 
	PARAMETER pos,posTime,localBody IS SHIP:BODY.
	LOCAL bodyNorth IS v(0,1,0).
	LOCAL rotationalDir IS VDOT(bodyNorth,localBody:ANGULARVEL) * CONSTANT:RADTODEG. 
	LOCAL posLATLNG IS localBody:GEOPOSITIONOF(pos).
	LOCAL timeDif IS posTime - TIME:SECONDS.
	LOCAL longitudeShift IS rotationalDir * timeDif.
	LOCAL newLNG IS MOD(posLATLNG:LNG + longitudeShift,360).
	IF newLNG < - 180 { SET newLNG TO newLNG + 360. }
	IF newLNG > 180 { SET newLNG TO newLNG - 360. }
	RETURN LATLNG(posLATLNG:LAT,newLNG).
}