#!/bin/bash

# Demande à l'utilisateur de fournir l'adresse IP
read -p "Veuillez entrer l'adresse IP : " ip_address

# Met à jour les paquets disponibles
apt-get update

# Installe les paquets nécessaires
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget

# Navigue vers le répertoire temporaire
cd /tmp

# Télécharge NRPE
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-4.1.0.tar.gz

# Décompresse NRPE
tar xzf nrpe.tar.gz

# Navigue vers le répertoire NRPE
cd /tmp/nrpe-nrpe-4.1.0/

# Configure NRPE
./configure --enable-command-args

# Compile NRPE
make all

# Installe les groupes et les utilisateurs nécessaires
make install-groups-users

# Installe NRPE
make install

# Installe la configuration par défaut
make install-config

# Ajoute une entrée pour NRPE dans /etc/services
echo >> /etc/services
echo '# Nagios services' >> /etc/services
echo 'nrpe    5666/tcp' >> /etc/services

# Installe le service NRPE en tant que service système
make install-init
systemctl enable nrpe.service

# Autorise le trafic NRPE via le pare-feu
iptables -I INPUT -p tcp --destination-port 5666 -j ACCEPT

# Installe iptables-persistent et répond "yes" pour sauvegarder les règles existantes
apt-get install -y iptables-persistent
echo "yes" | iptables-save > /etc/iptables/rules.v4

# Modifie le fichier de configuration NRPE pour autoriser l'adresse IP fournie
sed -i '/^allowed_hosts=/s/$/,'"$ip_address"'/' /usr/local/nagios/etc/nrpe.cfg

# Active la fonctionnalité dont_blame_nrpe
sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg

# Démarre le service NRPE
systemctl start nrpe.service

# Vérifie NRPE en utilisant l'adresse IP locale
/usr/local/nagios/libexec/check_nrpe -H 127.0.0.1

# Gère le service NRPE
systemctl start nrpe.service
systemctl stop nrpe.service
systemctl restart nrpe.service
systemctl status nrpe.service

# Installe les paquets supplémentaires
apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

# Télécharge les plugins Nagios
cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz
