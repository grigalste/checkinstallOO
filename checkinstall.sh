#!/bin/bash
#set -x
#clear

# Configuration parameters
	alias ls='ls --color=auto';
	PRODUCT="onlyoffice";
	DIR="/var/www/${PRODUCT}";
	LOG_DIR="/var/log/${PRODUCT}";
	COLOR="";

#Clear varibles on startup
clear_variables() {
	SRV_DAEMON="";
	SVC_DEP="";
	MYSQL="";
	DB_CHECK_HOST="";
	DB_CHECK_NAME="";
	DB_CHECK_USER="";
	DB_CHECK_PWD="";
	DB_TABLES_COUNT="";
}

clear_variables

while [ "$1" != "" ]; do
	if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
		echo -e "${Black}Created by grigalste${Color_Off}";
		echo "Usage: checkinstall.sh [OPTIONS]";
		echo "  -h, --help          Display this help and exit;";
		echo "  --color             Color the output;";
		echo "  --checkdb           Check connecthion to MySQL database.";
		exit 1;
	fi
	if [ "$1" == "--checkdb" ] ; then
		CHECKDB="true";
	fi
	if [ "$1" == "--color" ] ; then
		COLOR="true";
	fi
	shift
done

	if [ "$COLOR" == "true" ] ; then
		# Regular Colors
			Black="\033[0;30m"        # Black
			Red="\033[0;31m"          # Red
			Green="\033[0;32m"        # Green
			BGreen="\033[1;32m"   # Bold Green
			Yellow="\033[0;33m"       # Yellow
			Blue="\033[0;34m"         # Blue
			Purple="\033[0;35m"       # Purple
			Cyan="\033[0;36m"         # Cyan
			White="\033[0;37m"        # White
		# Reset
			Color_Off="\033[0m"       # Text Reset
	else
			Yellow="";
			Red="";
			Green="";
			BGreen="";
			Color_Off="";
	fi

# Not required in this version
	#root_checking () {
	#	if [ ! $( id -u ) -eq 0 ]; then
	#		echo "To perform this action you must be logged in with root rights"
	#		exit 1;
	#	fi
	#}
	#root_checking

command_exists () {
	type "$1" &> /dev/null;
	}

check_daemon() {
	SVC="";
	SVCE="";
	SVC_ERROR="";
	IS_ENABLED="";
	IS_ACTIVE="";
	for SVC in $@
		do
		
		
		#Check Service IS-ENABLE	
			if [[ "$(systemctl is-enabled $SVC.service 2> /dev/null)" == "enabled" ]]; then
			        IS_ENABLED=${Green}$(systemctl is-enabled $SVC.service 2> /dev/null)${Color_Off};
			elif [[ "$(systemctl is-enabled $SVC.service 2> /dev/null)" == "disabled" ]]; then #disabled on centos but service none
				IS_ENABLED=${Red}$(systemctl is-enabled $SVC.service 2>&1 )${Color_Off};
			elif [[ "$(systemctl is-enabled $SVC.service 2> /dev/null)" == "" ]]; then
				IS_ENABLED=${Red}"NOT AVAILABLE"${Color_Off};
	          	fi
	          	
		#Check Service IS-ACTIVE	
			if [[ "$(systemctl is-active $SVC.service 2> /dev/null)" == "active" ]]; then
	                        IS_ACTIVE="${Green}$(systemctl is-active $SVC.service 2> /dev/null)${Color_Off}";
			elif [[ "$(systemctl is-active $SVC.service 2> /dev/null)" != "active" ]]; then #unknown on centos but service none
				IS_ACTIVE="${Red}$(systemctl is-active $SVC.service 2>&1 )${Color_Off}";
	          	fi

		#Show Service status
			echo -e $SVC": is-enabled: "$IS_ENABLED" is-active: "$IS_ACTIVE ;
			if [[ ( "$(systemctl is-enabled $SVC.service 2> /dev/null)" == "enabled" || "$(systemctl is-enabled $SVC.service 2> /dev/null)" == "disabled" ) && ( "$(systemctl is-active $SVC.service 2> /dev/null)" != "active" || "$(systemctl is-active $SVC.service 2> /dev/null)" == "unknown" ) ]] ; then
				SVC_ERROR=$SVC_ERROR" "$SVC;
			fi          	
		done
		
		#Show ERROR Service status
			for SVCE in $SVC_ERROR
				do
					echo " ";
					systemctl status $SVCE.service 2> /dev/null | cat ;
				done	
	}
	
