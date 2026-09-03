clearscreen.
unlock all.
prep().
reentryprep().
reentry().
descending().
landing().


function prep {
    set h1 to ship:partsdubbed("h1")[0].   /// hinges tags
    set h2 to ship:partsdubbed("h2")[0].
    set h3 to ship:partsdubbed("h3")[0].
    set h4 to ship:partsdubbed("h4")[0].
    set lockstatus to 1.
    hingeslock().
    wait 1.
    set lockstatus to 0.
    hingeslock().

    

    set hts to ship:partsnamed("externalTankRound").    /// header tanks
    set rs1 to hts[0].
    set rs2 to hts[1].
    set rs3 to rs1:resources.
    set rs4 to rs2:resources.
    set rs5 to rs3[0].
    set rs6 to rs3[1].
    set rs7 to rs4[0].
    set rs8 to rs4[1].
    set rs5:enabled to false.
    set rs6:enabled to false.
    set rs7:enabled to false.
    set rs8:enabled to false.


    set grav to body:mu / body:radius^2.
    set steeringManager:maxstoppingtime to 0.005.
    set landingZone to latlng(impactpos():lat, 126).
    set reentered to 0.
    set descend to 0.
    set landingburn to 0.
    set maxqpassed to 0.   
    set neutralflapsaft to 5.       /// neutral stable flap angles for my vehicle -10
    set neutralflapstop to -65.    //-65
    set h to 2.45.     /// vehicle`s height
    set targetaltitswitch to 40.   /// landing burn target altitude(switch to 2 engine is near then)
    set targetaltit to 0.   /// landing burn target altitude
    set altit to alt:radar - h - targetaltit.
    set tarerror to 120.   /// undershoot value for bellyflop
    set accelCoef to 1.
    set east to vcrs(north:vector,up:vector).
    set FAR to addons:FAR.
    set timestep to 5.

    set P1 to 0.004.
    set P2 to 0.01.
    set I to 0.     
    set D to 0.  
    set minpitch to -15.
    set maxpitch to 30.
    set minroll to -10.
    set maxroll to 10.
    set neutralroll to 0.
    set neutralpitch to 50.
    set pid1 to pidloop(P1, I, D, minpitch,maxpitch).
    set pid2 to pidloop(P2, I, D, minroll,maxroll).
    set pid1:setpoint to 1000.
    set pid2:setpoint to 0.


    set engS1 to ship:partstagged("VectorS1")[0].
    set engS2 to ship:partstagged("VectorS2")[0].
    set engS3 to ship:partstagged("VectorS3")[0].
    set engS4 to ship:partstagged("VectorVac1")[0].
    set engS5 to ship:partstagged("VectorVac2")[0].
    set engS6 to ship:partstagged("VectorVac3")[0].
    list engines in engList.
    for eng in engList { set eng:thrustlimit to 100. }
    set i to 0.
    set SeaEngines to list().
    until i >= 3 {
        set i to i+1.
        SeaEngines:add(ship:partstagged("VectorS" + i)[0]).
    }

    set ign to 0.
    starshipengines().
    set Pthr to 1.05.
    set Ithr to 0.
    set Dthr to 0.
    set throttpid to pidloop(Pthr,Ithr,Dthr, 0, 1).

    set now to time:seconds - missiontime.
    set testtime to time:seconds - now + 146.
    set teststatus to "Preparing for reentering the atmosphere, T+: " + round(testtime,1) + " Seconds".
    update().
}


function engnumcheck {
    set curthr to 0.
    for eng in SeaEngines { set curthr to curthr + eng:possiblethrust. }
    set currentengnum to round(curthr/activeengine(),0).
    return currentengnum.
}


function reentryprep {  
    set tophingeleftang to neutralflapstop.
    set tophingerightang to neutralflapstop.
    set afthingerightang to neutralflapsaft.
    set afthingeleftang to neutralflapsaft.
    hingesmove().
    descendcontrol().
    set rs5:enabled to true.
    set rs6:enabled to true.
    set rs7:enabled to true.
    set rs8:enabled to true.
    rcs on.
    set targetheading to velheading.
    lock steering to heading(targetheading, neutralpitch, neutralroll).
    global oldError is downrangeError.
    global lastCheck is time:seconds.
    global errorDif is 0.
    set teststatus to "Flaps are configured for reentry, header tanks are enabled,orienting for reentry, T+: " + round(testtime,1) + " Seconds".
    until altit < 70000 {
        printing().
        update().
        headingchecker().
        descendcontrol().
    }

    set teststatus to "Starship has reentered the atmosphere, T+: " + round(testtime,1) + " Seconds".
    lock steering to heading(targetheading, pitchang, rollang).
    set AoA to vang(velocity:surface,vxcl(up:vector,velocity:surface)).
    set neutralpitch to 50-(AoA+5).
    set reentered to 1.
}


