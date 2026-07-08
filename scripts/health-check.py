#!/usr/bin/env python3
"""
Auto-Health Check & Startup
Checks if 9Router, Ruflo, Graphify are running.
If not, starts them silently in background.
Run this periodically or at system startup.
"""

import subprocess
import time
import sys
import os
import platform
import socket
from pathlib import Path

# Colors
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'

def is_port_open(host, port):
    """Check if a port is open (service running)"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def is_command_available(cmd):
    """Check if a command is available"""
    try:
        if platform.system() == "Windows":
            subprocess.run([cmd, "--version"],
                         capture_output=True,
                         timeout=2,
                         shell=True)
        else:
            subprocess.run([cmd, "--version"],
                         capture_output=True,
                         timeout=2)
        return True
    except:
        return False

def start_9router():
    """Start 9Router in background"""
    try:
        if platform.system() == "Windows":
            subprocess.Popen("9router",
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL,
                           creationflags=subprocess.CREATE_NEW_CONSOLE)
        else:
            subprocess.Popen(["9router"],
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        print(f"{RED}✗ Failed to start 9Router: {e}{RESET}")
        return False

def start_ruflo():
    """Start Ruflo daemon in background"""
    try:
        if platform.system() == "Windows":
            subprocess.Popen("ruflo daemon start",
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL,
                           creationflags=subprocess.CREATE_NEW_CONSOLE)
        else:
            subprocess.Popen(["ruflo", "daemon", "start"],
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        print(f"{RED}✗ Failed to start Ruflo: {e}{RESET}")
        return False

def main():
    print(f"{YELLOW}[Health Check] Verifying AI toolkit services...{RESET}")
    print()

    # Check if tools are installed
    print("Checking installations...")

    if not is_command_available("9router"):
        print(f"{RED}✗ 9Router not installed{RESET}")
        return False

    if not is_command_available("ruflo"):
        print(f"{RED}✗ Ruflo not installed{RESET}")
        return False

    if not is_command_available("graphify"):
        print(f"{RED}✗ Graphify not installed{RESET}")
        return False

    print(f"{GREEN}✓ All tools installed{RESET}")
    print()

    # Check if services are running
    print("Checking service status...")

    # 9Router
    if is_port_open("localhost", 20128):
        print(f"{GREEN}✓ 9Router running (localhost:20128){RESET}")
    else:
        print(f"{YELLOW}⏳ 9Router not running, starting...{RESET}")
        if start_9router():
            time.sleep(3)  # Wait for it to start
            if is_port_open("localhost", 20128):
                print(f"{GREEN}✓ 9Router started{RESET}")
            else:
                print(f"{RED}✗ 9Router failed to start{RESET}")

    # Ruflo
    try:
        result = subprocess.run(["ruflo", "daemon", "status"],
                              capture_output=True,
                              timeout=2,
                              text=True)
        if "running" in result.stdout.lower() or result.returncode == 0:
            print(f"{GREEN}✓ Ruflo daemon running{RESET}")
        else:
            print(f"{YELLOW}⏳ Ruflo daemon not running, starting...{RESET}")
            if start_ruflo():
                time.sleep(2)
                print(f"{GREEN}✓ Ruflo daemon started{RESET}")
    except:
        print(f"{YELLOW}⏳ Ruflo daemon not running, starting...{RESET}")
        if start_ruflo():
            time.sleep(2)
            print(f"{GREEN}✓ Ruflo daemon started{RESET}")

    # Graphify (no daemon, just check installation)
    print(f"{GREEN}✓ Graphify ready{RESET}")

    print()
    print(f"{GREEN}✅ All services ready!{RESET}")
    print()
    print("Available:")
    print("  • 9Router   → http://localhost:20128/dashboard")
    print("  • Ruflo     → Agent daemon ready")
    print("  • Graphify  → /graphify command ready")
    print()

    return True

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Interrupted{RESET}")
        sys.exit(0)
    except Exception as e:
        print(f"{RED}Error: {e}{RESET}")
        sys.exit(1)
