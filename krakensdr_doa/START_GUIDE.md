# 🚀 Dual KrakenSDR Startup Guide

## Quick Start for Optimized Configuration

This guide shows you how to start your dual KrakenSDR system with the optimized calibration settings.

---

## 📋 Prerequisites Check

Before starting, verify:

```bash
# 1. Check you're in the correct directory
cd ~/krakensdr
pwd
# Should show: /home/krakenrf/krakensdr (or your krakensdr path)

# 2. Verify optimized configs exist
ls -lh heimdall_daq_fw/Firmware/daq_chain_config*.ini
# Should see:
#   daq_chain_config.ini (Unit 1 - Master)
#   daq_chain_config5.ini (Unit 2 - Slave)
#   daq_chain_config.ini.backup
#   daq_chain_config5.ini.backup

# 3. Check scripts are executable
ls -lh heimdall_daq_fw/Firmware/*.sh
ls -lh krakensdr_doa/util/*.sh
```

**Hardware Check:**
- ✅ Both KrakenSDR units connected via USB
- ✅ External clock connected to both units
- ✅ Noise source split and connected to both units
- ✅ Antennas connected to all channels
- ✅ Power supply adequate for both units

---

## 🎯 Starting the System

### **IMPORTANT: Start Order**
Always start **Unit 1 (Master) FIRST**, then **Unit 2 (Slave)**

---

## 📍 UNIT 1 - Master (Channels 0-4)

### Terminal 1: Start Unit 1

```bash
# 1. Navigate to project directory
cd ~/krakensdr

# 2. Stop any existing processes
./krakensdr_doa/util/kraken_doa_stop.sh

# 3. Deploy Unit 1 configuration (if not already done)
cd heimdall_daq_fw/Firmware
./deploy_optimized_config.sh 1

# 4. Return to root and start
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_start.sh
```

**You'll see output like:**
```
Remote Control is DISABLED
Starting KrakenSDR Direction Finder
Web Interface Running at 0.0.0.0:8080
Data Out Server Running at 0.0.0.0:8081
      )  (     
      (   ) )  
       ) ( (   
     _______)_ 
  .-'---------|
 (  |/\/\/\/\/|
  '-./\/\/\/\/|
    '_________'
     '-------' 
Have a coffee watch radar
```

### Terminal 2: Monitor Unit 1 Calibration

```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware
./monitor_calibration.sh 180
```

**Expected Output:**
```
==========================================
  Dual KrakenSDR Calibration Monitor
==========================================

Current State: STATE_INIT
Tracking Mode: NO
Total Sync Failures: 0
Last Calibration: Never

⟳ Initial calibration in progress...

Recent Activity:
-----------------------------------
INFO: Starting calibration
INFO: Enabling noise source
INFO: Sample delay calibration in progress
INFO: IQ calibration in progress
INFO: Entering track mode

Time remaining: 150s
```

**Wait for Unit 1 to reach STATE_TRACK** (approximately 60-90 seconds)

You should see:
```
✓ System is CALIBRATED and TRACKING
```

---

## 📍 UNIT 2 - Slave (Channels 5-9)

**ONLY start Unit 2 AFTER Unit 1 reaches STATE_TRACK!**

### Terminal 3: Start Unit 2

```bash
# 1. Navigate to project directory (on Unit 2 machine or different terminal)
cd ~/krakensdr

# 2. Stop any existing processes
./krakensdr_doa/util/kraken_doa_stop.sh

# 3. Deploy Unit 2 configuration
cd heimdall_daq_fw/Firmware
./deploy_optimized_config.sh 2

# 4. Return to root and start
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_start.sh
```

### Terminal 4: Monitor Unit 2 Calibration

```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware
./monitor_calibration.sh 180
```

**Unit 2 should also reach STATE_TRACK within 60-90 seconds**

---

## ✅ Verification Steps

### 1. Check Both Units Are Running

```bash
# Check processes
ps aux | grep -E "python3.*app.py|rtl_daq|node.*index.js"

# Should see:
# - python3 _ui/_web_interface/app.py (GUI)
# - rtl_daq.out (DAQ subsystem)
# - node _nodejs/index.js (middleware)
```

### 2. Check Web Interfaces

Open in your browser:

**Unit 1 (Master):**
- Web UI: `http://UNIT1_IP:8080`
- Data Output: `http://UNIT1_IP:8081`

**Unit 2 (Slave):**
- Web UI: `http://UNIT2_IP:8080`
- Data Output: `http://UNIT2_IP:8081`

### 3. Verify Calibration Status

