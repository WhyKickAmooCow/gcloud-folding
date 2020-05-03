${ fah ? <<EOF
FAHClient --config=/etc/fahclient/config.xml --send-pause
sleep 15
EOF
: "" }