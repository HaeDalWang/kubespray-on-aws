#!/bin/bash

ansible-playbook -i inventory.yaml --private-key /root/.ssh/id_rsa cluster.yaml
