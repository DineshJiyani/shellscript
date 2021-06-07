#!/bin/bash
#Function for print main menu
mainmenu(){
    echo "==============================================================="
    echo "List of the action"
    echo "==============================================================="
    echo "1. Create local yum repo"
    echo "2. Check for internet connectivity"
    echo "3. Install and enable epel repo"
    echo "4. Install basic tools (net-tools, wget, rsync, mlocate, vim)"
    echo "5. Selinux configuration"
    echo "6. Manage firewall service (disable|enable|start|stop|restart|reload|restore-default)"
    echo "7. Allow / Deny Firewall rules"
    echo "8. Set Hostname"
    echo "9. Make entry in /etc/hosts"
    echo "10. Install Java (OpenJDK)"
    echo "11. Disable / remove postfix"
    echo "12. Print IP, MAC and DNS info"
    echo "13. Configure HTTP / HTTPS proxy"
    echo "14. Configure proxy setting for YUM"
    echo "15. Set custom environment variable in /etc/profile.d"
    echo "16. Set Datetime | Timezone | NTP client"
    echo "17. Install webmin"
    echo "18. Reboot server"
    echo "19. Exit"
    echo "==============================================================="
    
}

#Function for pausescript with break loop
pasusescript(){
        # read -t 5 -n 1 -s -r -p "Press any key to continue" KEYWORD
        read -n 1 -r -s -p "Press any key to continue..."
        # this will fire after the key is pressed
        echo ".."
        break;

    }

#Function for hold script 
holdscript(){
        # read -t 5 -n 1 -s -r -p "Press any key to continue" KEYWORD
        read -n 1 -r -s -p "Press any key to continue..."
        # this will fire after the key is pressed
        echo ".."
        #break;

    }

#Function for creating repo file
localrepo(){
cat <<EOF >/etc/yum.repos.d/My-Local.repo
[LOCAL-REPO]
name=Linux7-Local - Media
baseurl=file:///mnt
gpgcheck=0
enable=1
EOF
}

#Function for create local repo
createlocalrepo(){
    while true; 
    do
        echo "Creating loacal repo"
        echo "Press 1 for using CDROM and 2 for using local ISO image "
        read -p "Choose action 1 or 2: " SRC
        if [ $SRC == '1' ]; then
            mount /dev/sr0 /mnt
            if [ $? -eq 0 ]; then
                touch /etc/yum.repos.d/My-Local.repo
                localrepo
                echo "Local repo successfully created using CDROM"
            else
                echo "Failed to create local repo using CDROM"
            fi    
            pasusescript
           # break    
        elif [ $SRC == '2' ]; then
            read -p "Please enter ISO image path: " ISOPATH
            mount -t iso9660 -o loop $ISOPATH /mnt
            if [ $? -eq 0 ]; then
                touch /etc/yum.repos.d/My-Local.repo
                localrepo
                echo "Local repo successfully created using ISO image"
            else
                echo "Failed to create local repo using ISO image"
            fi
            pasusescript    
           # break     
        else
            echo "Invalid input"
        fi
        
    done
}

#Function for create Check connectivity
checkconnectivity(){
    echo "Checking internet connectivity"
    echo "-----------------------------------------------------------"
    ping -c 4 8.8.8.8
     if [ $? -eq 0 ]; then
        echo
        echo "ping 8.8.8.8 success"
    else
        echo   
        echo "ping 8.8.8.8 fail"
    fi
    #ping -c 2 8.8.8.8 &> /dev/null && echo "ping 8.8.8.8 success" || echo "ping 8.8.8.8 fail"
    echo "-----------------------------------------------------------"
    echo "Checking nslookup (DNS testing)........"
    echo
    #nslookup google.com &> /dev/null && echo "nslookup google.com success" || echo "nslookup google.com fail"
    nslookup google.com
    if [ $? -eq 0 ]; then
        echo "nslookup google.com success"
    else
        echo "nslookup google.com fail"
    fi
    echo "-----------------------------------------------------------"
    holdscript
}

#Function for installation epel repo
epelrepo(){
    PKG=$(rpm -qa | grep epel | wc -l)
    if [ $PKG -gt 0 ]; then
        echo "eple repo is already installed"
    else
        yum search epel-release
        yum info epel-release
        yum install -y epel-release
        echo "eple repo installed and enabled successfully"
    fi
    holdscript
}

