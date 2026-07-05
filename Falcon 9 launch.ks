clearscreen.
preflight().
countdown().
flight().


function abortofscript {
  clearscreen.
  print "Program aborted".
  shutdown.
}


function printing {
  clearscreen.
  if ship:status = "Flying" or ship:verticalspeed > 0 or ship:verticalspeed < 0 or alt:radar > 40 {
    set tpl to time:seconds - n.
  } else {
    set tpl to (n - time:seconds)+10.
  }
  print "Mission status: " + missionstatus.
  print "T: " + round(abs(tpl),1) + " Seconds".
  print "Target apoapsis: " + TargetAp + " Meters".
  print "Target periapsis: " + TargetPe + " Meters".
  print "Target inclination: " + TargetInc + " Degrees".
  print "Azimuth: " + Azimuth.
  print "Press 10 to abort current program".
  wait 0.05.
}

function AzimuthCalc {
  parameter TargetInc.
  parameter launchnorth.
  local IncInert is arccos(cos(TargetInc)/cos(ship:geoposition:lat)).
  local VelSite is (2*constant:pi*body:radius*cos(ship:geoposition:lat))/body:rotationperiod.
  local VelX is 2300*sin(IncInert)-VelSite.
  local VelY is 2300*cos(IncInert).
  local Azimuth is mod(arctan2(VelX, VelY)+360, 360).
  if launchnorth = true {
    return Azimuth.
  } else {
    return Azimuth+90.
  }
}


function preflight {
  set missionstatus to "Awaiting for launch window".
  set TargetPe to 90000.
  set TargetAp to 230000.
  set TargetInc to 45.
  set launchnorth to true.
  set Azimuth to AzimuthCalc(TargetInc, launchnorth).
  set startsteer to lookDirUp(up:vector, ship:facing:topvector).
  set PitchKickAlt to 130.
  set ThrDownAlt to 2450.
  set MECOAlt to 29200.
  set ThrDown2Alt to 25000.
  set FairingAlt to 53000.
  set g to body:mu / body:radius^2.
  set steeringManager:maxstoppingtime to 0.04.
  set sec to 50.
  set minut to 44.
  set hour to 04.
  set clock to "04:44:50".
  lights off.
  sas off.
  set n to time:seconds + ((hour-time:hour)*60+minut-time:minute)*60+(sec-time:second).
  set t to (n - time:seconds)+10.
  set rclock to time:clock.
  until rclock >= clock and rclock <= clock {
    clearscreen.
    print "Mission status: " + missionstatus.
    print "Left: " + t + " Seconds".
    print "Press 10 to abort current program".
    set t to (n - time:seconds)+10.
    set rclock to time:clock.
  }

  set n to time:seconds+10.
  lock t to n-time:seconds.
  set missionstatus to "Ready for launch, T- " + round(t,1) + " Seconds".
}


function countdown {
  until t <= 6 {
    printing().
  }

  stage.
  set missionstatus to "Water deluge activation, T- " + round(t,1) + " Seconds".
  until t <= 3 {
    printing().
  }

  stage.
  lock throttle to 0.01.
  set missionstatus to "Ignition, T- " + round(t,1) + " Seconds".
  until t <= 2 {
    printing().
  }

  set missionstatus to "Full thrust, T- " + round(t,1) + " Seconds".
  set now to time:seconds.
  lock ti to time:seconds - now.
  lock throttle to min(1, ti/1).
  until t <= 0 {
    printing().
  }
   
  stage.
  lock steering to startsteer.
  set n to time:seconds.
  set tpl to time:seconds - n.
  set missionstatus to "Liftoff!, T+ " + round(tpl,1) + " Seconds".
}


function inflightvars {
  if ship:maxthrust > 0 {
    set twr to ship:mass * g / ship:availablethrust.
  } else if ship:maxthrust = 0 {
    set twr to 0.
  }
  set pitchcalc to 90-((((ship:apoapsis/TargetPe)^0.8))*90).
}


