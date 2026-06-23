clearscreen.
on ag10 {
    abortflight().
}

prep().
fuel().
countdown().
flight().


function inflightvars {
   set altit to alt:radar-h.
   if sep = 1 {
      set gravityturn to 90-(((ship:apoapsis/(TargetAp-20000))^0.9)*90).
   } else {
      set gravityturn to 90-((((ship:apoapsis/TargetAp))^0.8)*90).
   }

   if ship:maxthrust > 0 {
      set twr to ship:mass * g / ship:availablethrust.
    } else if ship:maxthrust = 0 {
      set twr to 0.
    } 
}


function printing {
    clearscreen.
    if ship:status = "Preflight" or ship:verticalspeed < 1 or altit >= h - 1 or altit <= h + 1{
        print "Time from test beginning: " + round(testtime,1) + " Seconds".
        if ti >= 0 {
            print "T-: " + round(ti,1) + " Seconds".
            set ti to (now1 - time:seconds)+10.
        } 
    } else {
        print "T+: " + round(testtime,1) + " Seconds".
    }
    
    print "Status: " + teststatus.
    print "Target apoapsis: " + TargetAp + " Meters".
    print "Target periapsis: " + TargetPe + " Meters".
    print "Azimuth: " + Azimuth.
    print "Time(KSC): " + time:clock.
    print "Press 10 to abort program".
}


function prep {
    ag1 on. // LOX vents on Booster off, Header Tank vents on Ship off.
    ag2 on. // CH4 vents on Ship and Booster off.
    ag3 on. // Engine chill vents on Booster off.
    ag4 on. // 3 engine chill vents on Ship off.
    ag6 on. // Ship and Booster LOX dump vent off.
    lights on.
    set teststatus to "Software preparations".
    set liftoff to 0.
    set TargetAp to 106500.
    set TargetPe to 5000.
    set Azimuth to 115.
    set FinalAzimuth to 90.
    set landingZone to 160.
    set PitchKickAlt to 500.
    set ThrDownAlt to 1600.
    set ThrDownalt2 to 25000.
    set MECOAlt to 33500.
    set EngineChillAlt to 14000.
    set h to alt:radar.
    set sep to 0.
    set g to body:mu / body:radius^2.

    set sec to 20.
    set minut to 42.
    set hour to 4.
    set clock to "04:42:20".
    set now1 to time:seconds + ((hour-time:hour)*60+minut-time:minute)*60+(sec-time:second).
    set ti to (now1 - time:seconds)+10.


    set fte to ship:partstagged("fte").
    set ring to ship:partstagged("ring")[0].
    set bt to ship:partstagged("bts")[0].
    set waterdeluge to ship:partstagged("waterdeluge")[0].
    set OLM to ship:partstagged("OLM")[0].
    set SQD to ship:partstagged("SQD")[0].
    set tower to ship:partstagged("Tower")[0].


    set rb1 to bt:resources.
    set rb2 to rb1[0].
    set rb3 to rb1[1].
    set rb2:enabled to true.
    set rb3:enabled to true.
    set hts to ship:partsnamed("externalTankRound").
    set rs1 to hts[0].
    set rs2 to hts[1].
    set rs3 to rs1:resources.
    set rs4 to rs2:resources.
    set rs5 to rs3[0].
    set rs6 to rs3[1].
    set rs7 to rs4[0].
    set rs8 to rs4[1].
    set rs5:enabled to true.
    set rs6:enabled to true.
    set rs7:enabled to true.
    set rs8:enabled to true.


    set eng1 to ship:partstagged("VectorS1")[0].
    set eng2 to ship:partstagged("VectorS2")[0].
    set eng3 to ship:partstagged("VectorS3")[0].
    set eng4 to ship:partstagged("VectorVac1")[0].
    set eng5 to ship:partstagged("VectorVac2")[0].
    set eng6 to ship:partstagged("VectorVac3")[0].
    set engList to list().
    set i to -1.
    until i >= 32 {
        set i to i + 1.
        engList:add(ship:partstagged("Vector" + i)[0]).
    }

    for eng in engList { eng:shutdown. }
    set steeringManager:maxstoppingtime to 0.05.
    inflightvars().
    set now to time:seconds.
    lock testtime to time:seconds - now.
    set teststatus to "Beginning fueling, time from beginning: " + round(testtime,1) + " Seconds".
}

