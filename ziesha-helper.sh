#!/usr/bin/env bash
# shellcheck disable=1090,1091,2015,2034,2059
#
# Manage Ziesha-network infrastructure.
#
# - Run the command below:
#   $ curl -s https://raw.githubusercontent.com/isezen/ziesha-helper/main/ziesha | bash && . ~/.profile

ZIESHA_PATH="$HOME/.local/ziesha"
ZIESHA_HELPER_PATH="$ZIESHA_PATH/ziesha-helper"
ZORO_PATH="$ZIESHA_PATH/zoro-dat"
SYSTEMD_PATH="$HOME/.config/systemd/user"
ZIESHA_SETTINGS="$HOME/.ziesha.settings"
BOOTSTRAP="--bootstrap 65.108.193.133:8765"
# -------------------------------------------------------------
GITUSR="ziesha-network"
GITURL="https://github.com/$GITUSR/%s.git"
GITURLRAW="https://raw.githubusercontent.com/%s/%s"
ZIESHA_URL="https://raw.githubusercontent.com/isezen/ziesha-helper/main"
CARGO_TOML="$GITURLRAW/master/Cargo.toml"
APPS="bazuka zoro uzi-pool uzi-miner"
CARGO_ENV="$HOME/.cargo/env"
SCRIPT_REMOTE="$GITURLRAW/main/VERSION"
EXE="${0##*/}"
LOG_FILE="$HOME/.ziesha.log"

# -------------------------------------------------------------
# DEFINE SCRIPTS TO SAVE HERE

service_ziesha=$(cat <<EOF
# Path: $SYSTEMD_PATH/ziesha@.service
[Unit]
Description=Ziesha %i Daemon
After=network-online.target

[Service]
Type=simple
WorkingDirectory=$HOME
Environment="RUST_BACKTRACE=full"
ExecStart=$HOME/.local/bin/ziesha run %i
LimitNOFILE=50000
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
)

# -------------------------------------------------------------
# SOURCING
# Download and source a remote script
[ ! -d "$ZIESHA_HELPER_PATH" ] && mkdir -p "$ZIESHA_HELPER_PATH"
source_script () {
    [ ! -f "$ZIESHA_HELPER_PATH/$1" ] && 
        { curl -s -o "$ZIESHA_HELPER_PATH/$1" "$ZIESHA_URL/$1";
          source <(curl -s "$ZIESHA_URL/$1"); } ||
        source "$ZIESHA_HELPER_PATH/$1"
}
[ ! -f "$ZIESHA_HELPER_PATH/AUTHOR" ] &&
    curl -s -o "$ZIESHA_HELPER_PATH/AUTHOR" "$ZIESHA_URL/AUTHOR"
[ ! -f "$ZIESHA_HELPER_PATH/VERSION" ] &&
    curl -s -o "$ZIESHA_HELPER_PATH/VERSION" "$ZIESHA_URL/VERSION"
[ -f "$ZIESHA_SETTINGS" ] && source "$ZIESHA_SETTINGS"
source_script "ziesha-common.sh"
source_script "ziesha-usage.sh"
# shellcheck source=~/.profile
source "$PROFILE"

# -------------------------------------------------------------
# DEFAULT VARIABLES

[[ -z "$SHARE_CAPACITY" ]] && SHARE_CAPACITY=450
[[ -z "$SHARE_EASINESS" ]] && SHARE_EASINESS=300
[[ -z "$REWARD_RATIO" ]] && REWARD_RATIO="0.01"
[[ -z "$REWARD_DELAY" ]] && REWARD_DELAY=3
[[ -z "$UPDATE_DAT" ]] && UPDATE_DAT="$ZORO_PATH/update.dat"
[[ -z "$DEPOSIT_DAT" ]] && DEPOSIT_DAT="$ZORO_PATH/deposit.dat"
[[ -z "$WITHDRAW_DAT" ]] && WITHDRAW_DAT="$ZORO_PATH/withdraw.dat"
[[ -z "$DB_PATH" ]] && DB_PATH="$HOME/.bazuka"
[[ -z "$UPDATE_INTERVAL" ]] && UPDATE_INTERVAL=3600

# -------------------------------------------------------------
# FUNCTIONS:

# Get author info from file
set_author_info () {
    get_author_info () {
        grep -i "^$1 = " "$ZIESHA_HELPER_PATH/AUTHOR" | 
            awk '{print $NF}' | tr -d '"'
    }
    AUTHOR_NAME=$(get_author_info author)
    AUTHOR_TWITTER=$(get_author_info twitter)
    AUTHOR_DISCORD=$(get_author_info discord)
    AUTHOR_GITHUB=$(get_author_info github)
}
set_author_info