```bash
# Unit 1 - Should show STATE_TRACK
tail -20 heimdall_daq_fw/Firmware/_logs/delay_sync.log | grep STATE

# Unit 2 - Should show STATE_TRACK
tail -20 heimdall_daq_fw/Firmware/_logs/delay_sync.log | grep STATE
```

### 4. Check Noise Source Control

```bash
# Unit 1 - Should show noise source bursts every ~10 seconds
grep "noise source burst" heimdall_daq_fw/Firmware/_logs/hwc.log | tail -10

# Unit 2 - Should NOT show noise source control (it's disabled)
grep "noise source" heimdall_daq_fw/Firmware/_logs/hwc.log | tail -10
```

### 5. Verify Frame Processing

```bash
# Both units should show incrementing frame indices
tail -f heimdall_daq_fw/Firmware/_logs/delay_sync.log
# Press Ctrl+C to stop
```

---

## 🎛️ Configuration Check

### Verify Master Configuration (Unit 1)

```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware

# Check Unit 1 is Master
grep -E "unit_id|num_ch|en_noise_source_ctr|cal_track_mode" daq_chain_config.ini

# Should show:
# unit_id = 0
# num_ch = 5
# en_noise_source_ctr = 1  ← Controls noise source
# cal_track_mode = 2       ← Burst calibration
```

### Verify Slave Configuration (Unit 2)

```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware

# Check Unit 2 is Slave
grep -E "unit_id|num_ch|en_noise_source_ctr|cal_track_mode" daq_chain_config.ini

# Should show:
# unit_id = 1
# num_ch = 5
# en_noise_source_ctr = 0  ← Does NOT control noise source
# cal_track_mode = 1       ← Continuous tracking
```

---

## 🔍 Live Monitoring

### Monitor Both Units Simultaneously

```bash
# Watch logs in real-time
watch -n 2 '
echo "=== UNIT 1 (Master) ==="
tail -5 ~/krakensdr/heimdall_daq_fw/Firmware/_logs/delay_sync.log
echo ""
echo "=== UNIT 2 (Slave) ==="
tail -5 ~/krakensdr2/heimdall_daq_fw/Firmware/_logs/delay_sync.log
'
```

### Check System Resources

```bash
# CPU and Memory usage
top -b -n 1 | grep -E "python3|rtl_daq|node"

# USB device status
lsusb | grep RTL

# Should see both KrakenSDR units
```

---

## 🛑 Stopping the System

### Stop Both Units

```bash
# Unit 1
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh

# Unit 2
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh
```

**Or use the stop script:**
```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware
./daq_stop.sh

cd ~/krakensdr/krakensdr_doa
./kill.sh
```

### Verify Shutdown

```bash
# Check no processes remain
ps aux | grep -E "python3.*app.py|rtl_daq|node.*index.js"

# Should show no results (except the grep command itself)
```

---

## 🔧 Troubleshooting

### Issue: Unit 1 doesn't reach STATE_TRACK

**Check:**
```bash
# 1. Verify noise source is connected
grep "noise source" heimdall_daq_fw/Firmware/_logs/hwc.log

# 2. Check for errors
tail -50 heimdall_daq_fw/Firmware/_logs/rtl_daq.log

# 3. Verify USB devices
lsusb | grep RTL

# 4. Check configuration
cat heimdall_daq_fw/Firmware/daq_chain_config.ini | grep -A5 calibration
```

**Solutions:**
```bash
# Try restarting with cache clear
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_start.sh -c

# Or increase burst size temporarily
nano heimdall_daq_fw/Firmware/daq_chain_config.ini
# Change: cal_frame_burst_size = 40
```

### Issue: Unit 2 doesn't calibrate

**Check:**
```bash
# 1. Verify Unit 1 is running and in STATE_TRACK
ssh unit1 "tail -5 ~/krakensdr/heimdall_daq_fw/Firmware/_logs/delay_sync.log"

# 2. Check Unit 2 is NOT controlling noise source
grep "en_noise_source_ctr" heimdall_daq_fw/Firmware/daq_chain_config.ini
# Must show: en_noise_source_ctr = 0

# 3. Verify Unit 2 is in continuous tracking mode
grep "cal_track_mode" heimdall_daq_fw/Firmware/daq_chain_config.ini
# Must show: cal_track_mode = 1
```

**Solution:**
```bash
# Redeploy Unit 2 configuration
cd ~/krakensdr/heimdall_daq_fw/Firmware
./deploy_optimized_config.sh 2
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh
./krakensdr_doa/util/kraken_doa_start.sh
```

### Issue: "Port already in use" error

