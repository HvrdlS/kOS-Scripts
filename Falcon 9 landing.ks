clearscreen.
settings().
boostback().
coast().
entry().
landing().

on ag10 {
  abortofscript().
}


function settings {
  unlock all.
  set ship:control:pilotmainthrottle to 0.
  set preset to "LZ-1". // Your preset where to land
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
  set grav to body:mu / body:radius^2.
  set gm to 1.
  set oldTime to time:seconds.
  LBCalc().
  set entryburnalt to 35000.
  set entryburnmode to 3.
  set speedcancelonentry to 200.
  set boostbackcalc to 0.
  set landingburncalc to 0.
  set myvel to ship:velocity:surface.
  set targetaltit to 0.7. /// target altitude
  set P to 1.
  set I to 0.01.
  set D to 0.01.
  set throttpid to pidloop(P,I,D,-1, 1).
  lock tarerror to vxcl(up:vector, ship:velocity:surface):mag*(abs((ship:position-landingZone:position):mag)/15000).
  rcs on.
}

function overshootTargetError {
  set overshootTarget to landingZone:position+vxcl(up:vector,ship:velocity:surface):normalized*tarerror.
  return getImpact():position - overshootTarget.
}

function boostback {
  set n to time:seconds.
  set t to time:seconds - n.
  set sstatus to "Boostback burn starting, T+ " + round(t,1) + " Seconds".
  if ag6 = false {
    toggle ag7. //Turn off all engines, but left the center
    toggle ag6. //Turn on two aditional engines
  }
  
  set steeringManager:maxstoppingtime to 0.2.
  set steeringManager:torqueepsilonmin to 0.01.
  set steeringManager:torqueepsilonmax to 0.02.
  lock steering to -vxcl(up:vector, overshootTargetError()).
  lock throttle to 0.2.
  set boostbackcalc to 1.
  until vang(facing:vector, -vxcl(up:vector, overshootTargetError()))<10 {
    printing().
    overshootTargetError().
  }

  lock throttle to 1.
  set sstatus to "Boostback burn has started, T+ " + round(t,1) + " Seconds".
  until abs(overshootTargetError():mag) < 4000 {
    printing().
    overshootTargetError().
  }

  set sstatus to "Boostback burn is ending, two side engines cutoff".
  toggle ag6.
  set olderror to overshootTargetError():mag.
  wait 0.1.
  set newerror to overshootTargetError():mag.
  until newerror > olderror {
    set olderror to overshootTargetError():mag.
    wait 0.1.
    set newerror to overshootTargetError():mag.
    printing().
  }

  set sstatus to "Boostback burn shutdown, T+ " + round(t,1) + " Seconds".
  lock throttle to 0.
  set boostbackcalc to 0.
  lock steering to facing:vector.
  wait 2.
  toggle brakes.
  set sstatus to "Coast, grid fins deployed, T+ " + round(t,1) + " Seconds".
}


function coast {
  when ship:verticalspeed <= 0 then {
    set sstatus to "First stage has reached apoapsis, T+ " + round(t,1) + " Seconds".
  }

  set steeringManager:maxstoppingtime to 0.03.
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

  set sstatus to "Using RCS to push fuel down to the engines, 6km till entry burn, T+ " + round(t,1) + " Seconds".
  set ship:control:fore to 1.
  set ti to time:seconds + 2.
  until time:seconds > ti {
    printing().
  }

  set sstatus to "Awaiting for entry burn, T+ " + round(t,1) + " Seconds".
  set ship:control:fore to 0.
  set steeringManager:maxstoppingtime to 5.
  lock aoa to max(-15, -(errorVector():mag/speedcancelonentry)).
  until altit < entryburnalt {
    printing().
  }

  set sstatus to "Entry burn starting, one engine, T+ " + round(t,1) + " Seconds".
  lock steering to lookdirup(Steer(), facing:topvector).
  lock throttle to 1.
  set targetspeedonentry to myvel:mag - speedcancelonentry.
  if entryburnmode = 1 {
    until errorVector():mag < 100 or myvel:mag < targetspeedonentry {
      printing().
      if vdot(errorVector(), (landingZone:position-ship:position)) < 0 {
        set aoa to max(-20, -(errorVector():mag/30)).
      }
    }

  } else {
    wait 2.
    toggle ag6.
    set sstatus to "Entry burn starting, three engines lit, T+ " + round(t,1) + " Seconds".
    until errorVector():mag < 100 or myvel:mag < targetspeedonentry {
      printing().
      if vdot(errorVector(), (landingZone:position-ship:position)) < 0 {
        set aoa to max(-15, -(errorVector():mag/20)).
      }
    }

    toggle ag6.
    wait 2.
  }

  set sstatus to "Entry burn shutdown, T+ " + round(t,1) + " Seconds".
  print sstatus.
  lock throttle to 0.
  steeringManager:resettodefault.
  wait 0.1.
  toggle ag6.
  set sstatus to "Controlled descent".
  set aoa to -9.
  set engnum to 3.
  set landingburncalc to 1.
  lbcalc().
  ThrPid().
  lock P to abs(ship:velocity:surface:mag)/TargetVelocity.
  until altit < 3500 and ThrPID()+hoverThr >= 1.1 {
    printing().
    lbcalc().
    ThrPid().
  }
}


