#!/usr/bin/env bash
# shellcheck disable=1090,1091,2015,2034,2059
#
# Common functions to use in other installation scripts.
#
#

# PATHS
PROFILE=$HOME/.profile

# COLOR CODES
# -------------------------------------------------------------
NONE="\033[0m"    # unsets color to term's fg color

# regular colors
K="\033[0;30m"    # black
R="\033[0;31m"    # red
G="\033[0;32m"    # green
Y="\033[0;33m"    # yellow
B="\033[0;34m"    # blue
M="\033[0;35m"    # magenta
C="\033[0;49;96m" # cyan
W="\033[0;37m"    # white

# emphasized (bolded) colors
EK="\033[1;30m"
ER="\033[1;31m"
EG="\033[1;32m"
EY="\033[1;33m"
EB="\033[1;34m"
EM="\033[1;35m"
EC="\033[1;49;96m"
EW="\033[1;37m"

# background colors
BGK="\033[40m"
BGR="\033[41m"
BGG="\033[42m"
BGY="\033[43m"
BGB="\033[44m"
BGM="\033[45m"
BGC="\033[46m"
BGW="\033[47m"

# UNICODE CODES
# -------------------------------------------------------------
CHECK='\U02714'; WARN='\U026A1'; CROSS='\U274c'; NOTE='\U1F4D3'
PACK='\U1F4E6'
# -------------------------------------------------------------
# FUNCTIONS:
col () { echo -ne $1; shift; echo -ne "$@"; echo -ne ${NONE}; }
red () { col $R "$@"; }
grn () { col $G "$@"; }
ylw () { col $Y "$@"; }
blu () { col $B "$@"; }
mgt () { col $M "$@"; }
cyn () { col $C "$@"; }
wht () { col $W "$@"; }

msg_info () { grn "$CHECK $@"; }
msg_warn () { ylw "$WARN $@"; }
msg_err  () { red "$CROSS ${@}"; }
msg_note () { wht "$NOTE $@"; }

rep ()   { eval "printf -- '${1:-'-'}%.0s' {1.."${2:-65}"}"; }
line ()  { col ${2:-$M} $(rep ${1:-'-'}); }
line1 () { line; }
line2 () { line '=' ${1:-$M}; }

# Check if $1 contains $2
contains () { [[ $1 =~ (^|[[:space:]])"$2"($|[[:space:]]) ]]; }

# Return file path if exist
get_file_if_exist () { [ -f "$1" ] && echo "$1"; }

# Return public IP address
get_ip () { echo $(curl -s -4 ifconfig.co); }

# If set up, return IP6 address from inet6
get_ip6 () { ip addr | grep inet6 | grep "scope global" | awk '{$1=$1};1' | \
             awk '{print $2}' | awk -F'/' '{print $1}'; }

# Return OS name
get_os () {
    local un=$(uname | awk '{print tolower($0)}')
    [ "$un" = "darwin" ] && echo 'macos' || echo $un
}

# Return architecture name
get_arch () {
    local arc=$(arch)
    [ "$arc" = "aarch64" ] && echo 'arm64' || \
    ([ "$arc" = "x86_64" ] && echo 'amd64' || echo $arc)
}

# Return joined OS and architecture names
get_os_arch () {
    local un=$(get_os)
    local arc=$(get_arch)
    [[ $un == 'linux' && $arc == 'amd64' ]] && echo $un || echo $un'_'$arc
}

# A modified lsb_release wrapper.
lsb_releasef () {
    echo "$(lsb_release "$1" | \
            awk 'BEGIN{FS=":"} {print $2}' | \
            awk '{$1=$1};1')"
}

# Return name of linux distribution
get_linux_dist () {
    [ "$(get_os)" = "linux" ] && echo "$(lsb_releasef -i)" || echo "$(get_os)"
}

# Return version if dist is Ubuntu
get_ubuntu_ver () {
    [ "$(get_linux_dist)" = "Ubuntu" ] && echo "$(lsb_releasef -r)"
}

# String to lowercase
tolower () { echo "$1" | awk '{print tolower($0)}'; }

# String to uppercase
toupper () { echo "$1" | awk '{print toupper($0)}'; }

# Add a text to a specified file
a2f () {
    local exp=$1; local f=$2
    local exist; exist=$(grep "$exp" "$f")
    [ -z "$exist" ] && echo -e "$exp" >> "$f"
    source "$f"
}

# Remove text from specified file
rff () {
    grep -q "^$1*" "$2" && 
    grep -v "^$1*" "$2" > "$2.tmp" && 
    mv "$2.tmp" "$2"
}

# Add a text to bash profile file if it does not exist
# Default text is $HOME/.local/bin
a2p () { a2f ${1:-'PATH="$HOME/.local/bin:$PATH"'} "$PROFILE"; }

