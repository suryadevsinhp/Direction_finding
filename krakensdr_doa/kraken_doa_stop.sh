#!/bin/bash

# Optimized Dual KrakenSDR DOA Stop Script
# Fast shutdown with proper cleanup for dual SDR setup

echo "Stopping Dual KrakenSDR DOA System..."

# Performance monitoring
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

# Kill any remaining KrakenSDR processes
pkill -f "kraken" 2>/dev/null || true
pkill -f "daq" 2>/dev/null || true
pkill -f "heimdall" 2>/dev/null || true

# Clean up shared memory and temporary files
rm -f /tmp/kraken_* 2>/dev/null || true
rm -f /dev/shm/kraken_* 2>/dev/null || true

# Reset USB devices if needed (for dual SDR setup)
if [ -f "/usr/local/bin/kraken_reset_usb.sh" ]; then
    echo "Resetting USB devices for dual SDR setup..."
    /usr/local/bin/kraken_reset_usb.sh
fi

# Performance summary
STOP_END_TIME=$(date +%s)
STOP_TIME=$((STOP_END_TIME - STOP_START_TIME))
echo "Dual KrakenSDR DOA System stopped in ${STOP_TIME} seconds"
echo "Cleanup completed successfully"
