set doLand to true.
core:messages:clear().
until false {
    if ship:mass < 250 and altitude > 25000 {
        break.
    }

    print "No messages yet".
    wait until not core:messages:empty.
    set msg to core:messages:pop.
    print msg.
    if msg:content = "False" { 
        print "No landing".
        set doLand to false.
        shutdown.
    } else if msg:content = "True" {
        set doLand to true.
        wait until ship:mass < 250.
        wait 2.
        break.
    } 
}

print "Go for landing".
wait until ship:mass < 250 and doLand = true.
run ift5booster.