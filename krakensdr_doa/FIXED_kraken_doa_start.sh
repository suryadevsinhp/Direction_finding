#!/bin/bash
#
# FIXED KrakenSDR Startup Script
# Automatically finds conda installation
#
# Usage: bash FIXED_kraken_doa_start.sh [-c]
# -c flag: clear Python cache before starting
#

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "   KrakenSDR Startup"
echo -e "==========================================${NC}"
echo ""

# Clear pycache if -c flag is given
while getopts c flag
do
    case "${flag}" in
        c) 
            echo -e "${YELLOW}Clearing Python cache...${NC}"
            sudo py3clean . 2>/dev/null || true
            echo -e "${GREEN}✓ Cache cleared${NC}"
            ;;
    esac
done

# Find conda installation
echo -e "${YELLOW}Looking for conda...${NC}"
CONDA_PATH=""

# Check if conda command exists
if command -v conda &> /dev/null; then
    echo -e "${GREEN}✓ Found conda in PATH${NC}"
    eval "$(conda shell.bash hook)"
else
    # Try common conda locations
    for path in \
        "$HOME/miniforge3/etc/profile.d/conda.sh" \
        "$HOME/miniconda3/etc/profile.d/conda.sh" \
        "$HOME/anaconda3/etc/profile.d/conda.sh" \
        "/opt/conda/etc/profile.d/conda.sh" \
        "/usr/local/miniconda3/etc/profile.d/conda.sh"; do
        
        if [ -f "$path" ]; then
            echo -e "${GREEN}✓ Found conda at: $path${NC}"
            CONDA_PATH="$path"
            source "$CONDA_PATH"
            break
        fi
    done
    
    if [ -z "$CONDA_PATH" ]; then
        echo -e "${RED}✗ Error: Cannot find conda installation${NC}"
        echo ""
        echo "Please install Miniconda or initialize conda:"
        echo "  conda init bash"
        echo "  source ~/.bashrc"
        exit 1
    fi
fi
echo ""

# Activate kraken environment
echo -e "${YELLOW}Activating kraken environment...${NC}"
if ! conda activate kraken 2>/dev/null; then
    echo -e "${RED}✗ Error: Cannot activate 'kraken' conda environment${NC}"
    echo ""
    echo "Available environments:"
    conda env list
    echo ""
    echo "Please create the kraken environment or activate manually"
    exit 1
fi
echo -e "${GREEN}✓ Kraken environment activated${NC}"
echo ""

# Stop any existing processes
echo -e "${YELLOW}Stopping existing processes...${NC}"
if [ -f "./kraken_doa_stop.sh" ]; then
    ./kraken_doa_stop.sh 2>/dev/null || true
else
    # Manual cleanup
    sudo pkill -f "rtl_daq" 2>/dev/null || true
    sudo pkill -f "python3.*app.py" 2>/dev/null || true
    sudo pkill -f "node.*index.js" 2>/dev/null || true
fi
sleep 2
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Start DAQ
echo -e "${YELLOW}Starting DAQ subsystem...${NC}"
if [ ! -d "heimdall_daq_fw/Firmware" ]; then
    echo -e "${RED}✗ Error: heimdall_daq_fw/Firmware not found${NC}"
    echo "Current directory: $(pwd)"
    echo "Please run this script from krakensdr_doa root"
    exit 1
fi

cd heimdall_daq_fw/Firmware
sudo env "PATH=$PATH" bash ./daq_start_sm.sh &
sleep 3
echo -e "${GREEN}✓ DAQ started${NC}"
echo ""

# Start GUI
echo -e "${YELLOW}Starting Web GUI...${NC}"
cd ../../krakensdr_doa

if [ ! -f "gui_run.sh" ]; then
    echo -e "${RED}✗ Error: gui_run.sh not found${NC}"
    exit 1
fi

sudo env "PATH=$PATH" bash ./gui_run.sh &
GUI_PID=$!
sleep 3

# Check if GUI started
if ps -p $GUI_PID > /dev/null 2>&1 || pgrep -f "python3.*app.py" > /dev/null; then
    echo -e "${GREEN}✓ GUI started${NC}"
else
    echo -e "${YELLOW}⚠ GUI may have backgrounded${NC}"
fi
echo ""

# Optional: Start TAK server
if [ -d "../Kraken-to-TAK-Python" ]; then
    echo -e "${YELLOW}Starting TAK Server...${NC}"
    cd ../Kraken-to-TAK-Python
    python KrakenToTAK.py >/dev/null 2>/dev/null &
    echo -e "${GREEN}✓ TAK Server started${NC}"
    cd ../krakensdr_doa
else
    echo "TAK Server not installed (optional)"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "   Startup Complete!"
echo -e "==========================================${NC}"
echo ""

# Get IP address
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_IP")

echo "Access your KrakenSDR at:"
echo "  Web Interface: http://$IP_ADDR:8080"
echo "  Data Output:   http://$IP_ADDR:8081"
echo ""

# Verify processes
echo "Checking processes..."
sleep 2

if pgrep -f "rtl_daq" > /dev/null; then
    echo -e "${GREEN}✓ DAQ running${NC}"
else
    echo -e "${RED}✗ DAQ not running${NC}"
fi

if pgrep -f "python3.*app.py" > /dev/null; then
    echo -e "${GREEN}✓ Web GUI running${NC}"
else
    echo -e "${YELLOW}⚠ Web GUI not detected${NC}"
    echo "Check logs: tail -50 krakensdr_doa/_share/logs/krakensdr_doa/ui.log"
fi

if pgrep -f "node.*index.js" > /dev/null; then
    echo -e "${GREEN}✓ Node middleware running${NC}"
else
    echo -e "${YELLOW}⚠ Node middleware not detected${NC}"
fi

echo ""
echo "If Web GUI not accessible:"
echo "1. Check firewall: sudo ufw status"
echo "2. Check GUI logs: tail -f krakensdr_doa/_share/logs/krakensdr_doa/ui.log"
echo "3. Try: http://localhost:8080"
echo "4. Check process: ps aux | grep 'python3.*app.py'"
echo ""
echo "To stop: bash kraken_doa_stop.sh"
echo ""