function flight {
  until altitude > 140 {
    printing().
    inflightvars().
  }

  set missionstatus to "Falcon has cleared the towers, T+ " + round(tpl,1) + " Seconds".
  until altitude > PitchKickAlt - 50 {
    printing().
    inflightvars().
  }

  set missionstatus to "Pitch, roll program, T+ " + round(tpl,1) + " Seconds".
  lock steering to heading(Azimuth, pitchcalc).
  until altitude > ThrDownAlt {
    printing().
    inflightvars().
  }

  set missionstatus to "Throttle down, T+ " + round(tpl,1) + " Seconds".
  lock throttle to 1.6 * twr.
  set oldq to ship:q.
  wait 0.01.
  set newq to ship:q.
  until newq < oldq {
    printing().
    inflightvars().
    set oldq to ship:q.
    wait 0.01.
    set newq to ship:q.
  }

  set missionstatus to "Max-Q is reached, " + round(newq*constant:atmtokpa,3) + "kP, " +  "T+ " + round(tpl,1) + " Seconds".
  set now to time:seconds.
  set ti to time:seconds-now.
  until ti > 12 {
    printing().
    inflightvars().
    set ti to time:seconds-now.
  }

  set missionstatus to "Throttle up, T+ " + round(tpl,1) + " Seconds".
  lock throttle to 3*twr.
  until altitude > ThrDown2Alt {
    printing().
    inflightvars().
  }

  set missionstatus to "Throttle down before MECO, T+ " + round(tpl,1) + " Seconds".
  lock throttle to 2.5*twr.
  until altitude > MECOAlt {
    printing().
    inflightvars().
  }

  set missionstatus to "MECO, T+ " + round(tpl,1) + " Seconds".
  set now to time:seconds.
  lock ti to time:seconds - now.
  set thr to throttle.
  lock throttle to max(0, thr-ti/1).
  rcs on.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  until ti1 > 4 {
    printing().
    inflightvars().
  }

  set missionstatus to "Stage separation, T+ " + round(tpl,1) + " Seconds".
  lights on.
  toggle ag2.
  stage.
  set ship:control:fore to 1.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  until ti1 > 5 {
    printing().
    inflightvars().
  }

  set missionstatus to "SES-1, T+ " + round(tpl,1) + " Seconds".
  lock throttle to 0.01.
  stage.
  wait 1.
  set now to time:seconds.
  lock ti to time:seconds - now.
  lock throttle to min(0.5, ti/1).
  set ship:control:fore to 0.
  set steeringManager:maxstoppingtime to 2.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  until ti1 > 3 {
    printing().
    inflightvars().
  }

  set missionstatus to "SES-1, protection ring separation, T+ " + round(tpl,1) + " Seconds".
  stage.
  until altitude > FairingAlt {
    printing().
    inflightvars().
  }

  set missionstatus to "Fairing separation, T+ " + round(tpl,1) + " Seconds".
  stage.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  until ti1 > 3 {
    printing().
    inflightvars().
  }

  set missionstatus to "Guidance program is initiating till targeted parking orbit is reached, T+ " + round(tpl,1) + " Seconds".
  set pi1 to pidloop(0.15,0,0.001, 0.25,1).
  set pi2 to pidloop(0.2,0,0.001, -45,65).
  set thr to 0.5.
  lock throttle to thr.
  set pitch to 35.
  lock steering to heading(Azimuth, pitch).
  pid1().
  pid2().
  set missionstatus to "SECO-1, T+ " + round(tpl,1) + " Seconds".
  lock throttle to 0.
  wait 0.1.
  set ship:control:fore to -1.
  set now1 to time:seconds.
  lock ti1 to time:seconds-now1.
  until ti1 > 1 {
    printing().
    inflightvars().
  }

  set ship:control:fore to 0.
  run maneuvernodegeo.
  run payloaddeploy.
}


function pid1 {
  set targeteta1 to 120.
  set pi1:setpoint to targeteta1.
  set pi2:setpoint to TargetPe*1.01.
  until ship:apoapsis > TargetPe*1.01 {    
    printing().
    set thr to pi1:update(time:seconds,eta:apoapsis).  
    set pitch to pi2:update(time:seconds,ship:apoapsis).  
  }  
}


function pid2 {
  set targeteta2 to 15.
  set pi1:setpoint to targeteta2.
  set pi3 to pidloop(0.05,0,0.001, 0.25,1).
  set pi4 to pidloop(0.5,0,0.05, -10,30).
  set pi3:setpoint to 5.
  set pi4:setpoint to 5.
  until ship:apoapsis >= TargetAp and ship:periapsis >= TargetPe*0.95 {
    printing().
    set thr to pi1:update(time:seconds,eta:apoapsis).  
    set pitch to pi2:update(time:seconds,ship:apoapsis).
    set targeteta2 to (((TargetPe-ship:periapsis)/targeteta1)/targeteta1)+10.
    set pi1:setpoint to targeteta2.
    set pi2:setpoint to TargetPe*1.01.
    if ship:verticalspeed < 5 {
      set thr to pi3:update(time:seconds,ship:verticalspeed).
      set pitch to pi4:update(time:seconds, ship:verticalspeed).
    }   
  }
}
