clearscreen.
settings().
boostback().
entry().
landing().


function settings {
  unlock all.
  set ship:control:pilotmainthrottle to 0.
  set errorScalling to 1.
  set landingZone to latlng(-6.5, -83.7).
  set altit to ship:altitude - 38.
  set lngoff to (landingZone:lng - addons:tr:impactpos:lng)*10472.
  set latoff to (landingZone:lat - addons:tr:impactpos:lat)*10472.
  set grav to body:mu / body:radius^2.
  set error to errorVector:mag.
  set fte to ship:partstagged("fte")[0].
  set bt to ship:partsdubbed("bts")[0].
  set rb1 to bt:resources.
  set rb2 to rb1[0].
  set rb3 to rb1[1].
  set rb2:enabled to false.
  set rb3:enabled to false.
  set engnum to 13.
  set engList to list().
  set i to -1.
  until i >= 32 {
      set i to i + 1.
      engList:add(ship:partstagged("Vector" + i)[0]).
  }

  sas off.
  rcs on.
}


function boostback {
  set n to time:seconds.
  set t to time:seconds - n.
  set sstatus to "Boostback burn starting, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 0.8.
  set steeringManager:yawts to 2.
  set steeringManager:pitchts to 2.
  lock steering to -vxcl(up:vector, errorVector).
  lock throttle to 0.2.
  set now1 to time:seconds.
  lock ti to time:seconds - now1.
  until ti > 4 {
    printing().
  }

  lock throttle to min(1, max(0.2,(ti-4)/3)).
  set ship:partstagged("Vector0")[0]:thrustlimit to 100.
  set ship:partstagged("Vector1")[0]:thrustlimit to 100.
  set ship:partstagged("Vector2")[0]:thrustlimit to 100.
  ship:partstagged("Vector6")[0]:activate.
  ship:partstagged("Vector11")[0]:activate.
  until ti > 4.2 {
    printing().
  }

  ship:partstagged("Vector5")[0]:activate.
  ship:partstagged("Vector10")[0]:activate.
  until ti > 4.4 {
    printing().
  }

  ship:partstagged("Vector8")[0]:activate.
  ship:partstagged("Vector3")[0]:activate.
  until ti > 4.6 {
    printing().
  }

  ship:partstagged("Vector4")[0]:activate.
  ship:partstagged("Vector9")[0]:activate.
  until ti > 4.8 {
    printing().
  }

  ship:partstagged("Vector7")[0]:activate.
  ship:partstagged("Vector12")[0]:activate.
  set sstatus to "Superheavy boostback burn has started, T+ " + round(t,1) + " Seconds".
  until abs(error) < 15000 {
    printing().
  }

  set sstatus to "Boostback burn is ending".
  ship:partstagged("Vector4")[0]:shutdown.
  ship:partstagged("Vector6")[0]:shutdown.
  ship:partstagged("Vector8")[0]:shutdown.
  ship:partstagged("Vector10")[0]:shutdown.
  ship:partstagged("Vector12")[0]:shutdown.
  wait 0.1.
  ship:partstagged("Vector3")[0]:shutdown.
  ship:partstagged("Vector5")[0]:shutdown.
  ship:partstagged("Vector7")[0]:shutdown.
  ship:partstagged("Vector9")[0]:shutdown.
  ship:partstagged("Vector11")[0]:shutdown.
  until abs(error) < 1500 {
    printing().
  }

  lock throttle to 0.4.
  until abs(error) < 100 {
    printing().
  }

  set sstatus to "Boostback burn shutdown, T+ " + round(t,1) + " Seconds".
  lock throttle to 0.
  unlock steering.
  set ringdec to time:seconds + 10.
  wait 2.
  toggle brakes.
  unlock throttle.
  ag6 off.
  rcs on.
  set sstatus to "Coast, grid fins are enabled, draining fuel T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 0.06.
  lock steering to heading(270,90).
  if ship:liquidfuel > 2000 and altit > 25000 {
    fte:getmodule("ModuleResourceDrain"):doaction("drain",true).
  }

  set now1 to time:seconds + 10.
  until time:seconds > now1 {
    printing().
  }

  ship:partstagged("ringdec")[0]:getmodule("ModuleDecouple"):doevent("decouple").
  set sstatus to "Hot-Stage ring separation T+ " + round(t,1) + " Seconds".
  wait 0.01.
  set steeringManager:maxstoppingtime to 0.06.
  set ship:control:fore to -0.05.
  lock steering to heading(270,90).
  wait 2.
  set steeringManager:maxstoppingtime to 0.06.
  set steeringManager:yawts to 1.
  set steeringManager:pitchts to 1.
  lock steering to heading(270,90).
}