function fuel {
    ag1 off. // LOX vents on Booster on, Header Tank vents on Ship on. 
    ag2 off. // CH4 vents on Ship and Booster on.
    Tower:getmodule("ModuleEnginesFX"):doevent("activate engine").
    until ag9 {
        printing().
    }

    set rb2:enabled to false.
    set rb3:enabled to false.
    set rs5:enabled to false.
    set rs6:enabled to false.
    set rs7:enabled to false.
    set rs8:enabled to false.
    set teststatus to "Fueling finished, preparing for flight, time from beginning: " + round(testtime,1) + " Seconds".
    Tower:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    SQD:getmodule("ModuleSLESEquentialAnimate"):doevent("full retraction").
    ag3 off. // Engine chill vents on Booster on.
    until ag9 {
        printing().
    }

    toggle ag9.
}


function countdown {
    set rclock to time:clock.
    until rclock >= clock and rclock <= clock {
        printing().
        set rclock to time:clock.
    }

    ag1 on.
    ag2 on.
    waterdeluge:getmodule("ModuleEnginesFX"):doevent("Activate Engine").
    OLM:getmodule("ModuleEnginesFX"):doevent("Activate Engine").
    set topv to ship:facing:topvector.
    lock steering to lookdirup(up:vector,topv).
    set teststatus to "Countdown initiated, T-: " + round(ti,1) + " Seconds".
    until ti <= 2 {
        printing().
    }

    set teststatus to "Ignition sequence initiated, T-: " + round(ti,1) + " Seconds".
    lock throttle to 0.05.
    set n to time:seconds.
    lock ti1 to time:seconds-n.
    lock throttle to min(0.75, ti1/1.5).
    ship:partstagged("Vector0")[0]:activate.
    ship:partstagged("Vector1")[0]:activate.
    ship:partstagged("Vector2")[0]:activate.
    ship:partstagged("Vector3")[0]:activate.
    ship:partstagged("Vector4")[0]:activate.
    ship:partstagged("Vector5")[0]:activate.
    ship:partstagged("Vector6")[0]:activate.
    ship:partstagged("Vector7")[0]:activate.
    ship:partstagged("Vector8")[0]:activate.
    ship:partstagged("Vector9")[0]:activate.
    ship:partstagged("Vector10")[0]:activate.
    ship:partstagged("Vector11")[0]:activate.
    ship:partstagged("Vector12")[0]:activate.
    set now2 to time:seconds.
    lock ti2 to time:seconds - now2.
    until ti2 > 1 {
        printing().
    }

    ship:partstagged("Vector13")[0]:activate.
    ship:partstagged("Vector15")[0]:activate.
    ship:partstagged("Vector16")[0]:activate.
    ship:partstagged("Vector17")[0]:activate.
    ship:partstagged("Vector19")[0]:activate.
    ship:partstagged("Vector20")[0]:activate.
    ship:partstagged("Vector21")[0]:activate.
    ship:partstagged("Vector23")[0]:activate.
    ship:partstagged("Vector24")[0]:activate.
    ship:partstagged("Vector25")[0]:activate.
    ship:partstagged("Vector27")[0]:activate.
    ship:partstagged("Vector28")[0]:activate.
    ship:partstagged("Vector29")[0]:activate.
    ship:partstagged("Vector31")[0]:activate.
    ship:partstagged("Vector32")[0]:activate.
    set now2 to time:seconds.
    lock ti2 to time:seconds - now2.
    until ti2 > 1 {
        printing().
    }

    set ti to 0.
    ship:partstagged("Vector14")[0]:activate.
    ship:partstagged("Vector18")[0]:activate.
    ship:partstagged("Vector22")[0]:activate.
    ship:partstagged("Vector26")[0]:activate.
    ship:partstagged("Vector30")[0]:activate.
    set now to time:seconds.
    lock testtime to time:seconds - now.
    set teststatus to "Full Ignition, T+: " + round(testtime,1) + " Seconds".
    set liftoff to 1.
}


