docker run \
--name=kubespray \
--network=host \
--detach \
--restart=always \
--mount type=bind,source="$(pwd)/kubespray-on-aws/kubespray/inventory",dst=/kubespray/inventory \
--mount type=bind,source="$(pwd)/kubespray-on-aws/kubespray/extra_playbooks",dst=/kubespray/extra_playbooks \
--mount type=bind,source="$(pwd)/kubespray-on-aws/kubespray/artifacts",dst=/kubespray/artifacts \
--mount type=bind,source=/root/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
--env ANSIBLE_HOST_KEY_CHECKING=False \
quay.io/kubespray/kubespray:v2.28.0 sleep infinity