# Get info about project from remote github API
remote () {
    local url; local usr; local address
    local app=${1:-bazuka}
    url=$([ "$app" = "ziesha" ] && echo $SCRIPT_REMOTE || echo $CARGO_TOML)
    usr=$([ "$app" = "ziesha" ] && echo "isezen" || echo $GITUSR)
    address=$(printf "$url" "$usr" "$app")
    curl -s "$address"
}

# Add variable to setting file
a2set () {
    [ ! -f "$ZIESHA_SETTINGS" ] && touch "$ZIESHA_SETTINGS"
    rff "$1" "$ZIESHA_SETTINGS"; a2f "$1=\"$2\"" "$ZIESHA_SETTINGS"
}

# Get version of specified app
# Usage Examples:
#   version remote bazuka
#   version local zoro
#   version remote ziesha
version () {
    local t=${1:-local}
    local a=${2:-bazuka}
    if ! contains "local remote" "$t"; then
        msg_err "Target can be only 'local' or 'remote'"
        exit 1
    fi
    if ! contains "$APPS ziesha" "$a"; then
        msg_err "App can be one of '$APPS'"
        exit 1
    fi
    local ret=
    if [ "$t" = "local" ]; then
        [ "$a" = "ziesha" ] && 
        ret=$(grep -i "^version = " "$ZIESHA_HELPER_PATH/VERSION") ||
        ret=$([ -z "$(which "$a")" ] && echo 'NOTSET' || echo "$($a --version)")
    else
        file="$HOME/.cache/$a.cache"
        if [ -f "$file" ]; then
            local cur_time; cur_time=$(date +%s)
            local file_time; file_time=$(stat -c "%Y" "$file")
            if [ $((cur_time - file_time)) -gt $UPDATE_INTERVAL ]; then
                ret=$(remote "$a" | grep -i "^version = ")
                echo "$ret" > "$file"
            else
                ret=$(grep -i "^version = " "$file")
            fi
        else
            ret=$(remote "$a" | grep -i "^version = ")
            echo "$ret" > "$file"
        fi
    fi
    echo "$ret" | tail -n 1 | awk '{print $NF}' | tr -d '"'
}
VERSION=$(version local ziesha)

# Get/search binary path
get_bin_loc () { which "${1:-bazuka}"; }

# Check if app is installed
is_installed () { [[ -n "$(get_bin_loc "${1:-bazuka}")" ]]; }

# Get installed tools
get_installed_tools () {
    local ret=
    for a in $APPS; do is_installed "$a" && ret+=" $a"; done;
    echo "$ret"
}

# Check if rust is installed
rust_is_installed () { is_installed "cargo"; }

# Check if rust is installed and exit if it it is not.
check_rust_installed () {
    if ! rust_is_installed; then
        msg_err "Rust is not installed. Run 'ziesha install rust'."; echo
        exit 0
    fi
}

# Install dependencies
install_deps () {
    local pkgs="cmake build-essential libssl-dev ocl-icd-opencl-dev"
    install "$pkgs" "Installing dependencies" "Dependencies installed"
}

# Install Rust
install_rust () {
    if ! is_installed "$a"; then
        msg_warn "Installing Rust..."; echo -e ''
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs) -y
    else
        msg_info "Rust is ready."
    fi
}

get_running_services () {
    local services=
    local def="$SYSTEMD_PATH/default.target.wants"
    if [ -d "$def" ]; then
        for f in "$def"/ziesha@*; do
            f="${f##*/}"
            f=$(echo "$f" | awk -F '[@.]' '{print $2}')
            services+=" $f"
        done
        services=$(echo "$services" | awk '{$1=$1};1')
    fi
    echo "$services"
}

# Check if a Ziesha service is active or not
service_is_active () { systemctl --user is-active --quiet ziesha@"$1"; }

