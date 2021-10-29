#cloud-config

apt:
  sources:
    docker.list:
      source: deb [arch=arm64] https://download.docker.com/linux/ubuntu $RELEASE stable
      keyid: 9DC858229FC7DD38854AE2D88D81803C0EBFCD88

package_update: true
package_upgrade: true

packages:
  - screen
  - rsync
  - git
  - curl
  - docker-ce
  - docker-ce-cli
  - python3-pip
  - python3-dev
  - python3-selinux
  - python3-setuptools
  - python3-venv
  - libffi-dev
  - gcc
  - libssl-dev

groups:
  - docker
system_info:
  default_user:
    groups: [docker]

runcmd:
  - cp /home/ubuntu/daemon.json /etc/docker/daemon.json
  - systemctl restart docker
  - docker run -d --name registry --restart=always -p 4000:5000  -v registry:/var/lib/registry registry:2
  - pip3 install -U pip
  - pip3 install -U wheel
  - 'pip install "kolla>=11,<12"'
  - [ bash, /opt/kolla-build/kolla-build.sh ]
  - echo 'OCI Ampere Kolla Image Builder.' >> /etc/motd