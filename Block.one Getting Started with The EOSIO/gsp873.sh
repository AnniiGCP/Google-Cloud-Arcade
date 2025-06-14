#!/bin/bash

# Authenticate and configure gcloud
gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

# Create VM instance
gcloud compute instances create my-vm-1 \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=e2-standard-2 \
  --image-family=ubuntu-2004-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --boot-disk-device-name=my-vm-1 \
  --boot-disk-type=pd-balanced

# Wait for the VM to be ready
sleep 60

# Create the EOSIO setup script
cat > gsp.sh <<'EOF_CP'
#!/bin/bash

# Update system
sudo apt update

# Install EOSIO
curl -LO https://github.com/eosio/eos/releases/download/v2.1.0/eosio_2.1.0-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio_2.1.0-1-ubuntu-20.04_amd64.deb

# Verify installation
nodeos --version
cleos version client
keosd -v

# Start nodeos in background
nodeos -e -p eosio --plugin eosio::chain_api_plugin --plugin eosio::history_api_plugin --contracts-console >> nodeos.log 2>&1 &

# Wait and show log
sleep 10
tail -n 15 nodeos.log

# Create and unlock wallet
cleos wallet create --name my_wallet --file my_wallet_password
cat my_wallet_password

export wallet_password=$(cat my_wallet_password)
cleos wallet open --name my_wallet
cleos wallet unlock --name my_wallet --password $wallet_password

# Import default private key
cleos wallet import --name my_wallet --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

# Install EOSIO.CDT
curl -LO https://github.com/eosio/eosio.cdt/releases/download/v1.8.1/eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb

# Verify eosio-cpp
eosio-cpp --version

# Create new keypair
cleos wallet open --name my_wallet
cleos wallet unlock --name my_wallet --password $wallet_password
cleos create key --file my_keypair1

cat my_keypair1

user_private_key=$(grep "Private key:" my_keypair1 | cut -d ' ' -f 3)
user_public_key=$(grep "Public key:" my_keypair1 | cut -d ' ' -f 3)

# Import user key
cleos wallet import --name my_wallet --private-key $user_private_key

# Create new EOSIO account
cleos create account eosio bob $user_public_key

EOF_CP

# Make script executable
chmod +x gsp.sh

# Copy script to VM and execute it remotely
gcloud compute scp gsp.sh my-vm-1:/tmp --project=$PROJECT_ID --zone=$ZONE --quiet
gcloud compute ssh my-vm-1 --project=$PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/gsp.sh"