# Start/stop/restart/enable/disable a Ziesha service
service () {
    local status=${1:-enable}
    local a=${2:-bazuka}
    if ! contains "$APPS auto-update all" "$a"; then
        msg_err "Unknown argument: $a. ('$APPS auto-update all')"; echo -e ''
        exit 1
    fi
    if [ "$a" = "all" ]; then
        local services
        services="$(get_installed_tools) auto-update"
        if [ "$status" == "start" ]; then
            for s in $services; do service start "$s"; done
        else
            local active_services
            active_services=$(get_running_services)
            if [ -z "$active_services" ]; then
                msg_warn "No active services"; echo; return
            fi
            [ "$status" == "stop" ] && 
            ! is_yes "Do you want to stop all services?" && return
            for s in $active_services; do service "$status" "$s"; done
        fi
        return
    fi

    # check if arg is a service or not
    if ! contains "$(get_installed_tools) auto-update" "$a"; then 
        msg_err "$a is not installed. Please, first install."; echo
        return
    fi

    case $status in
        start)
            service_is_active "$a" && 
            { msg_warn "$a is already running."; echo; return; }
            service enable "$a"; msg_info "$a is started."; echo
        ;;
        stop)
            ! service_is_active "$a" && 
            { msg_warn "$a is not active. Run 'ziesha start $a'"; echo; return; }
            service disable "$a"; msg_info "$a is stopped successfully."; echo
        ;;
        restart)
            ! service_is_active "$a" &&
            { msg_warn "$a is not active. Run 'ziesha start $a'"; echo; return; }
            systemctl --user restart ziesha@"$a"
            msg_info "$a is restarted."; echo
        ;;
        enable)
            if ! service_is_active "$a"; then
                # Save Ziesha service file file to systemd path
                [ ! -d "$SYSTEMD_PATH" ] && mkdir -p "$SYSTEMD_PATH"
                if [ ! -f "$SYSTEMD_PATH/ziesha@.service" ]; then
                    save_embedded_content service
                fi
                systemctl --user "$status" --now ziesha@"$a" >> "$LOG_FILE" 2>&1
                systemctl --user daemon-reload >> "$LOG_FILE" 2>&1
            fi
        ;;
        disable)
            if service_is_active "$a"; then
                systemctl --user "$status" --now ziesha@"$a" >> "$LOG_FILE" 2>&1
                systemctl --user daemon-reload >> "$LOG_FILE" 2>&1
            fi
        ;;
        *)
            _unknown_option "$status"; exit 1 ;;
    esac
}

# Start a Ziesha service
start () { service start "$1"; }

# Stop a Ziesha service
stop () { service stop "$1"; }

# Restart a Ziesha service
restart () { service restart "$1"; }

# Check variable if it is a Ziesha tool or not
# if so, run specified function
check_a () {
    local func=$1; shift
    local a=${@:-bazuka}
    [ "$a" = "all" ] && a=$APPS
    if [[ "$a" = *" "* ]]; then
        for i in $a; do
            ! contains "$APPS" "$i" &&
            { msg_err "$i is not a Ziesha tool. ('$APPS')"; return 1; }
            $func "$i"
        done
        return 0
    else
        ! contains "$APPS" "$a" && 
        { msg_err "$a is not a Ziesha tool. ('$APPS')"; return 0; }
    fi
    return 1
}

# Install/update ziesha-helper
install_me () {
    install_deps
    mkdir -p "$HOME/.local/bin" && a2p
    mkdir -p "$ZIESHA_HELPER_PATH" && {
        for f in ziesha-helper.sh ziesha-common.sh ziesha-usage.sh \
                 VERSION AUTHOR; do
            curl -s -o "$ZIESHA_HELPER_PATH/$f" "$ZIESHA_URL/$f"
        done
        curl -s -o "$HOME/.local/bin/ziesha" "$ZIESHA_URL/ziesha"
        chmod +x "$HOME/.local/bin/ziesha"
    }
}

# Install given Ziesha app
install_app () {
    local a=$*
    if [ -z "$a" ]; then
        is_yes "Are you sure to install all Ziesha tools?" &&  a="all" || return 0
    fi
    if [ "$a" = "rust" ]; then
        rust_is_installed && msg_warn "$a is already installed." || install_rust
        echo -e ''
        return
    fi
    if [ "$a" = "me" ]; then
        install_me
        return
    fi
    check_rust_installed
    if ! check_a install_app "$a"; then
        if ! is_installed "$a"; then
            source "$CARGO_ENV"
            if [ -d "$ZIESHA_PATH/$a" ]; then
                msg_warn "$a is exist. Try to update!"
            fi
            mkdir -p "$ZIESHA_PATH" && cd "$ZIESHA_PATH" || return
            msg_warn "Building $a..."; echo -e ''
            git clone "$(printf $GITURL "$a")" >> "$LOG_FILE" 2>&1
            cd "$a" && cargo update >> "$LOG_FILE" 2>&1
            cargo install --path . >> "$LOG_FILE" 2>&1
            cd "$HOME" || return
            msg_info "$a installed to '$ZIESHA_PATH/$a'"
        else
            msg_warn "$a is already installed."
        fi
    fi
    echo -e ''
}

# Check need update
need_update () { [ "$(version local "$1")" != "$(version remote "$1")" ]; }

