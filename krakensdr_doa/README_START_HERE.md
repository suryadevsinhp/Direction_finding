# 🚀 HOW TO START YOUR DUAL KRAKENSDR SYSTEM

## Ultra-Quick Start (2 Commands)

### Unit 1 (Master - Channels 0-4):
```bash
cd ~/krakensdr
./QUICK_START.sh 1
```

### Unit 2 (Slave - Channels 5-9):
Wait for Unit 1 to reach STATE_TRACK (~90 seconds), then:
```bash
cd ~/krakensdr
./QUICK_START.sh 2
```

That's it! The script handles everything automatically.

---

## Manual Start (If You Prefer)

### Unit 1:
```bash
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh
./krakensdr_doa/util/kraken_doa_start.sh
```

### Unit 2:
```bash
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh
./krakensdr_doa/util/kraken_doa_start.sh
```

---

## 📚 Complete Documentation

- **Quick Start Script**: `./QUICK_START.sh [1|2]`
- **Detailed Guide**: `START_GUIDE.md`
- **Optimization Summary**: `OPTIMIZATION_SUMMARY.md`
- **Full Documentation**: `heimdall_daq_fw/Firmware/CALIBRATION_OPTIMIZATION_README.md`

---

## ✅ Quick Checks

**Web Interface:**
- http://YOUR_IP:8080

**Check if running:**
```bash
ps aux | grep -E "python3.*app.py|rtl_daq"
```

**Monitor calibration:**
```bash
cd ~/krakensdr/heimdall_daq_fw/Firmware
./monitor_calibration.sh 180
```

**Stop system:**
```bash
cd ~/krakensdr
./krakensdr_doa/util/kraken_doa_stop.sh
```

---

## 🎯 Expected Timeline

- **0:00** - Start script
- **0:05** - DAQ subsystem running
- **0:10** - GUI starts
- **1:30** - Calibration complete (STATE_TRACK)
- **1:35** - DoA processing active

**Total: ~90 seconds from start to full operation!**

---

Need help? See `START_GUIDE.md` for detailed troubleshooting.
