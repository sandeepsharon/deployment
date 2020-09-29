#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
suffix=.war
flag=0
war1=fibi-ntu.war
war2=fibi4_ntu.war
war3=fibi_ntu
war4=fibi-orcid.war
domain_name=fibidev.ntu.edu.sg
files=/opt/tomcat/rollback
list=`ls $files`
webapps=/opt/tomcat/webapps
count=`echo $list | wc -w`
tomcat_shutdown() {
 process=`pstree -apu | grep "[D]java.util" | sed 's/[^0-9]*//g'`
 for j in $process; do kill -9 $j; done
}
war_cut() {
 del=`echo "$i" | sed -e "s/$suffix$//"`
 rm -rf $webapps/$del
 }
 ping() {
 until nc -z 127.0.0.1 8005
 do
  sleep 5
 done
}
if [ $count -ne 0 ]; then
 echo -e "You are about to perform rollback in ${RED}$domain_name${NC}"
 echo "Please wait ......"
 for i in $list;
  do
   if [[ "$i" =~ ^($war1|$war2|$war3|$war4)$ ]]; then
    systemctl stop tomcat > /dev/null 2>&1
    sleep 5
    tomcat_shutdown
    rm -rf $webapps/$i 
    if [ $i == $war2 ]; then
     war_cut
    fi
    if [ $i == $war1 ]; then
     war_cut
    fi
    if [ $i == $war4 ]; then
     war_cut
    fi

    mv $files/$i $webapps
    chown -R tomcat.tomcat $webapps/$i
    echo -e "${GREEN}Rollback of $i done${NC}"
    ((flag++))

   else
    echo -e "${RED}Illegal file $i cannot be rolledback${NC}"
   fi
 sleep 1
 done
  if [ $flag -gt 0 ]; then
   systemctl start tomcat > /dev/null 2>&1
   echo "Please wait for tomcat to startup"
   ping
   echo -e "${GREEN}Tomcat server is up now${NC}"
  fi
while true; do
    sleep 3
    read -p "Do you wish to see application console/live log? [y/n]" yn
    case $yn in
        [Yy]* ) tail -f /opt/tomcat/logs/catalina.out;;
        [Nn]* ) exit;;
        * ) echo -e "${RED}Please answer y or n${NC}";;
    esac
    done
else
 echo -e "${RED}Nothing to Rollback!!!${NC}"
fi
