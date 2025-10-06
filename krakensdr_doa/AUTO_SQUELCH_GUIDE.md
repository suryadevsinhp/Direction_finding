# 🎯 Auto Squelch Configuration Guide

## Overview

KrakenSDR **already has built-in auto squelch functionality**! This guide shows you how to enable and configure it.

---

## 📋 Available Squelch Modes

### **1. Manual Mode**
- You manually set the squelch value
- Best when you know your signal characteristics
- Fixed threshold value

### **2. Auto Mode** ⭐ (Recommended)
- Automatically calculates squelch based on **average noise level**
- Single threshold for all VFOs
- Adapts to overall spectrum conditions
- **Best for most users**

### **3. Auto Channel Mode**
- Automatically calculates squelch **per VFO channel**
- Each VFO gets its own threshold based on local noise
- Best for signals with varying noise levels
- More adaptive but requires more processing

---

## ✅ HOW TO ENABLE AUTO SQUELCH

### **Method 1: Edit Settings File (Recommended)**

```bash
cd ~/krakensdr_doa/krakensdr_doa/_share

# Backup first
cp settings.json settings.json.backup

# Edit settings
nano settings.json
```

**Change these values:**

```json
{
  "vfo_default_squelch_mode": "Auto",        ← Change from "Manual" to "Auto"
  
  "vfo_squelch_mode_0": "Default",           ← Use "Default" to inherit from above
  "vfo_squelch_mode_1": "Default",           ← Or set to "Auto" explicitly
  "vfo_squelch_mode_2": "Default",
  
  // For per-VFO auto squelch, use "Auto Channel":
  "vfo_squelch_mode_0": "Auto Channel",      ← Independent auto squelch per VFO
}
```

### **Method 2: Via Web Interface**

1. **Open Web Interface:** `http://YOUR_IP:8080`

2. **Go to VFO Configuration Card**

3. **Set Default Squelch Mode:**
   - Find "VFO Default Squelch Mode" dropdown
   - Select **"Auto"** or **"Auto Channel"**

4. **For Each VFO:**
   - In VFO card, find "Squelch Mode" dropdown
   - Select **"Default"** (inherits from default setting)
   - Or select **"Auto"** or **"Auto Channel"** explicitly

5. **Click "Update Receiver Parameters"**

---

## 🔧 CONFIGURATION OPTIONS

### **Quick Setup for Auto Squelch**

Edit `settings.json`:

```json
{
  "center_freq": 430.0,
  "uniform_gain": 49.6,
  
  // Global auto squelch setting
  "vfo_default_squelch_mode": "Auto",       ← Enable auto squelch by default
  
  // VFO 0 configuration
  "vfo_freq_0": 430000000,                  ← Your frequency
  "vfo_bw_0": 344000,                       ← Your bandwidth
  "vfo_squelch_mode_0": "Default",          ← Use default (Auto)
  "vfo_squelch_0": -39,                     ← Initial value (will be auto-calculated)
  
  // Other VFOs
  "vfo_squelch_mode_1": "Default",
  "vfo_squelch_mode_2": "Default",
  "active_vfos": 1                          ← Number of active VFOs
}
```

### **Advanced: Per-VFO Auto Squelch**

For different squelch behavior per VFO:

```json
{
  "vfo_default_squelch_mode": "Auto",
  
  // VFO 0: Auto (global)
  "vfo_squelch_mode_0": "Auto",
  
  // VFO 1: Auto Channel (local)
  "vfo_squelch_mode_1": "Auto Channel",
  
  // VFO 2: Manual (fixed)
  "vfo_squelch_mode_2": "Manual",
  "vfo_squelch_2": -45
}
```

---

## 📊 HOW AUTO SQUELCH WORKS

### **Auto Mode Algorithm:**

1. **Spectrum Analysis:**
   - Calculates average noise floor across spectrum
   - Identifies noise level in dB

2. **Threshold Calculation:**
   - Sets squelch threshold above noise floor
   - Typically: `noise_floor + margin_dB`
   - Default margin: ~6-10 dB above noise

3. **Applied to All VFOs:**
   - Same threshold used for all VFOs
   - Updated periodically based on spectrum changes

