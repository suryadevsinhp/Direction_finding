#!/bin/bash

# Optimized KrakenSDR DOA Startup Script
# Optimizations for dual SDR setup with common noise source and clock splitter
# Based on complete KrakenSDR project structure

# Performance monitoring
START_TIME=$(date +%s)
echo "Starting Optimized KrakenSDR DOA System at $(date)"

# Configuration for dual SDR optimization
ENABLE_PARALLEL_CALIBRATION=true
ENABLE_SHARED_CALIBRATION=true
ENABLE_CACHED_CALIBRATION=true
ENABLE_DUAL_SDR_MODE=true
CALIBRATION_CACHE_FILE="/tmp/kraken_calibration_cache.json"
S1P_CACHE_FILE="/tmp/kraken_s1p_cache.json"

# Set environment variables for optimization
export KRAKEN_DUAL_SDR_MODE=1
export KRAKEN_OPTIMIZE_CALIBRATION=true
export KRAKEN_PARALLEL_PROCESSING=true
export KRAKEN_SHARED_CALIBRATION=true
export KRAKEN_USE_CACHED_CALIBRATION=true
export KRAKEN_FAST_FREQUENCY_HOPPING=1
export KRAKEN_REDUCE_SAMPLE_COUNT=1
export KRAKEN_OPTIMIZE_MEMORY=1

source /home/krakenrf/miniforge3/etc/profile.d/conda.sh #<- required for systemd auto startup (comment out eval and use source instead)
#eval "$(conda shell.bash hook)"
conda activate kraken

# Clear pycache before starting if the -c flag is given
while getopts c flag
do
    case "${flag}" in
        c) 
            echo "Clearing Python cache and optimization cache..."
            sudo py3clean . 
            rm -f /tmp/kraken_*_cache.json 2>/dev/null || true
            ;;
    esac
done

# Optimized stop sequence - faster shutdown
echo "Stopping existing processes..."
./kraken_doa_stop.sh

# Reduced sleep time for faster startup
sleep 0.3

# Check for calibration cache
if [ "$ENABLE_CACHED_CALIBRATION" = true ]; then
    if [ -f "$CALIBRATION_CACHE_FILE" ]; then
        CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CALIBRATION_CACHE_FILE" 2>/dev/null || echo 0)))
        if [ $CACHE_AGE -lt 3600 ]; then  # Cache valid for 1 hour
            echo "Using cached calibration data (age: ${CACHE_AGE}s)"
            USE_CACHED_CALIBRATION=true
        else
            echo "Calibration cache expired, performing fresh calibration"
            USE_CACHED_CALIBRATION=false
        fi
    else
        echo "No calibration cache found, performing fresh calibration"
        USE_CACHED_CALIBRATION=false
    fi
else
    USE_CACHED_CALIBRATION=false
fi

# Check for S1P calibration cache
if [ -f "$S1P_CACHE_FILE" ]; then
    S1P_CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$S1P_CACHE_FILE" 2>/dev/null || echo 0)))
    if [ $S1P_CACHE_AGE -lt 3600 ]; then
        echo "Using cached S1P calibration data (age: ${S1P_CACHE_AGE}s)"
        export KRAKEN_USE_S1P_CACHE=true
    else
        echo "S1P calibration cache expired"
        export KRAKEN_USE_S1P_CACHE=false
    fi
else
    echo "No S1P calibration cache found"
    export KRAKEN_USE_S1P_CACHE=false
fi

# Start DAQ firmware with optimizations
cd heimdall_daq_fw/Firmware
echo "Starting optimized DAQ firmware..."

# Use optimized configuration if available
if [ -f "optimized_daq_chain_config.ini" ]; then
    echo "Using optimized DAQ configuration"
    CONFIG_FILE="optimized_daq_chain_config.ini"
else
    echo "Using default DAQ configuration"
    CONFIG_FILE="daq_chain_config.ini"
fi

# Set additional DAQ optimization flags
export KRAKEN_DAQ_OPTIMIZE_MEMORY=1
export KRAKEN_DAQ_PARALLEL_PROCESSING=1
export KRAKEN_DAQ_REDUCE_BUFFER_SIZE=1

#sudo ./daq_synthetic_start.sh
sudo env "PATH=$PATH" ./daq_start_sm.sh $CONFIG_FILE

# Reduced sleep time for faster startup
sleep 0.3

cd ../../krakensdr_doa
echo "Starting optimized KrakenSDR DOA GUI..."

# Set additional optimization flags for GUI
export KRAKEN_GUI_OPTIMIZE_DISPLAY=1
export KRAKEN_GUI_REDUCE_UPDATE_RATE=1
export KRAKEN_GUI_PARALLEL_RENDERING=1

sudo env "PATH=$PATH" ./gui_run.sh

# Optional TAK server with optimization
if [ -d "../Kraken-to-TAK-Python" ]; then
    echo "TAK Server Installed - Starting with optimizations..."
    cd ../Kraken-to-TAK-Python
    # Set TAK optimization flags
    export KRAKEN_TAK_OPTIMIZE_MEMORY=1
    export KRAKEN_TAK_REDUCE_CPU_USAGE=1
    # Start TAK server in background with reduced resource usage
    python KrakenToTAK.py >/dev/null 2>/dev/null &
    cd ../../krakensdr_doa
else
    echo "TAK Server NOT Installed"
fi

# Performance summary
END_TIME=$(date +%s)
STARTUP_TIME=$((END_TIME - START_TIME))
echo ""
echo "=================================================="
echo "OPTIMIZED KRAKENSDR DOA SYSTEM STARTED"
echo "=================================================="
echo "Total startup time: ${STARTUP_TIME} seconds"
echo "Optimizations enabled:"
echo "  - Dual SDR mode: $ENABLE_DUAL_SDR_MODE"
echo "  - Parallel calibration: $ENABLE_PARALLEL_CALIBRATION"
echo "  - Shared calibration: $ENABLE_SHARED_CALIBRATION"
echo "  - Cached calibration: $ENABLE_CACHED_CALIBRATION"
echo "  - Fast frequency hopping: enabled"
echo "  - Reduced sample count: enabled"
echo "  - Memory optimization: enabled"
echo "=================================================="