function landing {
  set sstatus to "Landing burn has started, T+ " + round(t,1) + " Seconds".
  toggle ag6.
  wait 0.3.
  lock throttle to ThrPid()+hoverThr.
  wait 1.
  toggle ag6.
  wait 0.01.
  until altit < 100 {
    printing().
    lbcalc().
    set maxAoA to min(10, altit/10).
    set aoa to -min(maxAoA, errorVector():mag/2).
  }
      
  toggle gear.
  set topvec to ship:facing:topvector.
  lock steering to lookdirup(-ship:velocity:surface,topvec).
  set sstatus to "Landing burn, landing legs are deploying, T+ " + round(t,1) + " Seconds".
  until altit < 15 {
    printing().
    lbcalc().
  }

  lock steering to lookdirup(up:vector,topvec).
  set sstatus to "Landing burn, orienting retrograde, T+ " + round(t,1) + " Seconds".
  until ship:verticalspeed > -1 and ship:verticalspeed < 1 and altit < 2 {
    printing().
    lbcalc().
  }

  set sstatus to "Touchdown, T+ " + round(t,1) + " Seconds".
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  lock steering to lookdirup(up:vector, ship:facing:topvector).
  lock throttle to max(0.05, 0.5-ti1).
  until ship:status = "Landed" or ship:status = "Splashed" {
    printing().
    lbcalc().
  }

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
  print"Welcome to Falcon 9 Landing Software".
  print "Your preset is " +  preset.
  print "Status: " + sstatus.
  print "T+ since start of script to landing: " + round(t,1) + " Seconds".
  print "Entry burn altitude: " + entryburnalt + " Meters".
  print "Error(M): " + round(errorVector():mag,1).
  if boostbackcalc = 1 {
    print "Overshoot(M): " + round(tarerror,1).
    print "OvershootError(M) " + round(overshootTargetError():mag,1).
  }

  if landingburncalc = 1 {
    print "Landing Burn Altitude: " + round(LBAlt,1) + " Meters".
    print "Ship possible thrust: "  + round(shippossiblethr,1) + " kN".
    print "Angle to target steering: " + round(steeringManager:angleerror,2) + " Degrees".
    print "AoA: " + round(abs(aoa),2) + " Degrees" at (1, 12).
    print "Target velocity: " + round(TargetVelocity, 2) + " M/S".
    print "HoverThr: " + round(hoverThr,2).
    print "PidThr: " + round(ThrPID,2).
  }

  print "Press 10 to abort current program".
}

function ThrPID {
  set TargetVelocity to -sqrt(2*maxAccel*(max(0.01, altit-targetaltit))).
  set throttpid:setpoint to TargetVelocity.
  return throttpid:update(time:seconds, ship:verticalspeed).
}

function LBCalc {
  list engines in engList.
  set engpossibleThrust to engList[0]:possiblethrust.
  if engpossibleThrust = 0 { 
    set maxAccel to 0.01. 
    set hoverThr to grav * ship:mass / shippossiblethr.	
    set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).
  } else {
    for e in engList {
    if e:possiblethrust > engpossibleThrust {
      set engpossibleThrust to e:possiblethrust.
    }

    set shippossiblethr to engpossibleThrust*engnum.
    set maxAccel to (shippossiblethr / ship:mass) - grav.		
    set hoverThr to grav * ship:mass / shippossiblethr.	
    set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).
  }
}

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

 return result.
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



function impact_UTs {//returns the UTs of the ship's impact, NOTE: only works for non hyperbolic orbits
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
	return lex("time",impactUTs,//the UTs of the ship's impact
	"impactHeight",impact_UTs_impactHeight,//the aprox altitude of the ship's impact
	"converged",((abs(impact_UTs_impactHeight - newImpactHeight) * 2) < minError)).//will be true when the change in impactHeight between runs is less than the minError
}

function alt_to_ta {//returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	parameter sma,ecc,bodyIn,altIn.
	local rad is altIn + bodyIn:RADIUS.
	local taOfAlt is arccos((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	return list(taOfAlt,360-taOfAlt).//first true anomaly will be as orbit goes from PE to AP
}

function time_betwene_two_ta {//returns the difference in time between 2 true anomalies, traveling from taDeg1 to taDeg2
	parameter ecc,periodIn,taDeg1,taDeg2.
	
	local maDeg1 is ta_to_ma(ecc,taDeg1).
	LOCAL maDeg2 is ta_to_ma(ecc,taDeg2).
	
	local timeDiff is periodIn * ((maDeg2 - maDeg1) / 360).
	
	return mod(timeDiff + periodIn, periodIn).
}

function ta_to_ma {//converts a true anomaly(degrees) to the mean anomaly (degrees) NOTE: only works for non hyperbolic orbits
	parameter ecc,taDeg.
	local eaDeg is arctan2(sqrt(1-ecc^2) * sin(taDeg), ecc + cos(taDeg)).
	local maDeg is eaDeg - (ecc * sin(eaDeg) * constant:RADtoDEG).
	return mod(maDeg + 360,360).
}

function ground_track {	//returns the geocoordinates of the ship at a given time(UTs) adjusting for planetary rotation over time, only works for non tilted spin on bodies 
	PARAMETER pos,posTime,localBody IS SHIP:BODY.
	LOCAL bodyNorth IS v(0,1,0).//using this instead of localBody:NORTH:VECTOR because in many cases the non hard coded value is incorrect
	LOCAL rotationalDir IS VDOT(bodyNorth,localBody:ANGULARVEL) * CONSTANT:RADTODEG. //the number of degrees the body will rotate in one second
	LOCAL posLATLNG IS localBody:GEOPOSITIONOF(pos).
	LOCAL timeDif IS posTime - TIME:SECONDS.
	LOCAL longitudeShift IS rotationalDir * timeDif.
	LOCAL newLNG IS MOD(posLATLNG:LNG + longitudeShift,360).
	IF newLNG < - 180 { SET newLNG TO newLNG + 360. }
	IF newLNG > 180 { SET newLNG TO newLNG - 360. }
	RETURN LATLNG(posLATLNG:LAT,newLNG).
}
