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
RPI_IP="192.168.1.100"   # Your actual Raspberry Pi IP
RPI_USER="pi"            # Your actual username
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
cmake -DCMAKE_TOOLCHAIN_FILE=/home/leo/rpi/toolchain-rpi.cmake /home/leo/SEA-ME/DES_Instrument-Clu
ster_team06/Design
make -j$(nproc)
```

**What this step does:**
- Configures CMake (using the toolchain file)
- Overrides Qt5 IMPORTED_LOCATION
- Generates the ARM64 executable

### 5. Deploy to Raspberry Pi

```bash
# Transfer and run the generated executable
./scripts/deploy.sh your_app_name
```

**Example:**
```bash
# Deploy with the built executable name
./scripts/deploy.sh MyQtApp

# Deploy to a specific path
./scripts/deploy.sh build/MyQtApp ~/apps/
```

**What this step does:**
- Transfers the executable to the Raspberry Pi via SCP
- Sets execute permissions
- Checks for dependencies
- Suggests a remote execution test


## Full Workflow Example

```bash
# 1. Setup environment (one-time only)
./scripts/setup_host.sh

# 2. Edit config file
nano scripts/config.sh
# Change RPI_IP to "192.168.1.100"

# 3. Synchronize Sysroot  
./scripts/sync_sysroot.sh

# 4. Build the project
./scripts/build_project.sh /home/leo/MyQtApp

# 5. Deploy
./scripts/deploy.sh MyQtApp

# 6. Monitor logs (in a separate terminal)
./scripts/monitor.sh MyQtApp.log -f
```


## References

* **Official CMake Documentation**: For a foundational understanding of the variables and principles involved.
  * [CMake Toolchains Documentation](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html)

* **Community Guide**: A similar workflow for cross-compiling Qt 5.15 for Raspberry Pi 4, which provides additional context and examples.
  * [Cross-Compiling QT-5.15-For-RP4 (GitHub)](https://github.com/shekhuverma/Cross-Compiling-QT-5.15-For-RP4)
