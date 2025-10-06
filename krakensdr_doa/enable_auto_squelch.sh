#!/bin/bash
#
# Quick Auto Squelch Enable Script
# Enables automatic squelch calculation for KrakenSDR
#
# Usage: bash enable_auto_squelch.sh [mode]
# Modes: auto (default), auto-channel, manual
#

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODE=${1:-auto}
SETTINGS_DIR="krakensdr_doa/_share"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

echo -e "${BLUE}=========================================="
echo "   Auto Squelch Configuration"
echo -e "==========================================${NC}"
echo ""

# Check if settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}Warning: Settings file not found at $SETTINGS_FILE${NC}"
    echo "This script should be run from the krakensdr_doa root directory"
    echo ""
    echo "Current directory: $(pwd)"
    echo ""
    exit 1
fi

echo "Current directory: $(pwd)"
echo "Settings file: $SETTINGS_FILE"
echo ""

# Backup settings
echo -e "${YELLOW}Creating backup...${NC}"
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}✓ Backup created${NC}"
echo ""

# Determine squelch mode
case "$MODE" in
    auto)
        SQUELCH_MODE="Auto"
        echo "Enabling: Auto squelch (global noise floor)"
        ;;
    auto-channel)
        SQUELCH_MODE="Auto Channel"
        echo "Enabling: Auto Channel squelch (per-VFO noise floor)"
        ;;
    manual)
        SQUELCH_MODE="Manual"
        echo "Setting: Manual squelch (fixed values)"
        ;;
    *)
        echo -e "${YELLOW}Unknown mode: $MODE${NC}"
        echo "Valid modes: auto, auto-channel, manual"
        exit 1
        ;;
esac
echo ""

# Update settings using Python
echo -e "${YELLOW}Updating settings...${NC}"
python3 << EOF
import json

try:
    with open('$SETTINGS_FILE', 'r') as f:
        settings = json.load(f)
    
    # Set default squelch mode
    settings['vfo_default_squelch_mode'] = '$SQUELCH_MODE'
    
    # Set all VFO modes to Default (inherit from vfo_default_squelch_mode)
    for i in range(8):
        key = f'vfo_squelch_mode_{i}'
        if key in settings:
            settings[key] = 'Default'
    
    # Write updated settings
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(settings, f, indent=2)
    
    print("✓ Settings updated successfully")
    
except Exception as e:
    print(f"✗ Error: {e}")
    exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Auto squelch configured${NC}"
    echo ""
    echo "Configuration:"
    echo "  Mode: $SQUELCH_MODE"
    echo "  Applied to: All VFOs (using Default)"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart the KrakenSDR system:"
    echo "   bash kraken_doa_stop.sh && sleep 2 && bash kraken_doa_start.sh"
    echo ""
    echo "2. Verify in web interface:"
    echo "   http://YOUR_IP:8080"
    echo ""
    echo "3. Check VFO cards - squelch values will update automatically"
    echo ""
    echo "To restore original settings:"
    echo "  cp ${SETTINGS_FILE}.backup.* $SETTINGS_FILE"
else
    echo -e "${RED}✗ Failed to update settings${NC}"
    exit 1
fi