function reentry {
    until altit < 60000 {
        printing().
        update().
        descendcontrol().
    }

    set oldq to ship:q.
    wait 0.1.
    set newq to ship:q.
    set steeringManager:maxstoppingtime to 0.04.
    lock steering to heading(targetheading, pitchang, rollang).
    set teststatus to "Flaps take control of the vehicle, T+: " + round(testtime,1) + " Seconds".
    until newq < oldq {
        set oldq to ship:q.
        wait 0.01.
        set newq to ship:q.
        printing().
        update().
        headingchecker().
        descendcontrol().
        flapscontrol().
    }

    set teststatus to "Max-Q " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    set maxqpassed to 1.
    set neutralpitch to neutralpitch-10.
    set pid1:setpoint to 0.
    until ship:velocity:surface:mag < 280 or altit < 8000 {
        printing().
        update().
        headingchecker().
        descendcontrol().
        flapscontrol().
    }

    set teststatus to "Terminal guidance, awaiting for landing burn, " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    set steeringManager:maxstoppingtime to 0.025.
    set minpitch to -17.
    set maxpitch to 27.
    set minroll to -25.
    set maxroll to 25.
    set neutralflapsaft to 5.   /// 5
    set neutralflapstop to -65.  // -55
    set P1 to min(0.1,max(0.003,280/altit)).
    set I to 0. 
    set P2 to 0.2.
    set D to 0.
    set neutralpitch to 0.
    set pid1 to pidloop(P1, I, D, minpitch,maxpitch).
    set pid2 to pidloop(P2, I, D, minroll,maxroll).
}


function descendcontrol {
    pitchpid().
    rollpid().
} 

function pitchpid {
    set pitchang to pid1:update(time:seconds, -downrangeError)+neutralpitch.
    return pitchang.
}


function rollpid {
    set rollang to pid2:update(time:seconds, -crossError)+neutralroll.   
    return rollang.
}


function headingchecker {
    until false {
        if abs(crossError) > 1000 and altit > 4000 and maxqpassed = 1 or velocity:surface:mag < 1000 and velocity:surface:mag > 280 {
            set landingzonevecunit to (landingZone:position-ship:position):normalized.
            set shiptoimpact to impactpos():position-ship:position.
            set targetheading to compass(2*landingzonevecunit*vdot(shiptoimpact,landingzonevecunit)-shiptoimpact).
            break.
        } else if abs(crossError) < 1000 and velocity:surface:mag < 280 {
            set targetheading to compass(velocity:surface). 
            break.
        }

        if time:seconds - lastCheck >= timestep {
            set errorDif to downrangeError - oldError.
            set oldError to downrangeError.
            set lastCheck to time:seconds.
            if errorDif < 0 { 
                set targetheading to landingZone:heading. 
            } else {
                set landingzonevecunit to (landingZone:position-ship:position):normalized.
                set targetheading to compass(2*velocity:surface*vdot(landingzonevecunit,velocity:surface)-landingzonevecunit).
            }

            break.
        } else {
            break.
        }
    }
}


