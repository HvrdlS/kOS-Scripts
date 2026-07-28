clearscreen.
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
    set landingZone to latlng(4.5, 170).
    set reentered to 0.
    set descend to 0.
    set landingburn to 0.
    set maxqpassed to 0.   
    set neutralflapsaft to -35.       /// neutral stable flap angles for my vehicle
    set neutralflapstop to -27.
    set h to 15.     /// vehicle`s height
    set targetaltit to 15.   /// landing burn target altitude(switch to 1 engine then)
    set altit to alt:radar - h - targetaltit.
    set tarerror to 20.   /// undershoot value for bellyflop
    set east to vcrs(north:vector,up:vector).


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
    set throttpid to pidloop(Pthr,Ithr,Dthr,-0.1, 1).

    set now to time:seconds - missiontime.
    set testtime to time:seconds - now.
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
    lock steering to lookdirup(north:vector,up:vector).
    until altit < 90000 and ship:verticalspeed < 0 {
        printing().
        update().
    }

    set tophingeleftang to neutralflapstop.
    set tophingerightang to neutralflapstop.
    set afthingerightang to neutralflapsaft.
    set afthingeleftang to neutralflapsaft.
    set P1 to 0.008.
    set P2 to 0.01.
    set I to 0.     
    set D to 0.005.  
    set minpitch to -45.
    set maxpitch to 35.
    set minroll to -10.
    set maxroll to 10.
    set neutralroll to 0.
    set neutralpitch to 45.
    set pid1 to pidloop(P1, I, D, minpitch,maxpitch).
    set pid2 to pidloop(P2, I, D, minroll,maxroll).
    set pid1:setpoint to 0.
    set pid2:setpoint to 0.
    hingesmove().
    descendcontrol().
    set rs5:enabled to true.
    set rs6:enabled to true.
    set rs7:enabled to true.
    set rs8:enabled to true.
    rcs on.
    lock steering to heading(velheading, neutralpitch, neutralroll).
    set teststatus to "Flaps are configured for reentry, orienting for reentry, T+: " + round(testtime,1) + " Seconds".
    until altit < 70000 {
        printing().
        update().
        descendcontrol().
    }

    set teststatus to "Starship has reentered the atmosphere, T+: " + round(testtime,1) + " Seconds".
    lock steering to heading(velheading, pitchang, rollang).
    set reentered to 1.
}


