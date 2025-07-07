#!/bin/bash

ansible-playbook -i inventory.yaml ../cluster.yml --private-key /root/.ssh/seungdobae.pem --become --become-user=root -e inventory/variables.yaml