#Function for install basic tools
installbasictool(){
    yum install -y net-tools wget rsync mlocate vim bind-utils
    if [ $? -eq 0 ]
    then
        echo "Basic tools intsalled successfully"
    else
        echo "Basic tools installation failed"
    fi
    holdscript    
}

#Function for set selinux mode 
selinuxconfig(){
    while true;
    do
        echo "==================================="
        echo "List of selinux mode"
        echo "==================================="
        echo  "1.Permanently enforcing mode"
        echo  "2.Permanently permissive mode"
        echo  "3.Permanently disabled mode"
        echo  "4.Temporarily enforcing mode"
        echo  "5.Temporarily permissive mode"
        echo "==================================="
       
        read -p "Please enter selinux mode value: " SEMODE
        SESTATUS=$(getenforce)
        case $SEMODE in
            1) 
                sed -i s/^SELINUX=.*$/SELINUX=enforcing/ /etc/selinux/config
                echo "Permanently SELinux enforcing mode set successfully "
                pasusescript
                #break
            ;;
            2) 
                sed -i s/^SELINUX=.*$/SELINUX=permissive/ /etc/selinux/config
                echo "Permanently SELinux permissive mode set successfully "
                pasusescript
                #break
            ;;
            3) 
                sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
                echo "Permanently SELinux disabled mode set successfully "
                pasusescript
               # break
            ;;
            4) 
                if [ $SESTATUS == 'Disabled' ]
                then
                    echo "Current selinux status disabled mode. It's require permissive or enforcing mode" 
                else
                    setenforce 1
                    echo "Temporarily enforcing mode set successfully"
                fi
                pasusescript
                #break
            ;;
            5) 
                if [ $SESTATUS == 'Disabled' ]
                then
                    echo "Current selinux status disabled mode. It's require permissive or enforcing mode" 
                else
                    setenforce 0
                    echo "Temporarily permissive mode set successfully "
                fi 
                pasusescript
                #break
            ;;
            *) echo 'Invalid input????' >&2
        esac
    done
}

