# 🔧 FIXING YOUR STARTUP ISSUES

## The Problems You're Having

1. ❌ Running script with `sh` instead of `bash`
2. ❌ Conda not initialized properly
3. ❌ Running from wrong directory

---

## ✅ QUICK FIX - Use This Command Instead

### **Option 1: Use the Fixed Script (Easiest)**

```bash
# Navigate to the krakensdr_doa directory
cd /path/to/krakensdr_doa

# Run the fixed script
bash START_HERE_FIXED.sh
```

### **Option 2: Fix Your Conda Setup**

```bash
# Initialize conda for your shell
conda init bash

# Close and reopen your terminal, then try again
cd /path/to/krakensdr_doa
bash krakensdr_doa/util/kraken_doa_start.sh
```

---

## 🗂️ Correct Directory Structure

Your directory should look like this:

```
krakensdr_doa/                    ← YOU MUST BE HERE when running scripts
├── heimdall_daq_fw/
│   └── Firmware/
│       ├── daq_start_sm.sh       ← This needs to exist
│       ├── daq_stop.sh
│       └── ...
├── krakensdr_doa/
│   ├── gui_run.sh                ← This needs to exist
│   ├── kill.sh
│   └── util/
│       ├── kraken_doa_start.sh   ← Original script
│       └── kraken_doa_stop.sh
├── Kraken-to-TAK-Python/         ← Optional
└── START_HERE_FIXED.sh           ← NEW fixed script
```

---

## 📍 Step-by-Step Startup

### Step 1: Find Your Installation Directory

```bash
# Find where krakensdr_doa is installed
find ~/ -name "krakensdr_doa" -type d 2>/dev/null | grep -v ".cache"
```

### Step 2: Go to the Correct Directory

```bash
# Replace with your actual path
cd /path/to/krakensdr_doa
```

### Step 3: Verify Directory Structure

```bash
# Check required directories exist
ls -ld heimdall_daq_fw krakensdr_doa

# Should show both directories
```

### Step 4: Initialize Conda (One-Time Setup)

```bash
# Find your conda installation
which conda

# Initialize conda for bash
conda init bash

# Restart your terminal or run:
source ~/.bashrc
```

### Step 5: Start the System

```bash
# Make sure you're in the root krakensdr_doa directory
pwd
# Should show: /home/yourusername/krakensdr_doa (or similar)

# Use bash, NOT sh
bash START_HERE_FIXED.sh
```

---

## 🔍 Troubleshooting Each Error

### Error: "source: not found"

**Cause:** Using `sh` instead of `bash`

**Fix:**
```bash
# DON'T use:
sh kraken_doa_start.sh

# USE instead:
bash kraken_doa_start.sh
```

### Error: "Run 'conda init' before 'conda activate'"

**Cause:** Conda not initialized for your shell

**Fix:**
```bash
# Initialize conda
conda init bash

# Restart terminal or:
source ~/.bashrc

# Verify conda works
conda --version
```

### Error: "./daq_stop.sh: not found"

**Cause:** Running from wrong directory

**Fix:**
```bash
# Find the correct directory
cd /path/to/krakensdr_doa

# Verify you're in the right place
ls heimdall_daq_fw/Firmware/daq_stop.sh
# Should exist and be found

# Then run the script
bash krakensdr_doa/util/kraken_doa_start.sh
```

### Error: "No such file or directory"

**Cause:** Script paths are relative to the root directory

**Fix:**
```bash
# ALWAYS run from krakensdr_doa root
cd /path/to/krakensdr_doa

# Verify structure
tree -L 2 -d
# or
ls -R | grep -E "daq_start_sm.sh|gui_run.sh"
```

---

## 🚀 Working Example

Here's the complete working process:

```bash
# 1. Find your installation
cd ~
find . -name "heimdall_daq_fw" -type d | head -1
# Output: ./krakensdr/heimdall_daq_fw

# 2. Go to parent directory
cd ~/krakensdr

# 3. Verify structure
ls -l
# Should show: heimdall_daq_fw/ krakensdr_doa/ etc.

# 4. Initialize conda (if not done)
conda init bash
source ~/.bashrc

# 5. Verify conda environment exists
conda env list | grep kraken
# Should show: kraken

# 6. Run the fixed startup script
bash START_HERE_FIXED.sh
```

---

## 🔧 Manual Startup (If Scripts Don't Work)

If the scripts still don't work, start manually:

```bash
# 1. Navigate to root directory
cd /path/to/krakensdr_doa

# 2. Activate conda
eval "$(conda shell.bash hook)"
conda activate kraken

# 3. Start DAQ
cd heimdall_daq_fw/Firmware
sudo bash daq_start_sm.sh &
sleep 3

# 4. Start GUI
cd ../../krakensdr_doa
sudo bash gui_run.sh &

# 5. Check it's running
ps aux | grep -E "rtl_daq|python3.*app.py"
```

---

## ✅ Verification Steps

After starting, verify everything works:

```bash
# 1. Check processes are running
ps aux | grep -E "rtl_daq|python3.*app.py|node"

# 2. Check web interface
curl http://localhost:8080
# Should return HTML

# 3. Check logs
tail -20 heimdall_daq_fw/Firmware/_logs/delay_sync.log

# 4. Open in browser
# http://YOUR_IP:8080
```

---

## 📝 Common Installation Paths

Your krakensdr_doa might be in:
- `~/krakensdr/`
- `~/krakensdr_doa/`
- `/opt/krakensdr/`
- `/home/krakenrf/krakensdr/`

Use this to find it:
```bash
find ~/ -name "heimdall_daq_fw" -type d 2>/dev/null
```

---

## 🆘 Still Having Issues?

### Check These:

1. **Conda installed?**
   ```bash
   which conda
   # Should show: /home/user/miniconda3/bin/conda (or similar)
   ```

2. **Kraken environment exists?**
   ```bash
   conda env list | grep kraken
   # Should show: kraken
   ```

3. **In correct directory?**
   ```bash
   pwd
   # Should show: /path/to/krakensdr_doa
   ls -d heimdall_daq_fw krakensdr_doa
   # Both should exist
   ```

4. **Scripts are executable?**
   ```bash
   chmod +x heimdall_daq_fw/Firmware/daq_start_sm.sh
   chmod +x krakensdr_doa/gui_run.sh
   chmod +x krakensdr_doa/util/kraken_doa_*.sh
   ```

---

## 💡 Prevention for Future

Add this to your `~/.bashrc`:

```bash
# KrakenSDR environment
export KRAKEN_ROOT="$HOME/krakensdr"  # Adjust path
alias kraken-start="cd $KRAKEN_ROOT && bash START_HERE_FIXED.sh"
alias kraken-stop="cd $KRAKEN_ROOT/krakensdr_doa/util && bash kraken_doa_stop.sh"
alias kraken-monitor="cd $KRAKEN_ROOT/heimdall_daq_fw/Firmware && bash monitor_calibration.sh 180"

# Initialize conda
eval "$(conda shell.bash hook)"
```

Then use:
```bash
kraken-start    # Start system
kraken-stop     # Stop system
kraken-monitor  # Monitor calibration
```

---

## 🎯 Summary

**The main issues:**
1. Use `bash`, not `sh`
2. Run from the krakensdr_doa root directory
3. Initialize conda properly

**Quick solution:**
```bash
cd /path/to/krakensdr_doa
bash START_HERE_FIXED.sh
```

This fixed script handles everything automatically!
