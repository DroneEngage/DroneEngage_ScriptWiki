#!/bin/bash
echo "--- Starting Complete Private PKI Setup ---"

# ----------------------------------------------------------------------
# 1. Configuration & Variables
# ----------------------------------------------------------------------

# Check for required input parameter (Domain Name)
if [ -z "$1" ]; then
    echo "ERROR: Please provide the domain name as the first argument."
    echo "Usage: $0 <your.domain.name>"
    exit 1
fi

# Define the Domain Name from the first argument
DOMAIN_NAME="$1"
echo "Target Domain Name set to: $DOMAIN_NAME" # Confirmation of input

# Define base directory where all generated files will be stored
BASE_DIR="/home/pi/ssl_local"

# Define names and paths for the CA
CA_NAME="DroneEngage_Provider_CA"
CA_DIR="$BASE_DIR/$CA_NAME"
CA_KEY="$CA_DIR/ca.key"
CA_CRT="$CA_DIR/ca.crt"
CA_CONFIG="$BASE_DIR/ca.cnf"

# Define names and paths for the Domain Certificate
DOMAIN_DIR="$BASE_DIR/$DOMAIN_NAME" # Changed to use the domain name for the directory
DOMAIN_KEY="$DOMAIN_DIR/domain.key"
DOMAIN_CSR="$DOMAIN_DIR/domain.csr"
DOMAIN_CRT="$DOMAIN_DIR/domain.crt"
DOMAIN_CONFIG="$BASE_DIR/domain.cnf"


# Ensure directories exist
mkdir -p "$CA_DIR"
mkdir -p "$DOMAIN_DIR"

echo "Setup directories created in $BASE_DIR."

# ----------------------------------------------------------------------
# 2. Create Configuration Files
# ----------------------------------------------------------------------

echo -e "\n--- Writing CA Configuration File ($CA_CONFIG) ---"
cat <<EOL > "$CA_CONFIG"
[req]
# Request settings
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
# CA Subject Information (Provider Identity)
C = US
ST = California
L = San Jose
O = DroneEngage Private PKI
OU = Certificate Authority
CN = DroneEngage Provider Root CA

[v3_ca]
# Certificate extensions for a Root CA
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOL

echo -e "\n--- Writing Domain Configuration File ($DOMAIN_CONFIG) ---"
cat <<EOL > "$DOMAIN_CONFIG"
[req]
# Request settings
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
# Domain Subject Information
C = US
ST = California
L = San Jose
O = DroneEngage Systems
OU = IT Operations
CN = ${DOMAIN_NAME}

[v3_req]
# Certificate extensions for a server certificate (SAN is crucial)
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
# List all hostnames this certificate is valid for
DNS.1 = ${DOMAIN_NAME}
# Add more DNS entries or IPs if needed, e.g., DNS.2 = shortname
EOL

# ----------------------------------------------------------------------
# 3. Generate the Provider CA (Root Certificate)
# ----------------------------------------------------------------------
echo -e "\n--- [STEP 1] Generating Provider CA Key and Certificate ---"

# 3a. Generate CA Private Key (4096-bit RSA)
openssl genrsa -out "$CA_KEY" 4096
chmod 600 "$CA_KEY" # Protect the key

# 3b. Generate Self-Signed CA Certificate (Valid for 10 years)
openssl req -x509 \
    -new \
    -nodes \
    -key "$CA_KEY" \
    -sha256 \
    -days 3650 \
    -config "$CA_CONFIG" \
    -extensions v3_ca \
    -out "$CA_CRT"

echo "Provider CA Root Key: $CA_KEY"
echo "Provider CA Root Cert: $CA_CRT"
echo "NOTE: Distribute $CA_CRT to all client devices for trust."

# ----------------------------------------------------------------------
# 4. Generate and Sign the Domain Certificate
# ----------------------------------------------------------------------
echo -e "\n--- [STEP 2] Generating Domain Key and CSR ---"

# 4a. Generate Domain Private Key (2048-bit RSA)
openssl genrsa -out "$DOMAIN_KEY" 2048
chmod 600 "$DOMAIN_KEY" # Protect the key

# 4b. Create Certificate Signing Request (CSR)
openssl req -new \
    -key "$DOMAIN_KEY" \
    -out "$DOMAIN_CSR" \
    -config "$DOMAIN_CONFIG"

echo -e "\n--- [STEP 3] Signing the Domain CSR with the Provider CA ---"

# Create a serial file for the CA (mandatory for signing the first certificate)
# If this CA has signed certificates before, this file should already exist.
if [ ! -f "$CA_DIR/serial" ]; then
    echo 1000 > "$CA_DIR/serial"
fi

# Sign the domain certificate (Valid for 10 years, matching CA for simplicity)
openssl x509 -req \
    -in "$DOMAIN_CSR" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$DOMAIN_CRT" \
    -days 3650 \
    -sha256 \
    -extfile "$DOMAIN_CONFIG" \
    -extensions v3_req


ln -s "$DOMAIN_DIR" "$BASE_DIR/ssl_airgap"

echo "---------------------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "Server Key: $DOMAIN_KEY"
echo "Server Cert: $DOMAIN_CRT"
echo "---------------------------------------------------------------------"
echo "Files ready to be installed on the $DOMAIN_NAME web server."