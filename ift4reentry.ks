clearscreen.
prep().
reentryprep().
reentry().
descending().
landing().
function prep {
    set h1 to ship:partsdubbed("h1")[0].
    set h2 to ship:partsdubbed("h2")[0].
    set h3 to ship:partsdubbed("h3")[0].
    set h4 to ship:partsdubbed("h4")[0].
    set lockstatus to 1.
    hingeslock().
    wait 1.
    set lockstatus to 0.
    hingeslock().
    set hts to ship:partsnamed("externalTankRound").
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
    set eng1 to ship:partstagged("VectorS1")[0].
    set eng2 to ship:partstagged("VectorS2")[0].
    set eng3 to ship:partstagged("VectorS3")[0].
    set grav to body:mu / body:radius^2.
    set steeringManager:maxstoppingtime to 0.02.
    set landingZone to impactpos().
    set reentered to 0.
    set descend to 0.
    set landingburn to 0.
    set maxqpassed to 0.
    set h to 15.
    set altit to alt:radar - h.
    set now to time:seconds - missiontime.
    set testtime to time:seconds - now.
    set teststatus to "Preparing for reentering the atmosphere, T+: " + round(testtime,1) + " Seconds".
    wait 0.5.
    printing().
}


function reentryprep {  
    until altit < 87500 {
        printing().
    }

    set tophingeleftang to -35.
    set tophingerightang to -35.
    set afthingesang to -35.
    set P1 to 0.02.
    set P2 to 0.02.
    set I to 0.
    set D to 0.001.
    set minpitch to -45.
    set maxpitch to 45.
    set minroll to -5.
    set maxroll to 5.
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
        descendcontrol().
    }

    set teststatus to "Starship has reentered the atmosphere, T+: " + round(testtime,1) + " Seconds".
    set reentered to 1.
}


function reentry {
    set oldq to ship:q.
    wait 0.1.
    set newq to ship:q.
    set steeringManager:maxstoppingtime to 0.1.
    set lockstatus to 1.
    hingeslock().
    lock steering to heading(velheading, pitchang, rollang).
    until newq < oldq {
        set oldq to ship:q.
        wait 0.01.
        set newq to ship:q.
        printing().
        pitchpid().
        rollpid().
    }

    set teststatus to "Max-Q " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    until altit < 20000 and ship:velocity:surface:mag < 300 {
        printing().
        pitchpid().
        rollpid().
    }

    set teststatus to "Terminal guidance, awaiting for landing burn, " + round(newq*constant:atmtokpa,3) + " kPa, T+: " + round(testtime,1) + " Seconds".
    set maxqpassed to 1.
    set minpitch to -60.
    set maxpitch to 60.
    set P1 to 0.03.
    set I to 0.001.
    set D to 0.001.
    set minroll to -45.
    set maxroll to 45.
    set P2 to 0.04.
    set neutralpitch to 0.
    set pid1 to pidloop(P1, I, D, minpitch,maxpitch).
    set pid2 to pidloop(P2, I, D, minroll,maxroll).
}


function descendcontrol {
    pitchpid().
    rollpid().
} 

function pitchpid {
    if maxqpassed = 1 {
        compass(-ship:velocity:surface).
        if vdot(-ship:velocity:surface,east) < -0.5 or vdot(-ship:velocity:surface,east) > 0.5 {
            set pitchang to pid1:update(time:seconds, lngoff)+neutralpitch.
        } else {
            set pitchang to pid1:update(time:seconds, lngoff)-neutralpitch.
        }
    } else {
        set pitchang to pid1:update(time:seconds, lngoff)+neutralpitch.
    }

    return pitchang.
}


function rollpid {
    if maxqpassed = 1 {
        set rollang to pid2:update(time:seconds, latoff)+neutralroll.
    } else {
        set rollang to pid2:update(time:seconds, latoff)+neutralroll.
    }
    
    return rollang.
}


function descending {
    descendcontrol().
    set steeringManager:maxstoppingtime to 0.17.
    set steeringManager:rollts to 1.2.
    set steeringManager:pitchts to 1.2.
    set descend to 1.
    set engnum to 3.
    wait 0.01.
    lock steering to heading(90,pitchang,rollang).
    altitudecalc(engnum).
    until altit < altitudecalc(engnum) + 200 and altit < 2000 {
        printing().
        pitchpid().
        rollpid().
        altitudecalc(engnum).
    }
}

