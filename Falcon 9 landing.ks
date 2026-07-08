clearscreen.
settings().
boostback().
coast().
entry().
landing().


function settings {
  unlock all.
  set ship:control:pilotmainthrottle to 0.
  set preset to "BFT". // Your preset where to land
  if preset = "LZ-1" {
    set landingZone to latlng(-0.195523668957612,-74.4851660606608).
  } else if preset = "LZ-2" {
    set landingZone to latlng(-0.205430319,-74.47302929).
  } else if preset = "LZ-4" {
    set landingZone to latlng(-0.556128,-88.461235).
  } else if preset = "BFT" {
    set landingZone to vessel("Big Floating Thing"):geoposition.
  } else if preset = "MMWAM" {
    set landingZone to vessel("My Mum Wonders About Me"):geoposition.
  } else if preset = "LIOP" {
    set landingZone to vessel("Land In One Piece"):geoposition.
  }

  if preset = "LZ-1" or preset = "LZ-2" or preset = "LZ-4" {
    lock altit to alt:radar - 22.4.
  } else {
    lock altit to altitude - 22.6.
  }

  set engnum to 3.
  LBCalc().
  set entryburnalt to 34000.
  set entryburnmode to 3.
  set speedcancelonentry to 270.
  set landingburncalc to 0.
  set boostbackcalc to 1.
  set lngoff to (landingZone:lng - addons:tr:impactpos:lng)*10472.
  set latoff to (landingZone:lat - addons:tr:impactpos:lat)*10472.
  set myvel to ship:velocity:surface.
  set grav to constant:g * body:mass / body:radius^2.
  set maxAccel to (shippossiblethr / ship:mass) - grav.	
  set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).		
  set Thr to LBAlt / altit.	
  set tarerror to vxcl(up:vector, ship:velocity:surface):mag*(abs((ship:position-landingZone:position):mag)/20000). // overshoot distance calculation based on horizontalspeed and distance to the landing zone
  sas off.
  rcs on.
}

function overshootTargetError {
  if vang(vxcl(up:vector, errorVector), vxcl(up:vector, ship:velocity:surface)) > 90 {  // checks for whether landing zone is behind or at the side of the vehicle to overshoot correctly
    set overshootTarget to landingZone:position-vxcl(up:vector,-ship:velocity:surface):normalized*tarerror.
  } else {
    set overshootTarget to landingZone:position+vxcl(up:vector,ship:velocity:surface):normalized*tarerror.
  }

  return getImpact():position - overshootTarget.
}

function boostback {
  set n to time:seconds.
  set t to time:seconds - n.
  set sstatus to "Boostback burn starting, T+ " + round(t,1) + " Seconds".
  toggle ag7. //Turn off all engines, but left the center
  toggle ag6. //Turn on two aditional engines
  set steeringManager:maxstoppingtime to 0.3.
  set steeringManager:torqueepsilonmin to 0.01.
  set steeringManager:torqueepsilonmax to 0.02.
  set steeringManager:pitchtorquefactor to 0.7.
  set steeringManager:yawtorquefactor to 0.7.
  set steeringManager:rolltorquefactor to 0.3.
  lock steering to -vxcl(up:vector, overshootTargetError).
  lock throttle to 0.2.
  set ti to time:seconds + 6.
  until time:seconds > ti {
    printing().
  }

  lock throttle to 1.
  set sstatus to "Boostback burn has started, T+ " + round(t,1) + " Seconds".
  until abs(overshootTargetError:mag) < 4000 {
    printing().
  }

  set sstatus to "Boostback burn is ending, two side engines cutoff".
  toggle ag6.
  set oldshoot to overshootTargetError:mag.
  wait 0.1.
  set newshoot to overshootTargetError:mag.
  until newshoot > oldshoot {
    set oldshoot to overshootTargetError:mag.
    wait 0.1.
    set newshoot to overshootTargetError:mag.
    printing().
  }

  set sstatus to "Boostback burn shutdown, T+ " + round(t,1) + " Seconds".
  lock throttle to 0.
  set boostbackcalc to 0.
  lock steering to facing:vector.
  wait 2.
  toggle brakes.
  unlock steering.
  unlock throttle.
  set sstatus to "Coast, grid fins deployed, T+ " + round(t,1) + " Seconds".
}


function coast {
  when ship:verticalspeed <= 0 then {
    set sstatus to "First stage has reached apoapsis, T+ " + round(t,1) + " Seconds".
  }

  set steeringManager:pitchtorquefactor to 0.08.
  set steeringManager:yawtorquefactor to 0.08.
  set steeringManager:rolltorquefactor to 0.1.
  lock steering to heading(270,90). 
  until vang(up:vector, ship:facing:vector) < 3 and ship:verticalspeed < -20 {
    printing().
  }

  set sstatus to "First stage has reached apoapsis, orienting for entry burn, T+ " + round(t,1) + " Seconds".
  lock steering to srfretrograde.
}


