# ✅ 9-Channel Configuration Update

## Changes Made

Both Unit 1 and Unit 2 configurations have been updated to support **9 channels** instead of 5.

---

## Configuration Details

### **Unit 1 (Master) - `daq_chain_config.ini`**

```ini
[hw]
num_ch = 9                                    ← Updated from 5
en_bias_tee = 0,0,0,0,0,0,0,0,0              ← Updated from 5 values
unit_id = 0
en_noise_source_ctr = 1                       ← Controls noise source
cal_track_mode = 2                            ← Burst calibration

[calibration]
iq_adjust_amplitude = 0,0,0,0,0,0,0,0,0      ← Updated from 5 values
iq_adjust_time_delay_ns = 0,0,0,0,0,0,0,0,0  ← Updated from 5 values

[adpis]
adpis_gains_init = 0,0,0,0,0,0,0,0,0         ← Updated from 5 values
```

### **Unit 2 (Slave) - `daq_chain_config5.ini`**

```ini
[hw]
num_ch = 9                                    ← Updated from 5
en_bias_tee = 0,0,0,0,0,0,0,0,0              ← Updated from 5 values
unit_id = 1
en_noise_source_ctr = 0                       ← Does NOT control noise source
cal_track_mode = 1                            ← Continuous tracking

[calibration]
iq_adjust_amplitude = 0,0,0,0,0,0,0,0,0      ← Updated from 5 values
iq_adjust_time_delay_ns = 0,0,0,0,0,0,0,0,0  ← Updated from 5 values

[adpis]
adpis_gains_init = 0,0,0,0,0,0,0,0,0         ← Updated from 5 values
```

---

## What This Means

### **Total System Capacity:**
- **Unit 1:** 9 channels (CH 0-8)
- **Unit 2:** 9 channels (CH 0-8) 
- **Total:** 18 channels with dual units

Or if using single unit:
- **Single Unit:** 9 channels

---

## All Optimizations Still Active

✅ **Calibration Speed:** 5-6x faster (60-90 seconds)
✅ **Correlation:** 4x faster processing (16384 samples)
✅ **Recalibration:** Every 10 seconds (vs 68 seconds)
✅ **Master-Slave:** Noise source coordination
✅ **Tolerances:** Relaxed for stability

---

## Channel Mapping Options

### **Option 1: Single 9-Channel Unit**
```
KrakenSDR Unit 1:
├── Channel 0
├── Channel 1
├── Channel 2
├── Channel 3
├── Channel 4
├── Channel 5
├── Channel 6
├── Channel 7
└── Channel 8
```

### **Option 2: Dual 9-Channel Units (18 total)**
```
KrakenSDR Unit 1 (Master):    KrakenSDR Unit 2 (Slave):
├── Channel 0                 ├── Channel 0
├── Channel 1                 ├── Channel 1
├── Channel 2                 ├── Channel 2
├── Channel 3                 ├── Channel 3
├── Channel 4                 ├── Channel 4
├── Channel 5                 ├── Channel 5
├── Channel 6                 ├── Channel 6
├── Channel 7                 ├── Channel 7
└── Channel 8                 └── Channel 8
```

---

## Updated Arrays

All configuration arrays now have 9 values:

| Parameter | Old Length | New Length | Example |
|-----------|------------|------------|---------|
| `en_bias_tee` | 5 | **9** | `0,0,0,0,0,0,0,0,0` |
| `iq_adjust_amplitude` | 5 | **9** | `0,0,0,0,0,0,0,0,0` |
| `iq_adjust_time_delay_ns` | 5 | **9** | `0,0,0,0,0,0,0,0,0` |
| `adpis_gains_init` | 5 | **9** | `0,0,0,0,0,0,0,0,0` |

---

## Startup Process (No Change)

The startup process remains the same:

### **Single Unit:**
```bash
cd ~/krakensdr_doa
bash kraken_doa_start.sh
```

### **Dual Units:**
```bash
# Unit 1 (Master) first
cd ~/krakensdr_doa
bash kraken_doa_start.sh

# Wait for STATE_TRACK (~90 seconds)

# Then Unit 2 (Slave)
cd ~/krakensdr_doa
bash kraken_doa_start.sh
```

---

## Verification

Check that configurations are correct:

```bash
# Verify Unit 1 has 9 channels
grep "num_ch" heimdall_daq_fw/Firmware/daq_chain_config.ini
# Output: num_ch = 9

# Verify Unit 2 has 9 channels
grep "num_ch" heimdall_daq_fw/Firmware/daq_chain_config5.ini
# Output: num_ch = 9
```

---

## Important Notes

1. **Hardware Support:** Ensure your KrakenSDR hardware supports 9 channels
   - Standard KrakenSDR: 5 channels (CH 0-4)
   - KrakenSDR Pro: 9 channels (CH 0-8)

2. **USB Bandwidth:** 9 channels require more USB bandwidth than 5
   - Use USB 3.0 port recommended
   - Ensure adequate power supply

3. **Processing Load:** More channels = more CPU usage
   - Monitor CPU during operation
   - Optimizations help but load is higher

4. **Memory:** More channels require more RAM
   - Recommended: 4GB+ RAM
   - 8GB+ for dual units

---

## Still Having Issues?

Refer to these guides:
- `START_GUIDE.md` - Startup instructions
- `INSTALLATION_FIX.md` - Installation troubleshooting
- `COMPLETE_INSTALLATION_GUIDE.md` - Full setup from scratch
- `OPTIMIZATION_SUMMARY.md` - What was optimized and why

---

**Both configurations are now set for 9 channels!** 🚀

Updated: 2025-10-05
Configuration Version: v2 (9-channel)
