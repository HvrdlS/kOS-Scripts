clearscreen.
set n to time:seconds-missiontime.
lock testtime to time:seconds-n.
set h to 14.   
set teststatus to "SECO-1, dumping fuel T+: " + round(testtime,1) + " Seconds".
coast().
run ift5reentry.

function coast {
    set fte to ship:partstagged("fte").  /// fuel dump parts
    fte[0]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    fte[1]:getmodule("ModuleResourceDrain"):doaction("drain",true).
    ag6 off.
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
    set ship:control:pilotmainthrottle to 0.
    set steeringManager:maxstoppingtime to 0.005.
    unlock throttle.
    lock steering to lookdirup(north:vector,up:vector).
    when ship:liquidfuel <= 900 then {
        fte[0]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
        fte[1]:getmodule("ModuleResourceDrain"):doaction("stop draining",true).
        set rs5 to true.  /// header tanks resources enable
        set rs6 to true.
        set rs7 to true.
        set rs8 to true.
        set teststatus to "Fuel from main tanks is dumped, enabling header tanks T+: " + round(testtime,1) + " Seconds".
        ag6 on.
    }

    set teststatus to "Awaiting for fuel to dump, T+: " + round(testtime,1) + " Seconds".
    until ship:liquidfuel <= 900 {
        printing().
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