#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Setup Android SDK ===${NC}"

export ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"

# Download Command Line Tools if not exists
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
    echo -e "${GREEN}Downloading Android Command Line Tools...${NC}"
    cd "$ANDROID_HOME/cmdline-tools"
    # URL for commandlinetools-linux-11076708_latest.zip
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    
    unzip -q cmdline-tools.zip
    mv cmdline-tools latest
    rm cmdline-tools.zip
    echo -e "${GREEN}Command Line Tools installed.${NC}"
else
    echo -e "${BLUE}Command Line Tools already installed.${NC}"
fi

# Setup PATH for sdkmanager
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# 3. Accept Licenses
echo -e "${GREEN}Accepting Licenses...${NC}"
yes | sdkmanager --licenses > /dev/null 2>&1 || true

# 4. Install SDK Components
echo -e "${GREEN}Installing SDK Components...${NC}"
# Install: platform-tools, latest platform (e.g. android-34), build-tools
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo -e "${GREEN}=== SDK Setup Complete ===${NC}"
