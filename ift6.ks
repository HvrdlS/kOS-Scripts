clearscreen.
on ag10 {
    abortflight().
}

prep().
fuel().
countdown().
flight().


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


function engnumcheckship {
    set curthrsea to 0.
    activeengineship().
    for eng in shipSeaEngines { set curthrsea to curthrsea + eng:possiblethrust. }
    if testengsea > 0 {
        set currentengnumsea to round(curthrsea/testengsea,0).
    } else {
        set currentengnumsea to 0.
    }

    set curthrvac to 0.
    for eng in shipVacEngines { set curthrvac to curthrvac + eng:possiblethrust. }
    if testengvac > 0 {
        set currentengnumvac to round(curthrvac/testengvac,0).
    } else {
        set currentengnumvac to 0.
    }
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

function activeengineship {
    local i is 0.
    set testengsea to shipSeaEngines[i]:possiblethrust.
    until testengsea > 0 or i = 2 {
        set i to min(2, i + 1).
        set testengsea to shipSeaEngines[i]:possiblethrust.
    }

    set i to 0.
    set testengvac to shipVacEngines[i]:possiblethrust.
    until testengvac > 0 or i = 2 {
        set i to min(2, i + 1).
        set testengvac to shipVacEngines[i]:possiblethrust.
    }

}


function inflightvars {
    set altit to alt:radar-h.  /// altitude 
    set gravityturn to 90-((((ship:apoapsis/TargetAp))^0.78)*90).   /// wrong variable name, actually a pitch formulae
    if sep = 1 { /// if sep 1 twr calculation uses ship`s engines, if not - booster`s
        engnumcheckship().
        if testengsea*currentengnumsea+testengvac*currentengnumvac > 0 {
            set twr to ship:mass * g / (testengsea*currentengnumsea+testengvac*currentengnumvac).
        } else {
           set twr to 0. 
        }
    } else {
        if activeengine() > 0 {
            set twr to ship:mass * g / (activeengine()*engnumcheck()).
        } else {
            set twr to 0.
        }
    }
}


function printing {
    clearscreen.
    if ship:status = "Preflight" or ship:verticalspeed < 2 {
        print "Time from test beginning: " + round(testtime,1) + " Seconds".
        if ti >= 0 {
            print "T-: " + round(ti,1) + " Seconds".
            set ti to now1 - time:seconds.
        } 
    } else {
        print "T+: " + round(testtime,1) + " Seconds".
    }
    
    print "Status: " + teststatus.
    print "Target apoapsis: " + TargetAp + " Meters".
    print "Target periapsis: " + TargetPe + " Meters".
    print "Target velocity: " + round(TargetVel,2) + " M/S".
    print "Target inclination: " + round(TargetInc,3) + " Degrees".
    print "Azimuth: " + round(Azimuth,2).
    print "Time(KSC): " + time:clock.
    print "Press 10 to abort program".
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

function statedetectship {
   if sea = 1   {
       for eng in shipSeaEngines {
            if eng:thrustlimit < 0.1 {
                eng:shutdown.
            }

            if eng:thrustlimit > 0.1 {
                eng:activate.
            }
        }
    }

   if vac = 1 {
       for eng in shipVacEngines {
            if eng:thrustlimit < 0.1 {
                eng:shutdown.
            }

            if eng:thrustlimit > 0.1 {
                eng:activate.
            }
        }
    }
}


function boosterengines {   /// hell part 1
    if ign = 1 {
        for eng in engList { set eng:thrustlimit to 0. }
        set command to time:seconds.
        set commandtime to time:seconds - command.
        until commandtime > 3 {
            set commandtime to time:seconds - command.
            set sealim to (commandtime-0.28)*320.
            if commandtime < 0.29 {
                set sealim to 1.
            }

            for eng in centerEngines { set eng:thrustlimit to sealim. }
            for eng in innerEngines { set eng:thrustlimit to sealim. }

            if commandtime > 1 {
                set ship:partstagged("Vector13")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector14")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector16")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector17")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector18")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector20")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector21")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector22")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector24")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector25")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector26")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector28")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector29")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector30")[0]:thrustlimit to sealim-230.
                set ship:partstagged("Vector32")[0]:thrustlimit to sealim-230.
            }

            if commandtime > 2 {
                set ship:partstagged("Vector15")[0]:thrustlimit to sealim-560.
                set ship:partstagged("Vector19")[0]:thrustlimit to sealim-560.
                set ship:partstagged("Vector23")[0]:thrustlimit to sealim-560.
                set ship:partstagged("Vector27")[0]:thrustlimit to sealim-560.
                set ship:partstagged("Vector31")[0]:thrustlimit to sealim-560.
            }

            printing().
            statedetect().
        }

        for eng in engList { set eng:thrustlimit to 100. }
   } else if ign = 0 {
        if engineabortmode = 0 { 
            for eng in engList { 
                eng:shutdown. 
            }

        } else {
            set command to time:seconds.
            set commandtime to time:seconds - command.
            if sep = 1 {
            printing().
            until commandtime > 2.03 {
                    set commandtime to time:seconds - command.
                    set sealim to 100-commandtime*400.
                    if commandtime < 0.26 {
                        set sealim to sealim.
                        set ship:partstagged("Vector14")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector18")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector22")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector26")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector30")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 0.26 and commandtime < 0.52 {
                        set sealim to sealim+82.
                        set ship:partstagged("Vector32")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 0.52 and commandtime < 0.77 {
                        set sealim to sealim+164.
                        set ship:partstagged("Vector13")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector16")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector20")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector24")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector25")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector28")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector29")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 0.77 and commandtime < 1.02 {
                        set sealim to sealim+248.
                        set ship:partstagged("Vector15")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector17")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector19")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector21")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector27")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector31")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 1.02 and commandtime < 1.27 {
                        set sealim to sealim+330.
                        set ship:partstagged("Vector23")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector12")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector8")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector6")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector4")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 1.27 and commandtime < 1.57 {
                        set sealim to sealim+412.
                        set ship:partstagged("Vector10")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 1.57 and commandtime < 1.77 {
                        set sealim to sealim+496.
                        set ship:partstagged("Vector3")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector5")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector7")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector9")[0]:thrustlimit to sealim.
                        set ship:partstagged("Vector11")[0]:thrustlimit to sealim.
                    }

                    if commandtime > 1.77 and commandtime < 2.02 {
                        set sealim to sealim+580.
                        for eng in centerEngines { set eng:thrustlimit to max(50,sealim). }
                    }
                
                    statedetect().
            }

                for eng in innerEngines { eng:shutdown. }
                for eng in outerEngines { eng:shutdown. }
                for eng in innerEngines { set eng:thrustlimit to 100. }
                for eng in outerEngines { set eng:thrustlimit to 100. }
                for eng in centerEngines { set eng:thrustlimit to 50. }
            } else {
                until commandtime > 0.6 {
                    printing().
                    set commandtime to time:seconds - command.
                    set sealim to 100-commandtime*320.
                    if commandtime > 0.3 {
                        set sealim to 1.
                    }

                    for eng in engList { set eng:thrustlimit to sealim. }
                    statedetect().
                }

                lock throttle to 0.
                wait 0.01.
                for eng in engList { set eng:thrustlimit to 100. }
            }
        }
    }
}


