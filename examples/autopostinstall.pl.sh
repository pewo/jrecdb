#!/bin/sh

echo "Starting $0"
echo "Env"
env | grep ^JRECDB
echo "Args: $*"

for playbook in postinstall.yml site.yml prodinstall.yml; do
	ANSIBLE_PLAYBOOK="ansible-playbook $playbook ";

	if [ ! -z ${JRECDB_INVENTORY} ]; then
		ANSIBLE_PLAYBOOK="$ANSIBLE_PLAYBOOK -i $JRECDB_INVENTORY"
	fi

	if [ ! -z ${JRECDB_CLIENT} ]; then
		ANSIBLE_PLAYBOOK="$ANSIBLE_PLAYBOOK -l $JRECDB_CLIENT"
	fi
	echo "Ansible run: $ANSIBLE_PLAYBOOK"
done

echo "Done $0"
