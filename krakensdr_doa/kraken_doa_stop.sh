#!/bin/bash

# Optimized KrakenSDR DOA Stop Script
# Fast shutdown with proper cleanup for dual SDR setup
# Based on complete KrakenSDR project structure

echo "Stopping Optimized KrakenSDR DOA System..."

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
pkill -f "rtl" 2>/dev/null || true
pkill -f "python.*kraken" 2>/dev/null || true

# Clean up optimization cache files
echo "Cleaning up optimization cache..."
rm -f /tmp/kraken_*_cache.json 2>/dev/null || true
rm -f /tmp/kraken_calibration_cache.json 2>/dev/null || true
rm -f /tmp/kraken_s1p_cache.json 2>/dev/null || true

# Clean up shared memory and temporary files
rm -f /dev/shm/kraken_* 2>/dev/null || true
rm -f /dev/shm/daq_* 2>/dev/null || true

# Clean up log files (optional)
if [ "$1" = "--clean-logs" ]; then
    echo "Cleaning up log files..."
    rm -f _share/logs/*.log 2>/dev/null || true
    rm -f heimdall_daq_fw/Firmware/_logs/*.log 2>/dev/null || true
fi

# Reset USB devices if needed (for dual SDR setup)
if [ -f "/usr/local/bin/kraken_reset_usb.sh" ]; then
    echo "Resetting USB devices for dual SDR setup..."
    /usr/local/bin/kraken_reset_usb.sh
fi

# Clean up Python cache
echo "Cleaning up Python cache..."
find . -name "*.pyc" -delete 2>/dev/null || true
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Performance summary
STOP_END_TIME=$(date +%s)
STOP_TIME=$((STOP_END_TIME - STOP_START_TIME))
echo ""
echo "=================================================="
echo "OPTIMIZED KRAKENSDR DOA SYSTEM STOPPED"
echo "=================================================="
echo "Total shutdown time: ${STOP_TIME} seconds"
echo "Cleanup completed successfully"
echo "  - Processes terminated"
echo "  - Cache files cleaned"
echo "  - Shared memory cleared"
echo "  - Python cache cleaned"
echo "=================================================="