# Update given Ziesha app or rust
update_app () {
    local vc; local vr;
    local a=${@:-bazuka}
    if [ "$a" = "rust" ]; then
        rustup self update; return
    fi
    if [ "$a" = "me" ]; then
        install_me; return
    fi
    check_rust_installed
    if ! check_a update_app "$a"; then
        if is_installed "$a"; then
            now=$(date)
            if need_update "$a"; then
                cd "$ZIESHA_PATH/$a" || return
                vc="$(version local "$a")"
                vl="$(version remote "$a")"
                msg_warn "Updating $a $vc to $vr"
                git pull origin >> "$LOG_FILE" 2>&1
                source "$CARGO_ENV"
                cargo update >> "$LOG_FILE" 2>&1
                cargo install --path . >> "$LOG_FILE" 2>&1
                cd "$HOME" || return
                msg_info "$a was updated to v$(version local "$a")."
                echo "$now: $a was updated to v$(version local "$a")." >> "$HOME/.ziesha-update.log"
                if service_is_active "$a"; then
                    service "restart" "$a"
                fi
            else
                msg_warn "$a is up-to-date."
                echo "$now: $a is up-to-date." >> "$HOME/.ziesha-update.log"
            fi
        else
            msg_err "$a is NOT installed."
        fi
        echo -e ''
    fi
}

# Remove Ziesha-helper from system
remove_me () {
    msg_warn "This operation will stop running services\n   and remove Ziesha-helper."; echo
    if is_yes "Are you sure to remove Ziesha-helper?"; then
        for s in $(get_running_services); do
            service_is_active "$s" && service disable "$s"
        done
        [ -f "$SYSTEMD_PATH/ziesha@.service" ] && rm "$SYSTEMD_PATH/ziesha@.service"
        for f in ziesha-helper.sh ziesha-common.sh ziesha-usage.sh \
                 VERSION AUTHOR; do
            rm "$ZIESHA_HELPER_PATH/$f"
        done
         [ ! "$(ls -A "$ZIESHA_HELPER_PATH")" ] && rm -rf "$ZIESHA_HELPER_PATH"
        # rm -rf "$ZIESHA_HELPER_PATH"
        rm "$HOME/.local/bin/ziesha"
        msg_info "Ziesha removed from your system! :("; echo
    fi
}

# Remove/unimnstall given Ziesha app or rust
remove_app () {
    local a=${@:-bazuka}
    if [ "$a" = "rust" ]; then
        if is_yes "Are you sure to remove rust?"; then
            rustup self uninstall -y
            msg_info "$a removed from your system :("; echo
            return
        fi
    fi
    if [ "$a" = "me" ]; then
        remove_me; return
    fi
    check_a remove_app "$a"
    if is_installed "$a"; then
        service_is_active "$a" && service disable "$a"
        rm "$(get_bin_loc "$a")"
        rm -rf "${ZIESHA_PATH:?}/$a"
        if [ "$a" = "bazuka" ]; then
            rm -rf "$HOME/.bazuka" >> "$LOG_FILE" 2>&1
            rm "$HOME/.bazuka.yaml" >> "$LOG_FILE" 2>&1
            rm "$HOME/.bazuka-wallet" >> "$LOG_FILE" 2>&1
        fi
        msg_info "$a removed from your system :("
    else
        msg_err "$a is NOT installed."
    fi
    echo -e ''
}

# Show log of selected tool
show_log () {
    local color=true
    local nlines=30
    local short=true
    local timestamp=false
    local a=${1:-bazuka}; shift
    ! contains "$APPS" "$a" && 
    { msg_err "$a is not a Ziesha tool. ('$APPS')"; echo -e ''; exit 1; }

    if ([ "$a" = "auto-update" ] || is_installed "$a"); then
        while [[ $# -gt 0 ]]; do
            case $1 in
                -n|--nlines)
                    shift
                    nlines=$1
                    shift
                ;;
                -c|--no-color)
                    color=false
                    shift
                ;;
                -s|--short)
                    short=false
                    shift
                ;;
                -t|--timestamp)
                    timestamp=true
                    shift
                ;;
                *)
                    _unknown_option "$1"; exit 1 ;;
            esac
        done
        # cmd="journalctl -q -f -o short-iso-precise -n \"$nlines\" _COMM=\"$a\""
        cmd="journalctl -q -f -o short-iso-precise -n \"$nlines\" --user-unit=ziesha@$a"
        # echo "$cmd"
        cmd+=" | stdbuf -oL cut --complement -d' ' -f2,3"
        cmd+=" | sed -u 's/\(:[0-9][0-9]\)\.[0-9]\{6\}/\1/g'"
        cmd+=" | sed -u 's/\+0000//'"
        if [[ "${short}" == "true" ]]; then
             cmd+=" | sed -u -e 's/Height/H/' -e 's/Outdated states/ODs/'"
             cmd+=" -e 's/Timestamp/TS/' -e 's/Active nodes/AcN/'"
             cmd+=" -e 's/Chain Pool/CHp/' -e 's/MPN Pool/MPNp/'"
        fi
        [[ "${color}" == "true" && $(which ccze) ]] && cmd+=" |  ccze -Ar"
        if [[ "${timestamp}" == "true" ]]; then
            cmd+=' | sed -u '\''s/^/echo "/; s/\([0-9]\{10\}\)/$(date +"%Y-%m-%dT%T" -ud @\1)/; s/$/"/'\'' | bash'
        fi
        # echo "$cmd"
        eval "$cmd"
    else
        msg_err "$a is NOT installed."
    fi
    echo -e ''
}

