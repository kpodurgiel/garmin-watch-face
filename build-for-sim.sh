#!/bin/bash

monkeyc -o bin/garminwatchface_sim.prg -f monkey.jungle -y ~/garmin_developer_key -d venu3_sim -w  && monkeydo bin/garminwatchface_sim.prg venu3