function flight {
    until testtime > 1 {
        inflightvars().
        printing().      
    }

    olm:getmodule("ModuleAnimateGeneric"):doaction("toggle clamps + qd", true).
    wait 0.01.
    olm:getmodule("LaunchClamp"):doevent("release clamp").
    lock throttle to 0.7.
    lock steering to heading(52,87).
    until ship:verticalspeed > 1 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector16")[0]:shutdown.
    set teststatus to "Liftoff, T+: " + round(testtime,1) + " Seconds".
    until altit > pitchkickalt {
        inflightvars().
        printing().
    }

    lock steering to heading(Azimuth, gravityturn, 270).
    set teststatus to "Roll and pitch program initiated, T+: " + round(testtime,1) + " Seconds".
    until altit > ThrDownAlt {
        inflightvars().
        printing().
    }

    lock throttle to twr*1.48.
    set teststatus to "Throttle down, T+: " + round(testtime,1) + " Seconds".
    set oldq to ship:q.
    wait 0.1.
    set newq to ship:q.
    until newq < oldq {
        set oldq to ship:q.
        wait 0.1.
        set newq to ship:q.
        inflightvars().
        printing().
    }
    
    set teststatus to "Max-Q, " + round(newq*constant:atmtokpa, 3) + " kPa, " + "T+: " + round(testtime,1) + " Seconds".
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 15 {
        inflightvars().
        printing().
    }

    lock throttle to twr*2.5.
    set teststatus to "Throttle up, T+: " + round(testtime,1) + " Seconds".
    until altit > EngineChillAlt {
        inflightvars().
        printing().
    }

    ag4 off. // 3 engine chill vents on Ship on.
    set teststatus to "Ship Engines Chill, T+: " + round(testtime,1) + " Seconds".
    until altit > ThrDownAlt2 {
        inflightvars().
        printing().
    }

    lock throttle to twr*1.8.
    until altit > MECOAlt {
        inflightvars().
        printing().
    }

    set teststatus to "Shutdown sequence initiating, T+: " + round(testtime,1) + " Seconds".
    set thrott to throttle.
    set n to time:seconds.
    lock ti1 to time:seconds-n.
    lock throttle to max(0.2, thrott-ti1/2).
    ship:partstagged("Vector17")[0]:shutdown.
    ship:partstagged("Vector21")[0]:shutdown.
    ship:partstagged("Vector25")[0]:shutdown.
    ship:partstagged("Vector29")[0]:shutdown.
    ship:partstagged("Vector13")[0]:shutdown.
    until ti1 > 0.25 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector19")[0]:shutdown.
    ship:partstagged("Vector23")[0]:shutdown.
    ship:partstagged("Vector31")[0]:shutdown.
    until ti1 > 0.5 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector15")[0]:shutdown.
    ship:partstagged("Vector24")[0]:shutdown.
    ship:partstagged("Vector28")[0]:shutdown.
    ship:partstagged("Vector27")[0]:shutdown.
    until ti1 > 0.75 {
        inflightvars().
        printing().
    }


    ship:partstagged("Vector19")[0]:shutdown.
    ship:partstagged("Vector20")[0]:shutdown.
    ship:partstagged("Vector32")[0]:shutdown.
    until ti1 > 1 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector14")[0]:shutdown.
    ship:partstagged("Vector18")[0]:shutdown.
    ship:partstagged("Vector22")[0]:shutdown.
    ship:partstagged("Vector26")[0]:shutdown.
    ship:partstagged("Vector30")[0]:shutdown.
    until ti1 > 1.25 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector10")[0]:shutdown.
    ship:partstagged("Vector12")[0]:shutdown.
    ship:partstagged("Vector8")[0]:shutdown.
    ship:partstagged("Vector6")[0]:shutdown.
    ship:partstagged("Vector4")[0]:shutdown.
    until ti1 > 1.5 {
        inflightvars().
        printing().
    }

    ship:partstagged("Vector3")[0]:shutdown.
    ship:partstagged("Vector5")[0]:shutdown.
    ship:partstagged("Vector7")[0]:shutdown.
    ship:partstagged("Vector9")[0]:shutdown.
    ship:partstagged("Vector11")[0]:shutdown.
    lock throttle to 1.
    set ship:partstagged("Vector0")[0]:thrustlimit to 50.
    set ship:partstagged("Vector1")[0]:thrustlimit to 50.
    set ship:partstagged("Vector2")[0]:thrustlimit to 50.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 4 {
        inflightvars().
        printing().
    }

    set teststatus to "Vacuum engines are ignited, T+: " + round(testtime,1) + " Seconds".
    set vacthr to 5.
    set eng4:thrustlimit to vacthr.
    set eng4:thrustlimit to vacthr.
    set eng4:thrustlimit to vacthr.
    eng4:activate.
    wait 0.05.
    eng5:activate.
    wait 0.05.
    eng6:activate.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 1 {
        inflightvars().
        printing().
        set vacthr to min(1, ti1/1).
    }

    set teststatus to "Sea level engines are ignited, separation, T+: " + round(testtime,1) + " Seconds".
    set sthr to 5.
    set eng1:thrustlimit to sthr.
    set eng2:thrustlimit to sthr.
    set eng3:thrustlimit to sthr.
    eng1:activate.
    wait 0.05.
    eng2:activate.
    wait 0.05.
    eng3:activate.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    set sthr to min(1, ti1/1).
    ring:getmodule("ModuleDecouple"):doevent("decouple").
    lock steering to heading(FinalAzimuth, gravityturn, 270).
    set sep to 1.
    rcs on.
    until ti1 > 1 {
        inflightvars().
        printing().
        set eng1:thrustlimit to sthr.
        set eng2:thrustlimit to sthr.
        set eng3:thrustlimit to sthr.
        set sthr to min(1, ti1/1).
    }

    set teststatus to "All six engines are on full power, T+: " + round(testtime,1) + " Seconds".
    set eng1:thrustlimit to 100.
    set eng2:thrustlimit to 100.
    set eng3:thrustlimit to 100.
    set eng4:thrustlimit to 100.
    set eng5:thrustlimit to 100.
    set eng6:thrustlimit to 100.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 10 {
        inflightvars().
        printing().
    }

    lock throttle to 1.3*twr.
    set teststatus to "Throttle down of all engines, T+: " + round(testtime,1) + " Seconds".
    until ship:periapsis > -40000 {
        inflightvars().
        printing().
    }

    set teststatus to "Periapsis starts to rise, vacuum engines shutdown, T+: " + round(testtime,1) + " Seconds".
    eng4:shutdown.
    wait 0.05.
    eng5:shutdown.
    wait 0.05.
    eng6:shutdown.
    lock throttle to 0.5*twr.
    until impactpos():lng > landingZone - 3 and impactpos():lng < landingZone + 3 {
        inflightvars().
        printing().
    }

    eng1:shutdown.
    wait 0.1.
    eng2:shutdown.
    wait 0.1.
    eng3:shutdown.
    set teststatus to "SECO-1, dumping fuel, starting experiments, T+: " + round(testtime,1) + " Seconds".
    set ship:control:fore to -1.
    lock throttle to 0.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 1 {
        inflightvars().
        printing().
    }

    set ship:control:fore to 0.
    unlock throttle.
    unlock steering.
    run ift4coast.
}


