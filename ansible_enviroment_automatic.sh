#!/bin/bash
echo "Launch first container"
lxc launch ubuntu ansible01

echo "Creating script to configure SSH"
cat >> sshsetup.sh << EOF
#!/bin/bash
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
EOF

echo "Creating script to install ansible"
cat >> ansibleinstall.sh << EOF
#!/bin/bash
apt update
apt install software-properties-common -y
apt-add-repository --yes --update ppa:ansible/ansible
apt install ansible -y
export ANSIBLE_HOST_KEY_CHECKING=False
echo "[test]" >> /etc/ansible/hosts
echo "ansible02" >> /etc/ansible/hosts
echo "[defaults]" >> /root/.ansible.cfg
echo "host_key_checking = False" >> /root/.ansible.cfg

EOF

echo "Copy and Run SSH script"
lxc file push sshsetup.sh ansible01/tmp/
lxc exec ansible01 -- sh /tmp/sshsetup.sh

echo "Snapshot ansible01"
lxc snapshot ansible01 1.0

lxc copy ansible01/1.0 ansible02
lxc start ansible02

echo "Install Ansible on ansible01"
lxc file push ansibleinstall.sh ansible01/tmp/
lxc exec ansible01 -- sh /tmp/ansibleinstall.sh

echo "Clean Up Files"
rm ansibleinstall.sh
rm sshsetup.sh

echo "Install Finished!"
lxc list

echo "Test Ansible using Ping"
lxc exec ansible01 -- ansible test -m ping

echo "Complete!"