function starshipengines {  // hell part 2
   if ign = 1 {
        for eng in shipSeaEngines { set eng:thrustlimit to 0. }
        for eng in shipVacEngines { set eng:thrustlimit to 0. }
        statedetectship().
        set command to time:seconds.
        set commandtime to time:seconds - command.
        until commandtime > 2.1 {
            printing().
            set commandtime to time:seconds - command.
            set sealim to (commandtime-1)*100.
            set vaclim to commandtime*100. 
            if commandtime < 0.3 { 
                set vaclim to 1.
                set sealim to 0.
            }

            if commandtime > 0.7 and commandtime < 1 {
                set sealim to 1.
            }
    

            set engS3:thrustlimit to sealim.
            set engS2:thrustlimit to sealim.
            set engS1:thrustlimit to sealim.
            set engS4:thrustlimit to vaclim.
            set engS6:thrustlimit to vaclim.
            set engS5:thrustlimit to vaclim.
            statedetectship().
        }

        for eng in shipSeaEngines { set eng:thrustlimit to 100. }
        for eng in shipVacEngines { set eng:thrustlimit to 100. }
        
   } else if ign = 0 {
        if engineabortmode = 0 { 
            for eng in shipSeaEngines { eng:shutdown. }
            for eng in shipVacEngines { eng:shutdown. }
        } else if engineabortmode = 1 {
            set command to time:seconds.
            set commandtime to time:seconds - command.
            until commandtime > 1 {
                printing().
                set commandtime to time:seconds - command.
                if vac = 1 {
                    set vaclim to 100-commandtime*320.
                    if commandtime > 0.3 and commandtime < 0.9 {
                        set vaclim to 1.
                    }

                    for eng in shipVacEngines { set eng:thrustlimit to vaclim. }
                }

                if sea = 1 {
                    set sealim to 100-commandtime*320.
                    if commandtime < 0.9 {
                        set engS1:thrustlimit to max(1,sealim+90).
                        set engS2:thrustlimit to max(1,sealim).
                        set engS3:thrustlimit to max(1,sealim).
                    } else {
                        for eng in shipSeaEngines { set eng:thrustlimit to sealim. }
                    }
                }

                statedetectship().
            }

            if vac = 1 { for eng in shipVacEngines { eng:shutdown. } }
            if sea = 1 { for eng in shipSeaEngines { eng:shutdown. } }
        }
   }
}

