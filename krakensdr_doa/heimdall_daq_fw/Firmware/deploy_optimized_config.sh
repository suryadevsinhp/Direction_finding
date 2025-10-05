#!/bin/bash
#
# Automated Deployment Script for Optimized Dual KrakenSDR Configuration
# This script helps deploy the optimized calibration settings safely
#
# Usage: ./deploy_optimized_config.sh [unit_number]
# Example: ./deploy_optimized_config.sh 1  (for Unit 1 - Master)
#          ./deploy_optimized_config.sh 2  (for Unit 2 - Slave)
#

set -e  # Exit on error

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

UNIT=${1:-1}

echo -e "${BLUE}=========================================="
echo "  Dual KrakenSDR Configuration Deployer"
echo -e "==========================================${NC}"
echo ""

if [ "$UNIT" != "1" ] && [ "$UNIT" != "2" ]; then
    echo -e "${RED}Error: Please specify unit number (1 or 2)${NC}"
    echo "Usage: $0 [1|2]"
    echo "  1 = Master (CH 0-4, controls noise source)"
    echo "  2 = Slave (CH 5-9, does not control noise source)"
    exit 1
fi

echo -e "${YELLOW}Deploying configuration for Unit ${UNIT}${NC}"
echo ""

# Check if backups exist
if [ ! -f "daq_chain_config.ini.backup" ]; then
    echo -e "${YELLOW}Creating backup of current configuration...${NC}"
    cp daq_chain_config.ini daq_chain_config.ini.backup
    echo -e "${GREEN}✓ Backup created${NC}"
else
    echo -e "${GREEN}✓ Backup already exists${NC}"
fi

echo ""
echo "Current Configuration:"
echo "----------------------"
echo "Number of channels: $(grep "num_ch =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Correlation size: $(grep "corr_size =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Cal frame interval: $(grep "cal_frame_interval =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Noise source control: $(grep "en_noise_source_ctr =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo ""

read -p "Do you want to apply optimized settings? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Applying optimized configuration for Unit ${UNIT}...${NC}"

if [ "$UNIT" = "1" ]; then
    # Unit 1 is Master
    echo "Deploying Master configuration (Unit 1):"
    echo "  - Channels: 0-4 (5 channels)"
    echo "  - Controls noise source: YES"
    echo "  - Calibration mode: Burst (mode 2)"
    
    # The optimized config is already in daq_chain_config.ini
    # Just verify it's correct
    if grep -q "unit_id = 0" daq_chain_config.ini && \
       grep -q "num_ch = 5" daq_chain_config.ini && \
       grep -q "en_noise_source_ctr = 1" daq_chain_config.ini; then
        echo -e "${GREEN}✓ Master configuration already applied${NC}"
    else
        echo -e "${RED}✗ Configuration mismatch - please check daq_chain_config.ini${NC}"
        exit 1
    fi
    
else
    # Unit 2 is Slave
    echo "Deploying Slave configuration (Unit 2):"
    echo "  - Channels: 5-9 (5 channels)"
    echo "  - Controls noise source: NO"
    echo "  - Calibration mode: Continuous tracking (mode 1)"
    
    # Copy Unit 2 config to active config
    if [ -f "daq_chain_config5.ini" ]; then
        cp daq_chain_config5.ini daq_chain_config.ini
        echo -e "${GREEN}✓ Slave configuration applied${NC}"
    else
        echo -e "${RED}✗ daq_chain_config5.ini not found${NC}"
        exit 1
    fi
fi

echo ""
echo "New Configuration:"
echo "------------------"
echo "Number of channels: $(grep "num_ch =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Unit ID: $(grep "unit_id =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Correlation size: $(grep "corr_size =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Cal frame interval: $(grep "cal_frame_interval =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Cal frame burst size: $(grep "cal_frame_burst_size =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Cal track mode: $(grep "cal_track_mode =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Noise source control: $(grep "en_noise_source_ctr =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Amplitude tolerance: $(grep "amplitude_tolerance =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo "Phase tolerance: $(grep "phase_tolerance =" daq_chain_config.ini | awk -F'=' '{print $2}' | tr -d ' ')"
echo ""

echo -e "${GREEN}=========================================="
echo "  Configuration Deployed Successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Next Steps:"
echo "-----------"

if [ "$UNIT" = "1" ]; then
    echo "1. Start Master unit first:"
    echo "   cd ~/krakensdr"
    echo "   ./kraken_doa_start.sh"
    echo ""
    echo "2. Wait for Master to reach STATE_TRACK (~90 seconds)"
    echo "   ./monitor_calibration.sh 180"
    echo ""
    echo "3. Then start Slave unit (Unit 2)"
    echo ""
    echo "4. Monitor both units for successful calibration"
else
    echo "1. Ensure Master unit (Unit 1) is already running"
    echo ""
    echo "2. Start Slave unit:"
    echo "   cd ~/krakensdr"
    echo "   ./kraken_doa_start.sh"
    echo ""
    echo "3. Monitor calibration:"
    echo "   ./monitor_calibration.sh 180"
    echo ""
    echo "4. Verify Slave reaches STATE_TRACK within 90 seconds"
fi

echo ""
echo -e "${BLUE}Tip: Run './monitor_calibration.sh 180' to watch calibration progress${NC}"
echo ""
echo "To rollback to previous configuration:"
echo "  cp daq_chain_config.ini.backup daq_chain_config.ini"
echo ""
