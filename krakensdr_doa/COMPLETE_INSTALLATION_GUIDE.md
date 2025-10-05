# 🚨 YOUR INSTALLATION IS INCOMPLETE

## The Problem

Looking at your directory tree, you're **missing critical files**:

### ❌ Missing Files:
```
heimdall_daq_fw/Firmware/
├── daq_start_sm.sh        ← MISSING!
├── daq_stop.sh            ← MISSING!
├── daq_chain_config.ini   ← MISSING!
└── All Python/C files     ← MISSING!

krakensdr_doa/
├── gui_run.sh             ← MISSING!
├── kill.sh                ← MISSING!
└── All source code        ← MISSING!

Kraken-to-TAK-Python/
└── All files              ← MISSING!
```

### ✅ What You Have:
- Directory structure (empty folders)
- Compiled Python cache files (`__pycache__`)
- The two shell scripts in root

---

## 🔧 HOW TO FIX - Complete Your Installation

Your repo uses **git submodules** that need to be initialized.

### **Option 1: Initialize Git Submodules (Recommended)**

```bash
# Go to your krakensdr_doa directory
cd ~/work_space/Git_df/Direction_finding/krakensdr_doa

# Initialize and update submodules
git submodule update --init --recursive

# This will download:
# - heimdall_daq_fw (complete firmware)
# - krakensdr_doa (complete DSP code)
# - Kraken-to-TAK-Python (TAK integration)
```

**If that doesn't work (no .gitmodules file):**

### **Option 2: Clone Each Repository Manually**

```bash
cd ~/work_space/Git_df/Direction_finding/krakensdr_doa

# 1. Clone heimdall_daq_fw
cd heimdall_daq_fw
git init
git remote add origin https://github.com/krakenrf/heimdall_daq_fw.git
git pull origin main

# 2. Clone krakensdr_doa
cd ../krakensdr_doa
git init
git remote add origin https://github.com/krakenrf/krakensdr_doa.git
git pull origin main

# 3. Clone Kraken-to-TAK (optional)
cd ../Kraken-to-TAK-Python
git init
git remote add origin https://github.com/canaryradio/Kraken-to-TAK-Python.git
git pull origin main
```

### **Option 3: Fresh Clone from Official Repos**

Start fresh with complete repositories:

```bash
# Create a new directory
mkdir ~/krakensdr_complete
cd ~/krakensdr_complete

# Clone all three repos
git clone https://github.com/krakenrf/heimdall_daq_fw.git
git clone https://github.com/krakenrf/krakensdr_doa.git
git clone https://github.com/canaryradio/Kraken-to-TAK-Python.git

# Then follow the official installation guide
```

---

## 🎯 TEMPORARY WORKAROUND - For Your Current Setup

Since your installation is incomplete, here's a minimal startup script that works with what you have:

### Create this file: `START_MINIMAL.sh`

```bash
#!/bin/bash

cd ~/work_space/Git_df/Direction_finding/krakensdr_doa

# Check if we have the required files
if [ ! -f "heimdall_daq_fw/Firmware/daq_start_sm.sh" ]; then
    echo "ERROR: Installation incomplete!"
    echo "Missing: heimdall_daq_fw/Firmware/daq_start_sm.sh"
    echo ""
    echo "Please run: git submodule update --init --recursive"
    exit 1
fi

if [ ! -f "krakensdr_doa/gui_run.sh" ]; then
    echo "ERROR: Installation incomplete!"
    echo "Missing: krakensdr_doa/gui_run.sh"
    echo ""
    echo "Please complete installation first"
    exit 1
fi

# If we get here, start normally
eval "$(conda shell.bash hook)"
conda activate kraken

./kraken_doa_stop.sh

cd heimdall_daq_fw/Firmware
sudo env "PATH=$PATH" bash ./daq_start_sm.sh &
sleep 3

cd ../../krakensdr_doa
sudo env "PATH=$PATH" bash ./gui_run.sh &

echo "System started!"
```

---

## ✅ VERIFICATION - After Installation

After completing the installation, verify you have all files:

```bash
cd ~/work_space/Git_df/Direction_finding/krakensdr_doa

# Check heimdall_daq_fw
ls -l heimdall_daq_fw/Firmware/daq_start_sm.sh
ls -l heimdall_daq_fw/Firmware/daq_stop.sh
ls -l heimdall_daq_fw/Firmware/daq_chain_config.ini

# Check krakensdr_doa
ls -l krakensdr_doa/gui_run.sh
ls -l krakensdr_doa/kill.sh
ls -l krakensdr_doa/_ui/_web_interface/app.py

# Check Kraken-to-TAK (optional)
ls -l Kraken-to-TAK-Python/KrakenToTAK.py

# All should exist!
```

---

## 📋 OFFICIAL INSTALLATION GUIDE

Follow the official guide after getting the complete code:

### 1. Install Prerequisites

```bash
sudo apt update
sudo apt install nodejs jq rustc cargo
cargo install miniserve
```

### 2. Install Miniconda (if not installed)

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

### 3. Create Conda Environment

```bash
conda create -n kraken python=3.9
conda activate kraken
```

### 4. Install Python Dependencies

```bash
conda install pandas orjson matplotlib requests
pip3 install dash_bootstrap_components==1.1.0
pip3 install quart_compress==0.2.1
pip3 install quart==0.17.0
pip3 install dash_devices==0.1.3
pip3 install pyargus
conda install dash==1.20.0
conda install werkzeug==2.0.2
```

### 5. Install HeIMDALL DAQ Firmware

```bash
cd ~/work_space/Git_df/Direction_finding/krakensdr_doa/heimdall_daq_fw
sudo bash util/install.sh
```

---

## 🎯 WHY THIS HAPPENED

Your repository structure suggests you cloned from a fork/mirror that:
1. Only has the directory structure
2. Missing the actual submodule contents
3. Only kept compiled Python cache files

**This is why:**
- Scripts can't find other scripts (they don't exist)
- Only `__pycache__` directories are present
- Core functionality is missing

---

## 🚀 QUICK FIX COMMANDS

Run these in order:

```bash
# 1. Go to your directory
cd ~/work_space/Git_df/Direction_finding/krakensdr_doa

# 2. Try to initialize submodules
git submodule update --init --recursive

# 3. If that fails, clone manually:
# heimdall_daq_fw
rm -rf heimdall_daq_fw
git clone https://github.com/krakenrf/heimdall_daq_fw.git

# krakensdr_doa code
rm -rf krakensdr_doa
git clone https://github.com/krakenrf/krakensdr_doa.git

# 4. Copy your config files back to root
cp krakensdr_doa/util/kraken_doa_start.sh .
cp krakensdr_doa/util/kraken_doa_stop.sh .

# 5. Now you can start
bash kraken_doa_start.sh
```

---

## 📊 WHAT YOU SHOULD SEE AFTER FIXING

```bash
~/work_space/Git_df/Direction_finding/krakensdr_doa$ tree -L 2
.
├── heimdall_daq_fw/
│   ├── Firmware/           ← NOW HAS FILES!
│   │   ├── daq_start_sm.sh
│   │   ├── daq_stop.sh
│   │   ├── daq_chain_config.ini
│   │   ├── _daq_core/
│   │   │   ├── rtl_daq.c
│   │   │   ├── delay_sync.py
│   │   │   └── ...
│   │   └── ...
│   └── util/
├── krakensdr_doa/
│   ├── gui_run.sh          ← NOW EXISTS!
│   ├── kill.sh             ← NOW EXISTS!
│   ├── _ui/
│   │   └── _web_interface/
│   │       ├── app.py
│   │       └── ...
│   └── ...
├── Kraken-to-TAK-Python/
│   ├── KrakenToTAK.py      ← NOW EXISTS!
│   └── ...
├── kraken_doa_start.sh
└── kraken_doa_stop.sh
```

---

## ⚠️ IMPORTANT

**DO NOT** try to run the system until you complete the installation!

The current setup **will not work** because critical files are missing.

---

## 🆘 NEED HELP?

After fixing the installation, refer to:
- `START_GUIDE.md` - How to start the system
- `OPTIMIZATION_SUMMARY.md` - Optimization details
- Official docs: https://github.com/krakenrf/krakensdr_docs/wiki

---

**Bottom line: Complete the installation first, THEN you can start the system!** 🚀