# Remove variable from bash profile file
rfp () { rff "export $1" "$PROFILE"; }

# Get a password from $USER
get_pass () {
    local pass=
    local prompt=${1:-"Enter a password: "}
    stty -echo
    while [ -z "${pass}" ]; do
        echo -e ""
        read -p "$prompt" pass
    done
    stty echo
    echo "$pass"
}

# Ask yes/no question.
# Args:
#    $1: Question prompt
is_yes () {
    prompt=${1:-""}
    default=${2:-"n"}
    prompt+=$([ "$default" == "y" ] && echo " ([y]/n) " || echo " (y/[n]) ")
    while true; do
        read -p "$prompt" yn
        yn=${yn:-n}
        case $yn in 
            [yY] ) break;;
            [nN] ) break;;
            * ) echo [y]es or [n]o?;
        esac
    done
    [ "$yn" = "y" ]
}

# Check a package is already installed or not
# Args:
#   $1: Name of package
is_pkg_exist () {
    local dist=$(get_linux_dist)
    if [ $dist == "Ubuntu" ]; then
      [ -z "$(dpkg -l | grep $1)" ]
    elif [ $dist == "macos" ]; then
        if [ -f "$(which port)" ]; then
            ret=$(port installed $1)
            [ "$ret" != "None of the specified ports are installed." ]
        fi
    fi
}

# Check package(s) need to install
#   $1: Name of packages to install
to_install () {
    local to_install=
    for p in $1
    do
        if is_pkg_exist $p; then
            to_install+=" $p"
        fi

    done
    echo $to_install
}

# Multiple Install function
# Currently only supports Ubuntu/debian and Macports
#
# Args:
#    $1: Name of packages to install
install_pkg () {
    local dist=$(get_linux_dist)
    if [ $dist == "Ubuntu" ]; then
        sudo apt update > /dev/null 2>&1
        sudo apt install "$1" -y > /dev/null 2>&1
    elif [ $dist == "macos" ]; then
        if [ -f "$(which port)" ]; then
            sudo port install "$1" > /dev/null 2>&1
        fi
    else
        col $BGR "Installing dependencies on $dist is not supported."
        col $BGR "You need to make sure install dependencies manually."
    fi
}

# Install given packages if not installed
# Currently only supports Ubuntu and Macports
#
# Args:
#   $1: Name of packages to install
#   $2: Installing Message Text
#       Default: "Installing dependencies"
#   $3: End of Installing Message Text
#       Default: "Dependencies installed"
install () {
    local to_install=$(to_install "$1")
    local header="${2:-"Installing dependencies"}"
    local footer="${3:-"Dependencies installed"}"
    local installed=false
    if test -n "$to_install"; then
        installed=true
        ylw "$header"; echo -e ''
        install_pkg "$to_install"
    fi
    [ "$installed" = true ] && ylw "$footer"
}

# Install given packages if not installed.
# Currently only supports Ubuntu and Macports.
# Created for pre-dependencies.
#
# Args:
#   $1: Name of packages to install
install_pre_deps () {
    install "$1" \
            "Installing pre-dependencies to run the script..." \
            "Pre-dependencies installed"
}

# Save embedded content in script files
# Args:
#    $1: Starting pattern of variables
save_embedded_content () {
    pattern=${1:-script}
    echo -e ${YLW}'Generating '$pattern's...'${NC}
    vars="$(set | grep "^"$pattern"\_" | grep -v '_file' | 
        awk -F= '{print $1}' | uniq)"
    pat="^# Path:"
    for v in $vars
    do
        content=$(eval echo \"\${$v}\")
        file_path=$(echo "$content" | grep "$pat" | awk '{print $3}')
        dir_path="$(dirname "${file_path}")"
        mkdir -p "$dir_path"
        content=$(echo "$content" | grep -v "$pat")
        sd=
        if [[ $file_path != $HOME* ]]; then
            sd="sudo"
        fi
        if test -n "$file_path"; then
            eval 'echo "$content" | '$sd' tee $file_path > /dev/null'
            if [[ "$content" == "#!"* ]]; then
                eval $sd' chmod +x "$file_path"'
            fi
            echo -e ${YLW}' '${CHK}' '$file_path${NC}
        fi
    done
}

get_emb_cont_var_names () {
    pattern=${1:-script}
    vars="$(set | grep "^"$pattern"\_" | grep -v '_file' | 
        awk -F= '{print $1}' | uniq)"
    echo "$vars"
}

get_emb_cont_file_paths () {
    pattern=${1:-script}
    vars="$(get_emb_cont_var_names "$pattern")"
    pat="^# Path:"
    paths=
    for v in $vars
    do
        content=$(eval echo \"\${$v}\")
        paths+=$(echo "$content" | grep "$pat" | awk '{print $3}')" "
    done
    echo $paths
}
