#!/bin/bash

LANG="en_us_8859_1"

if [ ! -n "$3" ];then
	echo "usage: downtime_manual.sh downtime_type hostname duration author comment [service]"
	echo "downtime_type can be:"
	echo "downtime_host"
	echo "downtime_service"
	echo "downtime_hostgroup"
	echo "downtime_servicegroup"
	exit
fi

# variables
downtime_type=$1
hostname=$2
duration=$3
author="`echo $4 | sed 's:_: :g'`"
comment="`echo $5 | sed 's:_: :g'`"
service=$6

echocmd="/bin/echo"
CommandFile="/srv/eyesofnetwork/nagios/var/log/rw/nagios.cmd"
datetime=`date +%s`
end_time=`echo $(($datetime+$duration))`

# create the command line to add to the command file
case $downtime_type in
"downtime_host")
	cmdline="[$datetime] SCHEDULE_HOST_DOWNTIME;$hostname;$datetime;$end_time;1;0;0;${author};${comment}"
	;;
"downtime_service")
	cmdline="[$datetime] SCHEDULE_SVC_DOWNTIME;$hostname;$service;$datetime;$end_time;1;0;0;${author};${comment}"
	;;
"downtime_hostgroup")
	cmdline="[$datetime] SCHEDULE_HOSTGROUP_HOST_DOWNTIME;$hostname;$datetime;$end_time;1;0;0;${author};${comment}"
	;;
"downtime_servicegroup")
	cmdline="[$datetime] SCHEDULE_SERVICEGROUP_SVC_DOWNTIME;$hostname;$datetime;$end_time;1;0;0;${author};${comment}"
	;;
*)
	cmdline=""
	;;
esac

# append the command to the end of the command file
`$echocmd $cmdline >> $CommandFile`
