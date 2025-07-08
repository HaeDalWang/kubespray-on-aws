#!/bin/bash
cd /kubespray
ansible-playbook -i inventory/inventory.yaml cluster.yml --private-key ~/.ssh/kubespray --become --become-user=root -e @inventory/variables.yaml