function reentry {
    until ship:q > 0.5 or altit < 53000 {
        printing().
        update().
        descendcontrol().
    }

    set oldq to ship:q.
    wait 0.1.
    set newq to ship:q.
    set steeringManager:maxstoppingtime to 0.2.
    lock steering to heading(velheading, pitchang, rollang).
    set teststatus to "Flaps take control of the vehicle, T+: " + round(testtime,1) + " Seconds".
    until newq < oldq {
        set oldq to ship:q.
        wait 0.01.
        set newq to ship:q.
        printing().
        update().
        pitchpid().
        rollpid().
        flapscontrol().
        wait 0.
    }

    set teststatus to "Max-Q " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    until ship:velocity:surface:mag < 1000 {
        printing().
        update().
        pitchpid().
        rollpid().
        flapscontrol().
        wait 0.
    }

    set minroll to -25.
    set maxroll to 25.
    set minpitch to -30.
    set maxpitch to 25.
    set neutralpitch to 30.
    set pid1:minoutput to minpitch.
    set pid2:maxoutput to maxpitch.
    set pid2:minoutput to minroll.
    set pid2:maxoutput to maxroll.
    set pid2:kp to 0.07.
    set teststatus to "Beginning increasd roll banking and pitch control, " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    until ship:velocity:surface:mag < 260 {
        printing().
        update().
        pitchpid().
        rollpid().
        flapscontrol().
        wait 0.
    }

    set teststatus to "Terminal guidance, awaiting for landing burn, " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    set correctionheading to velheading+(landingZone:heading-velheading)/2.
    lock steering to heading(correctionheading, pitchang, rollang).
    set maxqpassed to 1.
    set minpitch to -15.
    set maxpitch to 20.
    set neutralflapsaft to -25.
    set neutralflapstop to -17.
    set P1 to 0.1.
    set I to 0. 
    set P2 to 0.14.
    set D to 0.005.
    set neutralpitch to 10.
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


function flapscontrol {
    set curpitch to 90-vang(up:vector,facing:vector).    /// calculates current pitch, has one flaw of not knowing which half of navball it is, but it is playable if vehicle is stable across 0-180 degrees pitch
    set sideVector to vcrs(up:vector,velocity:surface).
    set curroll to vang(facing:starvector,sideVector).  /// current roll calculation
    if vdot(facing:topvector,sideVector)>0 { set curroll to -curroll. }
    set pitcherror to pitchang-curpitch.
    set rollerror to rollang-curroll.

    if maxqpassed = 1 {   /// still needs some tweaking, especially roll
        set flapcoef to min(5,max(0.01,80/(ship:q*constant:atmtokpa))).
        set flapcoefroll to min(1,max(0.01,16/(ship:q*constant:atmtokpa))).
        set kDpitch to 2.5.
        set kDroll to 0.05.
        set kDyaw to 0.15.
    } else {      /// still needs some tweaking, especially roll
        set flapcoef to min(2.8,max(0.01,55/(ship:q*constant:atmtokpa))).
        set flapcoefroll to min(0.8,max(0.01,2/(ship:q*constant:atmtokpa))).
        set kDpitch to 1.
        set kDroll to 0.02.
        set kDyaw to 0.13.
    }

    set pitchangular to vdot(facing:starvector, ship:angularvel)*(180/constant:pi).
    set rollangular to vdot(facing:forevector, ship:angularvel) * (180 / constant:pi).
    set yawangular to vdot(facing:topvector, ship:angularvel) * (180 / constant:pi).

    set pitchcmd to pitcherror*flapcoef.
    set pitchdamp to kDpitch*pitchangular.
    set rolldamp to kDroll*rollangular.
    set rollcmd to rollerror*flapcoefroll.
    set yawcmd to kDyaw*yawangular.

    set rawafthingeleftang to (neutralflapsaft-pitchcmd-rollcmd)-pitchdamp-yawcmd.      
    set rawafthingerightang to (neutralflapsaft-pitchcmd+rollcmd)-pitchdamp+yawcmd.   
    set rawtophingeleftang to (neutralflapstop+pitchcmd)+pitchdamp-(rollcmd+rolldamp)-yawcmd.  
    set rawtophingerightang to (neutralflapstop+pitchcmd)+pitchdamp+(rollcmd+rolldamp)+yawcmd.

    set afthingeleftang to min(15,max(-75,rawafthingeleftang)).  
    set afthingerightang to min(15,max(-75,rawafthingerightang)).    
    set tophingeleftang to  min(15,max(-75,rawtophingeleftang)). 
    set tophingerightang to min(15,max(-75,rawtophingerightang)). 


    print "Current Pitch:" + curpitch.
    print "Pitch Angular:" + pitchangular.
    print "Roll Angular:" + rollangular.
    print "Current Roll: " + curroll.
    print "Pitch Error: " + pitcherror.
    print "Roll Error: " + rollerror.
    print "Pitch Damp: " + pitchdamp.
    print "Yaw Command: " + yawcmd.
    print "Aft Left: " + afthingeleftang.
    print "Aft Right: " + afthingerightang.
    print "Top Left: " + tophingeleftang.
    print "Top Right: " + tophingerightang.
    print "Flaps Coefficient: " + flapcoef.
    print "Aft Flaps Roll Coefficient: " + flapcoefroll.
    print "Top/Aft Flaps Roll Mix: " + rollcmd.
    hingesmove().
}

function descending {
    descendcontrol().
    set descend to 1.
    set accelCoef to 1.
    set plannedengnum to 3.
    engS1:activate.
    engS2:activate.
    engS3:activate.
    landingburncalc(engnumcheck(), plannedengnum).
    until altit < LBAlt+250 and altit < 2000 {
        printing().
        update().
        pitchpid().
        rollpid().
        flapscontrol().
        landingburncalc(engnumcheck(), plannedengnum).
    }
}

function landing {
    set teststatus to "Landing burn starting, T+: " + round(testtime,1) + " Seconds".
    set steeringManager:maxstoppingtime to 0.1.
    set reentered to 0.

    set afthingerightang to -75.
    set afthingeleftang to -75.
    set tophingerightang to 15.
    set tophingeleftang to 15.
    hingesmove().

    lock steering to lookdirup(-ship:velocity:surface,-east).
    lock throttle to 1.
    set ign to 1.
    starshipengines().
    set landingburn to 1.
    set accelCoef to 0.9.
    set afthingerightang to -65.
    set afthingeleftang to -65.
    hingesmove().
    until vang(ship:facing:vector, -ship:velocity:surface) < 10 {
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set steeringManager:maxstoppingtime to 1.
    lock throttle to thrott.
    lock steering to Steer().
    set tophingerightang to -75.
    set tophingeleftang to -75.
    hingesmove().
    set teststatus to "3 Sea level engines are lit, T+: " + round(testtime,1) + " Seconds".
    set plannedengnum to 1.
    until ship:verticalspeed > -13 {   /// velocity based switch due to pretty low twr of single engine(1.01) and thrust ramp system
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set targetaltit to 0.
    set ign to 0.
    lock throttle to 1.
    lock steering to finalSteer().
    set accelCoef to 1.
    starshipengines().
    landingburncalc(engnumcheck(), plannedengnum).
    lock throttle to thrott.
    set plannedengnum to currentengnum.
    set teststatus to "1 Raptor engines is lit, cancelling horizontal velocity, T+: " + round(testtime,1) + " Seconds".
    until ship:verticalspeed > -1 and ship:verticalspeed < 2 and altit < 5 {    /// still not ideal, bouncing
        printing().
        update().
        landingburncalc(engnumcheck(), plannedengnum).
    }

    set now1 to time:seconds.
    lock ti1 to time:seconds - now1.
    lock steering to lookdirup(up:vector,-east).  
    lock throttle to max(0.01, ti1/0.5).
    set landingburn to 0.
    set descend to 0.
    set reentered to 0.
    until ship:status = "Landed" or ship:status = "Splashed" {
        printing().
        update().
    }

    set teststatus to "Touchdown confirmed".
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
    set testtime to time:seconds - now.
    set forwardDir to vxcl(up:vector,ship:velocity:surface):normalized.
    set crossDir to vcrs(up:vector,forwardDir):normalized.
    set downrangeError to vdot(overshootTargetError(),forwardDir).
    set crossError to vdot(overshootTargetError(),crossDir).	
    set velheading to compass(ship:velocity:surface).
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
       print "Targeted heading is " + velheading + " Degrees".
    }
    
    if descend = 1 {
        print "Landing Burn Altitude: " + round(LBAlt,2) + " Meters".
        print "Target Velocity: " + round(TargetVelocity, 1) + " M/S".
    }

    if landingburn = 1 {
        set shipthrust to throttle.
        print "Current thrust percentage: " + round(shipthrust*100,2) + "%".
        print "Targeted thrust percentage: " + round((thrott)*100,2) + "%".
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
    set maxAccelcurrent to max(grav+0.1,(engpossibleThrustcurrent / ship:mass)) - grav.
    set maxAccelplanned to max(grav+0.1,(engpossibleThrustplanned / ship:mass)) - grav.	
    set LBAlt to ship:verticalspeed^2 / (2 * maxAccelplanned).	
    set TargetAccel to maxAccelcurrent*AccelCoef.
    set TargetVelocity to -sqrt(2*max(0.01,TargetAccel)*max(0.01, altit-targetaltit)).
    set hoverThr to grav * ship:mass / engpossibleThrustcurrent.	
    set Pthr to abs(verticalSpeed/TargetVelocity)+0.1.    /// this one should be tuned better along with targetaccel in next flight
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
        until commandtime > 1.5 {
            set commandtime to time:seconds - command.
            printing().
            update().
            set sealim to commandtime*320.
            set engS1:thrustlimit to sealim.
            set engS2:thrustlimit to sealim-200.
            set engS3:thrustlimit to sealim-300.
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
                set sealim to 100-commandtime*320.
                set engS1:thrustlimit to sealim.
                set engS2:thrustlimit to sealim+180.
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

function finalSteer {  /// should be more agressive in next flight
    set maxAoA to min(3, altit/10).
    set aoa to -min(maxAoA, errorVector():mag/3).
    set result to up:vector + errorvector().

    if vang(result, up:vector) > aoa {
        set result to up:vector:normalized + tan(aoa)*errorvector():normalized.
    }

    return lookdirup(result, -east).
}


function Steer {
    set maxAoA to min(15, altit/10).
    set aoa to -min(maxAoA, errorVector():mag/3).
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