
# DroneEngage Air-Gapped Server Docker Image

  

This repository contains the Dockerfile and scripts to build an air-gapped server for DroneEngage. This setup automates the installation and configuration of all necessary components, including DroneEngage Authenticator, Server, Web Client, CoTurn, and a local map server.

  

## Table of Contents

  

- [Features](#features)

- [Prerequisites](#prerequisites)

- [Building the Docker Image](#building-the-docker-image)

- [Running the Docker Container](#running-the-docker-container)

- [Configuration](#configuration)

- [SSL Certificates](#ssl-certificates)

- [Accessing the Services](#accessing-the-services)

- [Local Maps](#local-maps)

- [Troubleshooting](#troubleshooting)

- [Contributing](#contributing)

- [License](#license)

  

## Features

  

- Automated setup of DroneEngage components (Authenticator, Server, Web Client).

- Installation and configuration of CoTurn for WebRTC.

- Local map server using `http-server` with SSL.

- Node.js and PM2 installation.

- SSL certificate management.

- Air-gapped environment setup.

  

## Prerequisites

  

- Docker installed on your system.

- Basic understanding of Docker and containerization.

- Git (optional, for cloning the repository).

  

## Building the Docker Image

  

1. Clone this repository (or download the files).

2. Navigate to the directory containing the Dockerfile.

3. Build the Docker image using the following command:

  

```bash
# delete Old one
docker image rm droneengage-airgap-server:latest -f

# Build New one
docker build -t droneengage-airgap-server .

```

  

## Running the Docker Container

  

Run the Docker container using the following command:

  
```bash

docker run -it --network host droneengage-airgap-server

```  

Note:  Using  --network  host  is  critical  for  the  coturn  service  to  function  correctly.  If  you're using docker desktop on windows or mac, you may need to forward the coturn ports manually.

  

## Configuration

The setup_airgap_server.sh script contains several configurable variables:

  

## DOMAIN_NAME: The domain name for the server (e.g., airgap.droneengage.com).

- IP: The IP address of the server (automatically detected, but can be manually set).

- MACHINE_IP: The IP address of the machine running the docker container.

- MIN_WEBRTC_PORTS and MAX_WEBRTC_PORTS: The range of ports for WebRTC.

- TURN_PWD: The username and password for CoTurn (e.g., airgap:1234).

- NODE_MAJOR: The major version of Node.js to install.

- REPOSITORY_AUTH, REPOSITORY_SERVER, REPOSITORY_WEBCLIENT: The Git repositories for DroneEngage components.

Modify these variables in the setup_airgap_server.sh script as needed before building the Docker image.

  

## SSL Certificates

The script includes a self-signed SSL certificate for testing purposes. However, it is highly recommended to replace these with your own certificates for production use.

  

Replace the contents of ssl/fullchain.pem, ssl/privkey.pem, and ssl/root.crt with your own certificates.

Ensure that the root.crt certificate is added to the trusted root certificates on all client devices (browsers, Android phones) to avoid SSL errors.

Place your map images in the /root/map/cachedMap directory.

## Accessing the Services

Web Client: Access the web client at https://<DOMAIN_NAME>:8001.

Local Maps: Access the local map server at https://<DOMAIN_NAME>:88.

## Local Maps

Place your map images in the /root/map/cachedMap directory.

The map server will serve these images over HTTPS.

Configure the DroneEngage web client to use these local map images.

The setup script creates a directory for local cached maps, and the start script runs a http-server on port 88 with SSL.

## Troubleshooting

- SSL Errors: Ensure that the root.crt certificate is installed on client devices.

- CoTurn Issues: Verify that the CoTurn configuration is correct and that the necessary ports are open. Check the docker logs for errors. Also verify that the network mode is set to host.

- Node.js/PM2 Issues: Check the Docker logs for any errors during installation or startup.

- Web Client Issues: Ensure that the web client is configured to use the correct server address and SSL certificate.

- Map Server issues: Check the docker logs for errors from the http-server. Verify that the map images are in the correct directory. Please check [Server Installation & Configuration](https://cloud.ardupilot.org/srv-Installation.html)

## Contributing

Contributions are welcome! Please submit a pull request or create an issue for any bugs or feature requests.
 

## License

This project is licensed under the MIT License.