function AzimuthCalc {  /// Azimuth calculation based on planet`s rotation and target orbital velocity
  parameter TargetInc.
  local IncInert is arccos(cos(TargetInc)/cos(ship:geoposition:lat)).
  local VelSite is (2*constant:pi*body:radius*cos(ship:geoposition:lat))/body:rotationperiod.
  local VelX is TargetVel*cos(IncInert)-VelSite.
  local VelY is TargetVel*sin(IncInert).
  local AzimuthMath is mod(arctan2(VelX, VelY)+360, 360).
  return mod(AzimuthMath+360,360).
}


function prep {
    ag1 on. // LOX vents on Booster off, Header Tank vents on Ship off.
    ag2 on. // CH4 vents on Ship and Booster off.
    ag3 on. // Engine chill vents on Booster off.
    ag4 on. // 3 engine chill vents on Ship off.
    ag6 on. // Ship and Booster LOX dump vent off.
    ship:partsdubbed("ShipControl")[0]:controlfrom().   /// vehicle`s unique feature of hotstage ring being root part
    lights on.
    set teststatus to "Software preparations".
    set liftoff to 0.
    set TargetAp to 95000. /// Approximate apoapsis value just to target something
    set TargetPe to 75000.  /// Target periapsis just for orbit velocity calculation(used in Azimuth calculation and Vacs cutoff logic)
    set Azimuth to 115.   //dogleg azimuth, will be recalculated after stage separation
    set TargetInc to 0.
    set smja to (TargetPe+body:radius + TargetAp+body:radius) / 2.
    set TargetVel to sqrt(body:mu*((2/(TargetPe+body:radius))-(1/smja))).


    set landingZone to 106.  /// approximate landingzone lng, better undershoot
    set PitchKickAlt to 500.
    set ThrDownAlt to 1700.
    set MECOAlt to 31300.
    set h to alt:radar.   /// vehicle`s height(not accurate as it sits on OLM)
    set sep to 0.  /// separation state
    set g to body:mu / body:radius^2.

    set sec to 0.
    set minut to 45.
    set hour to 0.   /// target launch time, in cause of which script should be runned only after 00:00:00 
    set clock to "00:44:50". /// 10 seconds before
    set now1 to time:seconds + ((hour-time:hour)*60+minut-time:minute)*60+(sec-time:second).
    set ti to (now1 - time:seconds).


    set fte to ship:partstagged("fte").  /// fuel dump parts(2 Starship 2 SH)
    set ring to ship:partstagged("ring")[0].  /// hot stage ring
    set bt to ship:partstagged("bts")[0].  /// booster landing burn tank
    set waterdeluge to ship:partstagged("waterdeluge")[0].  /// water deluge part
    set OLM to ship:partstagged("OLM")[0].   /// OLM part
    set SQD to ship:partstagged("SQD")[0].  /// SQD part
    set tower to ship:partstagged("Tower")[0].   /// Tower Core part

    set doLand to "True". /// True/False
    set firststageCPU to processor("FirstStageMainPC").  /// SH CPU
    firststageCPU:connection:sendmessage(doLand).  /// Command on whether first stage executes land script on separation or not


    set rb1 to bt:resources.  // SH Landing Burn Tank
    set rb2 to rb1[0].
    set rb3 to rb1[1].
    set rb2:enabled to true.
    set rb3:enabled to true.
    set hts to ship:partsnamed("externalTankRound").  // Starship header tanks
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


    set engS1 to ship:partstagged("VectorS1")[0].   /// Starship 6 engines
    set engS2 to ship:partstagged("VectorS2")[0].
    set engS3 to ship:partstagged("VectorS3")[0].
    set engS4 to ship:partstagged("VectorVac1")[0].
    set engS5 to ship:partstagged("VectorVac2")[0].
    set engS6 to ship:partstagged("VectorVac3")[0].
    set engList to list().
    set i to -1.
    until i >= 32 {     //SH Engines management part
        set i to i + 1.
        engList:add(ship:partstagged("Vector" + i)[0]).
    }

    set shipSeaEngines to list().
    set i to 0.
    until i >= 3 {
        set i to i + 1.
        shipSeaEngines:add(ship:partstagged("VectorS" + i)[0]).
    }

    set shipVacEngines to list().
    set i to 0.
    until i >= 3 {
        set i to i + 1.
        shipVacEngines:add(ship:partstagged("VectorVac" + i)[0]).
    }

    set centerEngines to list().
    set i to -1.
    until i >= 2 {
        set i to i + 1.
        centerEngines:add(ship:partstagged("Vector" + i)[0]).
    }

    set innerEngines to list().
    set i to 2.
    until i >= 12 {
        set i to i + 1.
        innerEngines:add(ship:partstagged("Vector" + i)[0]).
    }

    set outerEngines to list().
    set i to 12.
    until i >= 32 {
        set i to i + 1.
        outerEngines:add(ship:partstagged("Vector" + i)[0]).
    }

    for eng in engList { set eng:thrustlimit to 0. }
    set now to time:seconds.
    lock testtime to time:seconds - now.
    set ign to 0.
    set engineabortmode to 0.
    starshipengines().
    boosterengines().
    set steeringManager:maxstoppingtime to 0.05.
    inflightvars().
    set teststatus to "Beginning fueling, time from beginning: " + round(testtime,1) + " Seconds".
}

