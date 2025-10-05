#!/bin/bash
#
# Quick Start Script for Dual KrakenSDR Setup
# Automated startup with monitoring
#
# Usage: ./QUICK_START.sh [unit_number]
# Example: ./QUICK_START.sh 1  (Start Unit 1 - Master)
#          ./QUICK_START.sh 2  (Start Unit 2 - Slave)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

UNIT=${1:-1}
MONITOR_TIME=180

echo -e "${BLUE}=========================================="
echo "   KrakenSDR Quick Start Script"
echo -e "==========================================${NC}"
echo ""

if [ "$UNIT" != "1" ] && [ "$UNIT" != "2" ]; then
    echo -e "${RED}Error: Please specify unit number (1 or 2)${NC}"
    echo "Usage: $0 [1|2]"
    echo ""
    echo "  1 = Master Unit (CH 0-4) - Start this FIRST"
    echo "  2 = Slave Unit (CH 5-9) - Start AFTER Master is tracking"
    exit 1
fi

if [ "$UNIT" = "1" ]; then
    echo -e "${GREEN}Starting Unit 1 (Master - CH 0-4)${NC}"
    echo "This unit controls the noise source"
else
    echo -e "${GREEN}Starting Unit 2 (Slave - CH 5-9)${NC}"
    echo "This unit follows Master's calibration schedule"
    echo ""
    echo -e "${YELLOW}WARNING: Make sure Unit 1 is running and in STATE_TRACK first!${NC}"
    read -p "Is Unit 1 already tracking? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Please start Unit 1 first, wait for STATE_TRACK, then start Unit 2${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Step 1: Stopping any existing processes...${NC}"
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh || true
sleep 2
echo -e "${GREEN}✓ Stopped${NC}"

echo ""
echo -e "${YELLOW}Step 2: Deploying optimized configuration...${NC}"
cd heimdall_daq_fw/Firmware
./deploy_optimized_config.sh $UNIT <<< "y"
echo -e "${GREEN}✓ Configuration deployed${NC}"

echo ""
echo -e "${YELLOW}Step 3: Starting KrakenSDR system...${NC}"
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_start.sh

echo ""
echo -e "${GREEN}✓ System started${NC}"
echo ""

# Wait a moment for logs to be created
sleep 5

echo -e "${YELLOW}Step 4: Monitoring calibration (${MONITOR_TIME}s)...${NC}"
echo ""
echo "This will automatically monitor the calibration progress."
echo "You should see STATE_TRACK within 60-90 seconds."
echo ""
read -p "Press Enter to start monitoring (or Ctrl+C to skip)..."

cd ~/krakensdr/heimdall_daq_fw/Firmware
if [ -f "./monitor_calibration.sh" ]; then
    ./monitor_calibration.sh $MONITOR_TIME
else
    echo -e "${YELLOW}Monitoring script not found, showing manual status...${NC}"
    echo ""
    for i in {1..30}; do
        echo "=== Status Check $i/30 ==="
        if [ -f "_logs/delay_sync.log" ]; then
            tail -5 _logs/delay_sync.log | grep -E "STATE_|calibration|sync"
        else
            echo "Waiting for logs..."
        fi
        echo ""
        sleep 3
    done
fi

echo ""
echo -e "${BLUE}=========================================="
echo "   Startup Complete!"
echo -e "==========================================${NC}"
echo ""

# Final status check
if [ -f "heimdall_daq_fw/Firmware/_logs/delay_sync.log" ]; then
    if grep -q "STATE_TRACK" heimdall_daq_fw/Firmware/_logs/delay_sync.log; then
        echo -e "${GREEN}✓ Unit $UNIT is TRACKING!${NC}"
        echo ""
        echo "System is ready for DoA processing!"
        echo ""
        if [ "$UNIT" = "1" ]; then
            echo "Next step: Start Unit 2 (Slave)"
            echo "  ./QUICK_START.sh 2"
        else
            echo "Both units are now running!"
            echo "Access web interface at: http://$(hostname -I | awk '{print $1}'):8080"
        fi
    else
        echo -e "${YELLOW}⚠ System started but not yet tracking${NC}"
        echo "Check status: tail -f heimdall_daq_fw/Firmware/_logs/delay_sync.log"
    fi
else
    echo -e "${YELLOW}⚠ Log file not found${NC}"
    echo "System may still be initializing..."
fi

echo ""
echo "Useful commands:"
echo "  - Monitor logs: tail -f heimdall_daq_fw/Firmware/_logs/delay_sync.log"
echo "  - Check status: ./heimdall_daq_fw/Firmware/monitor_calibration.sh 60"
echo "  - Stop system: ./krakensdr_doa/util/kraken_doa_stop.sh"
echo "  - Web interface: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
