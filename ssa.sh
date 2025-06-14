#!/bin/bash

add_bashrc_block(){

    TIME=$1
    BASHRC=~/.bashrc

    if grep -q '#BEGIN SSA' "$BASHRC"; then
        echo "SSA block already exists in $BASHRC."
        return 1    
    fi

    cp ~/.bashrc ~/.bashrc.bkp

    echo "Set 'SSA_CACHE_KEY_TIME' to '$TIME'"

    cat <<EOF >> "$BASHRC"
#BEGIN SSA
export SSA_CACHE_KEY_TIME=${TIME}
alias ssa='source ~/.ssa.sh'
ssa status
# END SSA
EOF

}

add_ssh_key (){

    TIME=${1:-3600}
    KEY=$2
   
    echo
    echo "Adding SSH Key with time '$TIME'..."
    echo

    if [ -z "$KEY" ]; then
        ssh-add -t "$TIME"
    else
        ssh-add -t "$TIME" "$KEY"
    fi
}

download_url () {
    URL="$1"

    RESULT=""
    STATUS=0
    TOOL=""

    if command -v curl > /dev/null 2>&1; then
        RESULT=$(curl -fsSL "$URL")
        STATUS=$?
        TOOL="curl"
    elif command -v wget > /dev/null 2>&1; then
        RESULT=$(wget -qO- "$URL")
        STATUS=$?
        TOOL="wget"
    else
        echo "Error: Neither curl nor wget is installed." >&2
        return 1
    fi

    if [ $STATUS -ne 0 ] || [ -z "$RESULT" ]; then
        echo "Error: Failed to download from '$URL' using '$TOOL'." >&2
        return 2
    fi

    echo "$RESULT"
}

init_ssh_agent(){

    ENVFILE=$1

    echo "No SSH Agent environment found. Starting a new SSH Agent..."

    ssh-agent -s > $ENVFILE
    source $ENVFILE
}

install_ssa() {

    TIME=${1:-3600}
    REF=${2:-refs/heads/stable}

    CONTENT=$(download_url "https://raw.githubusercontent.com/lvf23/ssa/$REF/ssa.sh")

    if [ $? -ne 0 ]; then
        echo "Download failed. Aborting installation." >&2
        exit 1
    fi

    echo "Installing version '$REF'..."
    echo

    if [ -f ~/.ssa.sh ]; then
        echo "File '~/.ssa.sh' already exists. Uninstall via 'ssa uninstall' or remove it manually and try again."
        return 1
    fi

    echo "$CONTENT" > ~/.ssa.sh
    chmod u+x ~/.ssa.sh

    add_bashrc_block "$TIME"

    source ~/.bashrc 2>/dev/null

    echo
    echo "Installation complete. Please restart your terminal session to complete it".

}

remove_bashrc_block() {
    BASHRC=~/.bashrc

    if grep -q '#BEGIN SSA' "$BASHRC"; then
        sed -i.bkp '/#BEGIN SSA/,/# END SSA/d' "$BASHRC"
        echo "SSA block removed from '$BASHRC' (backup saved as .bashrc.bkp')"
    else
        echo "No SSA block found in '$BASHRC'."
    fi
}

start_ssh_agent() {

    TIME=${1:-$SSA_CACHE_KEY_TIME}
    ENVFILE=~/.ssh/ssh-agent-env

    echo "Starting SSH Agent..."
    echo

    if [ -f "$ENVFILE" ]; then

        source "$ENVFILE"

        if ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
            echo "SSH Agent is already running (PID $SSH_AGENT_PID)."
        else
           init_ssh_agent "$ENVFILE"
        fi

    else
        init_ssh_agent "$ENVFILE"   
    fi

    echo

    if ssh-add -l > /dev/null 2>&1; then
        echo "SSH Key already added in agent."
    else
        add_ssh_key "$TIME"
    fi
}

status_ssh_agent() {
    
    echo "Checking status of SSH Agent..."
    echo

    if [ -f ~/.ssh/ssh-agent-env ]; then
        source ~/.ssh/ssh-agent-env
    fi

    if [ -z "$SSH_AGENT_PID" ] || [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH Agent variables are not set."
        return 1
    fi

    if ! ps -p "$SSH_AGENT_PID" > /dev/null 2>&1; then
        echo "SSH Agent process not running (PID $SSH_AGENT_PID)."
        return 1
    fi

    if [ ! -S "$SSH_AUTH_SOCK" ]; then
        echo "SSH Agent socket not found at $SSH_AUTH_SOCK."
        return 1
    fi

    if [ -z "$SSA_CACHE_KEY_TIME" ]; then
        echo "SSA_CACHE_KEY_TIME not found at .bashrc"
        return 1
    fi

    echo "SSH Agent is running."
    echo "PID: $SSH_AGENT_PID"
    echo "Socket: $SSH_AUTH_SOCK"
    echo "SSA Cache Key Time: $SSA_CACHE_KEY_TIME"
    echo 

    if ssh-add -l > /dev/null 2>&1; then
        echo "SSH Key was added in agent."
    else
        echo "SSH Key was not added in agent."
    fi

    return 0
}

stop_ssh_agent() {
    echo "Stopping SSH Agent..."
    echo

    ssh-agent -k

    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK

    [ -f ~/.ssh/ssh-agent-env ] && rm ~/.ssh/ssh-agent-env
}

uninstall_ssa() {
    echo "Uninstalling SSA..."

    stop_ssh_agent
    remove_bashrc_block

    rm -f ~/.ssa.sh

    source ~/.bashrc

    echo
    echo "Uninstall complete. Please restart terminal session to fully complete it."
}

case "$1" in
    install)
        install_ssa $2 $3
        ;;
    uninstall)
        uninstall_ssa
        ;;
    start)
        start_ssh_agent $2
        ;;
    status)
        status_ssh_agent
        ;;  
    stop)
        stop_ssh_agent
        ;;
    *)
        echo "Usage: ssa {start|status|stop|uninstall}"
        ;;
esac