function entry {
  until altit < entryburnalt + 6000 {
    printing().
  }

  set sstatus to "Using RCS to push fuel down to the engines, 7km till entry burn, T+ " + round(t,1) + " Seconds".
  set ship:control:fore to 1.
  set ti to time:seconds + 2.
  until time:seconds > ti {
    printing().
  }

  set sstatus to "Awaiting for entry burn, T+ " + round(t,1) + " Seconds".
  set ship:control:fore to 0.
  set steeringManager:pitchtorquefactor to 7.
  set steeringManager:yawtorquefactor to 7.
  set steeringManager:rolltorquefactor to 1.
  set steeringManager:maxstoppingtime to 1.
  until altit < entryburnalt {
    set aoa to max(-10, -(errorVector():mag/100)).
    printing().
    Steer().
  }

  set sstatus to "Entry burn starting, one engine, T+ " + round(t,1) + " Seconds".
  lock steering to Steer().
  lock throttle to 1.
  set targetspeedonentry to myvel:mag - speedcancelonentry.
  if entryburnmode = 1 {
    until myvel:mag < targetspeedonentry {
      printing().
      set aoa to max(-15, -(errorVector():mag/100)).
    }

  } else {
    wait 2.
    toggle ag6.
    set sstatus to "Entry burn starting, three engines lit, T+ " + round(t,1) + " Seconds".
    until myvel:mag < targetspeedonentry {
      printing().
      set aoa to max(-15, -(errorVector():mag/100)).
    }

    toggle ag6.
    wait 2.
  }

  set sstatus to "Entry burn shutdown, T+ " + round(t,1) + " Seconds".
  print sstatus.
  lock throttle to 0.
  wait 0.1.
  toggle ag6.
  set sstatus to "Controlled descent".
  set aoa to max(10,min(45, errorVector():mag/15)).
  set engnum to 3.
  set landingburncalc to 1.
  lbcalc().
  until altit < LBAlt and altit < 3000 {
    printing().
    lbcalc().
  }
}


function landing {
  set sstatus to "Landing burn has started, T+ " + round(t,1) + " Seconds".
  toggle ag6.
  lock steering to srfRetrograde.
  wait 0.3.
  lock throttle to Thr.
  wait 1.
  toggle ag6.
  wait 0.01.
  until -ship:velocity:surface:mag > -100 {
    printing().
    lbcalc().
  }

  lock steering to Steer().
  until altit < 250 {
    printing().
    lbcalc().
    set aoa to max(-25, -(errorVector():mag/2)).
  }

  until altit < 100 {
    printing().
    lbcalc().
    set aoa to max(-7, -(errorVector():mag/2)).
  }
      
  toggle gear.
  set steeringManager:maxstoppingtime to 3.
  set sstatus to "Landing burn, landing legs are deploying, T+ " + round(t,1) + " Seconds".
  until altit < 70 {
    printing().
    lbcalc().
  }

  lock steering to lookdirup(-ship:velocity:surface,ship:facing:topvector).
  set sstatus to "Landing burn, orienting retrograde, T+ " + round(t,1) + " Seconds".
  until ship:verticalspeed > -1 and ship:verticalspeed < 1 {
    printing().
    lbcalc().
  }

  set sstatus to "Touchdown, T+ " + round(t,1) + " Seconds".
  set lngoff to (landingZone:lng - geoposition:lng)*10472. 
  set latoff to (landingZone:lat - geoposition:lat)*10472. 
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  set topVec to ship:facing:topvector.
  lock steering to lookDirUp(up:vector, topVec).
  lock throttle to max(0.05, 0.5-ti1).
  until ship:status = "Landed" or ship:status = "Splashed" {
    printing().
    lbcalc().
  }

  set t to t.
  set sstatus to "Landing confirmed, T+ " + round(t,1) + " Seconds".
  lock throttle to 0.05.
  wait 1.
  lock throttle to 0.
  print preset + ", landing confirmed, getting ready for post landing procedures, T+ " + round(t,1) + " Seconds".
  set now1 to time:seconds.
  lock ti to time:seconds - now1.
  wait 1.
  unlock steering.
  until ti > 20 {
    printing().
  }

  set sstatus to "Shutting down all systems, unlocking controls, T+ " + round(t,1) + " Seconds".
  print sstatus.
  unlock steering.
  unlock throttle.
  sas off.
  rcs off.
  toggle brakes.
}


function abortofscript {
  clearscreen.
  print "Program aborted".
  shutdown.
}


function printing {
  clearscreen.
  set t to time:seconds - n.
  set myvel to ship:velocity:surface.
  print "Welcome to Falcon 9 Landing Software".
  print "Your preset is " +  preset.
  print "Status: " + sstatus.
  print "T+ since start of script to landing: " + round(t,1) + " Seconds".
  print "Entry burn altitude: " + entryburnalt + " Meters".
  print "Error(M): " + round(errorVector:mag,1).
  if boostbackcalc = 1 {
    print "Overshoot(M): " + round(tarerror,1).
    print "OvershootError(M) " + round(overshootTargetError:mag,1).
  }

  if landingburncalc = 1 {
    print "Landing Burn Altitude : " + round(LBAlt,1) + " Meters".
    print "Ship possible thrust: "  + round(shippossiblethr,1) + " kN".
  }

  print "Press 10 to abort current program".
}

function LBCalc {
  list engines in engList.
  set engpossibleThrust to engList[0]:possiblethrust.
  for e in engList {
    if e:possiblethrust > engpossibleThrust {
      set engpossibleThrust to e:possiblethrust.
    }
  }

  set grav to constant:g * body:mass / body:radius^2.
  set shippossiblethr to engpossibleThrust*engnum.
  set maxAccel to (shippossiblethr / ship:mass) - grav.	
  set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).		
  set ImpactTime to altit / abs(ship:verticalspeed).
  set Thr to LBAlt / altit.
}

function errorVector {
 return getImpact():position - landingZone:position.
}

function Steer {
 set result to -velocity:surface + errorVector().
 if vang(result, -velocity:surface) > aoa
 {
   set result to -velocity:surface:normalized + tan(aoa)*errorVector():normalized.
 }

 if errorVector():mag < 20 {
      set result to -velocity:surface.
  }

 return lookdirup(result, up:vector).
}

function getImpact {
  if addons:tr:hasimpact { 
    return addons:tr:impactpos.
  } else {
    return ship:geoposition.
  }
}