#Header
	echo " ";
	echo -e "${BGreen}### Check Install/Update installation ###${Color_Off}";
	echo " ";
	
#Check OS Type

	if [ -f /etc/os-release ] ; then
		DISTR_NAME=$(cat /etc/os-release | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"');
			echo -e "Operating System: "${Green} $DISTR_NAME ${Color_Off} ;
		DISTR_NAME=$(cat /etc/os-release | grep -w NAME | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]');
		DISTR_VERSION=$(cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]');
		DISTR_CODENAME=$(cat /etc/os-release | grep -w VERSION_CODENAME | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]');
	fi

	if [ -f /etc/altlinux-release ] ; then
		DISTR_ID="altlinux";
		SVC_DEP=(elasticsearch mysqld nginx postgresql rabbitmq redis supervisord);
	elif [ -f /etc/debian_version ] ; then
		DISTR_ID="debian";
		SVC_DEP=(elasticsearch mysql nginx postgresql rabbitmq-server redis-server supervisor);
	elif [ -f /etc/redhat-release ] ; then
		DISTR_ID="redhat";
		SVC_DEP=(elasticsearch mysqld nginx postgresql rabbitmq-server redis supervisord);
	else
		echo "Not supported OS";
		exit 1;
	fi

echo -e "Hostname:${Green} $(hostname) ${Color_Off}";
#echo $DISTR_ID $DISTR_NAME $DISTR_VERSION $DISTR_CODENAME

#Check Depends Version
	echo " "
	echo -e "${Yellow}### Check Depends Version ###${Color_Off}";

	CLI_NAME=(nginx dotnet mono mysql python3 pip node npm certbot snap redis-server psql rabbitmqctl supervisord);

	for CLI in ${CLI_NAME[*]}
		do

		if command_exists $CLI ; then

			case $CLI in

			  nginx)
			    echo NGINX: $(nginx -v 2>&1 | cut -d/ -f2)
			    ;;
    
			  dotnet)
			    echo dotNet: $(dotnet --info 2> /dev/null | grep -w Version  | cut -d: -f2 | tr -d ' ' | tail -n 1)
			    ;;

			  mono)
			    echo MONO: $(mono --version=number 2> /dev/null)
			    ;;

			  mysql)
			    echo MySQL: $(mysql --version 2> /dev/null | cut -d" " -f4);
			    ;;

			  python3)
			    echo $(python3 -V 2> /dev/null);
			    ;;

			  pip)
			    echo $(pip -V 2> /dev/null);
			    echo $(pip list 2> /dev/null | grep Radicale );
			    ;;
    
			  node)
			    echo NodeJS: $(node -v 2> /dev/null);
			    ;;
    
			  npm)
			    echo NPM: $(npm -v 2> /dev/null);
			    ;;
        
			  certbot)
			    echo $(certbot --version);
			    ;;
        
			  snap)
			    echo $(snap --version 2> /dev/null | grep snapd);
			    echo Snapd certbot: $(snap info certbot 2> /dev/null | grep installed | cut -d":" -f2 | cut -d"(" -f1 | tr -d ' ');
			    ;;

			  redis-server)
			    echo Redis: $(redis-server --version 2> /dev/null | cut -d"=" -f2 | cut -d" " -f1);
			    ;;

			  psql)
			    echo PostgreSQL: $(psql -V 2> /dev/null | cut -d" " -f3);
			    ;;

			  rabbitmqctl)
			    echo RabbitMQ: $(rabbitmqctl status 2> /dev/null | grep RabbitMQ |  cut -d"," -f4 | tr -d '"' | tr -d '}');
			    echo Erlang: $(rabbitmqctl status 2> /dev/null | grep erts |  cut -d"(" -f2 | cut -d")" -f1);
			    ;;
			
			  supervisord)
			    echo Supervisord: $(supervisord -v 2> /dev/null);
			    ;;
			    
			  *)
			    echo -e $CLI: ${Red}"NOT AVAILABLE"${Color_Off};
			    ;;
			    
			esac
		else
			echo -e $CLI: ${Red}"NOT AVAILABLE"${Color_Off};
		fi
	done

