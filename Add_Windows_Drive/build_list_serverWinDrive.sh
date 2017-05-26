#!/bin/bash
PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2017 Michael Aubertin (michael.aubertin@gmail.com)"


DEBUG=0

# Functions plugin usage
print_release() {
    echo "$RELEASE $AUTHOR"
}


print_usage() {
        echo ""
        echo "$PROGNAME $RELEASE - Build list of drive from Windows equipment."
        echo ""
        echo "Usage: $PROGNAME [ -D | --domain domainname ] [ -U | --username Username ] [ -P | --password WMI user password ]"
        echo ""
        echo "          -h  Show this page"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "    -D  domainname"
        echo "    -U  Username"
        echo "    -P  Password"  
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
        -D | --domain)
                shift
                DOMAIN=$1
                ;;
        -U | --username)
                shift
                USERNAME=$1
                ;;  
        -P | --password)
                shift
                PASSWD=$1
                ;;                   
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

SRVLIST="`printf "GET hosts\nColumns: name address groups\n" | /srv/eyesofnetwork/mk-livestatus/bin/unixcat /srv/eyesofnetwork/nagios/var/log/rw/live`"


for server in $SRVLIST; do
	servergroup="`echo $server | cut -d';' -f3`"
	if [ ! "$servergroup" = "WINDOWS" ]; then 
		continue 
	fi
  	servername="`echo $server | cut -d';' -f1`"
  	serverip="`echo $server | cut -d';' -f2`"
	DRIVE_LIST="`/usr/bin/wmic -U ${DOMAIN}/${USERNAME}%${PASSWD} --namespace root/cimv2 //${serverip}  'Select DeviceID from Win32_LogicalDisk where DriveType=3' 2> /dev/null | grep -v "Win32" |grep -v "DeviceID" | grep -v dcerpc_pipe_auth_recv | grep -v dcerpc_connect`"

	echo -n "$servername;$serverip;"
	for i in $DRIVE_LIST; do
		echo -n "$i"
	done
	echo ";"
done
