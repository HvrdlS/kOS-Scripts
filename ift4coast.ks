clearscreen.
lock testtime to time:seconds - missiontime.
set teststatus to "SECO-1, dumping fuel T+: " + round(testtime,1) + " Seconds".
coast().
run ift4reentry.

function coast {
    set fte to ship:partstagged("fte")[0].
    fte:getmodule("ModuleResourceDrain"):doaction("drain",true).
    ag6 off.
    set hts to ship:partsnamed("externalTankRound").
    set mts to ship:partsdubbed("mts")[0].
    set mts1 to mts:resources[0].
    set mts2 to mts:resources[1].
    set rs1 to hts[0].
    set rs2 to hts[1].
    set rs3 to rs1:resources.
    set rs4 to rs2:resources.
    set rs5 to rs3[0].
    set rs6 to rs3[1].
    set rs7 to rs4[0].
    set rs8 to rs4[1].
    set ship:control:pilotmainthrottle to 0.
    unlock throttle.
    lock steering to ship:velocity:surface.
    when mts1:amount <= 30 and mts2:amount <= 30 then {
        fte:getmodule("ModuleResourceDrain"):doaction("drain",true).
        ag6 on.
    }

    until vang(ship:facing:vector, ship:velocity:surface)<1 {
        printing().
    }

    unlock steering.
    set n to time:seconds.
    lock ti1 to time:seconds - n.
    until ti1 > 3 {
        printing().
    }

    set ship:control:starboard to 0.5.
    until ti1 > 4 {
        printing().
    }

    set ship:control:starboard to 0.
    set teststatus to "Awaiting for fuel to dump, T+: " + round(testtime,1) + " Seconds".
    set ship:control:starboard to 0.
    until mts1:amount <= 30 and mts2:amount <= 30 {
        printing().
    }

    set teststatus to "Fuel from main tanks is dumped, T+: " + round(testtime,1) + " Seconds".
}

function printing {
    clearscreen.
    set altit to alt:radar-h.
    print "Status: " + teststatus.
    print "T+: " + round(testtime,1) + " Seconds".   
    print "Time(KSC): " + time:clock.
    print "Press 10 to abort program".
}