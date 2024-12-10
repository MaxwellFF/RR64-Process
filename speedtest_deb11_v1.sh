#!/bin/bash                                                            
# OOOOOOOOOO  OOOOOOOOOO  OO     OO  OO          OOOOOOOOOO
# OO      OO  OO      OO  OO    OO   OO          OO      OO
# OO      OO  OO      OO  OO   OO    OO          OO      OO
# OO      OO  OO      OO  OO  OO     OO          OO      OO
# OO      OO  OO      OO  OO OO      OO          OO      OO
# OO      OO  OO      OO  OOOO       OO          OOOOOOOOOO
# OO      OO  OO      OO  OO OO      OO          OO      OO
# OO      OO  OO      OO  OO  OO     OO          OO      OO
# OO      OO  OO      OO  OO   OO    OO          OO      OO
# OO      OO  OO      OO  OO    OO   OO          OO      OO
# OOOOOOOOOO  OOOOOOOOOO  OO     OO  OOOOOOOOOO  OO      OO
# ====================================#
#
#  Speedtest - data: 21/08/2023
#  
# ====================================#
#  
#  autor: Rafael Burger de Oliveira
#
# ====================================#
#  
#  Instalando Speedtest
#
# ====================================#
#
# Requerimentos
# CPU 4vCPU/8vCPU
# Memory 16GB
# Storage 50GB
# Bandwith 1 Gbps
# Public reachable IPV6 address
# OoklaServer auto-updates are enable
#
# ====================================#

echo "Insira o nome do usuário criado: "
read user
mkdir /home/$user
echo "Insira o nome do seu dominio completo: (Ex.:speedtest.teste.com.br)"
read dominio

echo "Insira o nome do seu dominio simplificado: (Ex.:teste.com.br)"
read dominio2

# Correçao de Repositorio
export PATH=$PATH:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
echo "PATH="/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games"" >> /etc/environment

# Atualizando
apt update; apt upgrade -y
apt install -y vim nano wget net-tools snmpd certbot unzip psmisc

# Configurando Firewall
apt-get install -y nftables
echo "
#!/usr/sbin/nft -f

flush ruleset                                                                    
                                                                                 
