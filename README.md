# MLOps
*Applying DevOps principles to deploying Large Language Models.*

This project creates a Linux VM on your hypervisor and straps it with Jenkins, ready to run your first pipeline for deploying your *very own* personal, local, offline model.

## Requirements
- Linux (6GB RAM, 8 cores min.)
- An internet connection for strapping VM
- Superuser privileges
- KVM, QEMU and libvirt
- Terraform
- Ansible

## Build
(Optional) Modify the parameters of the VM, compose.yaml, Jenkinsfile or Ansible playbook to your liking.

```shell
$ sudo bash ./prepare_hypervisor.sh
$ git clone https://github.com/xcell96/MLOps && cd MLOps
$ cd terraform && sudo terraform apply
$ cd ../ansible
$ ansible-playbook -i inventory.ini playbook.yml
```

Once Ansible has finished, the last line will contain the local IP address of the LLM VM.

## Usage
1. Using your web browser of choice, open Jenkins with `http://<VM_IP>:8080`
2. Login using default credentials `llm_admin:password` (change these!)
3. Skip the Jenkins setup wizard (Jenkins was already set up by Ansible)
4. Find the pipeline `llm-pipeline`, hit **Build** and wait until it is done.
5. In your web browser, access `http://<VM_IP>:3000` for the web UI
6. Enjoy!
