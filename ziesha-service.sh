
# Get running ziesha services
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
    local status=${1:-enable}; shift
    local a="$1"
    [ -z "${a}" ] && 
        { is_yes "Are you sure to $status all Ziesha tools?" &&  a="all" || 
            return 0; }
    if ! contains "$APPS all" "$a"; then
        msg_err "Unknown argument: $a. ('$APPS all')"; echo -e ''
        exit 1
    fi
    if [ "$a" = "all" ]; then
        local services
        services="$(get_installed_tools)"
        if [ "$status" == "start" ]; then
            for s in $services; do service start "$s"; done
        else
            local active_services
            active_services=$(get_running_services)
            [ -z "$active_services" ] && 
                { msg_warn "No active services"; echo; return; }
            for s in $active_services; do service "$status" "$s"; done
        fi
        return
    fi

    # check if arg is a service or not
    if ! contains "$(get_installed_tools)" "$a"; then 
        msg_err "$a is not installed. Please, first install."; echo
        return
    fi

    case $status in
        start)
            service enable "$a"; msg_info "$a is started."; echo
        ;;
        stop)
            service disable "$a"; msg_info "$a is stopped successfully."; echo
        ;;
        restart)
            systemctl --user restart ziesha@"$a"
            msg_info "$a is restarted."; echo
        ;;
        enable)
            # Save Ziesha service file file to systemd path
            [ ! -d "$SYSTEMD_PATH" ] && mkdir -p "$SYSTEMD_PATH"
            if [ ! -f "$SYSTEMD_PATH/ziesha@.service" ]; then
                save_embedded_content service
            fi
            systemctl --user "$status" --now ziesha@"$a" >> "$LOG_FILE" 2>&1
            systemctl --user daemon-reload >> "$LOG_FILE" 2>&1
        ;;
        disable)
            systemctl --user "$status" --now ziesha@"$a" >> "$LOG_FILE" 2>&1
            systemctl --user daemon-reload >> "$LOG_FILE" 2>&1
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
