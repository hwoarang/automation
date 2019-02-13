#!/bin/bash

SUSEConnect -r ${regcodeSLES}
sleep 1
SUSEConnect -p ses/5/x86_64 -r ${regcodeSES}