function entry {
  when ship:verticalspeed <= 0 then {
    set sstatus to "Superheavy has reached apoapsis, T+ " + round(t,1) + " Seconds".
  }

  when ship:liquidfuel < 2000 and altit > 25000 then {
    fte:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    print "Fuel is drained, activating landing tank".
    ag6 on.
    set rb2:enabled to true.
    set rb3:enabled to true.
    wait 1.
  }
  
  until vang(up:vector, ship:facing:vector) < 3 and ship:verticalspeed < -20 {
    printing().
  }

  set sstatus to "Superheavy has reached apoapsis, orienting retrograde, T+ " + round(t,1) + " Seconds".
  lock steering to srfretrograde.
  until altit < 40000 {
    printing().
  }

  set sstatus to "Controlled descent, T+ " + round(t,1) + " Seconds".
  set steeringManager:maxstoppingtime to 5.
  set steeringManager:yawts to 1.
  set steeringManager:pitchts to 1.
  set aoa to 45.
  lock steering to Steer().
  set engnum to 12.
  until altit < lbcalc(engnum)+300 and altit < 3000 {
    printing().
    lbcalc(engnum).
    thrustcalc().
    Steer().
    if abs(error) < 200 and altit > 3000 {
      set aoa to 15.
    } else {
      set aoa to 45.
    }
    wait 0.
  }

}