#Check Package Version Install
	echo " "
	echo -e "${Yellow}### Check Package Version Install ###${Color_Off}";

	if [ $DISTR_ID == redhat ] || [ $DISTR_ID == altlinux ] ; then
		rpm -qa ${PRODUCT}*
		rpm -qa elasticsearch
	echo " "
	echo -e "${Yellow}### Check SELinux Status ###${Color_Off}";	
		if [[ "$(sestatus 2> /dev/null | grep -w "SELinux status" | cut -d":" -f2 | tr -d " ")" == "disabled" ]]; then
			echo -e SELinux Status: ${Green}$(sestatus 2> /dev/null)${Color_Off};
		elif [[ "$(sestatus 2> /dev/null | grep -w "SELinux status" | cut -d":" -f2 | tr -d " ")" == "enabled" ]]; then
			echo -e SELinux Status: ${Red}$(sestatus 2> /dev/null)${Color_Off};
		fi
	fi

	if [ $DISTR_ID == debian ] ; then
		apt list --installed 2> /dev/null | grep "${PRODUCT}"
		apt list --installed 2> /dev/null | grep elasticsearch
	fi

#Check Depends Daemon
	echo " "
	echo -e "${Yellow}### Check Depends Daemon ###${Color_Off}";
	
	check_daemon "${SVC_DEP[*]}"

#Check Service Daemon
	echo " "
	echo -e "${Yellow}### Check Service Daemon ###${Color_Off}";
	
	SRV_DAEMON=(god monoserve monoserveApiSystem ${PRODUCT}AutoCleanUp ${PRODUCT}Backup  ${PRODUCT}ControlPanel ${PRODUCT}Feed ${PRODUCT}Index ${PRODUCT}Jabber ${PRODUCT}MailAggregator ${PRODUCT}MailCleaner ${PRODUCT}MailImap ${PRODUCT}MailWatchdog ${PRODUCT}Notify ${PRODUCT}Radicale ${PRODUCT}SocketIO ${PRODUCT}SsoAuth ${PRODUCT}StorageEncryption ${PRODUCT}StorageMigrate ${PRODUCT}Telegram ${PRODUCT}Thumb ${PRODUCT}ThumbnailBuilder ${PRODUCT}UrlShortener ${PRODUCT}WebDav);
	check_daemon "${SRV_DAEMON[*]}"

#Check DocumentService
	echo " "
	echo -e "${Yellow}### Check DocumentService ###${Color_Off}";
	
	if command_exists supervisord ; then
		supervisorctl status all
	else
		echo -e DocumentService: ${Red}"NOT AVAILABLE"${Color_Off};
	fi
	
	
#Check Old Service Daemon
	echo " "
	echo -e "${Yellow}### Check Old Service Daemon ###${Color_Off}";
	
	if [[ "$(systemctl is-active pm2-${PRODUCT}.service 2> /dev/null)" == "active" ]]; then
                        echo -e Old Service PM2: ${Red}$(systemctl is-active pm2-${PRODUCT}.service 2> /dev/null)${Color_Off};
	elif [[ $(systemctl is-active pm2-${PRODUCT}.service 2> /dev/null) != "active" ]]; then
			echo -e Old Service PM2: ${Green}$(systemctl is-active pm2-${PRODUCT}.service 2> /dev/null)${Color_Off};
	fi
	
#Check NGINX Configurations
	echo " "
	echo -e "${Yellow}### Check NGINX Configurations ###${Color_Off}";
	
	if command_exists nginx ; then
		echo NGINX: $(nginx -t 2>&1 | cut -d":" -f2);
	else
		echo -e "${Red}NGINX not installed ${Color_Off}";
	fi

