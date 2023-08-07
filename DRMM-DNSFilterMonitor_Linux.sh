#!/bin/bash

if [ "$( docker container inspect -f '{{.State.Status}}' relay1 )" == "running" ] || [ "$( docker container inspect -f '{{.State.Status}}' relay2 )" == "running" ]; then
	echo "Docker container running"
    #echo '<-Start Result->'
    #echo "STATUS=DNSFilter relays OK"
    #echo'<-End Result->'
else
	echo "!! Docker cotainer NOT running"
    echo "<-Start Result->"
    echo "ALERT=DNSFilter relay(s) NOT RUNNING"
    echo "<-End Result->"
fi

#output="$( dig debug.dnsfilter.com TXT +short @127.0.0.1)"
dig debug.dnsfilter.com TXT +short @127.0.0.1 | grep "local_ipv4_address=127.0.0.1" &> /dev/null
if [[ $? == 0 ]]; then
    echo "Received expected result"
    echo "<-Start Result->"
    echo "STATUS=DNSFilter relays OK"
    echo "<-End Result->"
else
    echo "!! Received unexpected result to dig query"
    echo "<-Start Result->"
    echo "ALERT=DNSFilter relay(s) NOT RUNNING"
    echo "<-End Result->"
fi

