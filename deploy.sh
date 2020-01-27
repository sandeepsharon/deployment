#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
domain_name=fibidev.ntu.edu.sg
files=/root/list
list=`ls /root/list`
webapps=/opt/tomcat/webapps
backup_location=/opt/backup
count=`echo $list | wc -w`
current_date=`echo "$(date +"%d-%m-%Y")"`
#current_time=`echo "$(date +%H:%M:%S:%N)"`
time=$(date +"%d_%m_%Y-%I:%M:%p")
tomcat_shutdown() {
 process=`pstree -apu | grep "[D]java.util" | awk '{print $2}' | cut -c8-`
 for j in $process; do kill -9 $j; done
}
if [ $count -ne 0 ]; then
 echo -e "You are about to perform deployment in ${RED}$domain_name${NC}"
 echo "Please wait ......"
 for i in $list;
  do
   if [[ "$i" =~ ^(fibi_ntu|fibi4_ntu.war)$ ]]; then
    sh /opt/tomcat/bin/shutdown.sh > /dev/null 2>&1
    
    tomcat_shutdown
    mkdir -p $backup_location/$current_date
    rm -rf $backup_location/$current_date/$i    
    mv $webapps/$i $backup_location/$current_date/
    rm -rf $webapps/$i
    cp -R $files/$i $webapps
    chown -R tomcat.tomcat $webapps/$i
    sh /opt/tomcat/bin/startup.sh > /dev/null 2>&1
    echo -e "Backup of $i is taken"
    echo -e "${GREEN}Deployment of $i done${NC}"
   
   else
    echo -e "${RED}Illegal file $i cannot be deployed${NC}"
   fi
 sleep 1
 done
while true; do
    sleep 2
    read -p "Do you wish to see application console/live log? [y/n]" yn
    case $yn in
        [Yy]* ) tail -f /opt/tomcat/logs/catalina.out;;
        [Nn]* ) exit;;
        * ) echo -e "${RED}Please answer y or n${NC}";;
    esac
    done
else
 echo -e "${RED}File Not Found!!!${NC}"
fi
