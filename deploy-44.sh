#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
suffix=.war
sql=all.sql
flag=0
mysql_user=Riseappu
mysql_password='R1$e@ppu-LJUisRhzHQipvxrOVf29'
mysql_host=127.0.0.1
mysql_port=6446
mysql_schema=rise_uat
war1=fibi-ntu.war
war2=fibi4_ntu.war
war3=fibi_ntu
war4=fibi-orcid.war
domain_name=fibiuat.ntu.edu.sg
files=/root/rise_temp
db_scripts=/root/rise_bundle/Release_Bundle_Fibi_RISE/DB_Scripts
db_rollback_scripts=/root/rise_bundle/Release_Bundle_Fibi_RISE/DB_Rollback_Script
backend=/home/arjun.chand/Release_Bundle_Fibi_RISE/Application_File/Backend_for_server_1
frontend=/root/rise_bundle/Release_Bundle_Fibi_RISE/Application_File/Front_end
list=`ls $files`
list_home=`ls $db_scripts`
webapps=/opt/tomcat/webapps
backup_location=/opt/backup
rollback=/opt/backup/rollback
count=`echo $list | wc -w`
current_date=`echo "$(date +"%d-%m-%Y")"`
time=$(date +"%d_%m_%Y-%T:%p")
mysql_function() {
 if mysql -u "$mysql_user" -p"$mysql_password" -h $mysql_host -P $mysql_port $mysql_schema < $db_scripts/$sql ; then
    echo -e "${GREEN}MySQL script execution succeeded${NC}"
else
    echo -e "${RED}Script execution failed. Please contact POLUS${NC}"
    
#    rm -rf $rollback/*
    exit 1
fi
}
getuser() {
  read -p "Enter the MySQL username: " user
  case "$user" in
    $mysql_user)
      sleep 1
      return 0
      ;;
    *)
      echo -e "${RED}INCORRECT USERNAME. Please try again${NC}"
      return 1
      ;;
  esac
}
getpassword() {
  read -p "Enter the password: " pass
  case "$pass" in
    $mysql_password)
      mysql_function
      return 0
      ;;
    *)
      echo -e "${RED}INCORRECT PASSWORD. Please try again${NC}"
      return 1
      ;;
  esac
}

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
rm -rf $files
mkdir -p $files
cp -R $backend/* $files/ 2>/dev/null
cp -R $frontend/* $files/ 2>/dev/null

if [ $count -ne 0 ]; then

 for k in $list;
  do
   if [[ "$k" =~ ^($war1|$war2|$war3|$war4)$ ]]; then
   rm -rf $rollback/*
   fi
  done

 for m in $list_home;
  do
   if [[ "$m" =~ ^($sql)$ ]]; then
   
   cp -R $db_rollback_scripts $rollback/ 2>/dev/null
   echo -e "You are going to execute database scripts in ${RED}$domain_name${NC}"
   until getuser; do : ; done
   until getpassword; do : ; done
   fi
  done 
 echo -e "You are about to perform deployment in ${RED}$domain_name${NC}"
 echo "Please wait ......"
 
 for i in $list;
  do
   if [[ "$i" =~ ^($war1|$war2|$war3|$war4)$ ]]; then
    systemctl stop tomcat > /dev/null 2>&1
    sleep 5
    tomcat_shutdown
    mkdir -p $backup_location/$current_date
    cp -R $webapps/$i $rollback/ 2>/dev/null
    mv $webapps/$i $backup_location/$current_date/${i}_$time
    if [ $i == $war2 ]; then
     war_cut
    fi
    if [ $i == $war1 ]; then
     war_cut
    fi
    if [ $i == $war4 ]; then
     war_cut
    fi

    cp -R $files/$i $webapps 2>/dev/null
    chown -R tomcat.tomcat $webapps/$i
    echo -e "Backup of $i is taken"
    echo -e "${GREEN}Deployment of $i done${NC}"
    ((flag++))

   else
    echo -e "${RED}Illegal file $i cannot be deployed${NC}"
   fi
 sleep 1
 done
  
  rm -rf $files
  if [ $flag -gt 0 ]; then
   systemctl start tomcat > /dev/null 2>&1
   echo "Please wait while Tomcat starts ..........."
   ping
   echo -e "${GREEN}Tomcat server is up now${NC}"
  fi
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
