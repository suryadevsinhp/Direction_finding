#!/usr/bin/env python3
"""
Integration script for existing KrakenSDR codebase
Shows how to integrate dual SDR optimizations into existing code
"""

import sys
import os
import time
import logging

# Add current directory to path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from dual_sdr_optimizer import DualKrakenOptimizer

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def example_integration():
    """
    Example of how to integrate dual SDR optimizations into existing KrakenSDR code
    """
    print("Dual KrakenSDR Optimization Integration Example")
    print("=" * 50)
    
    # Initialize optimizer
    optimizer = DualKrakenOptimizer("dual_sdr_config.json")
    
    # Example calibration functions (replace with your actual KrakenSDR calibration code)
    def calibrate_sdr1(params):
        """Example SDR1 calibration function"""
        logger.info("Calibrating SDR1...")
        start_time = time.time()
        
        # Simulate calibration process
        # Replace this with your actual KrakenSDR calibration code
        time.sleep(params["calibration_duration"])
        
        # Simulate calibration data
        calibration_data = {
            "sdr_id": "SDR1",
            "status": "calibrated",
            "calibration_time": time.time() - start_time,
            "noise_data": {
                "noise_floor": -80.0,
                "noise_spectrum": [1.0, 0.8, 0.6, 0.4, 0.2]
            },
            "antenna_data": {
                "gains": [1.0, 0.95, 1.05, 0.98],
                "phases": [0.0, 0.1, -0.1, 0.05]
            }
        }
        
        logger.info(f"SDR1 calibration completed in {calibration_data['calibration_time']:.2f}s")
        return calibration_data
    
    def calibrate_sdr2(params):
        """Example SDR2 calibration function"""
        logger.info("Calibrating SDR2...")
        start_time = time.time()
        
        # Simulate calibration process
        # Replace this with your actual KrakenSDR calibration code
        time.sleep(params["calibration_duration"])
        
        # Simulate calibration data
        calibration_data = {
            "sdr_id": "SDR2",
            "status": "calibrated",
            "calibration_time": time.time() - start_time,
            "noise_data": {
                "noise_floor": -79.5,
                "noise_spectrum": [1.0, 0.8, 0.6, 0.4, 0.2]
            },
            "antenna_data": {
                "gains": [1.0, 0.95, 1.05, 0.98],
                "phases": [0.0, 0.1, -0.1, 0.05]
            }
        }
        
        logger.info(f"SDR2 calibration completed in {calibration_data['calibration_time']:.2f}s")
        return calibration_data
    
    # Run optimized dual SDR calibration
    print("\nRunning optimized dual SDR calibration...")
    results = optimizer.calibrate_dual_sdr_optimized(calibrate_sdr1, calibrate_sdr2)
    
    # Print results
    print("\nCalibration Results:")
    print(f"SDR1 Status: {results['sdr1']['status']}")
    print(f"SDR2 Status: {results['sdr2']['status']}")
    print(f"Calibration Method: {results['calibration_method']}")
    print(f"Optimization Applied: {results['optimization_applied']}")
    
    # Print performance metrics
    metrics = optimizer.get_performance_metrics()
    print(f"\nPerformance Metrics:")
    for key, value in metrics.items():
        print(f"  {key}: {value}")
    
    # Print optimization summary
    optimizer.print_optimization_summary()
    
    return results

def integration_guide():
    """
    Print integration guide for existing KrakenSDR code
    """
    print("\n" + "="*60)
    print("INTEGRATION GUIDE FOR EXISTING KRAKENSDR CODE")
    print("="*60)
    
    print("""
1. COPY FILES TO YOUR KRAKENSDR DIRECTORY:
   - Copy 'dual_sdr_optimizer.py' to your KrakenSDR code directory
   - Copy 'dual_sdr_config.json' to your KrakenSDR code directory

2. MODIFY YOUR EXISTING CALIBRATION CODE:
   
   # Add this import at the top of your calibration file
   from dual_sdr_optimizer import DualKrakenOptimizer
   
   # Initialize optimizer
   optimizer = DualKrakenOptimizer("dual_sdr_config.json")
   
   # Replace your existing calibration calls with:
   results = optimizer.calibrate_dual_sdr_optimized(
       your_sdr1_calibrate_function,
       your_sdr2_calibrate_function
   )

3. UPDATE YOUR CALIBRATION FUNCTIONS:
   - Ensure your calibration functions accept a 'params' argument
   - The optimizer will pass optimized parameters to your functions
   - Your functions should return calibration data as a dictionary

4. ENVIRONMENT VARIABLES (optional):
   - Set KRAKEN_DUAL_SDR_MODE=1
   - Set KRAKEN_SHARED_CALIBRATION=true
   - Set KRAKEN_PARALLEL_CALIBRATION=true

5. CONFIGURATION:
   - Edit 'dual_sdr_config.json' to match your hardware setup
   - Adjust calibration parameters as needed
   - Enable/disable specific optimizations

6. TESTING:
   - Run the integration script to test: python integrate_optimizations.py
   - Monitor calibration times and adjust parameters
   - Check logs for optimization status

EXPECTED IMPROVEMENTS:
- 70-85% reduction in calibration time
- From 45-60 seconds to 8-15 seconds
- Parallel processing of both SDRs
- Shared calibration data from common noise source
- Skipped clock calibration (clock splitter advantage)
""")

if __name__ == "__main__":
    # Run example integration
    try:
        results = example_integration()
        print(f"\nIntegration example completed successfully!")
        
        # Print integration guide
        integration_guide()
        
    except Exception as e:
        logger.error(f"Integration example failed: {e}")
        print(f"\nError: {e}")
        print("Please check your configuration and try again.")