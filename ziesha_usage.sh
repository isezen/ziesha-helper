#!/usr/bin/env bash
#
# Usage printing functions for Ziesha Helper
#
#

DESCRIPTION="[0;35mDESCRIPTION:[0m"
OPTIONS="[0;35mOPTIONS:[0m"
COMMANDS="[0;35mCOMMANDS:[0m"
USAGE="[0;35mUSAGE EXAMPLES:[0m"

# Print version
function _version () {
  cat<<EOF
[0;31mℤiesha Helper [0;34mv$VERSION[0m
EOF
}

# Print Header section of Usage
function _usage_header () {
  _version
  cat<<EOF

  Made with ❤️  by [0;31mPentafenolin[0m [0;34m(2022)[0m
  [0;32m● Discord: [0;33mpentafenolin#9413[0m
  [0;32m● Twitter: [0;33m@pentafenolin[0m (Follow me! ^_^)
  [0;32m● Github : [0;33misezen[0m

EOF
}

# Print main usage section
function _usage_main () {
  _usage_header
  cat<<EOF
  $DESCRIPTION
    Manage Ziesha-network infrastructure.
    For more info, type [0;49;96m'$EXE COMMAND -h'[0m

  $OPTIONS
    -h | --help     : Shows this message
    -v | --version  : Show Ziesha Helper version

  $COMMANDS
    -i | install    : Install a Ziesha tool
    -u | update     : Update a Ziesha tool
    -r | remove     : Remove/uninstall a Ziesha tool
    -l | log        : Show log of a Ziesha tool
    -a | autoupdate : Set auto-update on/off
    -s | set        : Set a variable
    -g | get        : Get a variable
       | download   : Download zoro dat files
       | init       : Initialize bazuka
       | run        : Run selected tool
       | reset      : Reset bazuka and wallet
       | start      : Start a service
       | stop       : Stop a service
       | restart    : Restart a service

  $USAGE
    [0;49;96m$ $EXE install bazuka
    $ $EXE -i bazuka
    $ $EXE remove zoro
    $ $EXE set discord-handle MYHANDLE
    $ $EXE start uzi-pool[0m

EOF
}

# Generalized usage function
function _usage () {
  _version
  cat<<EOF

  $DESCRIPTION
    $1 specified Ziesha tool
    Tools: ('$APPS')

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE $1 rust # will $1 rust toolchain
    $ $EXE $1 bazuka # will $1 bazuka
    $ $EXE $1 bazuka zoro # will $1 bazuka and zoro both
    $ $EXE $1 all # will install all Ziesha tools[0m

EOF
}

# Print usage for run command
function _usage_run () {
  _version
  cat<<EOF

  $DESCRIPTION
    Run specified Ziesha tool.
    You can run only a tool at a time.
    Tools: ('$APPS')

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE run bazuka # will run bazuka
    $ $EXE run zoro # will run zoro
    $ $EXE run zoro # will run uzi-pool
    $ $EXE run zoro # will run uzi-miner[0m

EOF
}

# Print usage for log command
function _usage_log () {
  _version
  cat<<EOF

  $DESCRIPTION
    Show log of specified tool
    Tools: ('$APPS')

  $OPTIONS
    -n | --nlines   : Initial number of lines to output [0;33m(Default is 30)[0m
    -c | --no-color : No colorized output
    -h | --help     : Shows this message

  $USAGE
    [0;49;96m$ $EXE log bazuka
    $ $EXE log zoro -c
    $ $EXE log uzi-pool -n 100
    $ $EXE log uzi-miner[0m

EOF
}

# Print usage for get command
function _usage_get () {
  _version
  cat<<EOF

  $DESCRIPTION
    Get value of specified variable.

  $OPTIONS
    -h | --help : Shows this message

  $COMMANDS
    GENERAL:
     discord-handle  : Your discord handle
     network         : Network name
     update-interval : Auto-update interval
    POOL:
     share-capacity  : Share Capacity
     share-easiness  : Share Easiness
     reward-ratio   : Reward Ratio
     reward-delay   : Reward Delay
    ZORO:
     zoro-seed      : Zoro Seed
     update-dat     : update.dat file path
     deposit-dat    : deposit.dat file path
     withdraw-dat   : withdraw.dat file path
    

  $USAGE
    [0;49;96m$ $EXE get discord-handle
    $ $EXE get zoro-seed
    $ $EXE get share-capacity
    $ $EXE get share-easiness
    $ $EXE get reward-ratio.02
    $ $EXE get reward-delay[0m

EOF
}

# Print usage for set command
function _usage_set () {
  _version
  cat<<EOF

  $DESCRIPTION
    Set the value of specified variable.
    If you do not give a values for some arguments,
    they will be set to default ones.

  $OPTIONS
     -h | --help            : Shows this message
    GENERAL:
     -d | --discord-handle  : Your discord handle
     -n | --network         : Network name
     -u | --update-interval : Auto-update interval [0;33m(Default is $UPDATE_INTERVAL seconds)[0m
    POOL:
     -c | --share-capacity  : Share Capacity [0;33m(Default is $SHARE_CAPACITY)[0m
     -e | --share-easiness  : Share Easiness [0;33m(Default is $SHARE_EASINESS)[0m
     -o | --reward-ratio    : Reward Ratio   [0;33m(Default is $REWARD_RATIO)[0m
     -y | --reward-delay    : Reward Delay   [0;33m(Default is $REWARD_DELAY)[0m
    ZORO:
     -z | --zoro-seed       : Zoro Seed
     -t | --update-dat      : update.dat file path
                              [0;33m(Default is $UPDATE_DAT)[0m
     -p | --deposit-dat     : deposit.dat file path
                              [0;33m(Default is $DEPOSIT_DAT)[0m
     -w | --withdraw-dat    : withdraw.dat file path
                              [0;33m(Default is $WITHDRAW_DAT)[0m

  $USAGE
    [0;49;96m$ $EXE set --discord-handle MYHANDLE
    $ $EXE set -d MYHANDLE [0;33m# same as above[0;49;96m
    $ $EXE set -z 12345 [0;33m# set zoro seed[0;49;96m
    $ $EXE set -c 450 -e 300 -o 0.02
    $ $EXE set --reward-delay 3
    $ $EXE set --deposit-dat $HOME/deposit.dat[0m

EOF
}

# Print usage for init command
function _usage_init () {
  _version
  cat<<EOF

  $DESCRIPTION
    Set-up initialization parameters for bazuka.
    Extra arguments will be passed to 'bazuka init'

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE init --network groth-5
    $ $EXE init --network groth-5 --bootstrap 65.108.193.133:8765
    $ $EXE init --network groth-5 --bootstrap 65.108.193.133:8765 --mnemonic "YOUR OLD MNEMONIC PHRASE"[0m

EOF
}

# Print usage for download command
function _usage_download () {
  _version
  cat<<EOF

  $DESCRIPTION
    Download Zoro circuit-param files.
    Downloading process may take a long time.
    Consider run the command in a screen session.

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE download update-dat
    $ $EXE download deposit-dat
    $ $EXE download withdraw-dat[0m

EOF
}

function _usage_reset () {
  _version
  cat<<EOF

  $DESCRIPTION
    Reset bazuka initialization parameters and wallet
    Argument 'all' will delete both .bazuka.yaml and .bazuka-wallet files

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE reset bazuka
    $ $EXE reset wallet
    $ $EXE reset all[0m

EOF
}

# Print usage for start/stop/restart commands
function _usage_service () {
  _version
  cat<<EOF

  $DESCRIPTION
    $1 specified service running in the background

  $OPTIONS
    -h | --help : Shows this message

  $USAGE
    [0;49;96m$ $EXE start bazuka # will start bazuka in background
    $ $EXE start auto-update # will start auto-update
    $ $EXE stop zoro # will stop if it is running
    $ $EXE restart uzi-pool # will restart uzi-pool[0m

EOF
}
