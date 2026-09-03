clearscreen.
unlock all.
set n to time:seconds-missiontime.
lock testtime to time:seconds-n.
set h to 2.5.   
set teststatus to "SECO-1, dumping fuel T+: " + round(testtime,1) + " Seconds".
printing().
coast().
relight().
run ift5reentry.

function coast {
    set fte to ship:partstagged("fte").  /// fuel dump parts
    set separator to ship:partstagged("bananadec")[0].  /// banana separator
    if ship:liquidfuel > 1000 {
        fte[0]:getmodule("ModuleResourceDrain"):doaction("drain",true).
        fte[1]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    }

    separator:getmodule("ModuleAnchoredDecoupler"):doevent("decouple").  /// decouple banana 
    set relightalt to 68750.
    set relightlenght to 4.
    set hts to ship:partsnamed("externalTankRound").   /// header tanks
    set rs1 to hts[0].  /// disable header tanks resources to dump fuel from main tanks
    set rs2 to hts[1].
    set rs3 to rs1:resources.
    set rs4 to rs2:resources.
    set rs5 to rs3[0].
    set rs6 to rs3[1].
    set rs7 to rs4[0].
    set rs8 to rs4[1].
    set rs5 to false.
    set rs6 to false.
    set rs7 to false.
    set rs8 to false.

    set engS1 to ship:partstagged("VectorS1")[0].   /// Starship 6 engines
    set engS2 to ship:partstagged("VectorS2")[0].
    set engS3 to ship:partstagged("VectorS3")[0].
    set engS4 to ship:partstagged("VectorVac1")[0].
    set engS5 to ship:partstagged("VectorVac2")[0].
    set engS6 to ship:partstagged("VectorVac3")[0].
    set sea to 1.
    set vac to 0.
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

    for eng in shipSeaEngines {
        eng:shutdown.
        set eng:thrustlimit to 0.
    }

    for eng in shipVacEngines {
        eng:shutdown.
        set eng:thrustlimit to 0.
    }
    
    set ship:control:pilotmainthrottle to 0.
    set steeringManager:maxstoppingtime to 0.003.
    unlock throttle.
    lock steering to lookdirup(north:vector,up:vector).
    when ship:liquidfuel <= 850 then {
        fte[0]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
        fte[1]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
        set rs5 to true.  /// header tanks resources enable
        set rs6 to true.
        set rs7 to true.
        set rs8 to true.
        set teststatus to "Fuel from main tanks is dumped, enabling header tanks T+: " + round(testtime,1) + " Seconds".
    }

    set teststatus to "Awaiting for fuel to dump, T+: " + round(testtime,1) + " Seconds".
    until altit < 85000 and verticalspeed < 0 {
        printing().
    }
}


function relight {
    set steeringManager:maxstoppingtime to 0.005.
    lock steering to srfprograde.
    until altit < relightalt+5000 and vang(facing:vector, velocity:surface) < 5 {
        printing().
    }

    set t1 to time:seconds+10.
    set ship:control:fore to 1.
    until time:seconds > t1 {
        printing().
    }

    set ship:control:fore to 0.
    until altit < relightalt {
        printing().
    }

    set ign to 1.
    lock throttle to 1.
    set ti1 to time:seconds+relightlenght.
    set ti2 to time:seconds.
    starshipengines().
    set teststatus to "Engine relight, T+: " + round(testtime,1) + " Seconds".
    until time:seconds > ti1 {
        relightupdate().
    }

    set ign to 0.
    starshipengines().
    lock throttle to 0.
    for eng in shipSeaEngines {
        eng:shutdown.
        set eng:thrustlimit to 100.
    }

    for eng in shipVacEngines {
        eng:shutdown.
        set eng:thrustlimit to 100.
    }

    set teststatus to "Engine shutdown, T+: " + round(testtime,1) + " Seconds".
    set ti1 to time:seconds+5.
    until time:seconds > ti1 {
        printing().
    }
}

function relightupdate {
    clearscreen.
    engnumcheckship().
    print "Relight duration: " + round(time:seconds-ti2,1) + " Seconds".
    print "Active sea engines number: " + currentengnumsea.
    print "Active vacuum engines number: " + currentengnumvac.
    print "Active engines thrust: " + round(ship:thrust,1) + " kN".
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


function starshipengines {
   if ign = 1 {
        set command to time:seconds.
        set commandtime to time:seconds - command.
        until commandtime > 1 {
            set commandtime to time:seconds - command.
            printing().
            set sealim to commandtime*320.
            set engS1:thrustlimit to sealim.
            statedetectship().
        }

        set engS1:thrustlimit to 100.   
   } else if ign = 0 {
        if altit < relightalt {
            set command to time:seconds.
            set commandtime to time:seconds - command.
            until commandtime > 1 {
                set commandtime to time:seconds - command.
                printing().
                set sealim to 100-commandtime*320.
                if commandtime > 0.3 and commandtime < 0.9 {
                    set sealim to 1.
                }

                set engS1:thrustlimit to sealim.
                statedetectship().
            }

            set engS1:thrustlimit to 0.
            set engS1:thrustlimit to 0.
            set engS1:thrustlimit to 0.
            statedetectship().

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


function printing {
    clearscreen.
    set altit to alt:radar-h.
    print "Status: " + teststatus.
    print "T+: " + round(testtime,1) + " Seconds".   
    print "Time(KSC): " + time:clock.
    print "Press 10 to abort program".
}