### **Auto Channel Mode Algorithm:**

1. **Per-VFO Analysis:**
   - Analyzes noise near each VFO frequency
   - Calculates local noise floor

2. **Independent Thresholds:**
   - Each VFO gets its own threshold
   - Adapts to local RF environment

3. **Best For:**
   - Wide frequency ranges
   - Varying noise conditions
   - Multiple signals with different SNR

---

## 🎯 RECOMMENDED SETTINGS

### **For Most Users:**

```json
{
  "vfo_default_squelch_mode": "Auto",
  "vfo_squelch_mode_0": "Default",
  "vfo_bw_0": 344000,
  "vfo_freq_0": 430000000
}
```

**Why:** Simple, automatic, works well in most conditions.

### **For Weak Signals:**

```json
{
  "vfo_default_squelch_mode": "Auto Channel",
  "vfo_squelch_mode_0": "Auto Channel",
  "en_optimize_short_bursts": true
}
```

**Why:** Per-channel adaptation gives better sensitivity.

### **For Strong Stable Signals:**

```json
{
  "vfo_default_squelch_mode": "Manual",
  "vfo_squelch_mode_0": "Manual",
  "vfo_squelch_0": -35
}
```

**Why:** Manual control when signal is predictable.

---

## 🔄 UPDATE PROCEDURE

### **1. Stop the System**

```bash
cd ~/krakensdr_doa
bash krakensdr_doa/util/kraken_doa_stop.sh
```

### **2. Edit Settings**

```bash
nano krakensdr_doa/_share/settings.json
```

Change:
```json
"vfo_default_squelch_mode": "Auto"
"vfo_squelch_mode_0": "Default"
```

Save: `Ctrl+O`, `Enter`, `Ctrl+X`

### **3. Restart System**

```bash
bash krakensdr_doa/util/kraken_doa_start.sh
```

### **4. Verify in Web Interface**

1. Open `http://YOUR_IP:8080`
2. Check VFO card shows auto-calculated squelch values
3. Squelch slider should be hidden (auto mode)

---

## 📈 MONITORING AUTO SQUELCH

### **Check Current Squelch Values:**

```bash
# View settings
cat krakensdr_doa/_share/settings.json | grep -A2 squelch

# Output shows:
# "vfo_default_squelch_mode": "Auto",
# "vfo_squelch_mode_0": "Default",
# "vfo_squelch_0": -42.5,  ← Auto-calculated value
```

### **In Web Interface:**

1. Open `http://YOUR_IP:8080`
2. Go to VFO card
3. When mode is "Auto", the squelch value updates automatically
4. Value shown is the calculated threshold in dB

---

## 🔍 TROUBLESHOOTING

### **Issue: Auto squelch not working**

**Check:**
```bash
grep "vfo_default_squelch_mode" krakensdr_doa/_share/settings.json
```

**Should show:**
```json
"vfo_default_squelch_mode": "Auto"
```

**Fix:**
```bash
nano krakensdr_doa/_share/settings.json
# Change to "Auto"
# Restart system
```

### **Issue: Squelch too sensitive (missing signals)**

**Options:**

1. **Use Auto Channel mode:**
   ```json
   "vfo_default_squelch_mode": "Auto Channel"
   ```

2. **Adjust gain:**
   ```json
   "uniform_gain": 45.0  // Reduce if too high
   ```

3. **Switch to Manual temporarily:**
   ```json
   "vfo_squelch_mode_0": "Manual",
   "vfo_squelch_0": -50  // Lower = more sensitive
   ```

### **Issue: Squelch not sensitive enough (false triggers)**

**Options:**

1. **Increase gain:**
   ```json
   "uniform_gain": 55.0  // Increase for better SNR
   ```

2. **Use Manual mode with higher threshold:**
   ```json
   "vfo_squelch_mode_0": "Manual",
   "vfo_squelch_0": -30  // Higher = less sensitive
   ```

---

## 💡 BEST PRACTICES

### **1. Start with Auto Mode**
Always try `"Auto"` mode first - it works well for most scenarios.

### **2. Monitor Performance**
Watch the spectrum and DoA output for a few minutes to verify correct operation.

