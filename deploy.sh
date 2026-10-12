#!/bin/bash
set -e
cd ~/wipe
sudo systemctl restart hardhat
sleep 8
npm run deploy:local
sudo cp index.html contract-config.js /var/www/html/
echo "Redeployed. Hard-refresh the browser (Ctrl+Shift+R)."
