#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

echo project = `gcloud config get-value project` \
    >> ~/.cbtrc

cbt listinstances

echo instance = personalized-sales \
    >> ~/.cbtrc


cat ~/.cbtrc

cbt createtable test-sessions

cbt createfamily test-sessions Interactions

cbt createfamily test-sessions Sales

cbt ls test-sessions

cbt read test-sessions

echo "${YELLOW}${BOLD}NOW${RESET}" "${WHITE}${BOLD}Check Your Progress${RESET}""${GREEN}${BOLD} For Task 3${RESET}"

sleep 120

cbt deletetable test-sessions

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#