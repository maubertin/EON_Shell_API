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
        echo "$PROGNAME $RELEASE - Build object list from nagiosbp apps."
        echo ""
        echo "Usage: $PROGNAME [ -A | --aaplication Target_Application ]"
        echo ""
        echo "          -h  Show this page"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "    -A  Application"
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
if [ $# -lt 2 ]; then
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
        -A | --application)
                shift
                APPS=$1
                ;;                                      
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

ARGS_WEB="detail=${APPS}&conf=nagios-bp&tree=none&outformat=json"

JSON_APPS="`/srv/eyesofnetwork/nagiosbp/sbin/nagios-bp.cgi ${ARGS_WEB} | cut -d'[' -f2 | cut -d']' -f1 | tr '\n' ';' | awk --field-separator=";      };   },;" '{print $2}' | tr '{' '\n' | sed -e 's: ::g' | grep -v "business_process" | sed -e 's:;::g' | grep "plugin_output" | sed -e 's:\"::g'`"

for Object in `echo $JSON_APPS | sed "s:},:\n:g" | awk --field-separator="service:" '{ print $2}'`; do
    EQUIP="`echo $Object | cut -d'}' -f1 | cut -d',' -f2 | cut -d':' -f2 | sed -e 's: ::g' | sed -e 's:\"::g'`"
    SERV="`echo $Object |  cut -d'}' -f1 | cut -d',' -f1 | cut -d':' -f2 | sed -e 's: ::g' | sed -e 's:\"::g'`"
    echo "$EQUIP:$SERV"
done