function flapscontrol {
    set curpitch to 90-vang(up:vector,facing:vector).    /// calculates current pitch
    if vdot(facing:vector,vxcl(up:vector,velocity:surface)) < 0 { 
        set curpitch to 90-curpitch+90. 
    }

    set sideVector to vcrs(up:vector,velocity:surface).
    set curroll to vang(facing:starvector,sideVector).  /// current roll calculation
    if vdot(facing:topvector,sideVector)>0 { set curroll to -curroll. }
    set pitcherror to pitchang-curpitch.
    set rollerror to rollang-curroll.

    set maxpitchflapQ to min(15,max(10, 300/(shipq))).
    set maxpitchflapV to min(15,max(10,20000/ship:velocity:surface:mag)).
    set maxpitchflap to min(maxpitchflapQ,maxpitchflapV).
    set maxrollflap to min(3,max(3,30/(shipq))).
    set kDpitch to 2.5.
    set kDroll to 0.25.
    set kDyaw to 1.4.

    set pitchangular to vdot(facing:starvector, ship:angularvel) * (180/constant:pi).
    set rollangular to vdot(facing:forevector, ship:angularvel) * (180 / constant:pi).
    set yawangular to vdot(facing:topvector, ship:angularvel) * (180 / constant:pi).

    set pitchcmd to min(90, max(-90, pitcherror*2.1)).
    set pitchdamp to min(15,max(-15,kDpitch*pitchangular)).
    if abs(pitchdamp)<1 { set pitchdamp to 0. }
    set rolldamp to min(3,max(-3,kDroll*rollangular)).
    set rollcmd to rollerror.
    set yawcmd to kDyaw*yawangular.

    // Hard limits on commanded flap contributions to prevent large, sudden deflections
    set pitchcmd to min(maxpitchflap, max(-maxpitchflap, pitchcmd)).
    set rollcmd to min(maxrollflap, max(-maxrollflap, rollcmd)).
    set yawcmd to min(3, max(-3, yawcmd)).

    set rawafthingeleftang to (neutralflapsaft-pitchcmd-pitchdamp)-(rollcmd-rolldamp).     ///+ 
    set rawafthingerightang to (neutralflapsaft-pitchcmd-pitchdamp)+(rollcmd+rolldamp).   ///-
    set rawtophingeleftang to (neutralflapstop+pitchcmd+pitchdamp)-(rollcmd-rolldamp)-yawcmd.  
    set rawtophingerightang to (neutralflapstop+pitchcmd+pitchdamp)+(rollcmd+rolldamp)+yawcmd.

    set afthingeleftang to min(15,max(-75,rawafthingeleftang)).  
    set afthingerightang to min(15,max(-75,rawafthingerightang)).    
    set tophingeleftang to  min(15,max(-75,rawtophingeleftang)). 
    set tophingerightang to min(15,max(-75,rawtophingerightang)). 


    print "Current Pitch:" + round(curpitch, 2).
    print "Pitch Angular:" + round(pitchangular, 2).
    print "Roll Angular:" + round(rollangular, 2).
    print "Current Roll: " + round(curroll, 2).
    print "Pitch Commamd: " + round(pitchcmd, 2).
    print "Pitch Damp: " + round(pitchdamp, 2).
    print "Yaw Command: " + round(yawcmd, 2).   
    print "Aft Left: " + round(afthingeleftang, 1).
    print "Aft Right: " + round(afthingerightang, 1).
    print "Top Left: " + round(tophingeleftang, 1).
    print "Top Right: " + round(tophingerightang, 1).
    print "Max Pitch Flaps Deflection: " + round(maxpitchflap, 2).
    print "Max Roll Flaps Deflection: " + round(maxrollflap, 2).
    print "Top/Aft Flaps Roll Mix: " + round(rollcmd, 2).
    print "Top/Aft Flaps Yaw Mix: " + round(yawcmd, 2).
    hingesmove().
}

function descending {
    descendcontrol().
    set descend to 1.
    set plannedengnum to 3.
    engS1:activate.
    engS2:activate.
    engS3:activate.
    landingburncalc(engnumcheck(), plannedengnum).
    until altit < LBAlt+1000 and altit < 5000 {
        printing().
        update().
        headingchecker().
        descendcontrol().
        flapscontrol().
        landingburncalc(engnumcheck(), plannedengnum).
        if shipq > 28 {
            set maxpitch to 5.
            set minpitch to -5.
            set pid1:maxoutput to maxpitch.
            set pid1:minoutput to minpitch.
        }
    }


    set minpitch to 0.
    set pid1:minoutput to minpitch.
    set neutralflapsaft to 10.  
    set neutralflapstop to -70.  
    set teststatus to "Preparing to landing burn, T+: " + round(testtime,1) + " Seconds".
    until altit < LBAlt+abs(velocity:surface:mag*2.25) {
        printing().
        update().
        headingchecker().
        descendcontrol().
        flapscontrol().
        landingburncalc(engnumcheck(), plannedengnum).
    }
}