# Set variable in .profile or .bazuka.yaml
set_var () {
    declare -A vars
    tool=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--discord-handle)
                local k=$1; shift
                if [ -z "$1" ]; then
                    msg_err "You have to give a value for $k"
                    exit 1
                fi
                if ! [[ "$1" =~ ^.{3,32}#[0-9]{4}$ ]]; then
                    msg_err "Wrong discord handle 'pentafenolin#9413'"
                    exit 1
                fi
                vars["DISCORD_HANDLE"]="$1"
                tool+=(bazuka)
                shift
            ;;
            -z|--zoro-seed)
                local k=$1; shift
                if [ -z "$1" ]; then
                    msg_err "You have to give a value for $k"
                    exit 1
                fi
                vars["ZORO_SEED"]="$1"
                tool+=(zoro)
                shift
            ;;
            -t|--update-dat)
                local k=$1; shift
                [[ -z "$1" ]] && v="$UPDATE_DAT" || v=$1
                vars["UPDATE_DAT"]="$v"
                tool+=(zoro)
                shift
            ;;
            -p|--deposit-dat)
                local k=$1; shift
                [[ -z "$1" ]] && v="$DEPOSIT_DAT" || v=$1
                vars["DEPOSIT_DAT"]="$v"
                tool+=(zoro)
                shift
            ;;
            -w|--withdraw-dat)
                local k=$1; shift
                [[ -z "$1" ]] && v="$WITHDRAW_DAT" || v=$1
                vars["WITHDRAW_DAT"]="$v"
                tool+=(zoro)
                shift
            ;;
            -c|--share-capacity)
                local k=$1; shift
                [[ -z "$1" ]] && v="$SHARE_CAPACITY" || v=$1
                vars["SHARE_CAPACITY"]="$v"
                tool+=(uzi-pool)
                shift
            ;;
            -e|--share-easiness)
                local k=$1; shift
                [[ -z "$1" ]] && v="$SHARE_EASINESS" || v=$1
                vars["SHARE_EASINESS"]="$v"
                tool+=(uzi-pool)
                shift
            ;;
            -o|--reward-ratio)
                local k=$1; shift
                [[ -z "$1" ]] && v="$REWARD_RATIO" || v=$1
                vars["REWARD_RATIO"]="$v"
                tool+=(uzi-pool)
                shift
            ;;
            -y|--reward-delay)
                [[ -z "$1" ]] && v="$REWARD_DELAY" || v=$1
                vars["REWARD_DELAY"]="$v"
                tool+=(uzi-pool)
                shift
            ;;
            -n|--network)
                local k=$1; shift
                if [ -z "$1" ]; then
                    msg_err "You have to give a value for $k"
                    exit 1
                fi
                vars["NETWORK"]="$1"
                tool+=(bazuka)
                shift
            ;;
            *)
                _unknown_option "$1"
                exit 1
            ;;
        esac
    done
    for k in "${!vars[@]}"; do
        [ "$k" = "NETWORK" ] &&
        sed -i "s/network:.*/network: ${vars[$k]}/g" "$HOME/.bazuka.yaml" ||
        { a2set "$k" "${vars[$k]}"; }
        msg_info "$k is set to ${vars[$k]}"; echo -e ''
    done
    source "$ZIESHA_SETTINGS"
    tool=( "$(printf "%s\n" "${tool[@]}" | sort | uniq)" )
    for t in "${tool[@]}"; do
        msg_warn "$(printf "You must restart %s for the changes to take effect." "$t")"
        echo -e ''
    done
}

# Get variable from .profile
get_var () {
    local k; k=$(toupper "$1" | tr - _)
    if [ "$k" = "NETWORK" ]; then
        v=$(grep "network" "$HOME/.bazuka.yaml")
        v="${v##*: }"
    else
        [ -z ${k+x} ] && v="NOT SET" || v="${!k}"
    fi
    echo "\"$v\""
}

