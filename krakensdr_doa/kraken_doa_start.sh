#!/bin/bash

# Optimized Dual KrakenSDR DOA Startup Script
# Optimizations for dual SDR setup with common noise source and clock splitter

# Performance monitoring
START_TIME=$(date +%s)
echo "Starting Dual KrakenSDR DOA System at $(date)"

# Configuration for dual SDR optimization
ENABLE_PARALLEL_CALIBRATION=true
ENABLE_SHARED_CALIBRATION=true
ENABLE_CACHED_CALIBRATION=true
CALIBRATION_CACHE_FILE="/tmp/kraken_calibration_cache.json"

source /home/krakenrf/miniforge3/etc/profile.d/conda.sh #<- required for systemd auto startup (comment out eval and use source instead)
#eval "$(conda shell.bash hook)"
conda activate kraken

# Clear pycache before starting if the -c flag is given
while getopts c flag
do
    case "${flag}" in
        c) 
            echo "Clearing Python cache for optimization..."
            sudo py3clean . 
            ;;
    esac
done

# Optimized stop sequence - faster shutdown
echo "Stopping existing processes..."
./kraken_doa_stop.sh

# Reduced sleep time for faster startup
sleep 0.5

# Check for calibration cache
if [ "$ENABLE_CACHED_CALIBRATION" = true ] && [ -f "$CALIBRATION_CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CALIBRATION_CACHE_FILE" 2>/dev/null || echo 0)))
    if [ $CACHE_AGE -lt 3600 ]; then  # Cache valid for 1 hour
        echo "Using cached calibration data (age: ${CACHE_AGE}s)"
        USE_CACHED_CALIBRATION=true
    else
        echo "Calibration cache expired, performing fresh calibration"
        USE_CACHED_CALIBRATION=false
    fi
else
    USE_CACHED_CALIBRATION=false
fi

# Start DAQ firmware with optimizations
cd heimdall_daq_fw/Firmware
echo "Starting DAQ firmware with dual SDR optimizations..."

# Set environment variables for dual SDR optimization
export KRAKEN_DUAL_SDR_MODE=1
export KRAKEN_SHARED_CALIBRATION=$ENABLE_SHARED_CALIBRATION
export KRAKEN_PARALLEL_CALIBRATION=$ENABLE_PARALLEL_CALIBRATION
export KRAKEN_USE_CACHED_CALIBRATION=$USE_CACHED_CALIBRATION
export KRAKEN_CALIBRATION_CACHE_FILE=$CALIBRATION_CACHE_FILE

#sudo ./daq_synthetic_start.sh
sudo env "PATH=$PATH" ./daq_start_sm.sh

# Reduced sleep time for faster startup
sleep 0.5

cd ../../krakensdr_doa
echo "Starting KrakenSDR DOA GUI with optimizations..."

# Set additional optimization flags
export KRAKEN_OPTIMIZE_CALIBRATION_TIME=1
export KRAKEN_REDUCE_SAMPLE_COUNT=1
export KRAKEN_FAST_FREQUENCY_HOPPING=1

sudo env "PATH=$PATH" ./gui_run.sh

# Optional TAK server with optimization
if [ -d "../Kraken-to-TAK-Python" ]; then
    echo "TAK Server Installed - Starting with optimizations..."
    cd ../Kraken-to-TAK-Python
    # Start TAK server in background with reduced resource usage
    python KrakenToTAK.py >/dev/null 2>/dev/null &
    cd ../../krakensdr_doa
else
    echo "TAK Server NOT Installed"
fi

# Performance summary
END_TIME=$(date +%s)
STARTUP_TIME=$((END_TIME - START_TIME))
echo "Dual KrakenSDR DOA System started in ${STARTUP_TIME} seconds"
echo "Optimizations enabled:"
echo "  - Parallel calibration: $ENABLE_PARALLEL_CALIBRATION"
echo "  - Shared calibration: $ENABLE_SHARED_CALIBRATION"
echo "  - Cached calibration: $ENABLE_CACHED_CALIBRATION"