function landing {
  set now1 to time:seconds.
  lock ti1 to time:seconds - now1.
  lock throttle to min(1, ti1/1).
  lock steering to Steer().
  set aoa to -3.
  print "Superheavy Landing Burn has started.".
  set now1 to time:seconds.
  lock ti1 to time:seconds - now1.
  until ti1 > 0.2 {
    printing().
    thrustcalc().
  }

  ship:partstagged("Vector4")[0]:activate.
  until ti1 > 0.4 {
    printing().
    thrustcalc().
  }

  ship:partstagged("Vector6")[0]:activate.
  ship:partstagged("Vector10")[0]:activate.
  ship:partstagged("Vector12")[0]:activate.
  until ti1 > 0.6 {
    printing().
    thrustcalc().
  }

  ship:partstagged("Vector3")[0]:activate.
  ship:partstagged("Vector7")[0]:activate.
  until ti1 > 0.8 {
    printing().
    thrustcalc().
  }

  ship:partstagged("Vector5")[0]:activate.
  ship:partstagged("Vector9")[0]:activate.
  ship:partstagged("Vector11")[0]:activate.
  set engnum to 5.
  lbcalc(engnum).
  thrustcalc().
  lock throttle to 1.
  until altit < lbcalc(engnum) + 30 and altit > lbcalc(engnum) - 30 {
    printing().
    lbcalc(engnum).
    thrustcalc().
    Steer().
  }

  ship:partstagged("Vector3")[0]:shutdown.
  ship:partstagged("Vector5")[0]:shutdown.
  ship:partstagged("Vector6")[0]:shutdown.
  ship:partstagged("Vector7")[0]:shutdown.
  ship:partstagged("Vector8")[0]:shutdown.
  ship:partstagged("Vector10")[0]:shutdown.
  ship:partstagged("Vector11")[0]:shutdown.
  ship:partstagged("Vector12")[0]:shutdown.
  lock throttle to abs(Thr2).
  set aoa to -1.
  until altit < 60 {
    printing().
    lbcalc(engnum).
    thrustcalc().
    Steer().
  }

  set sstatus to "Landing burn, orienting retrograde, T+ " + round(t,1) + " Seconds".
  lock steering to lookdirup(-ship:velocity:surface,ship:facing:topvector).
  until vang(up:vector, -ship:velocity:surface)<2 {
    printing().
    lbcalc(engnum).
    thrustcalc().
  }

  set sstatus to "Landing burn, orienting up, T+ " + round(t,1) + " Seconds".
  lock steering to lookdirup(up:vector,ship:facing:topvector).
  until ship:verticalspeed > -1 and ship:verticalspeed < 1 {
    printing().
    lbcalc(engnum).
    thrustcalc().
  }

  set sstatus to "Touchdown, T+ " + round(t,1) + " Seconds".
  set thrott to throttle.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  lock throttle to max(0.05, thrott-ti1).
  print "Lngoff(M):  " + lngoff.
  print "Latoff(M): " + latoff.
  print "Error(M): " + error.
  until ship:status = "Landed" or ship:status = "Splashed" {
    printing().
    thrustcalc().
  }

  set t to t.
  unlock steering.
  set sstatus to "Landing confirmed, T+ " + round(t,1) + " Seconds".
  print sstatus.
  lock throttle to 0.05.
  wait 1.
  lock throttle to 0.
  print "Superheavy, landing confirmed, getting ready for post landing procedures, T+ " + round(t,1) + " Seconds".
  set now1 to time:seconds.
  lock ti to time:seconds - now1.
  until ti > 20 {
    printing().
  }

  set sstatus to "Shutting down all systems, unlocking controls, T+ " + round(t,1) + " Seconds".
  print sstatus.
  unlock throttle.
  sas off.
  rcs off.
  toggle brakes.
}
  

function abortofscript {
  clearscreen.
  print "Program aborted".
  wait 2.
  print 3/0.
}


function printing {
  clearscreen.
  set t to time:seconds - n.
  set myvel to ship:velocity:surface.
  set altit to ship:altitude - 37.
  set lngoff to (landingZone:lng - getImpact:lng)*10472.
  set latoff to (landingZone:lat - getImpact:lat)*10472.
  set error to errorVector:mag.
  print "Welcome to Superheavy Landing Software".
  print "Status: " + sstatus.
  print "T+ since start of script to landing: " + round(t,1) + " Seconds".
  print "Error(M): " + error.
  print "Latoff(M): " + latoff.
  print "Lngoff(M): " + lngoff.
  print "Landing burn altitude: " + LBCalc(engnum) + " Meters".
  print "Possible thrust: "  + engnum*ship:partstagged("Vector0")[0]:possiblethrust + " kN".
  print "Press 10 to abort current program".
}


function LBCalc {
  parameter engnum.
  set maxAccel to (engnum*ship:partstagged("Vector0")[0]:possiblethrust / ship:mass) - grav.	
  set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).		
  return LBAlt.
}


function thrustcalc {
  set Thr1 to (LBcalc(engnum)+100) / altit.
  set Thr2 to LBcalc(engnum) / altit.
  return Thr1 and Thr2.
}

function errorVector {
 return getImpact():position - landingZone:position.
}

function Steer {
 local errorVector is errorVector().
 local velVector is -ship:velocity:surface.
 local result is velVector + errorVector*errorScalling.

 if vang(result, velVector) > aoa
 {
   set result to velVector:normalized + tan(aoa)*errorVector:normalized.
 }

 return lookdirup(result, ship:facing:topvector).
}

function getImpact {
  if addons:tr:hasimpact { 
    return addons:tr:impactpos.
  } else {
    return ship:geoposition.
  }
}