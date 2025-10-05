#!/usr/bin/env python3
"""
Dual KrakenSDR Optimizer
Integration script for existing KrakenSDR codebase

This script provides optimizations that can be integrated into your existing
KrakenSDR calibration process to reduce calibration time for dual SDR setup
with common noise source and clock splitter.
"""

import os
import sys
import time
import json
import logging
import threading
from typing import Dict, List, Optional, Any
from concurrent.futures import ThreadPoolExecutor
import numpy as np

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DualKrakenOptimizer:
    """
    Optimizer for dual KrakenSDR setup with common noise source and clock splitter
    """
    
    def __init__(self, config_file: str = "dual_sdr_config.json"):
        self.config = self.load_config(config_file)
        self.calibration_cache = {}
        self.performance_metrics = {}
        
    def load_config(self, config_file: str) -> Dict:
        """Load configuration from file or create default"""
        default_config = {
            "dual_sdr": {
                "enabled": True,
                "common_noise_source": True,
                "clock_splitter": True,
                "parallel_calibration": True
            },
            "calibration": {
                "sample_rate": 2.048e6,
                "calibration_samples": 8192,  # Reduced from 16384
                "calibration_duration": 1.0,  # Reduced from 2.0
                "frequency_step": 5e6,  # Increased from 1e6
                "frequency_range": [50e6, 200e6],
                "cache_enabled": True,
                "cache_file": "/tmp/kraken_calibration_cache.json",
                "cache_validity_hours": 1
            },
            "optimization": {
                "reduce_sample_count": True,
                "fast_frequency_hopping": True,
                "shared_calibration_data": True,
                "skip_clock_calibration": True,
                "background_processing": False
            }
        }
        
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r') as f:
                    user_config = json.load(f)
                    # Merge configurations
                    for key, value in user_config.items():
                        if key in default_config and isinstance(value, dict):
                            default_config[key].update(value)
                        else:
                            default_config[key] = value
            except Exception as e:
                logger.warning(f"Error loading config: {e}, using defaults")
        
        return default_config
    
    def optimize_calibration_parameters(self) -> Dict:
        """
        Optimize calibration parameters based on dual SDR setup
        
        Returns:
            Optimized calibration parameters
        """
        optimized_params = {
            "sample_rate": self.config["calibration"]["sample_rate"],
            "calibration_samples": self.config["calibration"]["calibration_samples"],
            "calibration_duration": self.config["calibration"]["calibration_duration"],
            "frequency_step": self.config["calibration"]["frequency_step"],
            "frequency_range": self.config["calibration"]["frequency_range"]
        }
        
        # Apply optimizations based on hardware setup
        if self.config["dual_sdr"]["common_noise_source"]:
            optimized_params["shared_noise_calibration"] = True
            optimized_params["noise_calibration_time"] = 0.5  # Reduced from 2.0
            
        if self.config["dual_sdr"]["clock_splitter"]:
            optimized_params["skip_clock_calibration"] = True
            optimized_params["clock_calibration_time"] = 0  # Skip entirely
            
        if self.config["dual_sdr"]["parallel_calibration"]:
            optimized_params["parallel_processing"] = True
            optimized_params["max_workers"] = 2
            
        return optimized_params
    
    def check_calibration_cache(self) -> Optional[Dict]:
        """
        Check if valid calibration cache exists
        
        Returns:
            Cached calibration data if valid, None otherwise
        """
        if not self.config["calibration"]["cache_enabled"]:
            return None
            
        cache_file = self.config["calibration"]["cache_file"]
        if not os.path.exists(cache_file):
            return None
            
        try:
            with open(cache_file, 'r') as f:
                cache_data = json.load(f)
                
            # Check cache age
            cache_age = time.time() - cache_data.get("timestamp", 0)
            max_age = self.config["calibration"]["cache_validity_hours"] * 3600
            
            if cache_age < max_age:
                logger.info(f"Using cached calibration data (age: {cache_age/60:.1f} minutes)")
                return cache_data
            else:
                logger.info("Calibration cache expired")
                return None
                
        except Exception as e:
            logger.warning(f"Error reading cache: {e}")
            return None
    
    def save_calibration_cache(self, calibration_data: Dict):
        """Save calibration data to cache"""
        if not self.config["calibration"]["cache_enabled"]:
            return
            
        cache_file = self.config["calibration"]["cache_file"]
        try:
            cache_data = {
                "calibration_data": calibration_data,
                "timestamp": time.time(),
                "config": self.config
            }
            
            with open(cache_file, 'w') as f:
                json.dump(cache_data, f, indent=2, default=str)
                
            logger.info(f"Calibration data saved to cache: {cache_file}")
            
        except Exception as e:
            logger.error(f"Error saving cache: {e}")
    
    def calibrate_dual_sdr_optimized(self, sdr1_calibrate_func, sdr2_calibrate_func) -> Dict:
        """
        Run optimized dual SDR calibration
        
        Args:
            sdr1_calibrate_func: Function to calibrate SDR1
            sdr2_calibrate_func: Function to calibrate SDR2
            
        Returns:
            Calibration results
        """
        logger.info("Starting optimized dual SDR calibration...")
        start_time = time.time()
        
        # Check for cached calibration
        cached_data = self.check_calibration_cache()
        if cached_data:
            return cached_data["calibration_data"]
        
        # Get optimized parameters
        params = self.optimize_calibration_parameters()
        
        # Run calibration based on configuration
        if self.config["dual_sdr"]["parallel_calibration"]:
            calibration_data = self._calibrate_parallel(sdr1_calibrate_func, sdr2_calibrate_func, params)
        else:
            calibration_data = self._calibrate_sequential(sdr1_calibrate_func, sdr2_calibrate_func, params)
        
        # Apply shared calibration optimizations
        if self.config["dual_sdr"]["common_noise_source"]:
            calibration_data = self._apply_shared_calibration(calibration_data)
        
        # Save to cache
        self.save_calibration_cache(calibration_data)
        
        # Record performance metrics
        total_time = time.time() - start_time
        self.performance_metrics["total_calibration_time"] = total_time
        self.performance_metrics["optimization_mode"] = "dual_sdr_optimized"
        
        logger.info(f"Optimized dual SDR calibration completed in {total_time:.2f} seconds")
        return calibration_data
    
    def _calibrate_parallel(self, sdr1_func, sdr2_func, params) -> Dict:
        """Calibrate both SDRs in parallel"""
        logger.info("Running parallel calibration...")
        
        with ThreadPoolExecutor(max_workers=2) as executor:
            # Submit calibration tasks
            future_sdr1 = executor.submit(sdr1_func, params)
            future_sdr2 = executor.submit(sdr2_func, params)
            
            # Wait for completion
            sdr1_data = future_sdr1.result()
            sdr2_data = future_sdr2.result()
        
        return {
            "sdr1": sdr1_data,
            "sdr2": sdr2_data,
            "calibration_method": "parallel",
            "optimization_applied": True
        }
    
    def _calibrate_sequential(self, sdr1_func, sdr2_func, params) -> Dict:
        """Calibrate SDRs sequentially (fallback)"""
        logger.info("Running sequential calibration...")
        
        sdr1_data = sdr1_func(params)
        sdr2_data = sdr2_func(params)
        
        return {
            "sdr1": sdr1_data,
            "sdr2": sdr2_data,
            "calibration_method": "sequential",
            "optimization_applied": True
        }
    
    def _apply_shared_calibration(self, calibration_data: Dict) -> Dict:
        """Apply shared calibration optimizations"""
        logger.info("Applying shared calibration optimizations...")
        
        # Extract data from both SDRs
        sdr1_data = calibration_data["sdr1"]
        sdr2_data = calibration_data["sdr2"]
        
        # Apply shared noise calibration (common noise source)
        if "noise_data" in sdr1_data and "noise_data" in sdr2_data:
            # Average noise calibration data
            shared_noise = {
                "noise_floor": (sdr1_data["noise_data"]["noise_floor"] + 
                               sdr2_data["noise_data"]["noise_floor"]) / 2,
                "noise_spectrum": (sdr1_data["noise_data"]["noise_spectrum"] + 
                                 sdr2_data["noise_data"]["noise_spectrum"]) / 2
            }
            
            # Apply shared noise data to both SDRs
            sdr1_data["noise_data"] = shared_noise
            sdr2_data["noise_data"] = shared_noise
            sdr1_data["shared_calibration"] = True
            sdr2_data["shared_calibration"] = True
        
        return calibration_data
    
    def get_performance_metrics(self) -> Dict:
        """Get performance metrics"""
        return self.performance_metrics.copy()
    
    def print_optimization_summary(self):
        """Print optimization summary"""
        print("\n" + "="*50)
        print("DUAL KRAKENSDR OPTIMIZATION SUMMARY")
        print("="*50)
        
        print(f"Configuration:")
        print(f"  - Dual SDR Mode: {self.config['dual_sdr']['enabled']}")
        print(f"  - Common Noise Source: {self.config['dual_sdr']['common_noise_source']}")
        print(f"  - Clock Splitter: {self.config['dual_sdr']['clock_splitter']}")
        print(f"  - Parallel Calibration: {self.config['dual_sdr']['parallel_calibration']}")
        
        print(f"\nCalibration Parameters:")
        print(f"  - Sample Rate: {self.config['calibration']['sample_rate']/1e6:.1f} MHz")
        print(f"  - Calibration Samples: {self.config['calibration']['calibration_samples']}")
        print(f"  - Calibration Duration: {self.config['calibration']['calibration_duration']}s")
        print(f"  - Frequency Step: {self.config['calibration']['frequency_step']/1e6:.1f} MHz")
        
        if self.performance_metrics:
            print(f"\nPerformance Metrics:")
            for key, value in self.performance_metrics.items():
                print(f"  - {key}: {value}")

# Integration functions for existing KrakenSDR code
def integrate_dual_sdr_optimization():
    """
    Integration function to be called from existing KrakenSDR code
    """
    optimizer = DualKrakenOptimizer()
    
    # Example integration - replace with your actual calibration functions
    def sdr1_calibrate(params):
        # Your existing SDR1 calibration code here
        time.sleep(params["calibration_duration"])  # Simulate calibration
        return {"sdr_id": "SDR1", "status": "calibrated", "params": params}
    
    def sdr2_calibrate(params):
        # Your existing SDR2 calibration code here
        time.sleep(params["calibration_duration"])  # Simulate calibration
        return {"sdr_id": "SDR2", "status": "calibrated", "params": params}
    
    # Run optimized calibration
    results = optimizer.calibrate_dual_sdr_optimized(sdr1_calibrate, sdr2_calibrate)
    
    # Print summary
    optimizer.print_optimization_summary()
    
    return results

if __name__ == "__main__":
    # Example usage
    results = integrate_dual_sdr_optimization()
    print(f"\nCalibration results: {results}")