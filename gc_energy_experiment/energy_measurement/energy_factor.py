#!/usr/bin/env python3
"""
Factory module for creating appropriate energy measurement providers.
"""

import os
from .gc_energy_wrapper import GCEnergyWrapper


def create_energy_provider(mock_mode: bool = None):
    """
    Factory function to create appropriate energy measurement provider.
    
    Args:
        mock_mode: If None, determined by ENERGY_MOCK_MODE environment variable
        
    Returns:
        GCEnergyWrapper instance configured for mock or real measurements
    """
    if mock_mode is None:
        mock_mode = os.getenv('ENERGY_MOCK_MODE', 'false').lower() == 'true'
    
    return GCEnergyWrapper(mock_mode=mock_mode)


# For backwards compatibility with your original test code
def get_energy_provider():
    """Legacy function name for compatibility."""
    return create_energy_provider()