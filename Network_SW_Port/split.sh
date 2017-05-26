#!/bin/bash

echo "" > sw_24.txt
echo "" > sw_12.txt

for ip in `cat ip_list.txt `; do 
	echo -n "Handling $ip..."
	if [ `snmpwalk -v 2c -c changeme $ip 1.3.6.1.2.1.2.2.1.1 | wc -l` -gt 37 ]; then 
		echo $ip >> sw_24.txt 
		echo "OK [24 Port]"
		
	else 
		echo $ip >> sw_12.txt 
		echo "OK [12 Port]"
	fi 
done