# Set-up initialization parameters for bazuka.
init_bazuka () {
    if is_installed "bazuka"; then
        local rem="$@"
        rem+=" $BOOTSTRAP"
        $(get_bin_loc bazuka) init "$@"
    else
        msg_err "bazuka is NOT installed."; echo -e ''
    fi
}

# Reset bazuka initialization parameters and wallet.
reset_bazuka () {
    case $1 in
        bazuka)
            rm -f "$HOME/.bazuka.yaml"
            msg_info "Bazuka was reset. Run 'bazuka init PARAMS'"
            ;;
        wallet)
            rm -f "$HOME/.bazuka-wallet"
            msg_info "Wallet was reset. Run 'bazuka init PARAMS'"
            ;;
        db)
            rm -rf "$HOME/.bazuka"
            msg_info "Bazuka database was reset.Run 'ziesha restart bazuka'"
            ;;
        all)
            rm -f "$HOME/.bazuka.yaml"
            rm -f "$HOME/.bazuka-wallet"
            rm -rf "$HOME/.bazuka"
            msg_info "Bazuka, wallet and database were reset. " \
                     "Run 'bazuka init PARAMS' and 'ziesha restart bazuka'"
            ;;
        *)
            _unknown_option "$1"
            exit 1
            ;;
    esac
    echo -e ''
}

# Run given Ziesha app
run () {
    local bin
    local installed_apps
    local a=${1:-bazuka}; shift
    # APPS+=" auto-update"
    if [ "$a" != "auto-update" ]; then
        if ! contains "$APPS" "$a"; then
            msg_err "$a is not a Ziesha tool. ('$APPS')"; echo -e ''
            exit 1
        fi
        local rem="$@"
        if ! is_installed "$a"; then
            msg_err "$a is NOT installed. Run 'ziesha install $a'."; echo -e ''
            exit 0
        fi
        # shellcheck source=$HOME/.cargo/env
        source "$CARGO_ENV"
        bin=$(get_bin_loc "$a")
    fi
    case $a in
        "bazuka")
            [[ -z "$DISCORD_HANDLE" ]] && { msg_err "discord-handle " \
            "is not set. Run 'ziesha set discord-handle MYHANDLE'"; exit 0; }
            # $bin node start --discord-handle "$DISCORD_HANDLE"
            { ret="$( { $bin node start --discord-handle "$DISCORD_HANDLE"; } 2>&1 1>&3 3>&- )"; } 3>&1;
            echo "RUST_BACKTRACE: $RUST_BACKTRACE"
            echo "$HOME"
            if echo "$ret" | grep -q "LOCK: Resource temporarily unavailable"; then
                ylw "------------------------------"; echo -e ""
                msg_info "bazuka is already running..."
                echo -e ""
                exit 0
            else
                echo "ERROR:"
                echo "$ret"
            fi
            ;;
        "zoro")
            [[ -z "$ZORO_SEED" ]] && { msg_err "zoro-seed is not set" \
            "Run 'ziesha set zoro-seed MYSEED'"; exit 0; }
            $bin --node 127.0.0.1:8765 --seed "$ZORO_SEED" \
            --update-circuit-params "$UPDATE_DAT" \
            --deposit-circuit-params "$DEPOSIT_DAT" \
            --withdraw-circuit-params "$WITHDRAW_DAT" \
            --db "$DB_PATH" --gpu
            ;;
        "uzi-pool")
            $bin --node 127.0.0.1:8765 --share-capacity $SHARE_CAPACITY \
            --share-easiness $SHARE_EASINESS \
            --owner-reward-ratio $REWARD_RATIO --reward-delay $REWARD_DELAY
            ;;
        "uzi-miner")
            ;;
        "auto-update")
            msg_info "Auto-update is started."; echo
            installed_apps=$(get_installed_tools)
            while true; do  
                update_app "$installed_apps"
                sleep $UPDATE_INTERVAL
            done
            echo "Auto-update is stopped."
            ;;
        -*)
            _unknown_option "$1"
            exit 1
            ;;
        *)
    esac
    echo -e ''
}

# Download zoro dat files
download () {
    local file=
    local a=${1:-all}
    case "$a" in
        update-dat)
            file=$UPDATE_DAT
            url="https://api.rues.info/update.dat" ;;
        deposit-dat)
            file=$DEPOSIT_DAT
            url="https://api.rues.info/deposit.dat" ;;
        withdraw-dat)
            file=$WITHDRAW_DAT
            url="https://api.rues.info/withdraw.dat" ;;
        all)
        download update-dat
        download deposit-dat
        download withdraw-dat
        ;;
        *)
            _unknown_option "$1"; exit 1 ;;
    esac
    mkdir -p "$ZORO_PATH" && cd "$ZORO_PATH" || return
    curl -o "$file" "$url"
}

