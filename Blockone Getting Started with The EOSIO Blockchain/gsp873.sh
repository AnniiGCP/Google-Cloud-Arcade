#!/bin/bash


BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

# Box Drawing Characters
BOX_TOP="${CYAN}╔════════════════════════════════════════════╗${RESET}"
BOX_MID="${CYAN}║                                            ║${RESET}"
BOX_BOT="${CYAN}╚════════════════════════════════════════════╝${RESET}"



# Authentication Check
echo -e "${GREEN}${BOLD}🔐 Checking Authentication...${RESET}"
gcloud auth list
echo

# Set Project Configuration
echo -e "${GREEN}${BOLD}⚙️ Configuring Project Settings...${RESET}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/zone "$ZONE"
gcloud config set compute/region "$REGION"

echo -e "${YELLOW}✅ Project: ${WHITE}$PROJECT_ID${RESET}"
echo -e "${YELLOW}✅ Region: ${WHITE}$REGION${RESET}"
echo -e "${YELLOW}✅ Zone: ${WHITE}$ZONE${RESET}"
echo

# Create VM Instance
echo -e "${GREEN}${BOLD}🖥️ Creating EOSIO VM Instance (e2-standard-2)...${RESET}"
gcloud compute instances create my-vm-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --image-family=ubuntu-2004-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --boot-disk-device-name=my-vm-1 \
    --boot-disk-type=pd-balanced

echo -e "${YELLOW}⏳ Waiting 60 seconds for VM to initialize...${RESET}"
for i in {60..1}; do
    printf "\r${BLUE}Time remaining: %2d seconds...${RESET}" $i
    sleep 1
done
printf "\n"

# Prepare EOSIO Installation Script
echo -e "${GREEN}${BOLD}📝 Preparing EOSIO Installation Script...${RESET}"
cat > eosio-setup.sh <<'EOF'
#!/bin/bash
# EOSIO Installation Script

echo "=== Updating System Packages ==="
sudo apt update -y

echo "=== Installing EOSIO ==="
curl -LO https://github.com/eosio/eos/releases/download/v2.1.0/eosio_2.1.0-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio_2.1.0-1-ubuntu-20.04_amd64.deb

echo "=== Verifying Installations ==="
nodeos --version
cleos version client
keosd -v

echo "=== Starting Nodeos ==="
nodeos -e -p eosio \
  --plugin eosio::chain_api_plugin \
  --plugin eosio::history_api_plugin \
  --contracts-console >> nodeos.log 2>&1 &

sleep 10
tail -n 15 nodeos.log

echo "=== Setting Up Wallet ==="
cleos wallet create --name my_wallet --file my_wallet_password
export wallet_password=$(cat my_wallet_password)
cleos wallet open --name my_wallet
cleos wallet unlock --name my_wallet --password $wallet_password
cleos wallet import --name my_wallet --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

echo "=== Installing EOSIO.CDT ==="
curl -LO https://github.com/eosio/eosio.cdt/releases/download/v1.8.1/eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
sudo apt install -y ./eosio.cdt_1.8.1-1-ubuntu-20.04_amd64.deb
eosio-cpp --version

echo "=== Creating Test Account ==="
cleos create key --file my_keypair1
user_private_key=$(grep "Private key:" my_keypair1 | cut -d ' ' -f 3)
user_public_key=$(grep "Public key:" my_keypair1 | cut -d ' ' -f 3)
cleos wallet import --name my_wallet --private-key $user_private_key
cleos create account eosio bob $user_public_key

echo "=== Setup Complete ==="
EOF

# Transfer and Execute Script
echo -e "${GREEN}${BOLD}📤 Transferring Script to VM...${RESET}"
gcloud compute scp eosio-setup.sh my-vm-1:/tmp \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet

echo -e "${GREEN}${BOLD}🚀 Executing EOSIO Setup on VM...${RESET}"
gcloud compute ssh my-vm-1 \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --quiet \
    --command="chmod +x /tmp/eosio-setup.sh && bash /tmp/eosio-setup.sh"

