#!/bin/bash

for i in `./build_list_serverWinDrive.sh | grep -v ERROR`; do 
	DRIVE_LIST="`echo $i | cut -d';' -f3 | sed -e 's/C://g' | sed -e 's/:/ /g'`"
	NAMEDESC="`echo $i | cut -d';' -f1`"
	for Drive in $DRIVE_LIST; do
		../eon_add_service.sh -H ${NAMEDESC} -s Drive_${Drive}_Queue -t WINDOWS_DRIVE_Queue_dom_user8 --arg1 "$Drive:" --arg2 "3" --arg3 "15"
		../eon_add_service.sh -H ${NAMEDESC} -s Drive_${Drive}_Size -t  WINDOWS_DRIVE_Size_dom_user8 --arg1 "$Drive:" --arg2 "85%" --arg3 "98%"
	done
done