function landing {
    set teststatus to "Landing burn starting, T+: " + round(testtime,1) + " Seconds".
    set steeringManager:maxstoppingtime to 0.1.
    set reentered to 0.
    set tarerror to 0.

    set afthingerightang to -70.
    set afthingeleftang to -70.
    set tophingerightang to 10.
    set tophingeleftang to 10.
    hingesmove().

    lock steering to lookdirup(up:vector,-east).
    lock throttle to 0.6.
    set ign to 1.
    starshipengines().
    set landingburn to 1.
    until vang(ship:facing:vector, up:vector) < 40 {
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set steeringManager:maxstoppingtime to 1.
    lock throttle to 1.
    lock steering to lookdirup(-ship:velocity:surface,-east).
    set tophingerightang to -65.
    set tophingeleftang to -65.
    set afthingerightang to -65.
    set afthingeleftang to -65.
    hingesmove().
    until vang(ship:facing:vector, -ship:velocity:surface) < 5 {
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    lock steering to Steer().
    lock throttle to thrott.
    set teststatus to "3 Sea level engines are lit, T+: " + round(testtime,1) + " Seconds".
    set plannedengnum to 2.
    landingburncalc(engnumcheck(), plannedengnum).
    until verticalspeed > TargetVelocityPlanned { 
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set ign to 0.
    lock steering to Steer().   /// finalSteer
    update().
    starshipengines().
    landingburncalc(engnumcheck(), plannedengnum).
    set plannedengnum to currentengnum.
    set teststatus to "2 Raptor engines are lit, cancelling horizontal velocity, T+: " + round(testtime,1) + " Seconds".
    until ship:verticalspeed > -0.5 or ship:status = "Landed" or ship:status = "Splashed" {    /// still not ideal, bouncing
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set now1 to time:seconds.
    lock ti1 to time:seconds - now1.
    lock steering to lookdirup(up:vector,-east).  
    lock throttle to max(0.03, 1-(ti1/0.5)).
    set landingburn to 0.
    set descend to 0.
    set reentered to 0.
    until ship:status = "Landed" or ship:status = "Splashed" {
        printing().
        update().
    }

    set teststatus to "Touchdown confirmed".
    set afthingerightang to -15.
    set afthingeleftang to -15.
    wait 2.
    lock throttle to 0.
    starshipengines().
    unlock steering.
    unlock throttle.
    set lockstatus to 1.
    hingeslock().
    rcs off.
    set ship:control:pilotmainthrottle to 0.
    set teststatus to "Ship has splashed!".
    printing().
}


function hingeslock {
    h1:getmodule("ModuleRoboticServoHinge"):setfield("Locked", lockstatus).
    h2:getmodule("ModuleRoboticServoHinge"):setfield("Locked", lockstatus).
    h3:getmodule("ModuleRoboticServoHinge"):setfield("Locked", lockstatus).
    h4:getmodule("ModuleRoboticServoHinge"):setfield("Locked", lockstatus).
}


function hingesmove {
    h1:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", tophingeleftang).
    h2:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", tophingerightang).
    h3:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", afthingeleftang).
    h4:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", afthingerightang).
}

function compass {   /// returns compass heading of any vector
    parameter vec.
    set east to vcrs(up:vector, north:vector).
    set northCompass to vdot(north:vector, vec).
    set eastCompass to vdot(east, vec).
    return mod(arctan2(eastCompass, northCompass) + 360, 360).
}


function update {  /// some variables to update frequently
    set altit to alt:radar - h - targetaltit.
    set testtime to time:seconds - now + 146.
    set forwardDir to vxcl(up:vector,ship:velocity:surface):normalized.
    set crossDir to vcrs(up:vector,forwardDir):normalized.
    set downrangeError to vdot(overshootTargetError(),forwardDir).
    set crossError to vdot(overshootTargetError(),crossDir).	
    set velheading to compass(ship:velocity:surface).
    set shipq to ship:q*constant:atmtokpa.
    if descend = 1 {
        set P1 to min(0.1,max(0.003,280/altit)).
        set pid1:kp to P1.
    }
}


function printing {
    clearscreen.
    print "Status: " + teststatus.
    print "T+: " + round(testtime,1) + " Seconds".  
    print "Error: " + round(errorvector():mag, 2) + " Meters".
    print "Downrange Error: " + round(downrangeError,2) + " Meters". 
    print "Cross Error " + round(crossError,2) + " Meters". 
    if reentered = 1 {
       print "Targeted pitch is " + round(pitchang,2) + " Degrees".
       print "Targeted roll is " + round(rollang,2) + " Degrees".
       print "Targeted heading is " + round(targetheading,2) + " Degrees".
    }
    
    if descend = 1 {
        print "Landing Burn Altitude Ideal: " + round(LBAlt,2) + " Meters".
        print "Landing Burn Altitude Targeted: " + round(LBAlt+velocity:surface:mag*2.25,2) + " Meters".
        print "Current Altitude: " + round(altit,2) + " Meters".
        print "Target Velocity Current: " + round(TargetVelocityCurrent, 1) + " M/S".
        print "Target Velocity Planned  : " + round(TargetVelocityPlanned, 1) + " M/S".
    }

    if landingburn = 1 {
        set shipthrust to throttle.
        print "Current thrust percentage: " + round(shipthrust*100,2) + "%".
        print "Targeted thrust percentage: " + round((thrott)*100,2) + "%".
        print "Throttle P: " + round(Pthr,2).
    }
 
    print "Press 10 to abort program".
}


function activeengine {
    local i is 0.
    set testeng to SeaEngines[i]:possiblethrust.
    until testeng > 0 or i = 2 {
        set i to min(2, i + 1).
        set testeng to SeaEngines[i]:possiblethrust.
    }

    return testeng.
}

function landingburncalc {	
    parameter currentengnum, plannedengnum.
    set engpossibleThrustcurrent to currentengnum*activeengine().
    set engpossibleThrustplanned to plannedengnum*activeengine().
    set maxAccelcurrent to max(grav+0.1,(engpossibleThrustcurrent / ship:mass))*max(0.1,cos(vang(facing:vector,up:vector))) - grav.
    set maxAccelplanned to max(grav+0.1,(engpossibleThrustplanned / ship:mass)) - grav.	
    set LBAlt to ship:verticalspeed^2 / (2 * maxAccelplanned).	
    if engnumcheck = 3 {
        set targetaltitswitch to targetaltitswitch.
    } else {
        set targetaltitswitch to targetaltit.
    }

    set TargetAccelCurrent to maxAccelcurrent*AccelCoef.
    set TargetVelocityCurrent to -sqrt(2*max(0.01,TargetAccelCurrent)*max(0.01, altit-targetaltitswitch)).

    set TargetAccelPlanned to maxAccelplanned*AccelCoef.
    set TargetVelocityPlanned to -sqrt(2*max(0.01,TargetAccelplanned)*max(0.01, altit-targetaltit)).
    set hoverThr to grav * ship:mass / engpossibleThrustcurrent.	
    set Pthr to abs(verticalSpeed/TargetVelocityCurrent). 
    set TargetVelocity to TargetVelocityCurrent.

    set throttpid:kp to Pthr.
    set throttpid:setpoint to TargetVelocity.	
    set thrott to throttpid:update(time:seconds, ship:verticalspeed)+hoverThr.
}

function statedetect {
    for eng in SeaEngines {
        if eng:thrustlimit < 0.1 {
            eng:shutdown.
        }

        if eng:thrustlimit > 0.1 {
            eng:activate.
        }
   }
}

function starshipengines {
   if ign = 1 {
        set engS1:thrustlimit to 0.
        set engS2:thrustlimit to 0.
        set engS3:thrustlimit to 0.
        set command to time:seconds.
        set commandtime to time:seconds - command.
        until commandtime > 1.6 {
            set commandtime to time:seconds - command.
            printing().
            update().
            set sealim to commandtime*320.
            set engS3:thrustlimit to sealim.
            set engS2:thrustlimit to sealim-150.
            set engS1:thrustlimit to sealim-300.
            statedetect().
        }

        set engS1:thrustlimit to 100.
        set engS2:thrustlimit to 100.
        set engS3:thrustlimit to 100.     
   } else if ign = 0 {
        if landingburn = 1 {
            set command to time:seconds.
            set commandtime to time:seconds - command.
            until commandtime > 1 {
                set commandtime to time:seconds - command.
                printing().
                update().
                set sealim to 100-commandtime*180.
                set engS1:thrustlimit to sealim.
                statedetect().
            }
        } else  {
            engS1:shutdown.
            engS2:shutdown.
            engS3:shutdown.
            engS4:shutdown.
            engS5:shutdown.
            engS6:shutdown.
        }
   }
}


function errorvector {
    set errorvec to impactpos():position - landingZone:position.
    return errorvec.
}

function overshootTargetError {
  set overshootTarget to landingZone:position-vxcl(up:vector,ship:velocity:surface):normalized*tarerror.
  return impactpos():position - overshootTarget.
}


function Steer {
    set maxAoA to min(10, max(1,altit/15)).
    set aoa to -min(maxAoA, errorVector():mag/2).
    set result to -velocity:surface + errorvector().

    if vang(result, -velocity:surface) > aoa {
        
        set result to -velocity:surface:normalized + tan(aoa)*errorvector():normalized.
    }

    return lookdirup(result, -east).
}


function impactpos {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos.
  } else {
    return ship:geoposition.
  }
}

on ag10 {
    set teststatus to "Abort, FTS activated".
    lock throttle to 0.
    wait 0.01.
    printing().
    unlock throttle.
    unlock steering.
    ag7 on.
    ag8 on.
}