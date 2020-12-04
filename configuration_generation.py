#Import Libraries used  
import csv      
import os
import string
import sys

#Get Site Code from command line input
site_code_submitted = sys.argv[1]   

#Open Site variables file
with open('SITE_VARIABLES_IN.csv','rb') as SiteVariablesFile:   

    SiteVariablesFileAsCSV = csv.reader(SiteVariablesFile)

    #Index Columns of CSV file 
    site_code_index = 0
    site_name_index = 1
    ppp_username_index = 2
    ppp_password_index = 3
    router_ip_address_index = 4

    #Set variables for submitted site code
    for row in SiteVariablesFileAsCSV:          
        site_code = row[site_code_index]      
        if site_code == site_code_submitted:  
            site_name = row[site_name_index]
            ppp_username = row[ppp_username_index]
            ppp_password = row[ppp_password_index]
            router_ip_address = row[router_ip_address_index]
                        
#Merge variables with template
template = open( 'TEMPLATE.cfg' )        
template_string = string.Template( template.read() )

substitutions={ 'SITE_CODE':site_code, 'SITE_NAME':site_name, 'PPP_USERNAME':ppp_username, 'PPP_PASSWORD':ppp_password, 'ROUTER_IP_ADDRESS':router_ip_address }   
configuration = template_string.substitute(substitutions)  

#Set filename and save configuration  
filename = site_code + '.ROUTER.cfg'   
config_out = open(filename, 'w')      
os.chmod(filename, 0o666)              
config_out.write(configuration)          

sys.exit()             