function impactpos {
    if addons:tr:hasimpact { 
    return addons:tr:impactpos.
  } else {
    return ship:geoposition.
  }
}

function detanking {
    print "Test status: " + teststatus.
    SQD:getmodule("ModuleSLESEquentialAnimate"):doevent("full extension").
    fte:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
    ag3 on.
    ag1 off.
    ag2 off.
    ag6 off. // Ship and Booster dump vents on.
    Tower:getmodule("ModuleEnginesFX"):doevent("activate engine").
    waterdeluge:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    OLM:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    for eng in engList { eng:shutdown. }
    eng1:shutdown.
    eng2:shutdown.
    eng3:shutdown.
    eng4:shutdown.
    eng5:shutdown.
    eng6:shutdown.
    wait 1.
    toggle ag9.
    set teststatus  to "Detanking, T+ " + testtime + " Seconds".
    until ship:liquidfuel < 200 and ship:oxidizer < 200 {
        printing().
    }

    set teststatus to "Vehicle has been detanked, T+: " + round(testtime,1) + " Seconds".
    Tower:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    SQD:getmodule("ModuleSLESEquentialAnimate"):doevent("full retraction").
    ag1 on.
    ag2 on.
    ag6 on.
}


function abortflight {
    set teststatus to "Abort, T+: " + round(testtime,1) + " Seconds".
    if liftoff = 1 {
        ag7 on. // FTS on Booster.
        ag8 on. // FTS on Ship.
    } else if liftoff = 0 and ship:availablethrust > 0 {
        set n to time:seconds.
        lock ti1 to time:seconds - n.
        set thr to throttle.
        lock throttle to max(0, thr-(ti1/2*thr)).
        ship:partstagged("Vector16")[0]:shutdown.
        ship:partstagged("Vector18")[0]:shutdown.
        ship:partstagged("Vector20")[0]:shutdown.
        ship:partstagged("Vector24")[0]:shutdown.
        ship:partstagged("Vector26")[0]:shutdown.
        ship:partstagged("Vector28")[0]:shutdown.
        ship:partstagged("Vector32")[0]:shutdown.
        wait 0.5.
        ship:partstagged("Vector14")[0]:shutdown.
        ship:partstagged("Vector22")[0]:shutdown.
        ship:partstagged("Vector30")[0]:shutdown.
        wait 0.3.
        ship:partstagged("Vector13")[0]:shutdown.
        ship:partstagged("Vector17")[0]:shutdown.
        ship:partstagged("Vector21")[0]:shutdown.
        ship:partstagged("Vector25")[0]:shutdown.
        ship:partstagged("Vector29")[0]:shutdown.
        wait 0.4.
        ship:partstagged("Vector15")[0]:shutdown.
        ship:partstagged("Vector19")[0]:shutdown.
        ship:partstagged("Vector23")[0]:shutdown.
        ship:partstagged("Vector27")[0]:shutdown.
        ship:partstagged("Vector31")[0]:shutdown.
        wait 0.4.
        ship:partstagged("Vector4")[0]:shutdown.
        ship:partstagged("Vector6")[0]:shutdown.
        ship:partstagged("Vector8")[0]:shutdown.
        ship:partstagged("Vector10")[0]:shutdown.
        ship:partstagged("Vector12")[0]:shutdown.
        wait 0.2.
        ship:partstagged("Vector3")[0]:shutdown.
        ship:partstagged("Vector5")[0]:shutdown.
        ship:partstagged("Vector7")[0]:shutdown.
        ship:partstagged("Vector9")[0]:shutdown.
        ship:partstagged("Vector11")[0]:shutdown.
        wait 0.2.
        ship:partstagged("Vector0")[0]:shutdown.
        ship:partstagged("Vector1")[0]:shutdown.
        ship:partstagged("Vector2")[0]:shutdown.
        lock throttle to 0.
        set teststatus to "Detanking".
        detanking().
    } else {
        set teststatus to "Abort, T+" + testtime + " Seconds".
        detanking().
    }
}