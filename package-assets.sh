#!/bin/sh
echo Creating assets...
pwd
mkdir assets
cp out/*.exe assets/
if [ -f "out/*.app"]; then
tar -zcvf assets/DiskImageManager-macOS.tar.gz out/*.app
fi