function landing {
    set teststatus to "Landing burn starting, T+: " + round(testtime,1) + " Seconds".
    set steeringManager:maxstoppingtime to 0.3.
    eng3:activate.
    set lockstatus to 0.
    hingeslock().
    set reentered to 0.
    set now1 to time:seconds.
    lock ti1 to time:seconds - now1.
    set afthingesang to -75.
    hingesmove().
    set topvector to ship:facing:vector.
    lock steering to lookdirup(-ship:velocity:surface,topvector).
    lock throttle to min(0.8, ti1/1).
    wait 0.2.
    eng2:activate.
    wait 0.2.
    eng1:activate.
    set tophingerightang to 15.
    set tophingeleftang to 15.
    hingesmove().
    until vang(ship:facing:vector, -ship:velocity:surface) < 15 {
        printing().
    }

    set aoa to -5.
    set tophingerightang to -35.
    set tophingeleftang to -35.
    set afthingesang to -35.
    hingesmove().
    lock steering to Steer().
    set teststatus to "All sea level engines are lit, T+: " + round(testtime,1) + " Seconds".
    set engnum to 1.
    altitudecalc(engnum).
    until altit < altitudecalc(engnum) and altit > altitudecalc(engnum) - 30 {
        printing().
        altitudecalc(engnum).
    }

    eng3:shutdown.
    wait 0.2.
    eng2:shutdown.
    thrustcalc().
    set landingburn to 1.
    lock throttle to thrustcalc().
    set teststatus to "1 Raptor engines is lit, T+: " + round(testtime,1) + " Seconds".
    until altit < 30 {
        printing().
        altitudecalc(engnum).
        thrustcalc().
    }

    set topvector to ship:facing:vector.
    lock steering to lookdirup(-ship:velocity:surface,topvector).  
    set teststatus to "Cancelling horizontal velocity, T+: " + round(testtime,1) + " Seconds".
    until vang(up:vector, -ship:velocity:surface)<4 {
        printing().
        altitudecalc(engnum).
        thrustcalc().
    }
    set topvector to ship:facing:vector.
    lock steering to lookdirup(up:vector,topvector). 
    until ship:verticalspeed > -1 and ship:verticalspeed < 1 {
        printing().
        altitudecalc(engnum).
        thrustcalc().
    }

    set now1 to time:seconds.
    lock ti1 to time:seconds - now1.
    lock throttle to max(0.05, 1-(ti1/0.5*1)).
    set landingburn to 0.
    set descend to 0.
    set reentered to 0.
    until ship:status = "Landed" or ship:status = "Splashed" {
        printing().
    }

    set teststatus to "Touchdown confirmed".
    lock throttle to 0.
    eng1:shutdown.
    eng2:shutdown.
    eng3:shutdown.
    wait 0.1.
    unlock steering.
    unlock throttle.
    set lockstatus to 1.
    hingeslock().
    rcs off.
    set ship:control:pilotmainthrottle to 0.
    set teststatus to "Ship has landed".
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
    h3:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", afthingesang).
    h4:getmodule("ModuleRoboticServoHinge"):setfield("Target Angle", afthingesang).
}

function compass {
    parameter vec.
    set east to vcrs(up:vector, north:vector).
    set northCompass to vdot(north:vector, vec).
    set eastCompass to vdot(east, vec).
    return mod(arctan2(eastCompass, northCompass) + 360, 360).
}


function printing {
    clearscreen.
    set altit to alt:radar - h.
    set testtime to time:seconds - now.
    set lngoff to (landingZone:lng - impactpos:lng)*10472.
    set latoff to (landingZone:lat - impactpos:lat)*10472.	
    set velheading to compass(ship:velocity:surface).
    print "Status: " + teststatus.
    print "T+: " + round(testtime,1) + " Seconds".  
    print "Longitude difference: " + round(lngoff,2) + " Meters". 
    print "Latitude difference: " + round(latoff,2) + " Meters". 
    print "Time(KSC): " + time:clock.
    if reentered = 1 {
       print "Targeted pitch is " + round(pitchang,2) + " Degrees".
       print "Targeted roll is " + round(rollang,2) + " Degrees".
    }
    
    if descend = 1 {
        print "Landing Burn Altitude : " + round(altitudecalc(engnum),2) + " Meters".
    }

    if landingburn = 1 {
        set shipthrust to throttle.
        print "Current thrust percentage: " + round(shipthrust*100,2) + "%".
        print "Targeted thrust percentage: " + round(thrustcalc()*100,2) + "%".
    }
 

    print "Press 10 to abort program".
}


function altitudecalc {	
    parameter engnum.
    set maxAccel to (engnum*eng1:possiblethrust / ship:mass) - grav.	
    set LBAlt to ship:verticalspeed^2 / (2 * maxAccel).		
    return abs(LBAlt).
}


function thrustcalc {
    set Thr to altitudecalc(engnum) / altit.
    return Thr.
}


function errorvector {
    set errorvec to Impactpos():position - landingZone:position.
    return errorvec.
}


function Steer {
 set result to -velocity:surface + errorvector().

 if vang(result, -velocity:surface) > aoa
 {
   set result to -velocity:surface:normalized + tan(aoa)*errorvector():normalized.
 }

 return lookdirup(result, topvector).
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