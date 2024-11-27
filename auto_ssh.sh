#!/bin/bash

##Function that checks that ssh-agent is running 
##global variables 
agent_pid=$(ps -C "ssh-agent" -o pid | grep -Eo '[0-9]{1,5}')

agent_exists () {
##return code 0 means it doesn't exist 
##return code 1 means it is already running 
##return code 2 means something went wrong, dont' ask me I won't know

#echo "$agent_pid" #output for debugging purposes

if [ -n "$agent_pid" ];then #agent is running 
echo 1
elif [ -z "$agent_pid" ];then #agent isn't running 
#echo "Agent isn't running"
echo 0
else #something isn't working
echo 3
fi 
}

import_env () {
echo "Importing environement variables to instance"
#TODO want to have that decremented agent pid in this grep search to defeat duplicate files in tmp file

SSH_AUTH_SOCK=$(find /tmp -maxdepth 2 | grep -P "agent(\.)[0-9]{1,6}")
echo "$SSH_AUTH_SOCK" # for debugging purposes
export SSH_AUTH_SOCK;
SSH_AGENT_PID=$agent_pid;
export SSH_AGENT_PID;
echo "$SSH_AGENT_PID" # for debugging purposes
ssh-add ~/.ssh/id_rsa
key_output="$(ssh-add -L)"
if [ -n "$key_output" ];then
echo "Private key attached to current ssh-agent"
else
echo "Private key not attached to ssh-agent, error occurred"
fi 
}

start_agent (){ 
echo "Starting ssh-agent for this instance" 
eval "$(ssh-agent -s)" > /dev/null
#Attach the ssh key
ssh-add ~/.ssh/id_rsa
key_output1="$(ssh-add -L)"
if [ -n "$key_output1" ];then
echo "Private key attached to current ssh-agent"
else
echo "Private key not attached to ssh-agent, error occurred"
fi
}


main (){
echo "ssh_agent script executing"
return_code=$(agent_exists) # returns all the executed echo code 
echo "Return code: $return_code" ## check agent_exists function for code meanings
#new_pid=$((agent_pid-1)) #what we need for the file search
#echo "Decremented: $new_pid"

if [[ $return_code -eq 1 ]];then
echo "ssh-agent already running, importing environment variables"
import_env
#new_pid=$((agent_pid-1)) #need for redundancy on grep search
#echo "Decremented: $new_pid"
elif [[ $return_code -eq 0 ]];then
echo "ssh-agent isn't running, adding ssh-agent to instance"
start_agent
else
echo "Something went wrong, possibly two instances of the ssh-agent"
fi
# TODO need to make sure the /tmp/ssh agent files are dumped something like 
# if (more than 2 bash instances) then do nothing else kill tmp agent and tmp file
}
main

