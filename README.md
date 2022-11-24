# About

This project is to simplify the process of creating OpenVPN servers on Oracle's OCI cloud. Their free offering is quite amazing, this is a great video by [IdeaSpot](https://ideaspot.com.au/) to get introduced: [https://www.youtube.com/watch?v=_m21FxvuQ4c](https://www.youtube.com/watch?v=_m21FxvuQ4c)


# Create Server

1. Get Oracle OCI account + login

2. Copy/paste into the Oracle Cloud Shell:

```bash
# curl -s https://raw.githubusercontent.com/alecmaly/One-Click-Oracle-OCI-OpenVPN-Deployment/main/new_oci_openvpn_server.sh | bash <cpu_count> <memory_in_gb>

curl -s https://raw.githubusercontent.com/alecmaly/One-Click-Oracle-OCI-OpenVPN-Deployment/main/new_oci_openvpn_server.sh | bash 1 6
```

