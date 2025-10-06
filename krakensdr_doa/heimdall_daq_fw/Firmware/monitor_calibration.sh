#!/bin/bash
#
# Calibration Monitoring Script for Dual KrakenSDR Setup
# Monitors calibration progress and sync status for both units
#
# Usage: ./monitor_calibration.sh [duration_seconds]
# Example: ./monitor_calibration.sh 300  (monitor for 5 minutes)
#

DURATION=${1:-60}  # Default 60 seconds
LOG_FILE="_logs/delay_sync.log"
HWC_LOG="_logs/hwc.log"

echo "=========================================="
echo "  Dual KrakenSDR Calibration Monitor"
echo "=========================================="
echo ""
echo "Monitoring for ${DURATION} seconds..."
echo "Press Ctrl+C to stop early"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get calibration state
get_cal_state() {
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE" | grep "current_state" | tail -1 | awk '{print $NF}'
    else
        echo "NO_LOG"
    fi
}

# Function to count sync failures
count_sync_fails() {
    if [ -f "$LOG_FILE" ]; then
        grep -c "sync may lost" "$LOG_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Function to get last calibration time
get_last_cal_time() {
    if [ -f "$HWC_LOG" ]; then
        grep "noise source burst" "$HWC_LOG" | tail -1 | awk '{print $1, $2}'
    else
        echo "Never"
    fi
}

# Function to check if in track mode
is_tracking() {
    if [ -f "$LOG_FILE" ]; then
        tail -10 "$LOG_FILE" | grep -q "STATE_TRACK" && echo "YES" || echo "NO"
    else
        echo "UNKNOWN"
    fi
}

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

while [ $(date +%s) -lt $END_TIME ]; do
    clear
    echo "=========================================="
    echo "  Dual KrakenSDR Calibration Monitor"
    echo "=========================================="
    echo ""
    
    CURRENT_STATE=$(get_cal_state)
    SYNC_FAILS=$(count_sync_fails)
    LAST_CAL=$(get_last_cal_time)
    IS_TRACK=$(is_tracking)
    
    echo -e "${BLUE}Current State:${NC} $CURRENT_STATE"
    echo -e "${BLUE}Tracking Mode:${NC} $IS_TRACK"
    echo -e "${BLUE}Total Sync Failures:${NC} $SYNC_FAILS"
    echo -e "${BLUE}Last Calibration:${NC} $LAST_CAL"
    echo ""
    
    # Status interpretation
    if [ "$IS_TRACK" = "YES" ]; then
        echo -e "${GREEN}✓ System is CALIBRATED and TRACKING${NC}"
    elif [ "$CURRENT_STATE" = "STATE_INIT" ]; then
        echo -e "${YELLOW}⟳ Initial calibration in progress...${NC}"
    elif [ "$CURRENT_STATE" = "STATE_SAMPLE_CAL" ]; then
        echo -e "${YELLOW}⟳ Sample delay calibration in progress...${NC}"
    elif [ "$CURRENT_STATE" = "STATE_IQ_CAL" ]; then
        echo -e "${YELLOW}⟳ IQ calibration in progress...${NC}"
    elif [ "$CURRENT_STATE" = "STATE_TRACK_LOCK" ]; then
        echo -e "${YELLOW}⟳ Entering track mode...${NC}"
    else
        echo -e "${RED}⚠ Unknown state: $CURRENT_STATE${NC}"
    fi
    
    echo ""
    echo "Recent Activity (last 5 entries):"
    echo "-----------------------------------"
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE" | grep -E "STATE_|Calibration|sync|noise source" | tail -5
    else
        echo "Log file not found"
    fi
    
    echo ""
    ELAPSED=$(($(date +%s) - START_TIME))
    REMAINING=$((DURATION - ELAPSED))
    echo "Time remaining: ${REMAINING}s"
    
    sleep 3
done

echo ""
echo "=========================================="
echo "  Monitoring Complete"
echo "=========================================="
echo ""
echo "Final Statistics:"
echo "-----------------"
echo "Total Sync Failures: $(count_sync_fails)"
echo "Final State: $(get_cal_state)"
echo "Tracking: $(is_tracking)"
echo ""

# Calculate calibration success
if [ "$(is_tracking)" = "YES" ]; then
    echo -e "${GREEN}✓ Calibration SUCCESSFUL${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Calibration still in progress or failed${NC}"
    echo "Check logs for details:"
    echo "  tail -100 $LOG_FILE"
    exit 1
fi
