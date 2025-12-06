#!/bin/bash

################################################################################
# Android Environment Check Script
# Kiểm tra môi trường build Android trên Ubuntu
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

################################################################################
# Functions
################################################################################

header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_item() {
    local name=$1
    local command=$2
    local required=$3
    
    echo -n "Checking $name... "
    
    if command -v $command &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗ NOT FOUND${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠ NOT FOUND${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

check_version() {
    local name=$1
    local command=$2
    
    if command -v $command &> /dev/null; then
        VERSION=$($command 2>&1 | head -n 1)
        echo -e "  ${CYAN}→${NC} $VERSION"
    fi
}

check_env_var() {
    local name=$1
    local var=$2
    local required=$3
    
    echo -n "Checking $name... "
    
    if [ -n "${!var}" ]; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  ${CYAN}→${NC} ${!var}"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗ NOT SET${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠ NOT SET${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

check_directory() {
    local name=$1
    local path=$2
    local required=$3
    
    echo -n "Checking $name... "
    
    if [ -d "$path" ]; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  ${CYAN}→${NC} $path"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗ NOT FOUND${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠ NOT FOUND${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

################################################################################
# Checks
################################################################################

header "🔍 Android Build Environment Check"

echo -e "${BLUE}System Information:${NC}"
echo -e "  OS: $(lsb_release -d | cut -f2)"
echo -e "  Kernel: $(uname -r)"
echo -e "  Architecture: $(uname -m)"
echo ""

# Node.js
header "📦 Node.js & npm"
if check_item "Node.js" "node" "true"; then
    check_version "Node.js" "node --version"
fi

if check_item "npm" "npm" "true"; then
    check_version "npm" "npm --version"
fi

# Java
header "☕ Java Development Kit"
if check_item "Java" "java" "true"; then
    check_version "Java" "java -version"
fi

if check_item "javac" "javac" "true"; then
    check_version "javac" "javac -version"
fi

check_env_var "JAVA_HOME" "JAVA_HOME" "true"

# Android SDK
header "🤖 Android SDK"
check_env_var "ANDROID_HOME" "ANDROID_HOME" "true"
check_env_var "ANDROID_SDK_ROOT" "ANDROID_SDK_ROOT" "false"

if [ -n "$ANDROID_HOME" ]; then
    check_directory "Android SDK" "$ANDROID_HOME" "true"
    check_directory "Platform Tools" "$ANDROID_HOME/platform-tools" "true"
    check_directory "Build Tools" "$ANDROID_HOME/build-tools" "true"
    check_directory "Platforms" "$ANDROID_HOME/platforms" "true"
fi

# Android Tools
header "🛠️ Android Build Tools"
check_item "adb" "adb" "true"
if command -v adb &> /dev/null; then
    check_version "adb" "adb --version"
fi

check_item "sdkmanager" "sdkmanager" "false"
check_item "avdmanager" "avdmanager" "false"
check_item "emulator" "emulator" "false"

# Gradle
header "🐘 Gradle"
check_item "gradle" "gradle" "false"
if command -v gradle &> /dev/null; then
    check_version "Gradle" "gradle --version"
fi

# Git
header "📚 Version Control"
check_item "git" "git" "true"
if command -v git &> /dev/null; then
    check_version "Git" "git --version"
fi

# Build Tools
header "🔨 Build Tools"
check_item "make" "make" "false"
check_item "gcc" "gcc" "false"
check_item "g++" "g++" "false"

# Capacitor
header "⚡ Capacitor"
if [ -f "package.json" ]; then
    if grep -q "@capacitor/cli" package.json; then
        echo -e "Capacitor CLI: ${GREEN}✓ Found in package.json${NC}"
        CAP_VERSION=$(grep "@capacitor/cli" package.json | sed 's/.*: "\(.*\)".*/\1/')
        echo -e "  ${CYAN}→${NC} Version: $CAP_VERSION"
    else
        echo -e "Capacitor CLI: ${RED}✗ Not found in package.json${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "package.json: ${RED}✗ Not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Android project
if [ -d "android" ]; then
    echo -e "Android project: ${GREEN}✓ Found${NC}"
    
    if [ -f "android/gradlew" ]; then
        echo -e "Gradle wrapper: ${GREEN}✓ Found${NC}"
        
        if [ -x "android/gradlew" ]; then
            echo -e "  ${CYAN}→${NC} Executable: Yes"
        else
            echo -e "  ${YELLOW}→${NC} Executable: No (run: chmod +x android/gradlew)"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "Gradle wrapper: ${RED}✗ Not found${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "Android project: ${RED}✗ Not found${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check devices
header "📱 Connected Devices"
if command -v adb &> /dev/null; then
    DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found $DEVICE_COUNT device(s)${NC}"
        adb devices | grep "device$" | while read line; do
            echo -e "  ${CYAN}→${NC} $line"
        done
    else
        echo -e "${YELLOW}⚠ No devices connected${NC}"
        echo -e "  ${CYAN}→${NC} Connect device via USB and enable USB Debugging"
    fi
else
    echo -e "${RED}✗ adb not available${NC}"
fi

# Summary
header "📊 Summary"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Môi trường build Android đã sẵn sàng!${NC}"
    echo ""
    echo -e "${CYAN}Bạn có thể bắt đầu build:${NC}"
    echo -e "  ./build-android.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Môi trường có $WARNINGS cảnh báo${NC}"
    echo -e "${CYAN}Bạn vẫn có thể build, nhưng một số tính năng có thể không khả dụng${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Tìm thấy $ERRORS lỗi và $WARNINGS cảnh báo${NC}"
    echo ""
    echo -e "${YELLOW}Hướng dẫn khắc phục:${NC}"
    echo ""
    
    if ! command -v node &> /dev/null; then
        echo -e "${CYAN}Cài Node.js:${NC}"
        echo -e "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo -e "  sudo apt install -y nodejs"
        echo ""
    fi
    
    if ! command -v java &> /dev/null; then
        echo -e "${CYAN}Cài JDK:${NC}"
        echo -e "  sudo apt install -y openjdk-17-jdk"
        echo ""
    fi
    
    if [ -z "$JAVA_HOME" ]; then
        echo -e "${CYAN}Thiết lập JAVA_HOME:${NC}"
        echo -e "  echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc"
        echo -e "  source ~/.bashrc"
        echo ""
    fi
    
    if [ -z "$ANDROID_HOME" ]; then
        echo -e "${CYAN}Thiết lập ANDROID_HOME:${NC}"
        echo -e "  echo 'export ANDROID_HOME=\$HOME/Android/Sdk' >> ~/.bashrc"
        echo -e "  echo 'export PATH=\$PATH:\$ANDROID_HOME/platform-tools' >> ~/.bashrc"
        echo -e "  source ~/.bashrc"
        echo ""
    fi
    
    if ! command -v adb &> /dev/null; then
        echo -e "${CYAN}Cài Android SDK:${NC}"
        echo -e "  sudo snap install android-studio --classic"
        echo -e "  # Hoặc tải từ: https://developer.android.com/studio"
        echo ""
    fi
    
    exit 1
fi
