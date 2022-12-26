# shellcheck disable=1090,1091,2015,2034,2059,2155
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
                [ -n "$ret" ] &&  { [[ $(echo "$ret" | wc -l) -eq 1 ]] && 
                    { echo "$content" | grep -q "Height advanced to" && 
                        ret="Good" || ret="Moderate"; } || ret="Good" ;} || 
                            ret="Bad"
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
    content=$(systemctl --user --timestamp=utc status ziesha@"$a" | grep "Active:")
    content="${content#*since }"
    echo "${content%%;*}"
}

# Return run-time part of systemctl status command
get_runtime () {
    local a=${1:-bazuka}
    local content
    content=$(systemctl --user status ziesha@"$a" | grep "Active:")
    content="${content##*; }"
    echo "${content:0:$#-4}"
}

# crawle currnet height from log content
# $1 : log content
get_current_height () {
    h1=$(echo "$content" | grep "Outdated states" | \
         tail -n 1 | awk -F ' ' '{print $5}')
    h2=$(echo "$content" | grep "Height advanced to" | \
         tail -n 1 | awk -F ' ' '{print $7}')
    [ -n "$h2" ] && { [ -z "$h1" ] && h1="${h2::-1}" ||
        { h2="${h2::-1}"; [ "$h1" -lt "$h2" ] && h1="$h2"; }; }
      echo "$h1"
}

# crawle currnet height from log content
# $1 : log content
get_active_nodes () {
    echo "$content" | grep "Outdated states" | \
        tail -n 1 | awk -F ' ' '{print $13}'
}

status () {
    local a=${1:-all}
    if ! check_a status "$a"; then
        ! service_is_active "$a" && { return; }
        local heal; heal=$(health "$a")
        local col="${ER}"
        local sign="${CROSS}"
        case "$heal" in
            "Good")
                col="${EG}"
                sign="${CHECK}"
            ;;
            "Moderate")
                col="${EY}"
                sign="\U23F3"
            ;;
            *)
        esac
        printf "${C}%-9s" "$a"; ylw ": "; echo -e "${col}$heal${sign}${NONE}"
    fi
}

summary () {
    local a=${*:-"all"}
    local time="10m"
    check_a summary "$a" && return
    ! service_is_active "$a" && { return; }

    local heal; heal=$(health "$a")
    local since; since=$(get_since "$a")
    local runtime; runtime=$(get_runtime "$a")
    local col="${ER}"
    local sign="\U26D4"
    local col="${ER}"

    case "$heal" in
        "Good")
            col="${EG}"
            sign="${CHECK}"
        ;;
        "Moderate")
            col="${EY}"
            sign="\U23F3"
        ;;
        *)
    esac

    vl=$(version local "$a"); vr=$(version remote "$a")
    cyn "$a v$vl:"
    need_update "$a" && echo -ne " ${EY}(New version v$vr)${NONE}"
    echo
    echo -e "  Status          : ${col}$heal${sign}${NONE}"
    echo -e "  Started at      : ${M}$since${NONE}"
    echo -e "  Running for     : ${EW}$runtime${NONE}"
    if [ "$heal" == "Good" ]; then
        sign=
        col="${G}"
    else
        sign=" \U203c"
    fi
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
        printf "${col}%s${NONE}" "$(nl "${2-$1} found")";
        echo -e " (in last ${time})"; 
    }
    case $a in
        "bazuka")
            height="$(get_current_height)"
            echo -ne "  Current Height  : ${col}$height${sign}${NONE}"
            echo "$content" | grep -q "Height advanced to" &&
                echo -ne "${Y} (Syncing)${NONE}"
            echo -ne "\n  Active Nodes    : ${col}$(get_active_nodes)${NONE}"
            balance=$(bazuka wallet info | grep "Ziesha:" | \
                      awk -F ' ' '{print $3}')
            [ -z "$balance" ] && balance="0.0\U2124"
            echo -e "\n  Balance         : ${col}$balance${NONE}"
            ;;
        "zoro")
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
            nh="$(nhashes)"
            if [ -n "$nh" ]; then
                local sp=$(echo "scale=3 ; $(nhashes) / $SHARE_EASINESS" | bc)
                local hr=$(echo "scale=3 ; $ns * $sp / (600 * 1000)" | bc)
                echo -e "  Hashrate        : ${col}$hr${NONE} KH/s"
            fi
            ;;
        "uzi-miner")
            ns="$(nl "Solution")"
            nh="$(nhashes)"
            echo -e "  Threads         : ${col}$NTHREADS${NONE}"
            echo -e "  Pool IP         : ${Y}$POOL_IP${NONE}"
            found "Share" "Solution"
            if [ -n "$SHARE_EASINESS" ] && [ -n "$nh" ]; then
                local sp=$(echo "scale=3 ; $(nhashes) / $SHARE_EASINESS" | bc)
                local hr=$(echo "scale=3 ; $ns * $sp / (600)" | bc | \
                        awk '{printf "%01.3f" ,$1}')
                echo -e "  Hashrate        : ${col}$hr${NONE} H/s"
            fi
            ;;
        -*)
            _unknown_option "$1"
            exit 1
            ;;
        *)
    esac
}
