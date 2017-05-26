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
        echo "Usage: $PROGNAME [ -H | --hostname TARGET_HOSTNAME ] | [ -s | --servicename SERVICENAME ] [ -t | --servicetemplatename ] [ -d ] [ --arg1 ] [ --arg2 ] [ --arg3 ] [ --arg4 ] [ --arg5 ] | [-h | --help] | [-v | --version]"
        echo ""
        echo "          -h  Show this page"
        echo "          -v  Version"
        echo "          -d  Debug"
        echo "    -H  TARGET_Hostname"
        echo "    -s  ServiceName"
        echo "    -t  ServiceTemplateName"
        echo "    --arg1 ARG1"
        echo "    --arg2 ARG1"
        echo "    --arg3 ARG1"
        echo "    --arg4 ARG1"
        echo "    --arg5 ARG1"
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
if [ $# -lt 6 ]; then
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
        -H | --hostname)
                shift
                HOSTDESC=$1
                ;;
        -s | --servicename)
               shift
               SERVICENAME=$1
               ;;
        -d)
               shift
               DEBUG=1
               ;;
        -t | --servicetemplatename)
               shift
               SERVICETEMPLATE=$1
               ;;
        --arg1)
               shift
               ARG1=$1
               ;;
        --arg2)
               shift
               ARG2=$1
               ;;
        --arg3)
               shift
               ARG3=$1
               ;;
        --arg4)
               shift
               ARG4=$1
               ;;
        --arg5)
               shift
               ARG5=$1
               ;;                                                        
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

if [ -n "$ARG1" ]; then ARG1="`echo $ARG1 | sed 's/:/%3A/g' | sed 's: :%20:g'`"; fi
if [ -n "$ARG2" ]; then ARG2="`echo $ARG2 | sed 's/:/%3A/g' | sed 's: :%20:g'`"; fi
if [ -n "$ARG3" ]; then ARG3="`echo $ARG3 | sed 's/:/%3A/g' | sed 's: :%20:g'`"; fi
if [ -n "$ARG4" ]; then ARG4="`echo $ARG4 | sed 's/:/%3A/g' | sed 's: :%20:g'`"; fi
if [ -n "$ARG5" ]; then ARG5="`echo $ARG5 | sed 's/:/%3A/g' | sed 's: :%20:g'`"; fi


HOSTID="`echo "SELECT id FROM nagios_host WHERE name='${HOSTDESC}'" | mysql -u${LILACACC} -p${LILACPWD} -N lilac`"
if [ $DEBUG -gt 0 ] ;then echo "Adding to host ${HOSTDES}(id=$HOSTID)"; fi


# To add service to host -> wget --no-check-certificate https://127.0.0.1/lilac/add_service.php?host_id=996 --post-data='request=add_service&service_description=Drive_Z_Queue&display_name=&servmanage%5Bserv_add%5D%5Bserv_id%5D=33&host_manage%5Bparameter%5D='
CHECKSERV="`echo "select id from nagios_service where host='${HOSTID}' AND description='${SERVICENAME}'" | mysql -u${LILACACC} -p${LILACPWD} -N lilac`"
if [ "$CHECKSERV" = "" ]; then
	wget --no-check-certificate https://127.0.0.1/lilac/add_service.php?host_id=${HOSTID} --post-data='request=add_service&service_description='${SERVICENAME}'&display_name=&servmanage%5Bserv_add%5D%5Bserv_id%5D=33&host_manage%5Bparameter%5D=' -o /dev/null -O /tmp/last_add_serv.html
	NEWSERVICEID="`echo "select id from nagios_service where host='${HOSTID}' AND description='${SERVICENAME}'" | mysql -u${LILACACC} -p${LILACPWD} -N lilac`"
else
	echo "Error: This service already exist."
	exit
fi
if [ $DEBUG -gt 0 ] ;then echo "Adding service ${SERVICENAME} to host ${HOSTDES}: ok Service ID is ($NEWSERVICEID)"; fi


# To add template to serv -> wget --no-check-certificate 'https://10.100.12.100/lilac/service.php?id=1409&section=inheritance' --post-data='request=add_template_command&servicemanage%5Btemplate_add%5D%5Btemplate_id%5D=37' -o /tmp/last_declared_serv -O /tmp/last_declared_serv.html
CHECKTEMPLATE="`echo "select id from nagios_service_template WHERE name='${SERVICETEMPLATE}'" | mysql -u${LILACACC} -p${LILACPWD} -N lilac`"
if [ ! "$CHECKTEMPLATE" = "" ]; then
	wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=inheritance --post-data='request=add_template_command&servicemanage%5Btemplate_add%5D%5Btemplate_id%5D='${CHECKTEMPLATE} -o /dev/null -O /tmp/last_add_serv.html
else
	echo "Error: The requested service doesn't exist."
	exit
fi
if [ $DEBUG -gt 0 ] ;then echo "Adding service template ${SERVICETEMPLATE} (id:${CHECKTEMPLATE}) to service ${SERVICENAME}."; fi

#  To ADD ARG1 to serv -> wget --no-check-certificate 'https://${EONSRV}/lilac/service.php?id=${NEWSERVICEID}&section=checkcommand' --post-data='request=command_parameter_add&service_manage%5Bparameter%5D=${ARG1}' -o /dev/null -O /tmp/last_declared_serv.html
if [ ! "$ARG1" = "" ]; then
  wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=checkcommand --post-data='request=command_parameter_add&service_manage%5Bparameter%5D='${ARG1} -o /dev/null -O /tmp/last_add_serv.html
  if [ $DEBUG -gt 0 ] ;then echo "Adding arg1: ${ARG1} to service ${SERVICENAME} on host ${HOSTNAME}."; fi
fi
if [ ! "$ARG2" = "" ]; then
  wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=checkcommand --post-data='request=command_parameter_add&service_manage%5Bparameter%5D='${ARG2} -o /dev/null -O /tmp/last_add_serv.html
  if [ $DEBUG -gt 0 ] ;then echo "Adding arg1: ${ARG2} to service ${SERVICENAME} on host ${HOSTNAME}."; fi
fi
if [ ! "$ARG3" = "" ]; then
  wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=checkcommand --post-data='request=command_parameter_add&service_manage%5Bparameter%5D='${ARG3} -o /dev/null -O /tmp/last_add_serv.html
  if [ $DEBUG -gt 0 ] ;then echo "Adding arg1: ${ARG3} to service ${SERVICENAME} on host ${HOSTNAME}."; fi
fi
if [ ! "$ARG4" = "" ]; then
  wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=checkcommand --post-data='request=command_parameter_add&service_manage%5Bparameter%5D='${ARG4} -o /dev/null -O /tmp/last_add_serv.html
  if [ $DEBUG -gt 0 ] ;then echo "Adding arg1: ${ARG4} to service ${SERVICENAME} on host ${HOSTNAME}."; fi
fi
if [ ! "$ARG5" = "" ]; then
  wget --no-check-certificate https://127.0.0.1/lilac/service.php?id=${NEWSERVICEID}\&section=checkcommand --post-data='request=command_parameter_add&service_manage%5Bparameter%5D='${ARG5} -o /dev/null -O /tmp/last_add_serv.html
  if [ $DEBUG -gt 0 ] ;then echo "Adding arg1: ${ARG5} to service ${SERVICENAME} on host ${HOSTNAME}."; fi
fi
