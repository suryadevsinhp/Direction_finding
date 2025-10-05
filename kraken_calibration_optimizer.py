#!/usr/bin/env python3
"""
KrakenSDR Calibration Optimizer
Advanced optimization techniques for dual KrakenSDR setup with common noise source

This module provides additional optimization strategies:
1. Frequency domain optimization
2. Memory-efficient data processing
3. Real-time calibration updates
4. Hardware-specific optimizations
"""

import numpy as np
import time
import threading
from typing import Dict, List, Tuple, Optional
import logging
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)

class CalibrationMode(Enum):
    FAST = "fast"
    BALANCED = "balanced"
    PRECISE = "precise"

@dataclass
class CalibrationMetrics:
    """Metrics for tracking calibration performance"""
    total_time: float
    sdr1_time: float
    sdr2_time: float
    parallel_efficiency: float
    memory_usage: float
    cpu_usage: float
    accuracy_score: float

class FrequencyDomainOptimizer:
    """Optimize calibration using frequency domain techniques"""
    
    def __init__(self, sample_rate: float, fft_size: int = 1024):
        self.sample_rate = sample_rate
        self.fft_size = fft_size
        self.freq_bins = np.fft.fftfreq(fft_size, 1/sample_rate)
        
    def optimize_frequency_hopping(self, signal_data: np.ndarray) -> List[float]:
        """
        Optimize frequency hopping based on signal strength analysis
        
        Args:
            signal_data: Input signal data
            
        Returns:
            List of optimized frequencies for calibration
        """
        # Perform FFT to analyze frequency content
        fft_data = np.fft.fft(signal_data, self.fft_size)
        power_spectrum = np.abs(fft_data) ** 2
        
        # Find peaks in the power spectrum
        peak_indices = self._find_peaks(power_spectrum)
        peak_frequencies = self.freq_bins[peak_indices]
        
        # Filter frequencies above noise floor
        noise_floor = np.percentile(power_spectrum, 10)
        valid_peaks = peak_frequencies[power_spectrum[peak_indices] > noise_floor * 2]
        
        return valid_peaks.tolist()
    
    def _find_peaks(self, data: np.ndarray, threshold: float = 0.1) -> np.ndarray:
        """Find peaks in data using simple threshold method"""
        peaks = []
        for i in range(1, len(data) - 1):
            if data[i] > data[i-1] and data[i] > data[i+1] and data[i] > threshold:
                peaks.append(i)
        return np.array(peaks)

class MemoryEfficientProcessor:
    """Memory-efficient data processing for large datasets"""
    
    def __init__(self, chunk_size: int = 1024):
        self.chunk_size = chunk_size
        
    def process_calibration_data_chunked(self, data: np.ndarray, 
                                       processing_func) -> np.ndarray:
        """
        Process large calibration data in chunks to save memory
        
        Args:
            data: Input data array
            processing_func: Function to apply to each chunk
            
        Returns:
            Processed data
        """
        results = []
        
        for i in range(0, len(data), self.chunk_size):
            chunk = data[i:i + self.chunk_size]
            processed_chunk = processing_func(chunk)
            results.append(processed_chunk)
            
        return np.concatenate(results)
    
    def streaming_calibration(self, data_stream, calibration_func):
        """
        Perform calibration on streaming data
        
        Args:
            data_stream: Generator yielding data chunks
            calibration_func: Calibration function to apply
        """
        calibration_results = []
        
        for chunk in data_stream:
            result = calibration_func(chunk)
            calibration_results.append(result)
            
            # Yield intermediate results for real-time processing
            yield result

