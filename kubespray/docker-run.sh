docker run \
--name=kubespray \
--network=host \
--detach \
--restart=always \
--mount type=bind,source="$(pwd)/inventory",dst=/kubespray/inventory \
--mount type=bind,source=$HOME/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
--env ANSIBLE_HOST_KEY_CHECKING=False \
quay.io/kubespray/kubespray:v2.28.0 sleep infinity