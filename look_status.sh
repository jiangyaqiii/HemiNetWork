#!/bin/bash

if screen -list | grep -q hemi; then
    echo "运行中"
else
    echo "停止"
fi