function fuel {
    ag1 off. // LOX vents on Booster on, Header Tank vents on Ship on. 
    ag2 off. // CH4 vents on Ship and Booster on.
    SQD:getmodule("ModuleSLESEquentialAnimate"):doaction("full extension", true).
    until ag9 {
        printing().
    }

    set rb2:enabled to false.  /// block resources Starship header tanks, SH landing burn tank
    set rb3:enabled to false.
    set rs5:enabled to false.
    set rs6:enabled to false.
    set rs7:enabled to false.
    set rs8:enabled to false.
    set teststatus to "Fueling finished, preparing for flight, time from beginning: " + round(testtime,1) + " Seconds".
    Tower:getmodule("ModuleEnginesFX"):doevent("activate engine").
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
    OLM:getmodule("ModuleEnginesFX"):doevent("Activate Engine").
    Tower:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    set topv to ship:facing:topvector.
    lock steering to lookdirup(up:vector,topv).
    set teststatus to "Countdown initiated, T-: " + round(ti,1) + " Seconds".
    until ti <= 5 {
        printing().
    }

    waterdeluge:getmodule("ModuleEnginesFX"):doaction("Activate Engine", true).
    set teststatus to "Water deluge activated, T-: " + round(ti,1) + " Seconds".
    until ti <= 2 {
        printing().
    }

    set teststatus to "Ignition sequence initiated, T-: " + round(ti,1) + " Seconds".
    set engineabortmode to 1.
    set ign to 1.
    lock throttle to 1.
    boosterengines().
    until ti < 0 {
        printing().
    }

    set now to time:seconds.
    lock testtime to time:seconds - now.
    set teststatus to "Engines Full Power, T+: " + round(testtime,1) + " Seconds".
    set liftoff to 1.
}


