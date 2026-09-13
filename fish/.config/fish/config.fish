if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -gx EDITOR nvim
set -gx CHROME_EXECUTABLE /usr/bin/chromium

# Android / Flutter (skip silently when SDK not installed)
set -gx ANDROID_EMULATOR_HOME $HOME/Android/Sdk/emulator
if test -d $HOME/.flutter/flutter/bin
    set -g fish_user_paths $HOME/.flutter/flutter/bin $HOME/.pub-cache/bin
end

alias femu='emulator -avd flutter_emulator -writable-system -no-snapshot'

# Toolchain paths (guarded so missing dirs don't pollute $PATH)
for p in $HOME/Android/Sdk/emulator $HOME/Android/Sdk/platform-tools \
         $HOME/.npm-global/bin $HOME/.flutter/flutter/bin $HOME/.pub-cache/bin \
         $HOME/.cargo/bin $HOME/.local/bin
    if test -d $p; and not contains $p $PATH
        fish_add_path $p
    end
end