#Function for disable firewall service
firewallmanage(){
    echo "0 - disable | 1 - enable | 2 - start | 3 - stop | 4 - restart | 5 - reload config | 6 - restore-default"
    read -p "Enter numeric value for firewall action: " faction
    case $faction in
        0)
            #systemctl stop firewalld
            systemctl disable firewalld
            echo "Firewall service disabled successfully"
        ;;
        1)
            systemctl enable firewalld
            echo "Firewall service enabled successfully"
        ;;
        2)
            systemctl start firewalld
            echo "Firewall service started successfully"
        ;;
        3)
            systemctl stop firewalld
            echo "Firewall service stoped successfully"          
        ;;
        4)
            systemctl restart firewalld
            echo "Firewall service restarted successfully"
        ;;
        5)
            firewall-cmd --reload
            echo "Firewall config reloaded successfully"
        ;;
        6)
            rm -rf /etc/firewalld/zones/*
            firewall-cmd --reload 
            echo "Firewall config restore-default successfully"
        ;;
        *)
            echo "Inavalid input"
        ;;
    esac
    holdscript
}

#Function for configure firewall
configfirewall(){
    while true
    do
        echo "==================================="    
        echo "List of the firewall action"    
        echo "==================================="
        echo "1. Allow or block service for all"
        echo "2. Allow or block port for all"
        echo "3. Add or remove ip or subnet in whitelisting source"
        echo "4. Add or remove ip or subnet in blocking source " 
        echo "5. Add or remove specific ip for specific dest port (Custom accept rule)"
        echo "6. Add or remove specific ip for specific dest port (Custom reject rule)"
        echo "7. Back to main menu with firewall reload config"
        echo "========================================================================="
            read -p "Please choose firewall action: " FACT
            case $FACT in
                1)
                    echo "1 for allow and 0 for block service like (ssh 1)"
                    read -p "please enter sevice name: " FSNAME
                    FSTYPE=$(echo $FSNAME | awk '{print $2}')
                    if [ "$FSTYPE" == '1' ]; then
                        firewall-cmd --permanent --add-service=$(echo $FSNAME | awk '{print $1}')
                        echo "Firewall rules updated successfully"  
                    elif [ "$FSTYPE" == '0' ]; then
                        firewall-cmd --permanent --remove-service=$(echo $FSNAME | awk '{print $1}')
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.1"
                    fi
                    
                ;;
                2)
                    echo "1 for allow and 0 for block port like (22/tcp 1)"
                    read -p "please enter sevice name: " FPNO
                    FPTYPE=$(echo $FPNO | awk '{print $2}')
                    if [ "$FPTYPE" == '1' ]; then
                        firewall-cmd --permanent --add-port=$(echo $FPNO | awk '{print $1}')
                        echo "Firewall rules updated successfully"  
                    elif [ "$FPTYPE" == '0' ]; then
                        firewall-cmd --permanent --remove-port=$(echo $FPNO | awk '{print $1}')
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.2"
                    fi
                    
                ;;
                3)
                    echo "1 for add and 0 for remove IP or subnet in whitelisting source like (192.168.x.x/32 1)"
                    read -p "please enter sevice name: " FIPA
                    FIPAT=$(echo $FIPA | awk '{print $2}')
                    if [ "$FIPAT" == '1' ]; then
                        firewall-cmd --permanent --add-source=$(echo $FIPA | awk '{print $1}')
                        echo "Firewall rules updated successfully"  
                    elif [ "$FIPAT" == '0' ]; then
                        firewall-cmd --permanent --remove-source=$(echo $FIPA | awk '{print $1}')
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.3"
                    fi
                    
                ;;
                4)
                    echo "1 for add and 0 for remove IP or subnet in block source like (192.168.x.x/32 1)"
                    read -p "please enter sevice name: " FIPB
                    FIPBT=$(echo $FIPB | awk '{print $2}')
                    if [ "$FIPBT" == '1' ]; then
                        firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address=$(echo $FIPB | awk '{print $1}') reject"
                        echo "Firewall rules updated successfully"
                    elif [ "$FIPBT" == '0' ]; then
                        firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address=$(echo $FIPB | awk '{print $1}') reject"
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.4"
                    fi
                    
                ;;
                5)
                    echo "1 for add and 0 for remove custom accept rule"
                    echo "Input format source-ip portocol dest-port add or remove (192.168.x.x/32 tcp 22 1)"
                    read -p "Enter custom rule: " FCRA
                    FCRAT=$(echo $FCRA | awk '{print $4}')
                    if [ "$FCRAT" == '1' ]; then
                        firewall-cmd --permanent --zone=public --add-rich-rule="rule family='ipv4' source address=$(echo $FCRA | awk '{print $1}') port protocol=$(echo $FCRA | awk '{print $2}') port=$(echo $FCRA | awk '{print $3}') accept"
                        echo "Firewall rules updated successfully"
                    elif [ "$FCRAT" == '0' ]; then
                        firewall-cmd --permanent --zone=public --remove-rich-rule="rule family='ipv4' source address=$(echo $FCRA | awk '{print $1}') port protocol=$(echo $FCRA | awk '{print $2}') port=$(echo $FCRA | awk '{print $3}') accept"
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.5"
                    fi
                    
                ;;
                6)
                    echo "1 for add and 0 for remove custom reject rule"
                    echo "Input format source-ip portocol dest-port add or remove (192.168.x.x/32 tcp 22 1)"
                    read -p "Enter custom rule: " FCRB
                    FCRBT=$(echo $FCRB | awk '{print $4}')
                    if [ "$FCRBT" == '1' ]; then
                        firewall-cmd --permanent --zone=public --add-rich-rule="rule family='ipv4' source address=$(echo $FCRB | awk '{print $1}') port protocol=$(echo $FCRB | awk '{print $2}') port=$(echo $FCRB | awk '{print $3}') reject"
                        echo "Firewall rules updated successfully"
                    elif [ "$FCRBT" == '0' ]; then
                        firewall-cmd --permanent --zone=public --remove-rich-rule="rule family='ipv4' source address=$(echo $FCRB | awk '{print $1}') port protocol=$(echo $FCRB | awk '{print $2}') port=$(echo $FCRB | awk '{print $3}') reject"
                        echo "Firewall rules updated successfully"
                    else
                        echo "Invalid input for firewall action no.6"
                    fi
                    
                ;;
                7)
                    echo "Firewalld config reloading"
                    firewall-cmd --reload
                    echo "Firewalld service restarting"
                    systemctl restart firewalld
                    pasusescript
                ;;
                *)
                    echo "Invalid input for firewall action" 
                    
                ;;
            esac
            holdscript
    done
}

#Function for sethostname
sethostname(){
    echo "Type FQDN host name(server.example.com) "
    read -p "Enter Host name " hostname
    hostnamectl set-hostname --static $hostname
    if [ $? -eq 0 ]
    then
        echo 'Hostname set successfully....'
    fi
    holdscript
}

#Function for edit /etc/hosts file
edithosts(){
    echo "Type FQDN host name(server.example.com) "
    read -p "Enter ip address: " HOSTIP
    read -p "Enter FQDN host name: " FQDN
    HOSTNAME=$(echo $FQDN | sed 's/\./ /1' | awk '{printf $1}')
    echo $HOSTIP $FQDN $HOSTNAME >> /etc/hosts 
    ping -c 2 $FQDN &> /dev/null && echo "/etc/hosts file configured successfully" || echo "Something wrong in /etc/hosts"
    holdscript
}

#Function for install openjdk and set environment variable
openjdk(){
    yum install -y java-11-openjdk
    echo "java-11-openjdk installed successfully"
    javahome=$(ls -d /usr/lib/jvm/* | grep java-11-openjdk)
    update-alternatives --set java $javahome/bin/java
    echo "Verify java version........"
    echo $(java -version) 
    cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME=\$(dirname \$(dirname \$(readlink \$(readlink \$(which java)))))
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib:\$JAVA_HOME/lib/tools.jar
EOF
    #touch /etc/profile.d/java.sh
    #echo "export JAVA_HOME=" >> /etc/profile.d/java.sh
    #echo "export PATH="'$PATH'":"'$JAVA_HOME'"/bin" >> /etc/profile.d/java.sh
    #echo $(source /etc/profile.d/java.sh)
    . /etc/profile.d/java.sh
    echo "JAVA_HOME environment variable set successfully"
    holdscript
}

#Function for postfix service handle
postfixhandle(){
    while true;
    do
        echo "Please enter 1 for disable and 2 for remove postfix service"
        read -p "Enter postfix action: " POSTFIX
        if [ "$POSTFIX" == '1' ]; then
            systemctl stop postfix
            systemctl disable postfix
            echo "postfix service disabled successfully"
        elif [ "$POSTFIX" == '2' ]; then
            read -p "Are you sure you want to remove postfix package [y/n]?" choice
            case "$choice" in 
                y|Y ) 
                    yum remove -y postfix
                    echo "Postfix service removed successfully"
                ;;
                n|N ) echo "Nothing change in postfix";;
                * ) echo "invalid input";;
            esac

        else
            echo "Please enter valid postfix input"
        fi
        pasusescript
    done
}

#Function for print IP MAC & DNS
ipmacdns(){
    #echo  "IP  : $(/sbin/ip -o -4 addr list enp0s3 | awk '{print $4}' | cut -d/ -f1)"
    
    echo "IP address printing-----------------------"
    echo "$(/sbin/ip -o -4 addr list | awk '{print $2 " : "$4}')"
    #echo "MAC : $(ip a show enp0s3 | grep ether | cut -d " " -f6)"
    echo
    echo "MAC address printing----------------------"
    echo "$(ip a | grep ether | cut -d " " -f6)"
    echo
    echo "/etc/reslov.conf printing (DNS)-----------"
    #echo "DNS : " 
    for var in $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    do
        echo "DNS : $var"
    done
    echo 
    holdscript

}

#Function for proxy for profile
proxyforprofile(){
    echo "Proxy settings for http or https in environment variable..."
    echo "1 - add proxy setting | 2 - remover proxy setting"
    read -p "Enter action number: " PACT
    case $PACT in
        1)
             echo "With authentication - http://USERNAME:PASSWORD@URL:PORT | Without authentication http://URL:PORT"
            read -p "Enter http or https proxy url: " ppinput
            if [[ ! -z "$ppinput" ]]; then
                cat > /etc/profile.d/proxy.sh <<EOF
export http_proxy=$ppinput
EOF
                set http_proxy=$ppinput
                echo "Proxy setting addedd successfully in profile"
                #echo $(source /etc/profile.d/proxy.sh)
                . /etc/profile.d/proxy.sh 
            else
                echo "Invalid input for http proxy"
            fi
        ;;
        2)
            rm -rf /etc/profile.d/proxy.sh
            unset http_proxy
            echo "Proxy setting removed successfully in profile"
        ;;
        *)
            echo "Invalid input for http proxy"
        ;;
    esac
    holdscript
}

#Function proxy setting for yum
proxyforyum(){
    echo "Proxy setting for yum package management utility"
    echo "1 - with authentication | 2 - without authentication proxy setting | 3 - remove proxy setting"
    read -p "Enter numeric value for proxy setting: " pinput
       
    if [ "$pinput" == "1" ]; then
        read -p "Enter proxy URL [http://URL:PORT]: " PROXYURL 
        read -p "Enter proxy username: " PROXYUSER
        read -p "Enter proxy password: " PROXYPASSWD
        if [[ ! -z "$PROXYUSER" ]] | [[ ! -z "$PROXYPASSWD" ]] | [[ ! -z "$PROXYURL" ]]; then
            echo "proxy=$PROXYURL" >> /etc/yum.conf
            echo "proxy_username=$PROXYUSER" >> /etc/yum.conf
            echo "proxy_password=$PROXYPASSWD" >> /etc/yum.conf
            echo "Proxy settings added in /etc/yum.conf successfully"
        else
            echo "Invalid input for proxy setting"
        fi
    elif [ "$pinput" == "2" ]; then
        read -p "Enter proxy URL [http://URL:PORT]: " PROXYURL 
        if [[ ! -z "$PROXYURL" ]]; then
            echo "proxy=$PROXYURL" >> /etc/yum.conf
            echo "Proxy settings added in /etc/yum.conf successfully"
        else
            echo "Invalid input for proxy setting"
        fi
    elif [ "$pinput" == "3" ]; then
        sed -i /^proxy/d /etc/yum.conf
        echo "Proxy setting remove in /etc/yum.conf successfully"
    else
        echo "Invalid input for proxy setting"
    fi
    holdscript
}

#Function for set environment variable
envvar(){
    FILE=/etc/profile.d/myvar.sh
    if [ ! -f "$FILE" ]; then
        touch /etc/profile.d/myvar.sh
    fi
    read -p "Enter variable name=url [NEW_HOME=/home/use1]: " envar
    echo "export $envar" >> /etc/profile.d/myvar.sh
    set $envar
    echo "Environment variable set successfully"
    . /etc/profile.d/myvar.sh 
    #echo $(source /etc/profile.d/myvar.sh)
    holdscript
}

#Function for datatime or NTP setting
Datetimeconfig(){
    while true
    do
        echo "-----------------------------------------"
        echo "List of the action for date time setting"
        echo "-----------------------------------------"
        echo "1. To view current datetime & zone info"
        echo "2. Set datetime"
        echo "3. To view list of time zone"
        echo "4. Change timezone"
        echo "5. Install & manage NTP client"
        echo "6. Back to main menu"
        echo "-----------------------------------------"
        read -p "Enter action number: " TACT
        case $TACT in
            1)
                echo "To view cuurent Datetine and zone information....."
                timedatectl
              
            ;;
            2)
                read -p "Enter datetime [YYYY-MM-DD HH:MM:SS]: " sdatetime
                timedatectl set-ntp 0
                timedatectl set-time "$sdatetime"
                if [ $? -eq 0 ]
                then
                    echo "Datetime set successfully...."
                else
                    echo "Invalid date time format or something wrong"
                fi
               
            ;;
            3)
                echo "Time zone list............."
                timedatectl list-timezones | more
      
            ;;
            4)
                echo "Changing time zone....."
                read -p "Enter time zone: " zone
                timedatectl set-timezone $zone
                if [ $? -eq 0 ]
                then
                    echo "Time zone updated successfully...."
                else
                    echo "Invalid zone details"
                fi
                
            ;;
            5)
                echo "1-ntp install | 2-ntp client enable | 3-ntp client disable | 4-ntp client config | 5-ntp service restart"
                read -p "Enter ntp client action number: " NACT
                case $NACT in
                    1)
                        yum install -y ntp
                        systemctl start ntpd
                        systemctl enable ntpd
                        echo "ntp installtion successfully"
                    ;;
                    2)
                        timedatectl set-ntp 1
                        echo "ntp client enabled successfully"
                    ;;
                    3)
                        timedatectl set-ntp 0
                        echo "ntp client disable successfully"
                    ;;
                    4)
                        echo "updating ntp server details in /etc/ntp.conf......."
                        read -p "Enter NTP server list [server1 server2 server3]: " SLIST
                        ROWLIST=( `awk '/^server/{ print NR }' /etc/ntp.conf | sort -n` )
                        ROWNO=${ROWLIST[0]}
                        sed -i /^server/d /etc/ntp.conf 
                        for svar in $SLIST
                        do
                            sed -i ''$ROWNO'i server '$svar'' /etc/ntp.conf
                            let ROWNO=$ROWNO+1
                        done
                        
                        if [ $? -eq 0 ]
                        then
                            echo "ntp client configuration successfully."
                        else
                            echo "Invalid zone details or something wrong"
                        fi
                    ;;
                    5)
                        systemctl restart ntpd
                        echo "Service ntp restarted successfully"
                    ;;
                    *)
                        echo "Invalid ntp client input"
                    ;;
                esac
            ;;
            6) pasusescript
            ;;
            *)
                echo "Invalid input for date time setting"
            ;;
        esac    
        holdscript

    done

}

#Function for webmin install
webmininstall(){
    echo "Creating webmin yum repo....."
    cat <<EOF >/etc/yum.repos.d/webmin.repo
[Webmin]
name=Webmin Distribution Neutral
#baseurl=https://download.webmin.com/download/yum
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
enabled=1
EOF
    echo "webmin repo created successfully"
    rpm --import http://www.webmin.com/jcameron-key.asc
    yum install -y webmin
    echo "Webmin install complete. You can now login to below URL as root with your root password."
    echo "$(/sbin/ip -o -4 addr list | awk '{print "http:"$4}')" |cut -d/ -f1 | sed 's|http:|http://|g' | awk '{print $1":10000"}'
    holdscript
}

#Function for reboot server
rebootpc(){
    read -p "Are you sure you want to reboot [y/n]?" REBOOT
    case "$REBOOT" in 
        y|Y ) 
            reboot
            exit 0
        ;;
        n|N ) 
            echo "Reboot cancelled "
            holdscript
        ;;
        * ) echo "invalid input";;
    esac
    
}

#Function for exit script
exitshell(){
    echo "Thank you !!!"
    exit 0
}

while true; 
do
    #Call function for main menu
    mainmenu
    read -p "Please select the action: " USERINPUT
    case $USERINPUT in
        1) echo 1
            #Call function for createing local repo
            createlocalrepo
        ;;
        2) 
            #Call function for check internet connectivity
            checkconnectivity
        ;;
        3)
            #Call function for install and enable epel repo
            epelrepo
        ;;
        4)
            #Call function for install basic tools
            installbasictool
        ;;
        5) 
            #Call function for SELINUX configuration
            selinuxconfig
        ;;
        6)
            #Call function for manage firewall service
            firewallmanage
        ;;
        7)
            #Call function for configure firewall rules
            configfirewall
        ;;
        8) 
            #Call function for set hostname
            sethostname
        ;;
        9)
            #Call function for /etc/hosts file edit
            edithosts
        ;;
        10)
            #Call function for installed openJDK and configure JAVA_HOME
            openjdk
        ;;
        11)
            #Call function for postfix handle
            postfixhandle
        ;;
        12)
            #Call function for print IP MAC DNS
            ipmacdns
        ;;
        13)
            #Call function for setting http proxy in profile
            proxyforprofile
        ;;
        14)
            #Call function for setting proxy in yum config
            proxyforyum
        ;;
        15)
            #Call function for environment variable
            envvar
        ;;
        16)
            #Call function for datetime or ntp client setting
            Datetimeconfig
        ;;
        17)
            #Call function for installing webmin
            webmininstall

        ;;
        18)
            #Call function for reboot server
            rebootpc
        ;;
        19)
            #Call function for exit script
            exitshell
        ;;
        *) echo "Invalid input. Please enter valid action"
        ;;
    esac
    
done
