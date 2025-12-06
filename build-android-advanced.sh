#!/bin/bash

################################################################################
# Moodist Android Advanced Build Script
# Script build nâng cao với nhiều options và tính năng
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
BUILD_TYPE="debug"
CLEAN_BUILD=false
SKIP_WEB=false
INSTALL_DEVICE=false
RUN_AFTER_INSTALL=false
BUILD_AAB=false
VERBOSE=false

################################################################################
# Parse arguments
################################################################################

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -s|--skip-web)
            SKIP_WEB=true
            shift
            ;;
        -i|--install)
            INSTALL_DEVICE=true
            shift
            ;;
        -r|--run)
            INSTALL_DEVICE=true
            RUN_AFTER_INSTALL=true
            shift
            ;;
        -a|--aab)
            BUILD_AAB=true
            BUILD_TYPE="release"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            cat << EOF
Moodist Android Advanced Build Script

Usage: $0 [OPTIONS]

Options:
  -t, --type TYPE       Build type: debug or release (default: debug)
  -c, --clean           Clean build (xóa cache trước khi build)
  -s, --skip-web        Bỏ qua build web app
  -i, --install         Cài đặt APK lên thiết bị sau khi build
  -r, --run             Cài đặt và chạy app sau khi build
  -a, --aab             Build Android App Bundle (AAB) cho Google Play
  -v, --verbose         Hiển thị log chi tiết
  -h, --help            Hiển thị help

Examples:
  $0                              # Build debug APK
  $0 -t release                   # Build release APK
  $0 -t release -c                # Clean build release APK
  $0 -t debug -i                  # Build và cài đặt debug APK
  $0 -t debug -r                  # Build, cài đặt và chạy app
  $0 -a                           # Build AAB cho Google Play
  $0 -t release -c -v             # Clean build release với verbose log

EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

header() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

check_device() {
    if [ "$INSTALL_DEVICE" = true ]; then
        log "Kiểm tra thiết bị Android..."
        
        DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
        
        if [ "$DEVICES" -eq 0 ]; then
            error "Không tìm thấy thiết bị Android nào!"
            info "Kết nối thiết bị qua USB và bật USB Debugging"
            exit 1
        fi
        
        success "Tìm thấy $DEVICES thiết bị"
        adb devices | grep "device$"
        echo ""
    fi
}

clean_build() {
    if [ "$CLEAN_BUILD" = true ]; then
        log "Cleaning build cache..."
        
        cd android
        ./gradlew clean
        cd ..
        
        # Clean node_modules if needed
        if [ -d "node_modules" ]; then
            warning "Giữ nguyên node_modules (không xóa)"
        fi
        
        # Clean dist
        if [ -d "dist" ]; then
            rm -rf dist
            success "Đã xóa thư mục dist"
        fi
        
        success "Clean hoàn tất"
        echo ""
    fi
}

build_web() {
    if [ "$SKIP_WEB" = true ]; then
        warning "Bỏ qua build web app"
        echo ""
        return
    fi
    
    log "Building web app..."
    
    if [ "$VERBOSE" = true ]; then
        npm run build
    else
        npm run build > /dev/null 2>&1
    fi
    
    success "Web app build hoàn tất"
    echo ""
}

sync_cap() {
    log "Syncing Capacitor..."
    
    if [ "$VERBOSE" = true ]; then
        npx cap sync android
    else
        npx cap sync android > /dev/null 2>&1
    fi
    
    success "Capacitor sync hoàn tất"
    echo ""
}

build_android_apk() {
    log "Building Android APK ($BUILD_TYPE)..."
    
    cd android
    chmod +x gradlew
    
    GRADLE_CMD="./gradlew"
    
    if [ "$BUILD_TYPE" = "release" ]; then
        GRADLE_CMD="$GRADLE_CMD assembleRelease"
        APK_PATH="app/build/outputs/apk/release/app-release.apk"
        OUTPUT_NAME="moodist-release.apk"
    else
        GRADLE_CMD="$GRADLE_CMD assembleDebug"
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
        OUTPUT_NAME="moodist-debug.apk"
    fi
    
    if [ "$VERBOSE" = true ]; then
        $GRADLE_CMD --info
    else
        $GRADLE_CMD
    fi
    
    cd ..
    
    if [ -f "android/$APK_PATH" ]; then
        cp "android/$APK_PATH" "$OUTPUT_NAME"
        APK_SIZE=$(du -h "$OUTPUT_NAME" | cut -f1)
        success "APK build hoàn tất ($APK_SIZE)"
        info "Location: $OUTPUT_NAME"
    else
        error "APK không được tạo!"
        exit 1
    fi
    
    echo ""
}