# Health of running service
# return Good if service is active and running normally
# otherwise return Bad
# Args:
#   $1: Name of service
#   $2: If set to '-q', it will return True/False quietly.
health () {
    local since="10min ago"
    local ret="inactive"
    local a=${1:-bazuka}; shift
    local quiet=$1
    if service_is_active "$a"; then
        local content
        content=$(journalctl -q -o short-iso-precise --since \
                "$since" --user-unit=ziesha@"$a")
        is_in () { echo "$content" | grep -q "$1"; }
        case $a in
            "bazuka")
                ret=$(echo "$content" | grep "Height" | grep "Outdated" | \
                    awk -F ' ' '{print $5}' | sort -n | uniq)
                [ -n "$ret" ] && 
                { [[ $(echo "$ret" | wc -l) -eq 1 ]] && 
                    { echo "$content" | grep -q "Height advanced to" && 
                        ret="Good" || ret="Bad"; } || ret="Good" ;} || ret="Bad"
                ;;
            "zoro")
                is_in "Proving took:" && ret="Good" || ret="Bad" ;;
            "uzi-pool")
                is_in "Share found by:" && ret="Good" || ret="Bad" ;;
            "uzi-miner")
                is_in "Solution found" && ret="Good" || ret="Bad" ;;
            -*)
                _unknown_option "$1" ;;
            *)
        esac
    fi
    [ -z "$quiet" ] && echo "$ret" || [ "$ret" = "Good" ]
}

# Return date part of systemctl status command
get_since () {
    local a=${1:-bazuka}
    local content
    content=$(systemctl --user status ziesha@"$a" | grep "Active:")
    content="${content#*since }"
    echo "${content%%;*}"
}

# Return run-time part of systemctl status command
get_runtime () {
    local a=${1:-bazuka}
    local content
    content=$(systemctl --user status ziesha@"$a" | grep "Active:")
    content="${content##*; }"
    echo "${content%% *}"
}

status () {
    local a=${1:-all}
    if ! check_a status "$a"; then
        ! service_is_active "$a" && { return; }
        local heal; heal=$(health "$a")
        local sign="${CROSS}"; [ "$heal" == "Good" ] && sign="${CHECK}"
        local col="${ER}"; [ "$heal" == "Good" ] && col="${EG}"
        printf "${C}%-9s" "$a"; ylw ": "; echo -e "${col}$heal${sign}${NONE}"
    fi
}

summary () {
    local a=${1:-"all"}; shift
    local time=${1:-"10m"}
    check_a summary "$a" && return
    ! service_is_active "$a" && { return; }

    local heal; heal=$(health "$a")
    local since; since=$(get_since "$a")
    local runtime; runtime=$(get_runtime "$a")
    local sign="\U26D4"; [ "$heal" == "Good" ] && sign="${CHECK}"
    local col="${ER}"; [ "$heal" == "Good" ] && col="${EG}"
    vl=$(version local "$a"); vr=$(version remote "$a")
    cyn "$a v$vl:"
    need_update "$a" && echo -ne " ${EY}(New version v$vr)${NONE}"
    echo
    echo -e "  Status          : ${col}$heal${sign}${NONE}"
    echo -e "  Started at      : ${M}$since${NONE}"
    echo -e "  Running for     : ${EW}$runtime${NONE}"
    sign=" \U203c"; [ "$heal" == "Good" ] && sign=
    col="${R}"; [ "$heal" == "Good" ] && col="${G}"
    local content
    content=$(journalctl -q -o short-iso-precise --since \
            "$time ago" --user-unit=ziesha@"$a")
    nhashes () {
        echo "$content" | grep "Got new puzzle! Approximately" | \
            tail -n 1 | awk -F ' ' '{print $8}'
    }
    nl () { echo "$content" | grep "$1" | wc -l; }
    found () {
        printf "%-18s" "  Found $1s"; echo -n ": "
        printf "${col}%4s${NONE}" "$(nl "${2-$1} found by:")";
        echo -e " (in last ${time})"; 
    }
    case $a in
        "bazuka")
            ret=$(echo "$content" | grep "Height" | grep "Outdated" | \
                tail -n 1 | awk -F ' ' '{print $5}')
            echo -ne "  Current Height  : ${col}$ret${sign}${NONE}"
            echo "$content" | grep -q "Height advanced to" &&
                echo -ne "${col} (Syncing)${NONE}"
            balance=$(bazuka wallet info | grep "Main chain balance:" | \
                      awk -F ' ' '{print $4}')
            echo -e "\n  Balance         : ${col}$balance${NONE}"
            ;;
        "zoro")
            content=$(journalctl -q -o short-iso-precise --since \
                    "$time ago" --user-unit=ziesha@"$a")
            ret=$(echo "$content" | grep "Proving took:" | \
                awk -F ' ' '{print $NF}' | sed 's/ms//g')
            avg=$(echo "$ret" | awk '{ total += $1 } END { print total/NR }' \
                | sed 's/,/\./g')
            echo -e "  Avg. Prov. time : ${col}$avg${NONE} ms"
            ;;
        "uzi-pool")
            found "Share"
            found "Solution"
            ns="$(nl "Share")"
            local sp=$(echo "scale=3 ; $(nhashes) / $SHARE_EASINESS" | bc)
            local hr=$(echo "scale=3 ; $ns * $sp / 600" | bc)
            echo "$hr"
            ;;
        "uzi-miner")
            found "Share" "Solution"
            ;;
        -*)
            _unknown_option "$1"
            exit 1
            ;;
        *)
    esac
}

