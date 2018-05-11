# Setup a color prompt for Environment.
# copy this file to /etc/profile.d/env_prompt.sh
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GRAY="\[\e[1;37m\]"
GREEN="\[\e[1;32m\]"
if [ "$ConfEnv" = prod ]; then
	PS1="[$RED$ConfEnv$NORMAL]$RED\h$NORMAL[$RED\w$NORMAL]\$ "
elif [ "$ConfEnv" = gray ]; then
	PS1="[$GRAY$ConfEnv$NORMAL]$GRAY\h$NORMAL[$GRAY\w$NORMAL]\$ "
elif [ "$ConfEnv" = dev ]; then 
	PS1="[$GREEN$ConfEnv$NORMAL]$GREEN\h$NORMAL[$GREEN\w$NORMAL]\$ "
else
	PS1="\h[\w]\$ "
fi