build_android_aab() {
    log "Building Android App Bundle (AAB)..."
    
    cd android
    chmod +x gradlew
    
    if [ "$VERBOSE" = true ]; then
        ./gradlew bundleRelease --info
    else
        ./gradlew bundleRelease
    fi
    
    cd ..
    
    AAB_PATH="android/app/build/outputs/bundle/release/app-release.aab"
    
    if [ -f "$AAB_PATH" ]; then
        cp "$AAB_PATH" "moodist-release.aab"
        AAB_SIZE=$(du -h "moodist-release.aab" | cut -f1)
        success "AAB build hoàn tất ($AAB_SIZE)"
        info "Location: moodist-release.aab"
    else
        error "AAB không được tạo!"
        exit 1
    fi
    
    echo ""
}

install_apk() {
    if [ "$INSTALL_DEVICE" = false ]; then
        return
    fi
    
    log "Cài đặt APK lên thiết bị..."
    
    if [ "$BUILD_TYPE" = "release" ]; then
        APK_FILE="moodist-release.apk"
    else
        APK_FILE="moodist-debug.apk"
    fi
    
    if [ ! -f "$APK_FILE" ]; then
        error "APK file không tồn tại: $APK_FILE"
        exit 1
    fi
    
    adb install -r "$APK_FILE"
    
    success "APK đã được cài đặt"
    echo ""
}

run_app() {
    if [ "$RUN_AFTER_INSTALL" = false ]; then
        return
    fi
    
    log "Khởi chạy ứng dụng..."
    
    # Launch app
    adb shell am start -n com.moodist.app/.MainActivity
    
    success "Ứng dụng đã được khởi chạy"
    
    # Show logs
    if [ "$VERBOSE" = true ]; then
        info "Hiển thị logs (Ctrl+C để thoát)..."
        adb logcat | grep -i moodist
    fi
    
    echo ""
}

show_summary() {
    header "🎉 Build Hoàn Thành"
    
    echo -e "${CYAN}Build Configuration:${NC}"
    echo -e "  Type: $BUILD_TYPE"
    echo -e "  Clean: $CLEAN_BUILD"
    echo -e "  Skip Web: $SKIP_WEB"
    
    if [ "$BUILD_AAB" = true ]; then
        echo -e "  Format: AAB (Android App Bundle)"
        echo -e "\n${CYAN}Output:${NC}"
        echo -e "  📦 moodist-release.aab"
    else
        echo -e "  Format: APK"
        echo -e "\n${CYAN}Output:${NC}"
        if [ "$BUILD_TYPE" = "release" ]; then
            echo -e "  📱 moodist-release.apk"
        else
            echo -e "  📱 moodist-debug.apk"
        fi
    fi
    
    if [ "$INSTALL_DEVICE" = true ]; then
        echo -e "\n${GREEN}✓ Đã cài đặt lên thiết bị${NC}"
    fi
    
    if [ "$RUN_AFTER_INSTALL" = true ]; then
        echo -e "${GREEN}✓ Đã khởi chạy ứng dụng${NC}"
    fi
    
    echo ""
}

################################################################################
# Main
################################################################################

header "🚀 Moodist Android Build"

info "Build type: $BUILD_TYPE"
info "Clean build: $CLEAN_BUILD"
info "Skip web: $SKIP_WEB"
info "Install: $INSTALL_DEVICE"
info "AAB: $BUILD_AAB"

START=$(date +%s)

check_device
clean_build
build_web
sync_cap

if [ "$BUILD_AAB" = true ]; then
    build_android_aab
else
    build_android_apk
fi

install_apk
run_app

END=$(date +%s)
DURATION=$((END - START))

show_summary

echo -e "${CYAN}⏱  Total time: ${DURATION}s${NC}"
echo ""
