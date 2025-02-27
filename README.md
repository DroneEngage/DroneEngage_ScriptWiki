

[![Ardupilot Cloud EcoSystem](https://cloud.ardupilot.org/_static/ardupilot_logo.png)](https://cloud.ardupilot.org)

**Drone Engage** is a vital component of the Ardupilot Cloud Ecosystem, providing powerful tools and scripts for managing your drone operations.

---

![Drone Engage Communicator Module](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/main/resources/de_logo_title.png)

# Drone Engage Scripts: Empowering Your Ardupilot Cloud Ecosystem

This repository hosts a collection of scripts designed to simplify the setup and management of Drone Engage, including air-gapped server installations and other helpful utilities.


  

[![help to run script](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/resources/youtube_IsolatedServerAndruavDroneEngage.png)](https://youtu.be/R1BedRTxuuY)


## Script Overview

### 1. Air-Gapped Server with Standalone Access Point

**Script:** [prepare-airgapped-server_w_ap.sh](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/prepare-airgapped-server_w_ap.sh)

**Purpose:** Automates the installation of the Drone Engage Server (Authenticator, Communication Server, Web Client) on a Raspberry Pi 4, creating a standalone access point for direct connectivity.

**Ideal for:** Deploying a fully isolated Drone Engage environment with its own Wi-Fi network.

**Installation Steps:**

1.  Start with a fresh Raspberry Pi OS (Legacy) Lite (bullseye) image ([download here](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf-lite.img.xz)).
2.  Connect your Raspberry Pi 4 to your LAN for internet access during installation.
3.  Open a terminal and execute the following commands:

    ```bash
    cd ~
    wget [https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server_w_ap.sh](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server_w_ap.sh)
    chmod +x prepare-airgapped-server_w_ap.sh
    ./prepare-airgapped-server_w_ap.sh
    wget [https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/helper_scripts/create_ap.sh](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/helper_scripts/create_ap.sh)
    chmod +x create_ap.sh
    ./create_ap.sh
    ```

4.  The script will configure the Raspberry Pi as an access point.

**Ready-to-Use Image:**

* Download: [rpi-bulleye-standalone-airgap-server-_32G_21_feb_2025_large.img.xz](https://cloud.ardupilot.org/downloads/RPI_Full_Images/airgap_server_rpi4/rpi-bulleye-standalone-airgap-server-_32G_21_feb_2025_large.img.xz)
* Access Point: `DE_2025`
* Password: `1234567890`
* Web Interface: `https://airgap.droneengage.com:8001/index.html`
* Email: `single@airgap.droneengage.com`
* Access Code: `test`
* **Note:** You can change the access code by editing `/home/pi/droneengage_authenticator/server.config`.

**Accessing the Server:**

1.  Connect your laptop to the Raspberry Pi's access point.
2.  Open a web browser and navigate to `https://airgap.droneengage.com:8001/`.
3.  Log in with the provided credentials.

---

### 2. Air-Gapped Server without Access Point

**Script:** [prepare-airgapped-server.sh](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/prepare-airgapped-server.sh)

**Purpose:** Installs the Drone Engage Server on a Raspberry Pi 4 for integration with an existing network.

**Ideal for:** Deployments where the server will connect to an existing Wi-Fi or wired network.

**Installation Steps:**

1.  Start with a fresh Raspberry Pi OS (Legacy) Lite (bullseye) image ([download here](https://downloads.raspberrypi.com/raspios_oldstable_lite_armhf/images/raspios_oldstable_lite_armhf-2024-10-28/2024-10-22-raspios-bullseye-armhf-lite.img.xz)).
2.  Connect your Raspberry Pi 4 to your network.
3.  Open a terminal and execute the following commands:

    ```bash
    cd ~
    wget [https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server.sh](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/server_installation/prepare-airgapped-server.sh)
    chmod +x prepare-airgapped-server.sh
    ./prepare-airgapped-server.sh
    ```

4.  After installation, you'll need to update your computer's `hosts` file to map `airgap.droneengage.com` to the Raspberry Pi's IP address.

**Ready-to-Use Image:**

* Download: [rpi_4_sd_card_16G_airgap_server_image.img.xz](https://cloud.ardupilot.org/downloads/RPI_Full_Images/airgap_server_rpi4/rpi_4_sd_card_16G_airgap_server_image.img.xz)
* Web Interface: `https://airgap.droneengage.com:8001/index.html`
* Email: `single@airgap.droneengage.com`

**Helpful Resource:**

* Video Tutorial: [Isolated Server and Andruav Drone Engage](https://youtu.be/R1BedRTxuuY)

---

### 3. Creating Secure SSL Certificates

**Important:** For Air-Gapped Server without AP configurations, ensure your computer's `hosts` file is correctly configured.

**Procedure:**

1.  Add the [root.crt](https://github.com/DroneEngage/DroneEngage_ScriptWiki/blob/main/server_installation/root.crt) certificate to your browser's trusted root certificate authorities.

    ![browser_certificate.png](https://raw.githubusercontent.com/DroneEngage/DroneEngage_ScriptWiki/refs/heads/main/resources/browser_certificate.png)

2.  This step is crucial for establishing a valid SSL connection and avoiding security warnings.