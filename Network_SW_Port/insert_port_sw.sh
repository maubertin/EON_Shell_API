#!/bin/bash
#!/bin/bash
PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2017 Michael Aubertin (michael.aubertin@gmail.com)"

LILACACC="root"
LILACPWD="root66"

DEBUG=0

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}


print_usage() {
        echo ""
        echo "$PROGNAME $RELEASE - Service add to EON"
        echo ""
        echo "Usage: $PROGNAME [ -F | --file input_file_ip_list ] | [ -P | --port SERVICENAME ] | [ -C | --community SNMPCOM ] | [ -T | --template SERVICE_TEMPLATE ] | [ -S | --suffix ]"
        echo ""
        echo "          -h  Show this page"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "    -F  input_file_ip_list"
        echo "    -P  PortName (ex:GigabitEthernet1/0/23)"
	echo "	  -T  Service Template name"
	echo "	  -S  Suffix name (to add error for exemple)."
  echo ""
}

print_help() {
                print_usage
        echo ""
        print_release $PROGNAME $RELEASE
        echo ""
        echo ""
                exit 0
}

# Make sure the correct number of command line arguments have been supplied
if [ $# -lt 8 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

# Grab the command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -F | --file)
                shift
                INPUTFILE=$1
                ;;
        -P | --port)
               shift
               PORTNAME=$1
               ;;
        -T | --template)
               shift
               SERVICE_TEMPLATE=$1
               ;;
        -S | --sufix_name)
               shift
               SUFIXNAME=$1
               ;;
        -C | --community)
               shift
               SNMPCOM=$1
               ;;
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done


if [ ! -f $INPUTFILE ]; then 
	echo "Input file doesn't exist."
	exit
fi

if [ ! -x /srv/eyesofnetwork/nagios/plugins/check_nwc_health ]; then
	echo "Requiered plugins is missing (check_nwc_health)..."
	exit
fi


for ip in `cat $INPUTFILE | tr ' ' '\n'`; do

	EQUIPMENTNAME="`snmpwalk -v 2c -c $SNMPCOM $ip .1.3.6.1.2.1.1.5.0 | grep "SNMPv2-MIB::sysName.0" | cut -d'=' -f2 | cut -d':' -f2 | cut -d'.' -f1 | tr '\n' ' ' | sed -e 's: ::g'`"	

	if [ ! -n "$EQUIPMENTNAME" ]; then
		echo "The host ($ip) is not responding to SNMP. Could not add a service."
		continue
	fi

	IS_PRESENT="`printf "GET hosts\nColumns: name address\nFilter: address = $ip\n" | /srv/eyesofnetwork/mk-livestatus/bin/unixcat /srv/eyesofnetwork/nagios/var/log/rw/live`"
	if [ ! -n "$IS_PRESENT" ]; then 
		echo "There is no host with ip ($ip) currently configured in EON."
		continue
	fi
	if [ `printf $IS_PRESENT | wc -l` -gt 1 ]; then
		echo "There is several host with the requested ip ($ip). Could not determine where to add new service to check."
		continue
	fi

	NAGIOSEQUIPNAME="`printf $IS_PRESENT | cut -d';' -f1`"

	if [ ! "$EQUIPMENTNAME" == "$NAGIOSEQUIPNAME" ]; then
		echo "The hostname found on equipment ($ip) does'nt fit the equipement name in EON. Could not determine where to add new service to check."
		continue
	fi
	
	INTERFACE="`su - nagios -c "/srv/eyesofnetwork/nagios/plugins/check_nwc_health --t 60 --hostname $ip --community $SNMPCOM --multiline --mode interface-usage --name '$PORTNAME'"`"
	VERIF_INTERFACE="`echo "$INTERFACE" | cut -d'-' -f1 | sed -e 's: ::g'`"

	if [ "$VERIF_INTERFACE" == "UNKNOWN" ]; then
		echo "$PORTNAME doesn't seem to exist on $ip"
		continue
	fi

	INTERFACE_NAME="`echo "$INTERFACE" | cut -d'(' -f2 | cut -d')' -f1 | tr '*' ' ' | sed -e 's:alias::g' | sed -e 's:  ::g' | sed -e 's:^ ::g' | awk --field-separator=" - " '{print $1}' | sed -e 's: $::g' | tr ' ' '_'`"
	echo "I add: the service ${INTERFACE_NAME}${SUFIXNAME} on host $NAGIOSEQUIPNAME whith template $SERVICE_TEMPLATE and arg '$PORTNAME'"
	../eon_add_service.sh -H $NAGIOSEQUIPNAME -s ${INTERFACE_NAME}${SUFIXNAME} -t $SERVICE_TEMPLATE --arg1 "$PORTNAME"
done