table inet firewall {
                                                                                 
    chain inbound_ipv4 {

        icmp type echo-request limit rate 5/second accept      
    }

    chain inbound_ipv6 {

        icmpv6 type { nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept                                                                         
        icmpv6 type echo-request limit rate 5/second accept
    }

    chain inbound {                                                              
        type filter hook input priority 0; policy drop;
        ct state vmap { established : accept, related : accept, invalid : drop } 
        iifname lo accept
        meta protocol vmap { ip : jump inbound_ipv4, ip6 : jump inbound_ipv6 }
        tcp dport { 8080, 5060, 443, 22, 2210, 80 } accept
        udp dport { 8080, 5060, 80 } accept

    }                                                                            
                                                                                 
    chain forward {                                                                              
        type filter hook forward priority 0; policy drop;                        
    }                                                                            
                                                                                 
}
" > /etc/nftables.conf
systemctl start nftables
systemctl enable nftables

cp /etc/issue /etc/issue.bkp
echo "\S" > /etc/issue
echo "Kernel \r on an \m" > /etc/issue
echo "                                                             
OOOOOOOOOO  OOOOOOOOOO  OO     OO  OO          OOOOOOOOOO
OO      OO  OO      OO  OO    OO   OO          OO      OO
OO      OO  OO      OO  OO   OO    OO          OO      OO
OO      OO  OO      OO  OO  OO     OO          OO      OO
OO      OO  OO      OO  OO OO      OO          OO      OO
OO      OO  OO      OO  OOOO       OO          OOOOOOOOOO
OO      OO  OO      OO  OO OO      OO          OO      OO
OO      OO  OO      OO  OO  OO     OO          OO      OO
OO      OO  OO      OO  OO   OO    OO          OO      OO
OO      OO  OO      OO  OO    OO   OO          OO      OO
OOOOOOOOOO  OOOOOOOOOO  OO     OO  OOOOOOOOOO  OO      OO
" > /etc/issue


cd /home/$user
wget https://install.speedtest.net/ooklaserver/ooklaserver.sh
chmod a+x ooklaserver.sh
echo -e "y" | ./ooklaserver.sh install
./ooklaserver.sh stop

sed -i 's/# OoklaServer.useIPv6 = true/OoklaServer.useIPv6 = true/' /home/$user/OoklaServer.properties
sed -i 's/^# OoklaServer\.allowedDomains = \*\.ookla\.com, \*\.speedtest\.net/OoklaServer.allowedDomains = *\.ookla\.com, *\.speedtest\.net, *\.'"$dominio2"'/' /home/"$user"/OoklaServer.properties
sed -i 's/# OoklaServer.enableAutoUpdate = true/OoklaServer.enableAutoUpdate = true/' /home/$user/OoklaServer.properties
sed -i 's/# OoklaServer.ssl.useLetsEncrypt = true/OoklaServer.ssl.useLetsEncrypt = true/' /home/$user/OoklaServer.properties

sed -i 's/#logging.loggers.app.name = Application/logging.loggers.app.name = Application/' /home/$user/OoklaServer.properties
sed -i 's/#logging.loggers.app.channel.class = FileChannel/logging.loggers.app.channel.class = FileChannel/' /home/$user/OoklaServer.properties
sed -i 's/^#logging\.loggers\.app\.channel\.pattern = %Y-%m-%d %H:%M:%S \[%P - %I\] \[%p\] %t/logging.loggers.app.channel.pattern = %Y-%m-%d %H:%M:%S \[%P - %I\] \[%p\] %t/' /home/$user/OoklaServer.properties
sed -i 's/#logging.loggers.app.channel.path = ${application.dir}\/ooklaserver.log/logging.loggers.app.channel.path = ${application.dir}\/ooklaserver.log/' /home/$user/OoklaServer.properties
sed -i 's/#logging.loggers.app.level = information/logging.loggers.app.level = information/' /home/$user/OoklaServer.properties

echo "[Unit]
Description=OoklaServer-SpeedTest 
After=network.target
 
[Service]
User=root
Group=root
Type=simple
RemainAfterExit=yes
 
WorkingDirectory=/home/$user
ExecStart=/home/$user/ooklaserver.sh start
ExecReload=/home/$user/ooklaserver.sh restart
ExecStop=/home/$user/ooklaserver.sh stop

 
TimeoutStartSec=60
TimeoutStopSec=300
 
[Install]
WantedBy=multi-user.target
Alias=speedtest.service" >> /lib/systemd/system/ooklaserver.service
systemctl daemon-reload
systemctl enable ooklaserver
systemctl start ooklaserver

# Configurando Certificado
#echo -e "null@'$dominio'\nY\nN\n'$dominio'" | certbot certonly --standalone precisara colocar um sleep entre os \n provavelmente
certbot certonly --standalone

sed -i 's|# openSSL.server.certificateFile = cert.pem|openSSL.server.certificateFile = /etc/letsencrypt/live/'"$dominio"'/fullchain.pem|' /home/"$user"/OoklaServer.properties
sed -i 's|# openSSL.server.privateKeyFile = key.pem|openSSL.server.privateKeyFile = /etc/letsencrypt/live/'"$dominio"'/privkey.pem|' /home/"$user"/OoklaServer.properties

touch /home/$user/cert_cron
echo "#!/bin/bash
/usr/bin/certbot renew -q
sleep 30
/usr/bin/systemctl restart ooklaserver" >> /home/$user/cert_cron

chmod +x /home/$user/cert_cron
echo "00 00   1 * *   root    /home/$user/cert_cron" >> /etc/crontab
systemctl enable cron
systemctl start cron

sleep 2
rm -rf /root/speedtest.sh
