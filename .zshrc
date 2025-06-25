
# Flutter SDK
export PATH="$PATH:/Users/himkerjain/Development/flutter/bin"
export PATH="$PATH:$HOME/Downloads/development/flutter/bin"
export PUB_CACHE="$HOME/.pub-cache"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"

export PATH="$PATH:$HOME/Downloads/development/flutter/bin"
export PUB_CACHE="${HOME}/.pub-cache"
export PATH="$PATH:/Users/himkerjain/Library/Android/sdk/cmdline-tools/latest/bin"
export PATH="$PATH:/Users/himkerjain/Documents/Flutter/flutter/bin"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

