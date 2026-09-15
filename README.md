# ares-infra

Infrastructure-as-code for my Purple Team Lab.

This repository contains the Ansible configuration used to provision and manage my lab environment.

## Components

- Ansible playbooks and roles
- k3s cluster configuration
- Elastic deployment (ECK)
- Gitea with runners
- Internal DNS, ingress and custom PKI
- Supporting lab infrastructure

## Usage

Deploy the Templates from the [`./packer`](./packer) directory:
```bash
bash scripts/secrets.sh && \
    bash scripts/packer.sh
```

Deploy the infrastructure from the [`./terraform`](./terraform) directory:
```bash
bash scripts/init.sh
```

To provision k3s, services, monitoring configurations and agents, nativate to the [`./ansible`](./ansible) directory and create/activate a venv with required dependencies:
Create and activate the Python environment:
```bash
bash scripts/venv.sh install
```

Now, run a playbook:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/<playbook>.yml
```

Or install it all:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/all.yml
```

## Documentation

https://manfred.gitbook.io/blog/

---
