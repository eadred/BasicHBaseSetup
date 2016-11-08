#!/bin/bash
sshpass -p $(cat cluster-ssh-pw) ssh -o StrictHostKeyChecking=no $(cat cluster-ssh-un)@$(cat cluster-name)-ssh.azurehdinsight.net
