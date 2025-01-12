#!/bin/bash

addrc(){
    content=$1
    if [ $(cat ~/.bashrc | grep "$content") == "" ]; then
        echo "$content" >> ~/.bashrc
    fi
}

addrc 'alias tn="tmux new -s"' 
addrc 'alias tl="tmux ls"'
addrc 'alias ta="tmux a -t"'
addrc 'alias kx=kubectx'
addrc 'alias kns=kubens'
