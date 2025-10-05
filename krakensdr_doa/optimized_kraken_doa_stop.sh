#!/bin/bash

# Optimized KrakenSDR DOA Stop Script
# Fast shutdown with proper cleanup for dual SDR setup

echo "Stopping Optimized Dual KrakenSDR DOA System..."

STOP_START_TIME=$(date +%s)

# Stop DAQ firmware
cd heimdall_daq_fw/Firmware
echo "Stopping DAQ firmware..."
./daq_stop.sh

# Fast return to main directory
cd ../../krakensdr_doa

# Optimized process termination
echo "Terminating KrakenSDR processes..."
./kill.sh

# Additional cleanup for dual SDR setup
echo "Cleaning up dual SDR resources..."

# Kill any remaining processes
pkill -f "kraken" 2>/dev/null || true
pkill -f "daq" 2>/dev/null || true
pkill -f "heimdall" 2>/dev/null || true

# Clean up optimization cache
rm -f /tmp/kraken_*_cache.json 2>/dev/null || true

# Clean up shared memory
rm -f /dev/shm/kraken_* 2>/dev/null || true

# Performance summary
STOP_END_TIME=$(date +%s)
STOP_TIME=$((STOP_END_TIME - STOP_START_TIME))
echo "Optimized KrakenSDR DOA System stopped in ${STOP_TIME} seconds"
echo "Cleanup completed successfully"
