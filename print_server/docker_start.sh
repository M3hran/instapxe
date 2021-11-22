#!/bin/bash
docker run -it -v /dev/bus/usb:/dev/bus/usb --device-cgroup-rule='c 180:* rmw' ubuntu bash
