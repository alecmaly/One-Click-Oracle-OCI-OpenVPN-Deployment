# Other Considerations
# - IPv6 support? https://4sysops.com/archives/openvpn-ipv6-minimal-configuration/#openvpn-server-configuration
# - Other Functions:
#       - List instances + how much Free Quota is left
#       - Change IP of instance
#       - certbot
#           - certbot auto renewals
#       - auto apt full-upgrade 

# install
# sudo su root        # execute all commands as super privileged user

# update and install - non-interactive
export DEBIAN_FRONTEND=noninteractive
apt-get update && 
    apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -q -y --force-yes

apt install -y ca-certificates wget net-tools gnupg jq

wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc
echo "deb [arch=arm64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian jammy main">/etc/apt/sources.list.d/openvpn-as-repo.list
apt update && apt -y install openvpn-as


# STEP: Set IP of host 
echo "[+] Configuring Server using CLI"
sacli --key "host.name" --value "$(curl -s ip.me)" ConfigPut

# STEP: Update "VPN Settings" > DNS > Client DNS = 8.8.8.8 1.1.1.1
sacli --key "vpn.client.routing.reroute_dns" --value "custom" ConfigPut
sacli --key "vpn.server.dhcp_option.dns.0" --value "8.8.8.8" ConfigPut
sacli --key "vpn.server.dhcp_option.dns.1" --value "1.1.1.1" ConfigPut
sacli start



# STEP: Open Ports: needed?
echo "[+] Updating iptable rules"
# UDP: openvpn prefers udp port 1194, falls back to https when not open
# SOURCE DOCS: https://openvpn.net/vpn-server-resources/advanced-option-settings-on-the-command-line/#:~:text=While%20the%20best%20connection%20for%20an%20OpenVPN%20tunnel%20is%20via%20the%20UDP%20port%2C%20we%20implement%20TCP%20443%20as%20a%20fallback%20method
sudo iptables -I INPUT -p udp -m udp --dport 1194 -j ACCEPT
# sudo iptables -I OUTPUT -p udp -m udp --sport 1194 -j ACCEPT

# TCP
sudo iptables -I INPUT -p tcp -m multiport --dports 943,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# sudo iptables -I OUTPUT -p tcp -m multiport --dports 943,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# save IP tables
sudo netfilter-persistent save


# STEP: Create new users - allow auto-login
echo "[+] Creating Users + updating admin password"
# https://openvpn.net/vpn-server-resources/managing-user-and-group-properties-from-command-line/
username="user"
password=`uuidgen`
openvpn_password=`uuidgen`

sacli --user $username --key "type" --value "user_connect" UserPropPut
sacli --user $username --key "prop_autologin" --value "true" UserPropPut
sacli --user "$username" --new_pass "$password" SetLocalPassword
user_token_url=`sacli --user "$username" --token_profile="autologin" --token_usage_count="2" AddProfileToken`

# STEP: Update admin password
sacli --user "openvpn" --new_pass "$openvpn_password" SetLocalPassword

# STEP: Hardening
# DOCS: https://openvpn.net/community-resources/hardening-openvpn-security/
# - OpenVPN now runs AES-256-CBC by default
# - 


public_ip=`curl -s ip.me`
echo "------- OpenVPN should be running on a fresh box! -------"
echo "---------- Copy / paste to Password Manager -------------"
printf "\nAdmin  UI: https://$public_ip:943/admin\n"
printf "Client UI: https://$public_ip:943\n\n"
printf "Admin Credentials:\n\tusername: openvpn\n\tpassword: $openvpn_password\n"
printf "User  Crednetials:\n\tusername: $username\n\tpassword: $password\n\t$user_token_url\n\n"
echo "---------- + update passwords if desired ----------------"

# clear .bash_history
cat /dev/null > ~/.bash_history
echo "Done."