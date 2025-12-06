#!/bin/bash

################################################################################
# Moodist Android Build Script
# Script tự động build ứng dụng Android cho Ubuntu
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build configuration
BUILD_TYPE="${1:-debug}"  # debug or release
SKIP_WEB_BUILD="${2:-false}"

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  🚀 Moodist Android Build Script${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 không được tìm thấy. Vui lòng cài đặt $1."
        exit 1
    fi
}

check_environment() {
    print_step "Kiểm tra môi trường..."
    
    # Check Node.js
    check_command node
    print_success "Node.js: $(node --version)"
    
    # Check npm
    check_command npm
    print_success "npm: $(npm --version)"
    
    # Check Java
    check_command java
    print_success "Java: $(java -version 2>&1 | head -n 1)"
    
    # Check ANDROID_HOME
    if [ -z "$ANDROID_HOME" ]; then
        print_error "ANDROID_HOME không được thiết lập!"
        print_info "Thêm vào ~/.bashrc: export ANDROID_HOME=\$HOME/Android/Sdk"
        exit 1
    fi
    print_success "ANDROID_HOME: $ANDROID_HOME"
    
    # Check adb
    if ! command -v adb &> /dev/null; then
        print_warning "adb không tìm thấy trong PATH"
    else
        print_success "adb: $(adb --version | head -n 1)"
    fi
    
    echo ""
}

install_dependencies() {
    print_step "Cài đặt dependencies..."
    
    if [ ! -d "node_modules" ]; then
        npm install
        print_success "Dependencies đã được cài đặt"
    else
        print_info "Dependencies đã tồn tại, bỏ qua..."
    fi
    
    echo ""
}

build_web_app() {
    if [ "$SKIP_WEB_BUILD" = "true" ]; then
        print_warning "Bỏ qua build web app (SKIP_WEB_BUILD=true)"
        echo ""
        return
    fi
    
    print_step "Building web app..."
    
    npm run build
    
    if [ $? -eq 0 ]; then
        print_success "Web app đã được build thành công"
    else
        print_error "Web app build thất bại!"
        exit 1
    fi
    
    echo ""
}

sync_capacitor() {
    print_step "Syncing Capacitor với Android..."
    
    npx cap sync android
    
    if [ $? -eq 0 ]; then
        print_success "Capacitor sync thành công"
    else
        print_error "Capacitor sync thất bại!"
        exit 1
    fi
    
    echo ""
}

build_android() {
    print_step "Building Android APK ($BUILD_TYPE)..."
    
    cd android
    
    # Make gradlew executable
    chmod +x gradlew
    
    if [ "$BUILD_TYPE" = "release" ]; then
        ./gradlew assembleRelease
        APK_PATH="app/build/outputs/apk/release/app-release.apk"
    else
        ./gradlew assembleDebug
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Android build thành công!"
        
        # Check if APK exists
        if [ -f "$APK_PATH" ]; then
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            print_info "APK Location: android/$APK_PATH"
            print_info "APK Size: $APK_SIZE"
            
            # Copy to root directory
            cp "$APK_PATH" "../moodist-$BUILD_TYPE.apk"
            print_success "APK đã được copy đến: moodist-$BUILD_TYPE.apk"
        fi
    else
        print_error "Android build thất bại!"
        cd ..
        exit 1
    fi
    
    cd ..
    echo ""
}

show_summary() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ Build Hoàn Thành!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}📱 APK File:${NC} moodist-$BUILD_TYPE.apk"
    echo -e "${CYAN}📂 Full Path:${NC} android/app/build/outputs/apk/$BUILD_TYPE/app-$BUILD_TYPE.apk"
    echo ""
    echo -e "${YELLOW}Cài đặt APK:${NC}"
    echo -e "  adb install -r moodist-$BUILD_TYPE.apk"
    echo ""
    echo -e "${YELLOW}Hoặc copy APK đến điện thoại và cài đặt thủ công${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [BUILD_TYPE] [SKIP_WEB_BUILD]"
    echo ""
    echo "BUILD_TYPE:"
    echo "  debug    - Build debug APK (default)"
    echo "  release  - Build release APK (cần keystore)"
    echo ""
    echo "SKIP_WEB_BUILD:"
    echo "  false    - Build web app (default)"
    echo "  true     - Bỏ qua build web app"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build debug APK"
    echo "  $0 release            # Build release APK"
    echo "  $0 debug true         # Build debug APK, bỏ qua web build"
    echo ""
}

################################################################################
# Main Script
################################################################################

# Show help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Validate build type
if [ "$BUILD_TYPE" != "debug" ] && [ "$BUILD_TYPE" != "release" ]; then
    print_error "BUILD_TYPE không hợp lệ: $BUILD_TYPE"
    echo ""
    show_usage
    exit 1
fi

# Start build process
print_header

START_TIME=$(date +%s)

check_environment
install_dependencies
build_web_app
sync_capacitor
build_android

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

show_summary

echo -e "${CYAN}⏱  Build time: ${DURATION}s${NC}"
echo ""