list () {
    local t; t=$(get_installed_tools)
    for i in $t; do
        vl=$(version local "$i")
        msg_info "$i v$vl"
        service_is_active "$i" && { echo -ne " - "; ylw "Running"; }
        echo;
    done
}

# -------------------------------------------------------------
# MAIN

function _unknown_option () { echo -n "Unknown option "; red "$1"; echo -e ''; }

function show_help () {
    case $1 in
        -h|--help)
            _usage_main ;;
        log)
            _usage_log ;;
        set)
            _usage_set ;;
        get)
            _usage_get ;;
        init)
            _usage_init ;;
        download)
            _usage_download ;;
        run)
            _usage_run ;;
        reset)
            _usage_reset ;;
        start|stop|restart)
            _usage_service "$1" ;;
        status|summary)
            _usage_status "$1" ;;
        list)
            _usage_list ;;
        -*)
            _unknown_option "$1"; exit 1 ;;
        *)
            _usage "$1"
  esac
}

cd "$HOME" || exit 1

OPTS=( "-i|install|install_app"
       "-u|update|update_app"
       "-r|remove|remove_app"
       "-l|log|show_log" 
       "-s|set|set_var" 
       "-g|get|get_var" 
       "|list|list" 
       "|download|download" 
       "|init|init_bazuka" 
       "|run|run"
       "|reset|reset_bazuka" 
       "|start|start" 
       "|stop|stop" 
       "|restart|restart"
       "|status|status"
       "|summary|summary" )


get_func () {
    local ret=
    if [ -n "$1" ]; then
        for opt in "${OPTS[@]}" ; do
            short_opt="${opt%%|*}"; rem="${opt#*|}"
            long_opt="${rem%%|*}"; rem="${rem#*|}"
            func="${rem%%|*}"; rem="${rem#*|}"
            if [ "$1" = "$short_opt" ]; then
                ret="$func"
                break
            elif [ "$1" = "$long_opt" ]; then
                ret="$func"
                break
            fi
        done
    fi
    echo "$ret"
}

get_long_opt () {
    local ret=
    if [ -n "$1" ]; then
        for opt in "${OPTS[@]}" ; do
            short_opt="${opt%%|*}"; rem="${opt#*|}"
            long_opt="${rem%%|*}"; rem="${rem#*|}"
            if [ "$1" = "$short_opt" ]; then
                ret="$long_opt"
                break
            elif [ "$1" = "$long_opt" ]; then
                ret="$long_opt"
                break
            fi
        done
    fi
    echo "$ret"
}

func=
long_opt="--help"
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            _version; exit 0 ;;
        -h|--help)
            [[ -z ${POSITIONAL_ARGS[@]} ]] && { show_help "$long_opt"; exit 0; }
            shift ;;
        *)
            if [ -z "$func" ]; then
                long_opt=$(get_long_opt "$1")
                func=$(get_func "$1")
                if [ -z "$func" ]; then
                    _unknown_option "$1"
                    exit 1
                fi
            else
                POSITIONAL_ARGS+=("$1")
            fi
            shift ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

# if [ "$func" != "list" ]; then
#     [[ -z "${1+x}" ]] && { show_help "$long_opt"; exit 0; }
# fi
# echo "func: $func"
[ -n "$func" ] && { $func "${POSITIONAL_ARGS[@]}"; } ||
    { [[ -z "${1+x}" ]] && { show_help "$long_opt"; exit 0; } }