**Fix:**
```bash
# Kill processes using ports 5000, 5001, 8080, 8081
sudo lsof -ti:5000,5001,8080,8081 | xargs kill -9

# Then restart
./krakensdr_doa/util/kraken_doa_start.sh
```

### Issue: Calibration takes longer than 3 minutes

**Try more aggressive settings:**
```bash
nano heimdall_daq_fw/Firmware/daq_chain_config.ini

# Modify:
corr_size = 8192              # Even faster (from 16384)
cal_frame_burst_size = 40     # More samples (from 25)
amplitude_tolerance = 6       # More relaxed (from 4)
phase_tolerance = 3           # More relaxed (from 2)
```

### Issue: Frequent "sync may lost" warnings

**Relax tolerances:**
```bash
nano heimdall_daq_fw/Firmware/daq_chain_config.ini

# Increase:
maximum_sync_fails = 20       # From 15
amplitude_tolerance = 6       # From 4
phase_tolerance = 3           # From 2
```

---

## 📊 Performance Metrics

### Expected Timings

| Milestone | Expected Time | Check Command |
|-----------|---------------|---------------|
| DAQ Start | 5 seconds | `ps aux \| grep rtl_daq` |
| GUI Start | 10 seconds | Browser: http://IP:8080 |
| Initial Calibration | 60-90 seconds | `./monitor_calibration.sh` |
| STATE_TRACK | ~90 seconds | `grep STATE_TRACK _logs/delay_sync.log` |
| First DoA Output | ~95 seconds | Browser DoA tab |

### Success Indicators

✅ **Both units show:**
- Frame index incrementing steadily
- STATE_TRACK in logs
- Minimal sync failures (<10 per hour)
- Web interface responsive

✅ **Unit 1 (Master) shows:**
- "Enable noise source burst" every ~10 seconds
- IQ calibration updates

✅ **Unit 2 (Slave) shows:**
- Calibration activity when noise source is active
- Following Master's schedule

---

## 🔄 Restart Procedure

### Clean Restart (Recommended)

```bash
# 1. Stop everything
./krakensdr_doa/util/kraken_doa_stop.sh

# 2. Clear caches
sudo py3clean ~/krakensdr

# 3. Wait 5 seconds
sleep 5

# 4. Start with cache clear flag
./krakensdr_doa/util/kraken_doa_start.sh -c
```

### Quick Restart

```bash
# Stop and immediately restart
./krakensdr_doa/util/kraken_doa_stop.sh && sleep 2 && ./krakensdr_doa/util/kraken_doa_start.sh
```

---

## 🎯 Next Steps After Startup

Once both units are running and calibrated:

1. **Configure DoA Settings**
   - Open web interface: http://IP:8080
   - Go to "DoA Configuration" card
   - Set antenna array parameters
   - Configure your frequency of interest

2. **Test DoA Estimation**
   - Tune to a known signal
   - Open "DoA Estimation" tab
   - Verify direction findings

3. **Monitor Performance**
   - Check "Spectrum" tab for signal visualization
   - Monitor CPU usage: `htop`
   - Watch calibration logs periodically

4. **Save Settings**
   - Web interface saves automatically
   - Settings stored in: `krakensdr_doa/_share/settings.json`

---

## 📞 Support

**Documentation:**
- Quick Reference: `/workspace/krakensdr_doa/OPTIMIZATION_SUMMARY.md`
- Detailed Guide: `/workspace/krakensdr_doa/heimdall_daq_fw/Firmware/CALIBRATION_OPTIMIZATION_README.md`

**Log Locations:**
- DAQ logs: `heimdall_daq_fw/Firmware/_logs/`
- DSP logs: `krakensdr_doa/_share/logs/`

**Useful Commands:**
```bash
# View all logs
ls -lh heimdall_daq_fw/Firmware/_logs/

# Monitor specific log
tail -f heimdall_daq_fw/Firmware/_logs/delay_sync.log

# Check calibration status
./monitor_calibration.sh 60
```

---

## ✅ Startup Checklist

- [ ] Both KrakenSDR units connected via USB
- [ ] External clock connected to both units
- [ ] Noise source split connected to both
- [ ] Antennas connected to all channels
- [ ] Configuration files deployed
- [ ] Unit 1 (Master) started first
- [ ] Unit 1 reached STATE_TRACK
- [ ] Unit 2 (Slave) started
- [ ] Unit 2 reached STATE_TRACK
- [ ] Web interfaces accessible
- [ ] DoA estimation active
- [ ] No errors in logs

---

**Ready to start! Follow the steps above and your system should be running in ~2 minutes.** 🚀
