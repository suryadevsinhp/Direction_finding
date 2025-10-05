#!/bin/bash

# Optimized KrakenSDR DOA Startup Script
# For dual SDR setup with common noise source and clock splitter

echo "Starting Optimized Dual KrakenSDR DOA System at $(date)"

# Performance monitoring
START_TIME=$(date +%s)

# Configuration
ENABLE_DUAL_SDR_OPTIMIZATION=true
ENABLE_PARALLEL_CALIBRATION=true
ENABLE_SHARED_CALIBRATION=true
ENABLE_CACHED_CALIBRATION=true

# Set environment variables for optimization
export KRAKEN_DUAL_SDR_MODE=1
export KRAKEN_OPTIMIZE_CALIBRATION=true
export KRAKEN_PARALLEL_PROCESSING=true
export KRAKEN_SHARED_CALIBRATION=true
export KRAKEN_USE_CACHED_CALIBRATION=true

# Source conda environment
source /home/krakenrf/miniforge3/etc/profile.d/conda.sh
conda activate kraken

# Clear cache if requested
while getopts c flag
do
    case "${flag}" in
        c) 
            echo "Clearing optimization cache..."
            rm -f /tmp/kraken_*_cache.json
            ;;
    esac
done

# Stop existing processes
echo "Stopping existing processes..."
./kraken_doa_stop.sh

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

sudo env "PATH=$PATH" ./daq_start_sm.sh $CONFIG_FILE

# Reduced sleep for faster startup
sleep 0.5

# Start KrakenSDR DOA with optimizations
cd ../../krakensdr_doa
echo "Starting optimized KrakenSDR DOA..."

# Set additional optimization flags
export KRAKEN_FAST_FREQUENCY_HOPPING=1
export KRAKEN_REDUCE_SAMPLE_COUNT=1
export KRAKEN_OPTIMIZE_MEMORY=1

sudo env "PATH=$PATH" ./gui_run.sh

# Performance summary
END_TIME=$(date +%s)
STARTUP_TIME=$((END_TIME - START_TIME))
echo "Optimized KrakenSDR DOA System started in ${STARTUP_TIME} seconds"
echo "Dual SDR optimizations enabled:"
echo "  - Parallel calibration: $ENABLE_PARALLEL_CALIBRATION"
echo "  - Shared calibration: $ENABLE_SHARED_CALIBRATION"
echo "  - Cached calibration: $ENABLE_CACHED_CALIBRATION"
