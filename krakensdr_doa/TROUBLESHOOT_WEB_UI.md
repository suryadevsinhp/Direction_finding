# 🔧 Web UI Not Loading - Troubleshooting Guide

## Your Current Issue

The DAQ starts successfully, but the Web UI at `http://IP:8080` is not accessible.

---

## 🔍 STEP 1: Check if Web GUI Process is Running

```bash
# Check for web GUI process
ps aux | grep -E "python3.*app.py|python.*app.py"

# If you see output like this, GUI is running:
# user  12345  ... python3 _ui/_web_interface/app.py

# If no output, GUI didn't start
```

**If not running, skip to [Fix: GUI Not Starting](#fix-gui-not-starting)**

---

## 🔍 STEP 2: Check GUI Logs

```bash
cd ~/krakensdr_doa/krakensdr_doa/_share/logs/krakensdr_doa

# View GUI startup logs
tail -50 ui.log

# Common errors to look for:
# - "ModuleNotFoundError" → Missing Python packages
# - "Permission denied" → Port already in use
# - "ImportError" → Missing dependencies
# - "Address already in use" → Port 8080 taken
```

---

## 🔍 STEP 3: Check if Port 8080 is Listening

```bash
# Check if something is listening on port 8080
sudo lsof -i :8080

# Should show something like:
# python3  12345  user  ... TCP *:8080 (LISTEN)

# If nothing, GUI didn't bind to port
```

---

## 🔍 STEP 4: Try Accessing Locally

```bash
# From the KrakenSDR machine itself
curl http://localhost:8080

# Should return HTML
# If it works locally but not remotely → Firewall issue
```

---

## 🔧 FIX: GUI Not Starting

### **Fix 1: Missing Python Dependencies**

```bash
# Activate conda environment
eval "$(conda shell.bash hook)"
conda activate kraken

# Install/reinstall dependencies
conda install pandas orjson matplotlib requests
pip3 install dash==1.20.0
pip3 install werkzeug==2.0.2
pip3 install dash_bootstrap_components==1.1.0
pip3 install quart_compress==0.2.1
pip3 install quart==0.17.0
pip3 install dash_devices==0.1.3
pip3 install pyargus

# Restart
bash kraken_doa_stop.sh
bash FIXED_kraken_doa_start.sh
```

### **Fix 2: Port Already in Use**

```bash
# Find what's using port 8080
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>

# Or use different port (edit gui_run.sh)
nano krakensdr_doa/gui_run.sh
# Change: --port 8080 to --port 8090

# Restart
bash FIXED_kraken_doa_start.sh
```

### **Fix 3: Conda Environment Issue**

```bash
# Check conda environments
conda env list

# If 'kraken' is missing, you need to set it up
# Follow the installation guide

# If kraken exists but has issues, recreate it
conda deactivate
conda env remove -n kraken
conda create -n kraken python=3.9
conda activate kraken
# Install all dependencies (see Fix 1)
```

### **Fix 4: Permission Issues**

```bash
# Make sure gui_run.sh is executable
chmod +x krakensdr_doa/gui_run.sh

# Check ownership
ls -l krakensdr_doa/gui_run.sh

# If owned by root, fix it
sudo chown $USER:$USER krakensdr_doa/gui_run.sh
```

---

## 🔧 FIX: Firewall Blocking Access

### **Check Firewall Status**

```bash
sudo ufw status

# If active, add rule for port 8080
sudo ufw allow 8080/tcp
sudo ufw reload

# Or temporarily disable (testing only!)
sudo ufw disable
```

### **Check iptables**

```bash
sudo iptables -L -n | grep 8080

# If port is blocked, allow it
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8081 -j ACCEPT
```

---

## 🔧 FIX: Network Issues

### **Find Your IP Address**

```bash
# Get IP address
hostname -I

# Or
ip addr show | grep inet

# Try accessing with each IP shown
```

### **Try Different URLs**

```bash
# Local
http://localhost:8080
http://127.0.0.1:8080

# LAN IP (common)
http://192.168.1.X:8080
http://192.168.0.X:8080
http://10.0.0.X:8080

# Ethernet vs WiFi
# Check both network interfaces
```

---

## 🔧 FIX: Start GUI Manually (Debug)

```bash
cd ~/krakensdr_doa/krakensdr_doa

# Activate conda
eval "$(conda shell.bash hook)"
conda activate kraken

# Start GUI manually to see errors
python3 _ui/_web_interface/app.py

# This will show any startup errors directly
# Press Ctrl+C to stop
```

**Common errors and fixes:**

```
ModuleNotFoundError: No module named 'dash'
→ pip3 install dash==1.20.0

ModuleNotFoundError: No module named 'orjson'
→ conda install orjson

ImportError: cannot import name 'soft_unicode'
→ pip3 install werkzeug==2.0.2

Address already in use
→ sudo lsof -i :8080 && kill <PID>
```

---

## 🔍 COMPLETE DIAGNOSTIC SCRIPT

Save as `diagnose_web_ui.sh`:

```bash
#!/bin/bash

echo "=== KrakenSDR Web UI Diagnostics ==="
echo ""

echo "1. Checking processes..."
echo "DAQ process:"
ps aux | grep -E "rtl_daq|rebuffer|delay_sync" | grep -v grep
echo ""
echo "Web GUI process:"
ps aux | grep "python3.*app.py" | grep -v grep
echo ""
echo "Node process:"
ps aux | grep "node.*index.js" | grep -v grep
echo ""

echo "2. Checking ports..."
echo "Port 8080 (Web UI):"
sudo lsof -i :8080
echo ""
echo "Port 8081 (Data):"
sudo lsof -i :8081
echo ""
echo "Port 5000 (DAQ IQ):"
sudo lsof -i :5000
echo ""
echo "Port 5001 (DAQ HWC):"
sudo lsof -i :5001
echo ""

echo "3. Checking logs..."
if [ -f "krakensdr_doa/_share/logs/krakensdr_doa/ui.log" ]; then
    echo "Last 10 lines of ui.log:"
    tail -10 krakensdr_doa/_share/logs/krakensdr_doa/ui.log
else
    echo "ui.log not found"
fi
echo ""

echo "4. Network info..."
echo "IP addresses:"
hostname -I
echo ""
echo "Listening ports:"
sudo netstat -tlnp | grep -E "8080|8081|5000|5001"
echo ""

echo "5. Conda environment..."
conda env list | grep kraken
echo ""

echo "6. Test local access..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:8080
echo ""

echo "=== Diagnosis Complete ==="
echo ""
echo "Access URLs to try:"
for ip in $(hostname -I); do
    echo "  http://$ip:8080"
done
```

**Run it:**
```bash
bash diagnose_web_ui.sh
```

---

## 🎯 MOST COMMON FIXES

### **Quick Fix 1: Just Restart Everything**

```bash
cd ~/krakensdr_doa

# Stop everything
bash kraken_doa_stop.sh
sleep 5

# Kill any stragglers
sudo pkill -f rtl_daq
sudo pkill -f "python3.*app.py"
sudo pkill -f "node.*index.js"
sleep 2

# Clear cache
sudo py3clean .

# Start fresh
bash FIXED_kraken_doa_start.sh
```

### **Quick Fix 2: Use the Fixed Script**

```bash
cd ~/krakensdr_doa

# Use the new fixed startup script
bash FIXED_kraken_doa_start.sh

# It automatically:
# - Finds conda
# - Checks processes
# - Verifies GUI started
# - Shows you the correct URL
```

### **Quick Fix 3: Access from Same Machine**

```bash
# If running on the KrakenSDR device directly
firefox http://localhost:8080

# Or
chromium-browser http://localhost:8080

# This bypasses network issues
```

---

## 📋 CHECKLIST

Work through this list:

- [ ] Conda environment 'kraken' exists: `conda env list | grep kraken`
- [ ] Python packages installed: `pip3 list | grep dash`
- [ ] GUI process running: `ps aux | grep "python3.*app.py"`
- [ ] Port 8080 listening: `sudo lsof -i :8080`
- [ ] No firewall blocking: `sudo ufw status`
- [ ] Correct IP address: `hostname -I`
- [ ] GUI logs show no errors: `tail krakensdr_doa/_share/logs/krakensdr_doa/ui.log`
- [ ] Can access locally: `curl http://localhost:8080`

---

## 🆘 STILL NOT WORKING?

### **Gather Information:**

```bash
# Create a diagnostic report
cd ~/krakensdr_doa

echo "=== System Info ===" > diagnostic_report.txt
uname -a >> diagnostic_report.txt
echo "" >> diagnostic_report.txt

echo "=== Conda Info ===" >> diagnostic_report.txt
conda --version >> diagnostic_report.txt
conda env list >> diagnostic_report.txt
echo "" >> diagnostic_report.txt

echo "=== Processes ===" >> diagnostic_report.txt
ps aux | grep -E "python|rtl_daq|node" >> diagnostic_report.txt
echo "" >> diagnostic_report.txt

echo "=== Ports ===" >> diagnostic_report.txt
sudo lsof -i :8080 >> diagnostic_report.txt
sudo lsof -i :8081 >> diagnostic_report.txt
echo "" >> diagnostic_report.txt

echo "=== GUI Log ===" >> diagnostic_report.txt
if [ -f "krakensdr_doa/_share/logs/krakensdr_doa/ui.log" ]; then
    tail -100 krakensdr_doa/_share/logs/krakensdr_doa/ui.log >> diagnostic_report.txt
fi

echo "Report saved to: diagnostic_report.txt"
```

**Share this report for help!**

---

## ✅ SUCCESS INDICATORS

When it's working correctly, you'll see:

1. **Process running:**
   ```
   $ ps aux | grep python3.*app.py
   user  12345  python3 _ui/_web_interface/app.py
   ```

2. **Port listening:**
   ```
   $ sudo lsof -i :8080
   python3  12345  user  TCP *:8080 (LISTEN)
   ```

3. **Web page loads:**
   - Browser shows KrakenSDR interface
   - DoA, Spectrum, Configuration tabs visible

4. **No errors in log:**
   ```
   $ tail krakensdr_doa/_share/logs/krakensdr_doa/ui.log
   Dash is running on http://0.0.0.0:8080/
   ```

---

**Try these fixes in order - most issues are solved by the first few!** 🚀
