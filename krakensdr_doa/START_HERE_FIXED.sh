#!/bin/bash
#
# FIXED Startup Script for KrakenSDR
# This script can be run from anywhere
#
# Usage: bash START_HERE_FIXED.sh
#

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "   KrakenSDR Startup Script"
echo -e "==========================================${NC}"
echo ""

# Find the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KRAKEN_ROOT="$SCRIPT_DIR"

echo -e "${YELLOW}Working directory: $KRAKEN_ROOT${NC}"
echo ""

# Check if we're in the right place
if [ ! -d "$KRAKEN_ROOT/heimdall_daq_fw" ] || [ ! -d "$KRAKEN_ROOT/krakensdr_doa" ]; then
    echo -e "${RED}Error: Cannot find heimdall_daq_fw or krakensdr_doa directories${NC}"
    echo "Current directory: $KRAKEN_ROOT"
    echo "Please run this script from the krakensdr_doa root directory"
    exit 1
fi

echo -e "${GREEN}✓ Found required directories${NC}"
echo ""

# Check conda
if ! command -v conda &> /dev/null; then
    echo -e "${RED}Error: conda is not installed or not in PATH${NC}"
    echo "Please install Miniconda or Anaconda first"
    exit 1
fi

# Initialize conda if needed
echo -e "${YELLOW}Initializing conda...${NC}"
eval "$(conda shell.bash hook)" || {
    echo -e "${YELLOW}Trying alternative conda initialization...${NC}"
    # Try common conda locations
    for conda_path in \
        "$HOME/miniforge3/etc/profile.d/conda.sh" \
        "$HOME/miniconda3/etc/profile.d/conda.sh" \
        "$HOME/anaconda3/etc/profile.d/conda.sh" \
        "/opt/conda/etc/profile.d/conda.sh"; do
        if [ -f "$conda_path" ]; then
            echo "Found conda at: $conda_path"
            source "$conda_path"
            break
        fi
    done
}

# Activate kraken environment
echo -e "${YELLOW}Activating kraken environment...${NC}"
if ! conda activate kraken 2>/dev/null; then
    echo -e "${RED}Error: Cannot activate 'kraken' conda environment${NC}"
    echo ""
    echo "Please create the kraken environment first:"
    echo "  conda create -n kraken python=3.10"
    echo "  conda activate kraken"
    echo "  # Install required packages..."
    exit 1
fi

echo -e "${GREEN}✓ Conda environment activated${NC}"
echo ""

# Stop any existing processes
echo -e "${YELLOW}Stopping any existing processes...${NC}"
cd "$KRAKEN_ROOT/krakensdr_doa/util"
if [ -f "kraken_doa_stop.sh" ]; then
    bash kraken_doa_stop.sh || true
fi
sleep 2
echo -e "${GREEN}✓ Stopped${NC}"
echo ""

# Start DAQ
echo -e "${YELLOW}Starting DAQ subsystem...${NC}"
cd "$KRAKEN_ROOT/heimdall_daq_fw/Firmware"
if [ ! -f "daq_start_sm.sh" ]; then
    echo -e "${RED}Error: daq_start_sm.sh not found${NC}"
    exit 1
fi
sudo env "PATH=$PATH" bash ./daq_start_sm.sh &
DAQ_PID=$!
sleep 3

# Check if DAQ started
if ! ps -p $DAQ_PID > /dev/null 2>&1; then
    echo -e "${YELLOW}DAQ may have backgrounded itself${NC}"
fi
echo -e "${GREEN}✓ DAQ started${NC}"
echo ""

# Start GUI
echo -e "${YELLOW}Starting GUI...${NC}"
cd "$KRAKEN_ROOT/krakensdr_doa"
if [ ! -f "gui_run.sh" ]; then
    echo -e "${RED}Error: gui_run.sh not found${NC}"
    exit 1
fi
sudo env "PATH=$PATH" bash ./gui_run.sh &
sleep 2
echo -e "${GREEN}✓ GUI started${NC}"
echo ""

# Check if TAK server exists
if [ -d "$KRAKEN_ROOT/Kraken-to-TAK-Python" ]; then
    echo -e "${YELLOW}Starting TAK Server...${NC}"
    cd "$KRAKEN_ROOT/Kraken-to-TAK-Python"
    python KrakenToTAK.py >/dev/null 2>/dev/null &
    echo -e "${GREEN}✓ TAK Server started${NC}"
else
    echo -e "${YELLOW}TAK Server not installed (optional)${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "   KrakenSDR Started Successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Web Interface: http://$(hostname -I | awk '{print $1}'):8080"
echo "Data Output: http://$(hostname -I | awk '{print $1}'):8081"
echo ""
echo "To monitor calibration:"
echo "  cd $KRAKEN_ROOT/heimdall_daq_fw/Firmware"
echo "  bash ./monitor_calibration.sh 180"
echo ""
echo "To stop:"
echo "  cd $KRAKEN_ROOT/krakensdr_doa/util"
echo "  bash ./kraken_doa_stop.sh"
echo ""