function flight {
    until testtime > 0.8 {
        inflightvars().
        printing().      
    }

    olm:getmodule("ModuleAnimateGeneric"):doaction("toggle clamps + qd", true).
    SQD:getmodule("ModuleSLESEquentialAnimate"):doaction("full retraction", true).
    wait 0.2.
    olm:getmodule("LaunchClamp"):doevent("release clamp").
    inflightvars().
    lock throttle to twr*1.3.
    set thrott to throttle.
    lock throttle to thrott.
    lock steering to heading(52,86).  /// heading is hardcoded
    set teststatus to "Liftoff, T+: " + round(testtime,1) + " Seconds".
    until altit > pitchkickalt {
        inflightvars().
        printing().
    }

    set steeringManager:maxstoppingtime to 0.03.
    lock steering to heading(Azimuth, gravityturn, 270).
    set teststatus to "Roll and pitch program initiated, T+: " + round(testtime,1) + " Seconds".
    until altit > ThrDownAlt {
        inflightvars().
        printing().
    }

    lock throttle to twr*1.26.
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

    lock throttle to twr*1.78.
    set teststatus to "Throttle up, T+: " + round(testtime,1) + " Seconds".
    until altit > MECOAlt-3000 {
        inflightvars().
        printing().
    }

    set pitch to 90-vang(up:vector, facing:vector).  /// raises pitch on 10 from actual(realistic)
    lock steering to heading(Azimuth, pitch+10, 270).
    set teststatus to "Pitch raise maneuver, T+: " + round(testtime,1) + " Seconds".
    until altit > MECOAlt {
        inflightvars().
        printing().
    }

    set teststatus to "Shutdown sequence initiating, T+: " + round(testtime,1) + " Seconds".
    set thrott to throttle.
    lock throttle to thrott.
    set ign to 0.
    set sep to 1.
    boosterengines().
    lock throttle to 1.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 4 {
        inflightvars().
        printing().
    }

    rcs on.
    set ign to 1.
    set sea to 1.
    set vac to 1.
    set engineabortmode to 1.
    set teststatus to "Hot-Staging, Starship engines are ignited, T+: " + round(testtime,1) + " Seconds".   
    ring:getmodule("ModuleDecouple"):doevent("decouple").  ///hot stage ring decouples Starship
    wait 0.01.
    starshipengines().
    if TargetInc <= abs(ship:geoposition:lat) {   /// recalculating TargetInc based on current latitutde
        if abs(ship:geoposition:lat) < 0.01 {
        set TargetInc to 0.01.
        } else {
            set TargetInc to abs(ship:geoposition:lat).
        }
    }

    set Azimuth to AzimuthCalc(TargetInc).
    lock steering to heading(Azimuth, gravityturn, 270).
    set teststatus to "All six engines are on full power, T+: " + round(testtime,1) + " Seconds".
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 10 {
        inflightvars().
        printing().
    }

    set teststatus to "Orbit insertion guidance, T+: " + round(testtime,1) + " Seconds".
    set pi1 to pidloop(0.05,0,0.001, 0.4,0.8).
    set pi2 to pidloop(0.005,0,0.001, -25,15).
    set thr to 0.5.
    lock throttle to thr.
    set pitch to 35.
    lock steering to heading(Azimuth, pitch, 270).  
    pid1().     /// not ideal but basic guidance just to get impact trajectory with decent apoapsis 
    lock throttle to 0.5.
    lock steering to heading(Azimuth, gravityturn-6, 270).
    until ship:velocity:orbit:mag > TargetVel-150 {
        inflightvars().
        printing().
    }

    set ign to 0.
    set vac to 1.
    set sea to 0.
    starshipengines().
    set teststatus to "Periapsis starts to rise, vacuum engines shutdown, T+: " + round(testtime,1) + " Seconds".
    set vac to 0.
    for eng in shipVacEngines { set eng:thrustlimit to 100. }
    lock throttle to 0.5*twr.
    until abs(impactpos():lng - landingZone) < 3 {
        inflightvars().
        printing().
    }

    set sea to 1.
    starshipengines().
    set sea to 0.
    for eng in shipSeaEngines { set eng:thrustlimit to 100. }
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
    run ift5coast.
}


function pid1 {
  set targeteta1 to 360.
  set pi1:setpoint to targeteta1.
  set pi2:setpoint to TargetAp.
  until ship:apoapsis > TargetAp {    
    printing().
    set thr to pi1:update(time:seconds,eta:apoapsis).  
    set pitch to pi2:update(time:seconds,ship:apoapsis).  
  }  
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
    fte[0]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    fte[1]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    fte[2]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    fte[3]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    ag3 on.
    ag1 off.
    ag2 off.
    ag6 off. // Ship and Booster dump vents on.
    Tower:getmodule("ModuleEnginesFX"):doevent("activate engine").
    waterdeluge:getmodule("ModuleEnginesFX"):doaction("shutdown engine", true).
    OLM:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    for eng in engList { eng:shutdown. }
    engS1:shutdown.
    engS2:shutdown.
    engS3:shutdown.
    engS4:shutdown.
    engS5:shutdown.
    engS6:shutdown.
    wait 1.
    toggle ag9.
    set teststatus  to "Detanking, T+ " + testtime + " Seconds".
    until ship:liquidfuel < 200 and ship:oxidizer < 200 {
        printing().
    }

    set teststatus to "Vehicle has been detanked, T+: " + round(testtime,1) + " Seconds".
    Tower:getmodule("ModuleEnginesFX"):doevent("shutdown engine").
    SQD:getmodule("ModuleSLESEquentialAnimate"):doaction("full retraction", true).
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
        set ign to 0.
        boosterengines().
        starshipengines().
        lock throttle to 0.
        set teststatus to "Detanking".
        detanking().
    } else {
        set teststatus to "Abort, T+" + testtime + " Seconds".
        detanking().
    }
}