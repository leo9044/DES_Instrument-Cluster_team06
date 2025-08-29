## Prerequisites

### Preconditions
- Ubuntu 20.04+ (Host)
- Raspberry Pi 4 (Target)
- Network connection (with SSH access)
- Qt5 project source code

## Step-by-Step Guide

### 1. Setup Host Environment (One-time only)

```bash
# Check script permissions
chmod +x scripts/*.sh

# Run the automatic host setup script
./scripts/setup_host.sh
```

**What this step does:**
- Installs essential packages (GCC, Qt5 development tools)
- Installs the cross-compiler
- Creates a build directory

### 2. Edit Configuration File

```bash
# Configure Raspberry Pi information
nano scripts/config.sh
```

**Items to edit:**
```bash
# Raspberry Pi Connection Info (Required!)
RPI_IP="192.168.86.38"   # Your actual Raspberry Pi IP
RPI_USER="team06"        # Your actual username
```

**How to find the IP address:**
```bash
# Execute on the Raspberry Pi
hostname -I
```

### 3. Synchronize Sysroot

```bash
# Copy system files from the Raspberry Pi
./scripts/sync_sysroot.sh
```

**What this step does:**
- Copies `/usr/lib` and `/usr/include` from the Raspberry Pi
- Downloads the ARM64 version of Qt5 libraries
- Fixes symbolic links

**Estimated time:** 5-15 minutes (depends on network speed)

### 4. Build the Project

```bash
# Cross-compile the Qt5 project
cd ~
mkdir -p build
cd build
cmake -DCMAKE_TOOLCHAIN_FILE=/home/leo/rpi/toolchain-rpi.cmake /your/project/path
make -j$(nproc)
```

**What this step does:**
- Configures CMake (using the toolchain file)
- Overrides Qt5 IMPORTED_LOCATION
- Generates the ARM64 executable

### 5. Deploy to Raspberry Pi

```bash
# Automatically find and transfer the ARM64 executable
/home/leo/rpi/scripts/deploy.sh
```

**What this step does:**
- Automatically finds ARM64 executable in build directory
- Transfers to Raspberry Pi via SCP
- Done!

## Full Workflow Example

```bash
# 1. Setup environment (one-time only)
./scripts/setup_host.sh

# 2. Edit config file
nano scripts/config.sh
# Change RPI_IP to "192.168.86.38"

# 3. Synchronize Sysroot  
./scripts/sync_sysroot.sh

# 4. Build the project
cd ~/build
cmake -DCMAKE_TOOLCHAIN_FILE=/home/leo/rpi/toolchain-rpi.cmake /your/project/path
make -j$(nproc)

# 5. Deploy
/home/leo/rpi/scripts/deploy.sh
```

## References

* **Official CMake Documentation**: For a foundational understanding of the variables and principles involved.
  * [CMake Toolchains Documentation](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html)

* **Community Guide**: A similar workflow for cross-compiling Qt 5.15 for Raspberry Pi 4, which provides additional context and examples.
  * [Cross-Compiling QT-5.15-For-RP4 (GitHub)](https://github.com/shekhuverma/Cross-Compiling-QT-5.15-For-RP4)
