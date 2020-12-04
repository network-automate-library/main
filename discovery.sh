#!/bin/bash  

# set snmp community string used on routers using initial configuration  
snmp_string="<initial_community_string>"  

# delete temporary results file
rm discoverred.tmp       

# ping each of the IP addresses in initial_ip_addresses.in
cat initial_ip_addresses.in | while read ip_address  
do

  serial_number=""   
  ping_ok=""         
  
  ping_ok=`ping -c 1 -w 1 $ip_address | grep "1 received"`  

  # if ping is successful get router’s serial number via SNMP
  if [ "$ping_ok" != "" ]; then  

    serial_number=`snmpwalk -v2c -c $snmp_string $ip_address .iso.3.6.1.4.1.9.3.6.3 | cut -f 2 -d "\""`

  fi  
  
  # save result to temporary file      
  echo $ip_address $serial_number >> discoverred.tmp  
        
done  

#create results file
cat discoverred.tmp | sort -u > discoverred.out  

