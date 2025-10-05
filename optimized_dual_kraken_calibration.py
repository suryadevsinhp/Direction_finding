#!/usr/bin/env python3
"""
Optimized Dual KrakenSDR Calibration Script
For dual KrakenSDR setup with common noise source and clock splitter PCB

This script implements several optimizations to reduce calibration time:
1. Parallel calibration of both SDRs
2. Reduced sample collection time
3. Optimized frequency hopping
4. Shared calibration data between SDRs
5. Pre-computed calibration matrices
"""

import numpy as np
import time
import threading
import queue
import json
import os
from typing import Dict, List, Tuple, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class OptimizedDualKrakenCalibration:
    def __init__(self, config_file: str = "dual_kraken_config.json"):
        """
        Initialize optimized dual KrakenSDR calibration system
        
        Args:
            config_file: Path to configuration file
        """
        self.config = self.load_config(config_file)
        self.calibration_data = {}
        self.calibration_lock = threading.Lock()
        
        # Performance tracking
        self.start_time = None
        self.calibration_times = {}
        
    def load_config(self, config_file: str) -> Dict:
        """Load configuration from JSON file"""
        default_config = {
            "sdr_configs": {
                "sdr1": {
                    "device_id": 0,
                    "sample_rate": 2.048e6,  # Reduced from typical 2.5e6
                    "center_freq": 100e6,
                    "gain": 20,
                    "calibration_samples": 8192,  # Reduced from 16384
                    "calibration_duration": 1.0,  # Reduced from 2.0 seconds
                    "frequency_hop_interval": 0.1  # Reduced from 0.2 seconds
                },
                "sdr2": {
                    "device_id": 1,
                    "sample_rate": 2.048e6,
                    "center_freq": 100e6,
                    "gain": 20,
                    "calibration_samples": 8192,
                    "calibration_duration": 1.0,
                    "frequency_hop_interval": 0.1
                }
            },
            "calibration": {
                "frequency_range": [50e6, 200e6],  # MHz
                "frequency_step": 5e6,  # 5 MHz steps instead of 1 MHz
                "noise_source_power": -20,  # dBm
                "calibration_threshold": 0.8,
                "parallel_calibration": True,
                "shared_calibration_data": True,
                "precompute_matrices": True
            },
            "optimization": {
                "use_cached_calibration": True,
                "cache_file": "dual_kraken_calibration_cache.json",
                "adaptive_sample_count": True,
                "frequency_hopping_enabled": True,
                "background_calibration": True
            }
        }
        
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                user_config = json.load(f)
                # Merge with defaults
                for key, value in user_config.items():
                    if key in default_config:
                        if isinstance(value, dict):
                            default_config[key].update(value)
                        else:
                            default_config[key] = value
        else:
            # Save default config
            with open(config_file, 'w') as f:
                json.dump(default_config, f, indent=2)
                
        return default_config
    
    def optimize_sample_parameters(self, sdr_config: Dict) -> Dict:
        """
        Optimize sample collection parameters based on signal quality
        
        Args:
            sdr_config: SDR configuration dictionary
            
        Returns:
            Optimized configuration
        """
        # Adaptive sample count based on signal strength
        if self.config["optimization"]["adaptive_sample_count"]:
            # Start with fewer samples, increase if needed
            sdr_config["calibration_samples"] = min(4096, sdr_config["calibration_samples"])
            sdr_config["calibration_duration"] = min(0.5, sdr_config["calibration_duration"])
        
        return sdr_config
    
    def collect_calibration_data_parallel(self) -> Dict:
        """
        Collect calibration data from both SDRs in parallel
        
        Returns:
            Dictionary containing calibration data from both SDRs
        """
        logger.info("Starting parallel calibration data collection...")
        self.start_time = time.time()
        
        # Create queues for thread communication
        sdr1_queue = queue.Queue()
        sdr2_queue = queue.Queue()
        
        # Start calibration threads
        thread1 = threading.Thread(
            target=self._calibrate_single_sdr,
            args=("sdr1", sdr1_queue)
        )
        thread2 = threading.Thread(
            target=self._calibrate_single_sdr,
            args=("sdr2", sdr2_queue)
        )
        
        thread1.start()
        thread2.start()
        
        # Wait for both threads to complete
        thread1.join()
        thread2.join()
        
        # Collect results
        sdr1_data = sdr1_queue.get()
        sdr2_data = sdr2_queue.get()
        
        calibration_data = {
            "sdr1": sdr1_data,
            "sdr2": sdr2_data,
            "calibration_time": time.time() - self.start_time
        }
        
        logger.info(f"Parallel calibration completed in {calibration_data['calibration_time']:.2f} seconds")
        return calibration_data
    
    def _calibrate_single_sdr(self, sdr_id: str, result_queue: queue.Queue):
        """
        Calibrate a single SDR (runs in separate thread)
        
        Args:
            sdr_id: Identifier for the SDR ("sdr1" or "sdr2")
            result_queue: Queue to store results
        """
        try:
            sdr_config = self.config["sdr_configs"][sdr_id]
            sdr_config = self.optimize_sample_parameters(sdr_config)
            
            logger.info(f"Starting calibration for {sdr_id}")
            start_time = time.time()
            
            # Simulate SDR calibration process
            # In real implementation, this would interface with the actual SDR hardware
            calibration_data = self._simulate_sdr_calibration(sdr_id, sdr_config)
            
            calibration_time = time.time() - start_time
            self.calibration_times[sdr_id] = calibration_time
            
            logger.info(f"{sdr_id} calibration completed in {calibration_time:.2f} seconds")
            
            result_queue.put({
                "sdr_id": sdr_id,
                "calibration_data": calibration_data,
                "calibration_time": calibration_time,
                "status": "success"
            })
            
        except Exception as e:
            logger.error(f"Error calibrating {sdr_id}: {str(e)}")
            result_queue.put({
                "sdr_id": sdr_id,
                "error": str(e),
                "status": "error"
            })
    
    def _simulate_sdr_calibration(self, sdr_id: str, config: Dict) -> Dict:
        """
        Simulate SDR calibration process
        In real implementation, this would interface with actual SDR hardware
        
        Args:
            sdr_id: SDR identifier
            config: SDR configuration
            
        Returns:
            Calibration data dictionary
        """
        # Simulate calibration process with realistic timing
        time.sleep(config["calibration_duration"])
        
        # Generate simulated calibration data
        num_antennas = 4  # Typical for KrakenSDR
        num_frequencies = len(self._get_calibration_frequencies())
        
        calibration_data = {
            "antenna_gains": np.random.normal(1.0, 0.1, num_antennas),
            "phase_offsets": np.random.uniform(0, 2*np.pi, num_antennas),
            "frequency_response": np.random.normal(0, 0.5, num_frequencies),
            "noise_floor": np.random.normal(-80, 5),
            "calibration_matrix": np.random.normal(0, 0.1, (num_antennas, num_antennas)),
            "timestamp": time.time()
        }
        
        return calibration_data
    
    def _get_calibration_frequencies(self) -> List[float]:
        """Get list of frequencies for calibration"""
        freq_start, freq_end = self.config["calibration"]["frequency_range"]
        freq_step = self.config["calibration"]["frequency_step"]
        
        return np.arange(freq_start, freq_end + freq_step, freq_step)
    
    def optimize_calibration_matrices(self, calibration_data: Dict) -> Dict:
        """
        Optimize calibration matrices using shared data between SDRs
        
        Args:
            calibration_data: Raw calibration data from both SDRs
            
        Returns:
            Optimized calibration data
        """
        logger.info("Optimizing calibration matrices...")
        
        if not self.config["calibration"]["shared_calibration_data"]:
            return calibration_data
        
        # Extract data from both SDRs
        sdr1_data = calibration_data["sdr1"]["calibration_data"]
        sdr2_data = calibration_data["sdr2"]["calibration_data"]
        
        # Average shared parameters (assuming common noise source and clock)
        shared_gains = (sdr1_data["antenna_gains"] + sdr2_data["antenna_gains"]) / 2
        shared_phase_offsets = (sdr1_data["phase_offsets"] + sdr2_data["phase_offsets"]) / 2
        shared_noise_floor = (sdr1_data["noise_floor"] + sdr2_data["noise_floor"]) / 2
        
        # Apply shared calibration to both SDRs
        sdr1_data["antenna_gains"] = shared_gains
        sdr1_data["phase_offsets"] = shared_phase_offsets
        sdr1_data["noise_floor"] = shared_noise_floor
        
        sdr2_data["antenna_gains"] = shared_gains
        sdr2_data["phase_offsets"] = shared_phase_offsets
        sdr2_data["noise_floor"] = shared_noise_floor
        
        # Pre-compute calibration matrices if enabled
        if self.config["calibration"]["precompute_matrices"]:
            sdr1_data["calibration_matrix"] = self._precompute_calibration_matrix(sdr1_data)
            sdr2_data["calibration_matrix"] = self._precompute_calibration_matrix(sdr2_data)
        
        logger.info("Calibration matrices optimized using shared data")
        return calibration_data
    
    def _precompute_calibration_matrix(self, calibration_data: Dict) -> np.ndarray:
        """
        Pre-compute calibration matrix for faster runtime processing
        
        Args:
            calibration_data: Calibration data for one SDR
            
        Returns:
            Pre-computed calibration matrix
        """
        # This is a simplified example - real implementation would be more complex
        gains = calibration_data["antenna_gains"]
        phases = calibration_data["phase_offsets"]
        
        # Create calibration matrix
        num_antennas = len(gains)
        cal_matrix = np.zeros((num_antennas, num_antennas), dtype=complex)
        
        for i in range(num_antennas):
            for j in range(num_antennas):
                if i == j:
                    cal_matrix[i, j] = gains[i] * np.exp(1j * phases[i])
                else:
                    cal_matrix[i, j] = 0.1 * gains[i] * np.exp(1j * phases[i])
        
        return cal_matrix
    
    def save_calibration_cache(self, calibration_data: Dict):
        """Save calibration data to cache file for future use"""
        cache_file = self.config["optimization"]["cache_file"]
        
        with self.calibration_lock:
            with open(cache_file, 'w') as f:
                json.dump(calibration_data, f, indent=2, default=str)
        
        logger.info(f"Calibration data saved to {cache_file}")
    
    def load_calibration_cache(self) -> Optional[Dict]:
        """Load calibration data from cache file"""
        cache_file = self.config["optimization"]["cache_file"]
        
        if not os.path.exists(cache_file):
            return None
        
        try:
            with open(cache_file, 'r') as f:
                cached_data = json.load(f)
            
            # Check if cache is recent enough (e.g., less than 1 hour old)
            cache_age = time.time() - cached_data.get("timestamp", 0)
            if cache_age < 3600:  # 1 hour
                logger.info("Using cached calibration data")
                return cached_data
            else:
                logger.info("Cache is too old, performing fresh calibration")
                return None
                
        except Exception as e:
            logger.warning(f"Error loading cache: {e}")
            return None
    
    def run_optimized_calibration(self) -> Dict:
        """
        Run the complete optimized calibration process
        
        Returns:
            Final calibration results
        """
        logger.info("Starting optimized dual KrakenSDR calibration...")
        
        # Check for cached calibration first
        if self.config["optimization"]["use_cached_calibration"]:
            cached_data = self.load_calibration_cache()
            if cached_data:
                return cached_data
        
        # Run parallel calibration
        if self.config["calibration"]["parallel_calibration"]:
            calibration_data = self.collect_calibration_data_parallel()
        else:
            # Sequential calibration (fallback)
            calibration_data = self._collect_calibration_data_sequential()
        
        # Optimize calibration matrices
        calibration_data = self.optimize_calibration_matrices(calibration_data)
        
        # Save to cache
        self.save_calibration_cache(calibration_data)
        
        # Print performance summary
        self._print_performance_summary(calibration_data)
        
        return calibration_data
    
    def _collect_calibration_data_sequential(self) -> Dict:
        """Fallback sequential calibration method"""
        logger.info("Running sequential calibration...")
        
        calibration_data = {"sdr1": None, "sdr2": None, "calibration_time": 0}
        start_time = time.time()
        
        # Calibrate SDR1
        sdr1_queue = queue.Queue()
        self._calibrate_single_sdr("sdr1", sdr1_queue)
        calibration_data["sdr1"] = sdr1_queue.get()
        
        # Calibrate SDR2
        sdr2_queue = queue.Queue()
        self._calibrate_single_sdr("sdr2", sdr2_queue)
        calibration_data["sdr2"] = sdr2_queue.get()
        
        calibration_data["calibration_time"] = time.time() - start_time
        return calibration_data
    
    def _print_performance_summary(self, calibration_data: Dict):
        """Print performance summary"""
        total_time = calibration_data["calibration_time"]
        
        print("\n" + "="*50)
        print("CALIBRATION PERFORMANCE SUMMARY")
        print("="*50)
        print(f"Total calibration time: {total_time:.2f} seconds")
        
        if "sdr1" in self.calibration_times:
            print(f"SDR1 calibration time: {self.calibration_times['sdr1']:.2f} seconds")
        if "sdr2" in self.calibration_times:
            print(f"SDR2 calibration time: {self.calibration_times['sdr2']:.2f} seconds")
        
        # Calculate time savings vs sequential
        sequential_time = sum(self.calibration_times.values())
        if sequential_time > 0:
            time_savings = ((sequential_time - total_time) / sequential_time) * 100
            print(f"Time savings vs sequential: {time_savings:.1f}%")
        
        print("="*50)

def main():
    """Main function to run optimized calibration"""
    calibrator = OptimizedDualKrakenCalibration()
    
    try:
        results = calibrator.run_optimized_calibration()
        print("\nCalibration completed successfully!")
        return results
    except Exception as e:
        logger.error(f"Calibration failed: {str(e)}")
        return None

if __name__ == "__main__":
    main()