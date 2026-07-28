set MZ to ship:partsdubbed("MZ")[0].
set waterdeluge to ship:partsdubbed("waterdeluge")[0].
set SQD to ship:partstagged("SQD")[0].
set OLM to ship:partstagged("OLM")[0].
set Catch to false.
print "Waiting for command to close arms".
ship:messages:clear().
SQD:getmodule("ModuleSLEAnimate"):doaction("stop qd", true).
wait 1.
SQD:getmodule("ModuleSLESequentialAnimate"):doaction("full retraction", true).
wait 0.1.
SQD:getmodule("ModuleSLESequentialAnimate"):doaction("full extension", true).
wait 0.1.
SQD:getmodule("ModuleSLESequentialAnimate"):doaction("full retraction", true).
until Catch = true {
    print "No messages yet".
    wait until not ship:messages:empty.
    set msg to ship:messages:pop.
    print msg.
    if msg:content = 1 {
        set Catch to true.
        print "GO For catch".
    } else {
        print "No catch".
        shutdown.
    }
}

print "Closing arms".
MZ:getmodule("ModuleSLEController"):doaction("toggle arms", true).
set waterdelugeoff to false.
ship:messages:clear().
until waterdelugeoff = true {
    print "No messages yet".
    wait until not ship:messages:empty.
    set msg to ship:messages:pop.
    print msg.
    if msg:content = "Deluge off" {
        set waterdelugeoff to true.
        print "Deluge off".
    }
}

waterdeluge:getmodule("ModuleEnginesFX"):doaction("activate engine", true).
wait 0.1.
waterdeluge:getmodule("ModuleEnginesFX"):doaction("shutdown engine", true).
wait 0.1.
OLM:getmodule("ModuleEnginesFX"):doaction("shutdown engine", true).