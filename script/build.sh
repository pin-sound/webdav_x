#!/bin/bash

echo "========================================"

cd ..

flutter build apk --release --no-tree-shake-icons

flutter build apk --split-per-abi --release --no-tree-shake-icons

flutter build windows --release
cd script && flutter pub get && dart index.dart && ./enigmavbconsole.exe pack.evb

echo "所有构建任务均已完成!"
echo "========================================"