#Check Folder Permissions
	echo " ";
	echo -e "${Yellow}### Check Folder Permissions ###${Color_Off}";

	if [ -d "${DIR}" ]; then
		if [[ "$(ls -l ${DIR}  | grep " root " | awk '{print $1" "$3" "$9}')" != "" ]]; then
			echo -e "${Red}${DIR}" $(ls -l ${DIR}  | grep " root " | awk '{print $1" "$3" "$9}';)${Color_Off};
		fi
	fi

	if [ -d "${DIR}/Data/" ]; then
		if [[ "$(ls -lR ${DIR}/Data/ | grep " root " | awk '{print $1" "$3" "$9}')" != "" ]]; then
			echo -e "${Red}${DIR}/Data/" $(ls -lR ${DIR}/Data/ | grep " root " | awk '{print $1" "$3" "$9}')${Color_Off};
		fi
	fi
		
	if [ -d "/var/cache/nginx/" ]; then
		if [[ "$(ls -l /var/cache/nginx/ | awk '{print $1" "$3" "$9}' | grep " root ")" != "" ]]; then
			echo -e "${Red}/var/cache/nginx/" $(ls -l /var/cache/nginx/ | awk '{print $1" "$3" "$9}' | grep " root ")${Color_Off};
		fi
	fi
		
	if [ -d "/var/lib/nginx/" ]; then
		if [[ "$(ls -l /var/lib/nginx/ | awk '{print $1" "$3" "$9}' | grep " root ")" != "" ]]; then
			echo -e "${Red}/var/lib/nginx/"	$(ls -l /var/lib/nginx/ | awk '{print $1" "$3" "$9}' | grep " root ")${Color_Off};
		fi
	fi

#Check Repositories
	echo " ";
	echo -e "${Yellow}### Check Repositories ###${Color_Off}";
	
	if [ -d "/etc/apt/sources.list.d/" ]; then
		ls -l /etc/apt/sources.list.d/  | awk '{print $9}';
	elif [ -d "/etc/yum.repos.d/" ]; then	
		ls -l /etc/yum.repos.d/  | awk '{print $9}';
	fi
	
#Check MySQL Connection
mysql_id_connection() {
	echo " ";
	echo -e "${Yellow}### Check MySQL Connection ###${Color_Off}";
	
	CONF=$DIR/WebStudio
	MYSQL=""

	if [ -f "${CONF}/web.connections.config" ]; then
		DB_CHECK_HOST=$(cat $CONF/web.connections.config | grep "default" |  cut -d"=" -f4 | cut -d";" -f1);
		DB_CHECK_NAME=$(cat $CONF/web.connections.config | grep "default" |  cut -d"=" -f5 | cut -d";" -f1);
		DB_CHECK_USER=$(cat $CONF/web.connections.config | grep "default" |  cut -d"=" -f6 | cut -d";" -f1);
		DB_CHECK_PWD=$(cat $CONF/web.connections.config | grep "default" |  cut -d"=" -f7 | cut -d";" -f1);
	fi
}

mysql_check_connection() {
	MYSQL="mysql -h$DB_CHECK_HOST -u$DB_CHECK_USER"
	if [ -n "$DB_CHECK_PWD" ]; then
		MYSQL="$MYSQL -p$DB_CHECK_PWD"
	fi
	$MYSQL -e ";" >/dev/null 2>&1
	ERRCODE=$?
	if [ $ERRCODE -ne 0 ]; then
		$MYSQL -e ";" >/dev/null 2>&1 || { echo -e ${Red}"Connect to MySQL - FAILURE"${Color_Off}; exit 1; }
	fi
	echo -e ${Green}"Connect to MySQL - OK"${Color_Off};

	DB_TABLES_COUNT=$($MYSQL --silent --skip-column-names -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_CHECK_NAME}'");
		if [[ "${DB_TABLES_COUNT}" -ne "0" ]]; then
			echo "Tables count in DataBase $DB_CHECK_NAME: ${DB_TABLES_COUNT}";
		fi
}

	if [ "$CHECKDB" == "true" ] ; then
		mysql_id_connection	
		mysql_check_connection
	fi
	
#Clear varibles in the end
clear_variables
	
