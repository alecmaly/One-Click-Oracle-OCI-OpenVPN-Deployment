# About

This project is to simplify the process of creating OpenVPN servers on Oracle's OCI cloud. Their free offering is quite amazing, this is a great video by [IdeaSpot](https://ideaspot.com.au/) to get introduced: [https://www.youtube.com/watch?v=_m21FxvuQ4c](https://www.youtube.com/watch?v=_m21FxvuQ4c)

These scripts assume you do not work out of Oracle OCI Cloud as they modify the default network security list/OCI firewall + drop files to Cloud Shell `pwd`.

Note that key `id_rsa` are saved to `pwd` and can be copied offline to SSH into each VPS. 


# Create Server

1. Get Oracle OCI account 

2. Open Oracle Cloud Shell: [https://cloud.oracle.com?cloudshell=true](https://cloud.oracle.com?cloudshell=true)

2. Copy/paste into the Oracle Cloud Shell:

<span style='color:indianred; font-weight:bold'>Use with caution! Piping script to /bin/bash can be dangerous. Please validate all scripts before running.</span>

```bash
# curl -s https://raw.githubusercontent.com/alecmaly/One-Click-Oracle-OCI-OpenVPN-Deployment/main/new_oci_openvpn_server.sh | /bin/bash -s -- <instance_name> <cpu_count> <memory_in_gb>

curl -s https://raw.githubusercontent.com/alecmaly/One-Click-Oracle-OCI-OpenVPN-Deployment/main/new_oci_openvpn_server.sh | /bin/bash -s -- openvpn 1 6
```

# Notes
- Have not tested default timeout rules for SSH, may need to configure timeout policy and/or implement whitelist ingress firewall rules?