class HardwareSpecificOptimizer:
    """Hardware-specific optimizations for KrakenSDR"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.clock_splitter_enabled = config.get("clock_splitter_enabled", False)
        self.common_noise_source = config.get("common_noise_source", False)
        
    def optimize_for_clock_splitter(self) -> Dict:
        """
        Optimize calibration for clock splitter setup
        
        Returns:
            Optimization parameters
        """
        optimizations = {
            "synchronize_clocks": True,
            "shared_reference": True,
            "reduced_phase_calibration": True,
            "common_gain_calibration": True
        }
        
        if self.clock_splitter_enabled:
            # Clock splitter provides synchronized clocks
            optimizations["skip_clock_calibration"] = True
            optimizations["shared_phase_reference"] = True
            
        return optimizations
    
    def optimize_for_common_noise_source(self) -> Dict:
        """
        Optimize calibration for common noise source setup
        
        Returns:
            Optimization parameters
        """
        optimizations = {
            "shared_noise_calibration": True,
            "reduced_noise_measurements": True,
            "common_gain_reference": True
        }
        
        if self.common_noise_source:
            # Common noise source allows shared calibration data
            optimizations["skip_individual_noise_calibration"] = True
            optimizations["use_shared_noise_data"] = True
            
        return optimizations

class RealTimeCalibrationUpdater:
    """Real-time calibration updates and monitoring"""
    
    def __init__(self, update_interval: float = 1.0):
        self.update_interval = update_interval
        self.is_running = False
        self.calibration_data = None
        self.update_callbacks = []
        
    def add_update_callback(self, callback):
        """Add callback function for calibration updates"""
        self.update_callbacks.append(callback)
    
    def start_background_updates(self, calibration_func):
        """Start background calibration updates"""
        self.is_running = True
        
        def update_loop():
            while self.is_running:
                try:
                    # Perform calibration update
                    new_data = calibration_func()
                    self.calibration_data = new_data
                    
                    # Notify callbacks
                    for callback in self.update_callbacks:
                        callback(new_data)
                        
                except Exception as e:
                    logger.error(f"Error in background calibration update: {e}")
                
                time.sleep(self.update_interval)
        
        update_thread = threading.Thread(target=update_loop, daemon=True)
        update_thread.start()
    
    def stop_background_updates(self):
        """Stop background calibration updates"""
        self.is_running = False

class CalibrationProfiler:
    """Profile calibration performance and identify bottlenecks"""
    
    def __init__(self):
        self.timings = {}
        self.memory_usage = {}
        self.start_times = {}
        
    def start_timer(self, operation: str):
        """Start timing an operation"""
        self.start_times[operation] = time.time()
    
    def end_timer(self, operation: str):
        """End timing an operation"""
        if operation in self.start_times:
            duration = time.time() - self.start_times[operation]
            self.timings[operation] = duration
            del self.start_times[operation]
            return duration
        return 0
    
    def get_performance_report(self) -> Dict:
        """Get comprehensive performance report"""
        total_time = sum(self.timings.values())
        
        report = {
            "total_calibration_time": total_time,
            "operation_timings": self.timings.copy(),
            "memory_usage": self.memory_usage.copy(),
            "bottlenecks": self._identify_bottlenecks()
        }
        
        return report
    
    def _identify_bottlenecks(self) -> List[str]:
        """Identify performance bottlenecks"""
        bottlenecks = []
        
        if not self.timings:
            return bottlenecks
        
        total_time = sum(self.timings.values())
        threshold = 0.2  # 20% of total time
        
        for operation, time_taken in self.timings.items():
            if time_taken / total_time > threshold:
                bottlenecks.append(f"{operation}: {time_taken:.2f}s ({time_taken/total_time*100:.1f}%)")
        
        return bottlenecks

class AdvancedCalibrationOptimizer:
    """Main optimizer class combining all optimization techniques"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.freq_optimizer = FrequencyDomainOptimizer(
            sample_rate=config["sdr_configs"]["sdr1"]["sample_rate"]
        )
        self.memory_processor = MemoryEfficientProcessor()
        self.hardware_optimizer = HardwareSpecificOptimizer(config["hardware"])
        self.realtime_updater = RealTimeCalibrationUpdater()
        self.profiler = CalibrationProfiler()
        
    def optimize_calibration_parameters(self) -> Dict:
        """
        Optimize all calibration parameters based on hardware setup
        
        Returns:
            Optimized calibration parameters
        """
        logger.info("Optimizing calibration parameters...")
        
        # Get hardware-specific optimizations
        clock_optimizations = self.hardware_optimizer.optimize_for_clock_splitter()
        noise_optimizations = self.hardware_optimizer.optimize_for_common_noise_source()
        
        # Combine optimizations
        optimized_params = {
            **clock_optimizations,
            **noise_optimizations,
            "frequency_hopping": True,
            "parallel_processing": True,
            "memory_efficient": True,
            "adaptive_sampling": True
        }
        
        # Adjust parameters based on optimizations
        if optimized_params.get("skip_clock_calibration"):
            optimized_params["clock_calibration_time"] = 0
        else:
            optimized_params["clock_calibration_time"] = 2.0
            
        if optimized_params.get("skip_individual_noise_calibration"):
            optimized_params["noise_calibration_time"] = 1.0  # Shared calibration
        else:
            optimized_params["noise_calibration_time"] = 2.0  # Individual calibration
            
        logger.info("Calibration parameters optimized")
        return optimized_params
    
    def run_optimized_calibration(self, mode: CalibrationMode = CalibrationMode.BALANCED) -> Dict:
        """
        Run calibration with all optimizations applied
        
        Args:
            mode: Calibration mode (fast, balanced, precise)
            
        Returns:
            Calibration results with performance metrics
        """
        logger.info(f"Running optimized calibration in {mode.value} mode...")
        
        # Start profiling
        self.profiler.start_timer("total_calibration")
        
        # Get optimized parameters
        optimized_params = self.optimize_calibration_parameters()
        
        # Adjust parameters based on mode
        if mode == CalibrationMode.FAST:
            optimized_params["calibration_samples"] = 4096
            optimized_params["frequency_step"] = 10e6
        elif mode == CalibrationMode.PRECISE:
            optimized_params["calibration_samples"] = 16384
            optimized_params["frequency_step"] = 1e6
        
        # Run calibration with optimizations
        self.profiler.start_timer("data_collection")
        calibration_data = self._run_calibration_with_optimizations(optimized_params)
        self.profiler.end_timer("data_collection")
        
        # Process results
        self.profiler.start_timer("data_processing")
        processed_data = self._process_calibration_data(calibration_data)
        self.profiler.end_timer("data_processing")
        
        # End profiling
        self.profiler.end_timer("total_calibration")
        
        # Generate performance report
        performance_report = self.profiler.get_performance_report()
        
        results = {
            "calibration_data": processed_data,
            "performance_metrics": performance_report,
            "optimization_mode": mode.value,
            "optimized_parameters": optimized_params
        }
        
        logger.info(f"Optimized calibration completed in {performance_report['total_calibration_time']:.2f} seconds")
        return results
    
    def _run_calibration_with_optimizations(self, params: Dict) -> Dict:
        """Run calibration with all optimizations applied"""
        # This would interface with the actual SDR hardware
        # For now, simulate the process
        time.sleep(params.get("calibration_time", 5.0))
        
        return {
            "sdr1_data": {"status": "success"},
            "sdr2_data": {"status": "success"},
            "shared_data": {"status": "success"}
        }
    
    def _process_calibration_data(self, data: Dict) -> Dict:
        """Process calibration data with memory-efficient techniques"""
        # Apply memory-efficient processing
        processed_data = self.memory_processor.process_calibration_data_chunked(
            np.array([1, 2, 3, 4]),  # Placeholder data
            lambda x: x * 2  # Placeholder processing
        )
        
        return {
            "processed_data": processed_data.tolist(),
            "processing_method": "memory_efficient"
        }

def main():
    """Example usage of the advanced calibration optimizer"""
    config = {
        "sdr_configs": {
            "sdr1": {"sample_rate": 2.048e6},
            "sdr2": {"sample_rate": 2.048e6}
        },
        "hardware": {
            "clock_splitter_enabled": True,
            "common_noise_source": True
        }
    }
    
    optimizer = AdvancedCalibrationOptimizer(config)
    
    # Run calibration in different modes
    for mode in CalibrationMode:
        print(f"\nRunning calibration in {mode.value} mode...")
        results = optimizer.run_optimized_calibration(mode)
        
        print(f"Calibration time: {results['performance_metrics']['total_calibration_time']:.2f}s")
        print(f"Bottlenecks: {results['performance_metrics']['bottlenecks']}")

if __name__ == "__main__":
    main()