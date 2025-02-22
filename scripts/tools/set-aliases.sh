#!/bin/bash

addrc(){
    content=$1
    if [ "$(cat ~/.bashrc | grep "$content")" == "" ]; then
        echo "$content" >> ~/.bashrc
    fi
}

addrc 'alias k=kubectl' 
addrc 'alias tn="tmux -2 new -s"' 
addrc 'alias tl="tmux ls"'
addrc 'alias ta="tmux a -t"'
addrc 'alias kx=kubectx'
addrc 'alias kns=kubens'
