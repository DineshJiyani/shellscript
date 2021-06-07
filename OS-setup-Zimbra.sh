#!/bin/bash
if [ $# -ne 3 ]; then
    echo "No arguments or less arguments provided"
    exit 1
fi

HOSTNAME="mail"
DOMAIN=$1
FQDN=$HOSTNAME.$DOMAINs
HOSTIP=$2
DNSSERVER=$3
: '
===Below step run one bye one =======
1. Set hostname
2. Add in hostfile entry
3. Set selinux disable permenantly and temporaly permissive mode
4. Stop postfix service stop
5. Check Internet connectivity
6. Install require package for zimbra
7. Install DNS server 
'
for i in {1..7}
do
    case $i in
        1)
            echo "=====Setting hostname====="
            hostnamectl set-hostname --static $FQDN
            if [ $? -eq 0 ]
            then
                echo 'Hostname set successfully....'
            fi           
            
        ;;
        2)
            echo "=====Adding hosts entry====="
            # HOSTNAME=$(hostname -s)
            # DOMAIN=$(echo $1 | sed 's/\./ /1' | awk '{printf $2}')
            #hostname=$(echo $1 | sed 's/\./ /1' | awk '{printf $1}')
            echo $HOSTIP $FQDN $HOSTNAME >> /etc/hosts 
            ping -c 2 $1 &> /dev/null && echo "/etc/hosts file configured successfully" || echo "Something wrong in /etc/hosts"
        ;;
        3)
            echo "=====Setting selinux mode====="
            sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
            setenforce 0
            if [ $? -eq 0 ]
            then
                echo "Selinux mode set successfully"
            fi    
            
        ;;
        4)
            echo "=====Stopping postfix service====="
            systemctl stop postfix
            if [ $? -eq 0 ]
            then
                echo "Postfix service stopped succesfully"
            fi
            echo "=====disable postfix service on startup====="    
            systemctl disable postfix
            if [ $? -eq 0 ]
            then
                echo "Postfix service disabled succesfully"
            fi    
            
        ;;
        5)
            echo "=====Checking internet connectivity======" 
            echo "-----------------------------------------------------------"
            ping -c 2 8.8.8.8 &> /dev/null && echo "ping 8.8.8.8 success" || echo "ping 8.8.8.8 fail"
            nslookup google.com &> /dev/null && echo "nslookup google.com success" || echo "nslookup google.com fail"
            echo "-----------------------------------------------------------"
        ;;
        6)
            echo "=====Installing required packages for zimbra======"
            yum install -y perl net-tools wget unzip nc
          
        ;;
        7)
            if [[ $DNSSERVER =~ ^([yY][eE][sS]|[yY])$ ]];
            then
                yum update -y && yum install -y bind bind-utils
                echo "Installing Bind DNS Server"
                mv /etc/named.conf /etc/named.conf.original
cat <<EOF >>/etc/named.conf
options {
        listen-on port 53 { 127.0.0.1; $2; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { localhost; $2; };
        recursion yes;
        dnssec-enable yes;
        dnssec-validation yes;
        bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
        allow-transfer { none; }; # disable zone transfers by default
        forwarders {
            8.8.8.8;
            8.8.4.4;
        };
        auth-nxdomain no; # conform to RFC1035
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
        type hint;
        file "named.ca";
};
zone "$1" IN {
        type master;
        file "$1.zone";
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
touch /var/named/$1.zone
SERIAL=$(date +%Y%m%d2)
cat <<EOF >/var/named/$1.zone
\$TTL  604800
@      IN      SOA    ns1.$1. root.localhost. (
                                ${SERIAL}        ; Serial
                        604800        ; Refresh
                        86400        ; Retry
                        2419200        ; Expire
                        604800 )      ; Negative Cache TTL
;
@     IN      NS      ns1.$1.
@     IN      A      $2
@     IN      MX     10     $HOSTNAME.$1.
$HOSTNAME     IN      A      $2
ns1     IN      A      $2
mail     IN      A      $2
pop3     IN      A      $2
imap     IN      A      $2
imap4     IN      A      $2
smtp     IN      A      $2
EOF
                systemctl enable named && systemctl start named
				if [ $? -eq 0 ]
				then
					echo "DNS server configured succesfully"
				fi
            fi
        ;;
    esac
done
echo "Thank you see you again!!!!"