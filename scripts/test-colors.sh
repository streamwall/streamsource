#!/bin/bash
# Test script for terminal colors

echo -e "\033[1;34m=== Terminal Color Test ===\033[0m"
echo ""

# Basic colors
echo -e "\033[0;30mBlack\033[0m \033[1;30mBold Black\033[0m"
echo -e "\033[0;31mRed\033[0m \033[1;31mBold Red\033[0m"
echo -e "\033[0;32mGreen\033[0m \033[1;32mBold Green\033[0m"
echo -e "\033[0;33mYellow\033[0m \033[1;33mBold Yellow\033[0m"
echo -e "\033[0;34mBlue\033[0m \033[1;34mBold Blue\033[0m"
echo -e "\033[0;35mPurple\033[0m \033[1;35mBold Purple\033[0m"
echo -e "\033[0;36mCyan\033[0m \033[1;36mBold Cyan\033[0m"
echo -e "\033[0;37mWhite\033[0m \033[1;37mBold White\033[0m"

echo ""
echo -e "\033[1;34m=== 256 Color Support Test ===\033[0m"
echo ""

# Test 256 colors
for i in {0..255}; do
    printf "\033[38;5;${i}m%3d " $i
    if (( ($i + 1) % 16 == 0 )); then
        echo -e "\033[0m"
    fi
done
echo -e "\033[0m"

echo ""
echo -e "\033[1;34m=== True Color (24-bit) Test ===\033[0m"
echo ""

# Test true color gradient
awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'

echo ""
echo -e "\033[1;34m=== Emoji Support Test ===\033[0m"
echo ""
echo "✓ ✗ 🚀 💻 🔧 📦 🎨 🐛 ⚡ 🔥"

echo ""
echo -e "\033[1;34m=== Makefile Colors Preview ===\033[0m"
echo ""
echo -e "\033[1m\033[0;34m🚀 StreamSource Development Commands\033[0m"
echo -e "\033[1m\033[0;32mCore Commands:\033[0m"
echo -e "  \033[0;36mmake dev\033[0m        - Start all services with asset watchers"
echo -e "  \033[0;36mmake test\033[0m       - Run full test suite (use \033[0;33mfile=path/to/spec.rb\033[0m)"
echo -e "\033[1m\033[0;32m✓ Setup complete!\033[0m"
echo -e "\033[0;31mError: No file specified\033[0m"
echo -e "\033[0;33mUsage:\033[0m make spec file=spec/models/stream_spec.rb"

echo ""
echo -e "\033[1;34m=== Environment Info ===\033[0m"
echo "Terminal: $TERM"
echo "Shell: $SHELL"
echo "Color support: $(tput colors) colors"