#!/bin/bash

# check missing parmeters
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    printf "\n[!] Missing parameters!!
Reminder: Free Oracle OCI offers a maximum of 4 cpu and 24 gb of memory per account.

Usage: /bin/bash ./$0 <cpu_count> <memory_in_gb>

Example:
# Build 1 CPU / 6 GB memory (can build up to 4) VPS
/bin/bash ./$0 1 6
\n\n"
    exit 1
fi

# assign to
cpu_count=$1
memory_in_gb=$2

# valiate args are numbers
re='^[0-9]+$' # regular expression - validate whole number
if ! [[ $cpu_count =~ $re ]] ||  ! [[ $memory_in_gb =~ $re ]] ; then
   echo "error: Parameters cpu_count and memory_in_gb should be whole numbers." >&2
   exit 1
fi



# download configure-server.sh
echo "[!] Downloading configure-server.sh, will be executed on VPN once it is RUNNING..."
wget -q "https://raw.githubusercontent.com/alecmaly/One-Click-Oracle-OCI-OpenVPN-Deployment/main/configure-server.sh" -O configure-server.sh


# SOURCE: https://eclipsys.ca/launch-an-oci-instance-with-oci-cli-in-10-minutes/
# oci iam availability-domain list

# TO DO: 
# - Research : network chuck : client use Server

# Credit: https://www.dbarj.com.br/en/2020/10/get-your-tenancy-ocid-using-a-single-oci-cli-command/


# STEP: Create keys to get into VMs
# TO DO: 
# - output to ~/.ssh 
# - check if id_rsa already exists
# - let user to 
# mkdir -p ~/.ssh
if [ ! -f ./id_rsa ]
then
    echo "[!] id_rsa not found, generating new keys..."
    ssh-keygen -t rsa -N "" -b 2048 -f "id_rsa"
fi

# STEP: Create VNet & Compute Instanece 
# https://eclipsys.ca/launch-an-oci-instance-with-oci-cli-in-10-minutes/
instance_name="vpn"
shape="VM.Standard.A1.Flex"
# cpu_count="1"
# memory_in_gb="6"  

# Step: Get Tenancy / Container ID
echo "[+] Getting Tenacy ID / Container ID"
T=$(
    oci iam compartment list \
        --all \
        --compartment-id-in-subtree true \
        --access-level ACCESSIBLE \
        --include-root \
        --raw-output \
        --query "data[?contains(\"id\",'tenancy')].id | [0]"
)
C="$T"

# Step: Get OCIDs (Oracle Cloud IDs) 
# Ubuntu image
# list images: oci compute image list --all -c $C --query "data[?\"operating-system\" == 'Canonical Ubuntu'] | [?contains(\"display-name\", 'aarch64')] | [?contains(\"display-name\", 'Minimal') == \`false\`] | [].\"display-name\"" 
echo "[+] Getting Image ID"
ocid_img=$(oci compute image list --all -c $C --query "data[?\"operating-system\" == 'Canonical Ubuntu'] | [?contains(\"display-name\", 'aarch64')] | [?contains(\"display-name\", 'Minimal') == \`false\`] | [0].id" --raw-output)

# Get First Availability Domain
echo "[+] Getting (first) Availability Domain ID"
ocid_ad=`oci iam availability-domain list -c $C --query "data[0].name" --raw-output`

# Get First VCN (Virtual Cloud Network)
echo "[+] Getting (First) Virtual Cloud Network ID"
ocid_vcn=`oci network vcn list -c $C --query 'data[0].id' --raw-output`

# Get First Subnet
echo "[+] Getting (First) Subnet ID in (First) Virtual Cloud Network"
ocid_sub=`oci network subnet list -c $C --vcn-id $ocid_vcn --query 'data[0].id' --raw-output`


# TO DO: Update Subnet params to allow ports
# https://blogs.oracle.com/cloud-infrastructure/post/a-simple-guide-to-adding-rules-to-security-lists-using-oci-cli
echo "[+] Getting (First) Security List"
ocid_securiy_list=`oci network security-list list -c $C --query 'data[0].id' --raw-output`

# STEP: Update Security List (Ingress Rules)
# Oracle example doesn't work? https://docs.oracle.com/en-us/iaas/tools/oci-cli/2.9.7/oci_cli_docs/cmdref/network/security-list/update.html#cmdoption-ingress-security-rules
# TCP Ports 443 + 943, UDP: 1194
echo "[+] Updating Security List firewall rules for OpenVPN"
network_ingress_rules='[ { "description": "TCP Port 22", "source": "0.0.0.0/0", "protocol": "6", "isStateless": true, "tcpOptions": { "destinationPortRange": { "max": 22, "min": 22 } } }, { "description": "TCP Port 443", "source": "0.0.0.0/0", "protocol": "6", "isStateless": true, "tcpOptions": { "destinationPortRange": { "max": 443, "min": 443 } } }, { "description": "TCP Port 943", "source": "0.0.0.0/0", "protocol": "6", "isStateless": true, "tcpOptions": { "destinationPortRange": { "max": 943, "min": 943 } } }, { "description": "UDP Port 1194", "source": "0.0.0.0/0", "protocol": "17", "isStateless": true, "udpOptions": { "destinationPortRange": { "max": 1194, "min": 1194 } } } ]'
oci network security-list update --security-list-id $ocid_securiy_list --ingress-security-rules "$network_ingress_rules"


# STEP: Create Compute Instance (VM) + get public_ip
echo "[+] Creating Computue Instance (VM / VPS)"
ocid_instance=$(oci compute instance launch --display-name "${instance_name}" --availability-domain "${ocid_ad}" -c "$C" --subnet-id "${ocid_sub}" --image-id "${ocid_img}" \
--shape "${shape}" \
--shape-config "{\"memory-in-gbs\":$memory_in_gb, \"ocpus\":\"$cpu_count\"}" \
--ssh-authorized-keys-file "id_rsa.pub" \
--assign-public-ip true \
--wait-for-state RUNNING \
--query 'data.id' \
--hostname-label "$instance_name" \
--raw-output)

echo "[+] Getting Public IP"
public_ip=`oci compute instance list-vnics --instance-id $ocid_instance | jq -r '.data[]."public-ip"'`


# execute command on box
echo "[!] Instance is up, can now ssh in"
echo "[+] Configuring server, this could take a while.."
ssh -oStrictHostKeyChecking=no -i id_rsa ubuntu@$public_ip -t 'sudo /bin/bash -s' < configure-server.sh

# ssh into server
# ssh -oStrictHostKeyChecking=no -i id_rsa ubuntu@$public_ip 

# clear .bash_history
cat /dev/null > ~/.bash_history