### **3. Adjust Gain First**
Before tweaking squelch, ensure gain is properly set:
- Too low: weak signals
- Too high: noise and false triggers
- Optimal: Signal peaks at 80-90% of scale

### **4. Use Auto Channel for Wide Frequency Ranges**
If monitoring multiple frequencies with different conditions, use `"Auto Channel"`.

### **5. Keep Manual as Backup**
Note the auto-calculated values - you can use them as manual settings if needed.

---

## 🎛️ COMPLETE EXAMPLE CONFIGURATION

### **Auto Squelch for Single VFO:**

```json
{
  "center_freq": 430.0,
  "uniform_gain": 49.6,
  "data_interface": "shmem",
  "default_ip": "0.0.0.0",
  
  "en_doa": true,
  "ant_arrangement": "UCA",
  "ant_spacing_meters": 0.4,
  "array_offset": 12,
  "doa_method": "MUSIC",
  
  "vfo_mode": "Standard",
  "vfo_default_squelch_mode": "Auto",           ← Auto squelch enabled
  "active_vfos": 1,
  "output_vfo": 0,
  
  "vfo_freq_0": 430000000,
  "vfo_bw_0": 344000,
  "vfo_squelch_mode_0": "Default",              ← Inherits "Auto"
  "vfo_squelch_0": -39,                         ← Will be auto-calculated
  "vfo_demod_0": "Default",
  "vfo_iq_0": "Default"
}
```

### **Auto Channel for Multiple VFOs:**

```json
{
  "vfo_default_squelch_mode": "Auto Channel",   ← Per-VFO auto
  "active_vfos": 3,
  
  "vfo_freq_0": 430000000,
  "vfo_squelch_mode_0": "Default",              ← Auto Channel
  
  "vfo_freq_1": 433000000,
  "vfo_squelch_mode_1": "Default",              ← Auto Channel
  
  "vfo_freq_2": 146000000,
  "vfo_squelch_mode_2": "Default"               ← Auto Channel
}
```

---

## 📚 RELATED SETTINGS

Settings that affect squelch behavior:

```json
{
  "uniform_gain": 49.6,                         ← Overall gain
  "vfo_bw_0": 344000,                           ← Bandwidth affects noise
  "spectrum_calculation": "Single",             ← Spectrum averaging
  "en_optimize_short_bursts": false,            ← Burst detection
  "max_demod_timeout": 60                       ← Demod timeout
}
```

---

## ✅ QUICK ENABLE SCRIPT

Save this as `enable_auto_squelch.sh`:

```bash
#!/bin/bash
cd ~/krakensdr_doa/krakensdr_doa/_share

# Backup
cp settings.json settings.json.backup

# Enable auto squelch using Python
python3 << 'EOF'
import json

with open('settings.json', 'r') as f:
    settings = json.load(f)

# Enable auto squelch
settings['vfo_default_squelch_mode'] = 'Auto'

# Set all VFOs to use default (Auto)
for i in range(8):
    settings[f'vfo_squelch_mode_{i}'] = 'Default'

with open('settings.json', 'w') as f:
    json.dump(settings, f, indent=2)

print("✓ Auto squelch enabled!")
print("Restart the system to apply changes")
EOF

echo "Settings updated. Restart KrakenSDR to apply."
```

**Usage:**
```bash
bash enable_auto_squelch.sh
bash kraken_doa_start.sh
```

---

## 🎯 SUMMARY

**To enable auto squelch:**

1. ✅ Edit `krakensdr_doa/_share/settings.json`
2. ✅ Set `"vfo_default_squelch_mode": "Auto"`
3. ✅ Set each VFO to `"vfo_squelch_mode_X": "Default"`
4. ✅ Restart the system
5. ✅ Verify in web interface

**Three modes available:**
- **Auto:** Global automatic (recommended)
- **Auto Channel:** Per-VFO automatic (advanced)
- **Manual:** Fixed value (fallback)

**Auto squelch adapts to:**
- Noise floor changes
- Frequency changes
- Gain adjustments
- Environmental conditions

---

**Auto squelch is already built-in and ready to use!** 🚀

Just enable it in the settings and restart!
