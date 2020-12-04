#!/bin/bash 

#get process ID
pid=$$

# get serial number and site code from command line
serial_number=$1
site_code=$2   

#set required IOS version
required_IOS_version="15.7(3)M4a"  

# get discovered IP address for serial number  
ip_address=`cat discoverred.out | grep " " | grep -i "$serial_number" | cut -f 1 -d " "`

# pre-checks before loading new configuration e.g. router IOS version, but could include modules etc 
automatic_login.exp $ip_address -i -f pre_checks.cmd -pid $pid > dump.dmp 

IOS_version=`cat results.$ip_address.$pid.out | grep Version | cut -f 8 -d " " | cut -f 1 -d ,`
                 
if [ "$IOS_version" != "$required_IOS_version" ]; then
    echo "ERROR - IOS version invalid:"
    echo " Installed: $IOS_version"
    echo " Required:  $required_IOS_version"
    exit
fi
   
echo "OK – IOS version is: $IOS_version as required"
    
# generate configuration
python configuration_generation.py $site_code  
chmod 666 $site_code.ROUTER.cfg  

# scp copy new configuration file to startup-config of router
automatic_scp.exp $ip_address $site_code.ROUTER.cfg "startup-config" -pid $pid > dump.dmp

copied_startup_config_ok=`cat results.$ip_address.$pid.out | grep "100%"`

if [ "$copied_startup_config_ok" = "" ]; then
echo "ERROR - Configuration file copy failed"
exit
fi

echo "Config file copy successful"

# Reload router
automatic_login.exp $ip_address -i -f reload.cmd -pid $pid > dump.dmp

# wait 2 minutes for router to reload
sleep 120

# get new IP address from new configuration
ip_address_from_new_configuration=`cat $site_code.ROUTER.cfg | grep " ip address 10" | cut -f 4 -d " "`

# ping new IP address every 10 seconds until it becomes reachable
ping_ok="no"

while [ $ping_ok = "no" ]
do
    new_ping_ok=""
 new_ping_ok=`ping -c 1 -w 1 $ip_address_from_new_configuration | grep "1 received"`
 if [ "$new_ping_ok" = "" ]; then 
        ping_ok="no"
        echo awaiting router recovery
    else
        ping_ok="yes"
    fi
    sleep 10
done

echo pings to $ip_address_from_new_configuration OK - router has recovered

# collect user-specific login credentials via user interaction 
printf " Enter Username: "
read login_username
                                
login_password=""
printf " Enter Password: "
passchar=""
is_return="no"

until [ $is_return = "yes" ]
do
    stty -echo
    read -n 1 passchar
    stty echo
    printf "*"
    login_password_new=$login_password$passchar
    login_password=$login_password_new
    if [[ $passchar = $cr ]] ; then
        is_return="yes"
    else
        is_return="no"
    fi
done

# login to router using its new IP address, and user-specific login credentials to perform automated testing

automatic_login.exp $ip_address_from_new_configuration $login_username $login_password -f tests.cmd -pid $pid > dump.dmp 

# add code to analyse test results here – not included in this version

