#!/usr/bin/env python
import os
import sys
import argparse

# DO NOT import any LibreTranslate modules
# This is a dummy version that always succeeds

if __name__ == "__main__":
    # Parse arguments (for compatibility) but don't use them
    parser = argparse.ArgumentParser()
    parser.add_argument("--load_only_lang_codes", type=str, default="")
    parser.add_argument("--update", action='store_true')
    args = parser.parse_args()
    
    print("Dummy script for DigitalOcean deployment - No models will be installed at build time")
    print("Models will be pre-downloaded in the Dockerfile")
    sys.exit(0)  # Always exit successfully
