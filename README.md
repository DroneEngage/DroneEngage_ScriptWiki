
  

[![Ardupilot Cloud EcoSystem](https://cloud.ardupilot.org/_static/ardupilot_logo.png  "Ardupilot Cloud EcoSystem")](https://cloud.ardupilot.org  "Ardupilot Cloud EcoSystem") **Drone Engage** is part of Ardupilot Cloud Eco System

  

  

------------

  

  

![Drone Engage Communicator Module](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/main/resources/de_logo_title.png)

  

  

# Drone Engage Scripts

  

This repository contains script used to install Air-Gap Server, and other helper scripts.

  

## Scripts

  

### Air Gap-Server with Stand alone Access-Point

[prepare-airgapped-server_w_ap.sh](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/prepare-airgapped-server_w_ap.sh)

  

You might need to connect LAN to your RPI-4 to maintain connection during installation.

#### Ready-Image:

[here](https://cloud.ardupilot.org/downloads/RPI_Full_Images/airgap_server_rpi4/rpi-bulleye-standalone-airgap-server-_32G_21_feb_2025_large.img.xz)

  
  

AP: DE_2025

PWD: 1234567890

   
https://airgap.droneengage.com:8001/index.html

email: **single@airgap.droneengage.com**

accesscode: **test**

  
  
  

#### Purpose

Install DroneEngage Server (DroneEngage Authenticator, DroneEngage Communication Server, WebClient)

Use this script if you want to create a server with AP.

  

Prepare a new **Raspberry Pi OS (Legacy) Lite (bullseye)** from [here](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf-lite.img.xz)

  

cd ~

wget https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server_w_ap.sh

chmod +x prepare-airgapped-server_w_ap.sh

./prepare-airgapped-server_w_ap.sh

wget https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/helper_scripts/create_ap.sh

chmod +x create_ap.sh

./create_ap.sh

The result will be a RPI Image with AP (access-point) of your choice and password.

**Connect to your RPI-4 using laptop** and connect using https://airgap.droneengage.com:8001/

  

**username:** single@airgap.droneengage.com

**password:** test

  

you can edit password in **./home/pi/droneengage_authenticator/server.config**

  

-------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------

  

### Air Gap-Server without AP

  

[prepare-airgapped-server.sh](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/prepare-airgapped-server.sh)

  

#### Ready-Image:

[here](https://cloud.ardupilot.org/downloads/RPI_Full_Images/airgap_server_rpi4/rpi_4_sd_card_16G_airgap_server_image.img.xz)

  
  

You need to set the IP address of the RPI in hosts file.

https://airgap.droneengage.com:8001/index.html

email: **single@airgap.droneengage.com**

  

#### Purpose

  

Install DroneEngage Server (DroneEngage Authenticator, DroneEngage Communication Server, WebClient)

Use this script if you want to create a server and connect this server to your WiFi.

  

Prepare a new **Raspberry Pi OS (Legacy) Lite (bullseye)** from [here](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf-lite.img.xz)

  

cd ~

wget https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server.sh

chmod +x prepare-airgapped-server.sh

./prepare-airgapped-server.sh

  

You will need to edit hosts file on your computer to map **airgap.droneengage.com** to RPI-4 IP.

  

[![help to run script](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/resources/youtube_IsolatedServerAndruavDroneEngage.png)](https://youtu.be/R1BedRTxuuY)

-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------


### Creating Secure SSL
  
  
You need to set the IP address of the RPI in hosts file especially in **Air Gap-Server without AP** configuration.

You have to add [root.crt](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/root.crt) in Authorities Certificate in Broswer to create a valis SSL certificate.

  

![browser_certificate.png](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/resources/browser_certificate.png)
