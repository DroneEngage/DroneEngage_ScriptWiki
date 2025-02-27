# Use the official Ubuntu 22.04 as a base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    gnupg \
    dnsmasq \
    coturn \
    build-essential \
    net-tools \
    cmake \
    libzmq3-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*



# Copy the setup script into the container
COPY setup_airgap_server.sh /root/setup_airgap_server.sh
COPY start.sh /root/start.sh

# Make the script executable
RUN chmod +x /root/setup_airgap_server.sh
RUN chmod +x /root/start.sh

# Run the setup script during the image build
RUN /root/setup_airgap_server.sh

# Copy SSL certificates into the container
COPY ssl /root/ssl

# Set the working directory
WORKDIR /root

# Run the setup script when the container starts
CMD ["/bin/bash", "/root/start.sh"]