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
        echo "Usage: $PROGNAME [ -A | --aplication Target_Application ]"
        echo ""
        echo "          -h  Show this page"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "    -A  Application"
        echo "    -O  Author :)"
        echo "    -C  Comment"
        echo "    -D  Duration in second from now."        
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
        -A | --application)
                shift
                APPS=$1
                ;;
        -O | --author)
                shift
                AUTHORDT=$1
                ;;  
        -C | --comment)
                shift
                COMMENT=$1
                ;;  
        -D | --duration)
                shift
                DURATION=$1
                ;;                                      
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

OBJECT_LIST="`./Build_Apps_Object_list.sh -A $APPS`"

for Object in $OBJECT_LIST; do
  PARAM1="`echo $Object | cut -d':' -f1`"
  PARAM2="`echo $Object | cut -d':' -f2`"
  
  if [ "$PARAM2" == "Hoststatus" ]; then
    echo "Downtime host -> $PARAM1"
    ./downtime_manual.sh downtime_host $PARAM1 $DURATION "$AUTHORDT" "$COMMENT"
  else
    echo "Downtime service -> $PARAM1($PARAM2)"
    ./downtime_manual.sh downtime_service $PARAM1 $DURATION "$AUTHORDT" "$COMMENT" $PARAM2
  fi
done
