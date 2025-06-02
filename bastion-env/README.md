# Déployer OpenShift

Note: Configuration à type d'exemple.

Tenant cirrus-dev
<br>
DC: qbc1
<br>
vcd: vdc-0046
<br>
domaine: dev0046.cirrus.local
<br>
Gateway external network ip: 63.135.171.152
<br>
Gateway external network name: ISP-63.135.171.0

## Prérequis

* Dans Keeper, cloner une entré "vcd API" de l'usager api-platform. Mettre à jour selon le nouveau cluster et important de générer un nouveau mot de passe.
* Dans le nouveau Tenant/Org vCloud:
  * Créer une librairie PaaS.
  * Y placer le dernier, ou la version actuellement stampé pour Cirrus, [template RHCOS ova](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/). 
    * Nommer rhcos-\<_version_\>. Exemple: rhcos-4.10.16.
  * Y placer le dernier template helper, le nommer helper (à reconsidérer).

### Initialisation

Il faut ici loader un fichier de configuration. Si vous n'en avez pas pour le déploiement désiré rérérez vous au template dans le repos `openshift_inspq_poc-qbc1-vdc-9001-Linux.config.template`.
* Format: <nom vcd org/tenant>-\<[DC](https://team-1606402103067.atlassian.net/wiki/spaces/PC/pages/255655945/Infrastructure#Environnements)\>-\<nom du vdc\>.config
  * Même format que le `.tfvars` associé. 

```
cd terraform

source ./cirrusdev-qbc1-vdc-0046.config

terraform init
```

Si vous obtenez l'erreur "Error: Backend configuration changed". À moins de savoir ce que vous faite, vous pouvez vous contentez de faire `rm -rf .terraform.lock.hcl .terraform`

### Exécuter terraform

Note: Le source utilisé lors du init est essentiel pour le plan et apply.

```
cd terraform

source ./cirrusdev-qbc1-vdc-0046.config

terraform fmt ; terraform validate && terraform plan

terraform apply
```
Note: les terraform fmt et validate ne sont pas essentiel.

### Ansible

Ansible sur le helper node configure le DNS, PXE, DHCP, HAProxy et Apache.

#### Configuration

Dans le répertoire ansible/inventory, il y a un fichier inventory par helper différent. En le spécifiant comme paramètre `-i inventory/inventory-<tenant>-<dc><vdc>`, c'est ce qui fait en sorte que ansible ce connectera sur le bon helper. Je suis certain qu'il y aurais une meilleure façon de faire cela, donc à revoir.

Il faut également créer un fichier ansible/host_vars/\<helper ip\>.yaml où il y a une configuration spécifique pour l'installation. Créer et l'ajuster selon les besoins.

#### NFS
* Ansible
```
cd ansible
(cd ..; docker run --rm -it -v $(pwd)/ansible:/opt/ansible ansible:latest -i inventory/cirrrus-mlventes-qbc1-vdc-cirrus-mlventes-Linux nfs.yml --tags nfs )
```
* Sur le serveur NFS.
```
sudo -i
parted /dev/sdb mklabel gpt
parted -a opt /dev/sdb mkpart primary xfs 0% 100%
mkfs.xfs /dev/sdb1
mkfs.xfs -f -L datapart /dev/sdb1
echo "LABEL=datapart  /data   xfs     defaults        0 2" >> /etc/fstab
systemctl daemon-reload
mount /data
echo "/data *(rw,sync,no_root_squash,no_subtree_check,insecure)" >> /etc/exports

systemctl enable nfs-server
systemctl start nfs-server
systemctl status nfs-server
firewall-cmd --permanent --list-all | grep services
firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --list-all | grep services
firewall-cmd --reload

showmount -e
```

* Validation du volume exporté à partir d'une node externe.

```
cirrus-mlventes <user>@ns-1 ~]$ showmount -e 172.16.1.200
Export list for 172.16.1.200:
/data *
```

#### Build de l'image Ansible

```
docker build -t ansible:2.9.27_rockylinux_python39-2 .
```

* À partir de votre laptop ou d'un pipeline. L'authentification ce fait via une clé ssh.
```
$ pwd                                                                                                                                                                  
Git/projet_cirrus/PaaS/ocp-deploy/ansible
$ cd ..

$ docker run --rm -it -v $(pwd)/ansible:/opt/ansible ansible:2.9.27 -e @vars.yaml -i inventory/inventory-openshift_inspq_poc-qbc1-vdc-9001-Linux tasks/main.yml
```

Ceci déploit l'infra. Pour le cluster lui même voir le repos associé.