#!/bin/bash

ansible-playbook -i inventory.yaml ../cluster.yml --private-key /root/.ssh/kubespray --become --become-user=root -e inventory/variables.yaml