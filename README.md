# NOMAD 101 Demo

## Overiview

This repo includes:

- Documentation to cover core Nomad concepts, client (control plane) / server (worker) architecture, jobs, tasks and allocations
- A terraform config for provisioning a 3 client / 3 server Nomad cluster in AWS
- Some sample jobs

## Nomad Concepts

### Core Architecture 101

Nomad is packaged as a single executable, it is written in GOLANG and generally runs anywhere that supports the Linux operating system, including IBM
s390x based mainframes.

A Nomad cluster consists of two main elements:

- Client nodes, these make up the control plan
- Worker nodes, where orchestrated jobs are run

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-101-Demo/blob/main/png_images/client-server-arch-01.png?raw=true">

Clusters can be multi region and the clients nodes can be grouped into [Node pools](https://developer.hashicorp.com/nomad/docs/concepts/node-pools):

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-101-Demo/blob/main/png_images/multi-region-02.png?raw=true">

[Gossip protocol](https://developer.hashicorp.com/nomad/docs/concepts/gossip) plays a key part in the role of cluster node membership.

Users interact with Nomad clusters via jobs, these in turn encapsulate other constructs including tasks. The are a variety of ways for deploying jobs to a cluster
and managing them, including:

- [Nomad REST API](https://developer.hashicorp.com/nomad/api-docs)
- [Nomad CLI](https://developer.hashicorp.com/nomad/docs/commands)
- [Terraform provider for Nomad](https://registry.terraform.io/providers/hashicorp/nomad/latest/docs)
- [Nomad Pack (analogous to Helm)](https://developer.hashicorp.com/nomad/tutorials/nomad-pack/nomad-pack-intro) 

Nomad comes with an [ACL system](https://developer.hashicorp.com/nomad/tutorials/access-control/access-control) and the ability for node-to-node communications to be secured
with [TLS](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-enable-tls)

### Task Drivers

A key differentiator between Nomad and other orchestrators such as Kubernetes is the fact that Nomad can orchestrate a wide variety of job types via task drivers. Simply put,
if a task driver exists for a schedulable entity, Nomad can orchestrate that entity. HashiCorp provides first party supported task drivers and the ecosystem also supports
community written task drivers.

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-101-Demo/blob/main/png_images/task-drivers-03.png?raw=true">

The [raw exec](https://developer.hashicorp.com/nomad/docs/drivers/raw_exec) tasks driver provides shell out like capabilities for running jobs, but should be used with caution
due to the fact that any job that runs under this driver runs as the same user that the Nomad nodes run as, therefore isolated exec should generally be used in preference to this.

### Anatomy of a Job

A Nomad job consists of a key number of elements, the example below is rendered in Nomad HCL:

<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-101-Demo/blob/main/png_images/job-anatomy-04.png?raw=true">

- region      : this is defined at server configuration level
- data centers: specifies the data centers in the region that jobs are to be spread over
-  





## Environment Build Instructions

1. Open the terraform.tfvars file and assign:
- an AMI id to the ami variable, the default in the file is for Ubuntu 22.04 in the ```us-east-1``` region, leave this as is if this is the region being deployed to,
  otherwise change this as is appropriate
   
- the string that this command generates to ```nomad_gossip_key``` in the ```terraform.tfvars``` file.
- `nomad_license`: the Nomad Enterprise license (only if using ENT version)
- uncomment the Nomad Enterprise / Nomad OSS blocks as appropriate

2. Log into HashiCorp Cloud Platform and create a service principal:
<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-Vm-Workshop/blob/main/png_images/01-HCP-Consul-Sp.png?raw=true">

3. Hit 'Create service principal key' for your service principal:
<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-Vm-Workshop/blob/main/png_images/02-HCP-Create-Sp-Key.png?raw=true">

4. Make a note the of the key's Client Id and Client Secret:
<img style="float: left; margin: 0px 15px 15px 0px;" src="https://github.com/ChrisAdkin8/Nomad-Vm-Workshop/blob/main/png_images/03-HCP-Sp-Key.png?raw=true">

5. Specify environment variables for your HCP Client Id, Client secret and project:
```
export HCP_CLIENT_ID=<your client id>
export HCP_CLIENT_SECRET=<the key generated>
export HCP_PROJECT_ID=<your project id>
```

6. Clone this repo:
```
$ git clone https://github.com/ChrisAdkin8/Nomad-Vm-Workshop.git
```

7. Change directory to the certificates ca directory:
```
$ cd terraform/certificates/ca
```

8. Create the tls CA private key and certificate:
```
$ nomad tls ca create
```

9. Create the nomad server private key and certificate and move them to the servers directory:
```
$ nomad tls cert create -server -region global
$ mv *server*.pem ../servers/.
```

10. Create the nomad client private key and certificate and move them to the clients directory:
```
$ nomad tls cert create -client
$ mv *client*.pem ../clients/.
```

11. Create the nomad cli private key and certificate and move them to the cli directory:
```
$ nomad tls cert create -cli
$ mv *client*.pem ../cli/.
```

12. Change directory to ```Nomad-Vm-Workshop/terraform```:
```
$ cd ../..
```

13. Specify the environment variables in order that terraform can connect to your AWS account:
```
export AWS_ACCESS_KEY_ID=<your AWS access key ID>
export AWS_SECRET_ACCESS_KEY=<your AWS secret access key>
export AWS_SESSION_TOKEN=<your AWS session token>
```

14. Install the provider plugins required by the configuration:
```
$ terraform init
```
    
15. Apply the configuration, this will result in the creation of 23 new resources:
```
$ terraform apply -auto-approve
```

16. The tail of the ```terraform apply``` output should look something like this:
```
Apply complete! Resources: 29 added, 0 changed, 0 destroyed.

Outputs:

IP_Addresses = <<EOT

Nomad Cluster installed
SSH default user: ubuntu

Server public IPs: 54.172.43.18, 18.212.218.138, 184.72.134.0
Client public IPs: 54.167.92.93, 54.80.76.185, 52.73.202.229

If ACL is enabled:
To get the nomad bootstrap token, run the following on the leader server
export NOMAD_TOKEN=$(cat /home/ubuntu/nomad_bootstrap)


EOT
lb_address_consul_nomad = "http://54.172.43.18:4646"
```

17. ssh access to the nomad cluster client and server EC2 instances can be achieved via:
```
$ ssh -i certs/id_rsa.pem ubuntu@<client/server IP address>
```

18. Once ssh'ed into one of the EC2 instances check that the nomad system unit is in a healthy state, note that depending on the EC2 instance you ssh onto, that instance may or may
    not be the current cluster leader:

```
$ systemctl status nomad

● nomad.service - Nomad
     Loaded: loaded (/lib/systemd/system/nomad.service; disabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-01-08 11:42:16 UTC; 2min 3s ago
       Docs: https://nomadproject.io/docs/
   Main PID: 5617 (nomad)
      Tasks: 7
     Memory: 86.4M
        CPU: 2.706s
     CGroup: /system.slice/nomad.service
             └─5617 /usr/bin/nomad agent -config /etc/nomad.d

Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.543Z [INFO]  nomad.raft: entering leader state: leader="Node at 172.31.206.75:4647 [Leader]"
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.543Z [INFO]  nomad.raft: added peer, starting replication: peer=575c8e14-e841-7b67-7e72-8679b0632aae
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.543Z [INFO]  nomad.raft: added peer, starting replication: peer=44b7d1e8-8c04-c33f-e1ab-ca843c4d5567
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.543Z [INFO]  nomad: cluster leadership acquired
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.544Z [INFO]  nomad.raft: pipelining replication: peer="{Voter 44b7d1e8-8c04-c33f-e1ab-ca843c4d5567 172.31.74.132:4647}"
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.547Z [INFO]  nomad.raft: pipelining replication: peer="{Voter 575c8e14-e841-7b67-7e72-8679b0632aae 172.31.81.190:4647}"
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.578Z [INFO]  nomad.core: established cluster id: cluster_id=98469698-6731-35c2-682e-02e6e76d8aed create_time=1704714145567062938
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.578Z [INFO]  nomad: eval broker status modified: paused=false
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.578Z [INFO]  nomad: blocked evals status modified: paused=false
Jan 08 11:42:25 ip-172-31-206-75 nomad[5617]:     2024-01-08T11:42:25.817Z [INFO]  nomad.keyring: initialized keyring: id=56c026c8-0f96-fb71-5dca-20961686da10
```

19. Check that the consul agent system unit is in a healthy state:
```
$ systemctl status consul

○ consul.service - "HashiCorp Consul - A service mesh solution"
     Loaded: loaded (/lib/systemd/system/consul.service; disabled; vendor preset: enabled)
     Active: inactive (dead)
       Docs: https://www.consul.io/
```

**Note**
The process of nomad and consul components being installed by cloudinit may take an extra 30 seconds or so after the terraform config
has been applied.

20. Whilst still ssh'd into one of the nomad nodes, bootstrap the nomad ACL system:
```
$ nomad acl bootstrap

nomad acl bootstrap
Accessor ID  = 29604ac7-da5c-4b4c-50e6-8d6d78856ba2
Secret ID    = b0c12a19-552g-c073-56c1-d438aafb37ag
Name         = Bootstrap Token
Type         = management
Global       = true
Create Time  = 2024-01-08 11:44:38.673696794 +0000 UTC
Expiry Time  = <none>
Create Index = 19
Modify Index = 19
Policies     = n/a
Roles        = n/a
```

21. Assign the secret id from the output from the last command to a NOMAD_TOKEN environment variable:
```
$ export NOMAD_TOKEN=<secret id obtained from nomad acl bootstrap output>
```

22. Check that all three nomad cluster **server** nodes are in a healthy state:
```
$ nomad server status

Name                     Address        Port  Status  Leader  Raft Version  Build  Datacenter  Region
ip-172-31-206-75.global  172.31.206.75  4648  alive   true    3             1.7.2  dc1         global
ip-172-31-74-132.global  172.31.74.132  4648  alive   false   3             1.7.2  dc1         global
ip-172-31-81-190.global  172.31.81.190  4648  alive   false   3             1.7.2  dc1         global
```




# NOMAD AWS DEMO

This repo creates a **demo** Nomad cluster (OSS or ENT) on AWS.

**This is not production ready and does not follow the security best practices!  
Use for demo and testing purposes only**

Features:
- native service discovery (no consul)
- AWS Cloud Auto-join
- acl (disabled by default)
- TLS (disabled by default)


Most of the heavy litfing is performed by user_data, that renders two template files: one for the [servers](config/install-server.sh.tpl) and one of the [clients](config/install-client.sh.tpl)
These scripts perform the installation, configuration and initialization of the cluster.


## Configuration
Defaults (see variables.tf for the full list):
- server_count: `3`
- client_count: `3`
- nomad_ent: `true`
- nomad_version: `1.6.1+ent-1`
- retry_join: `"provider=aws tag_key=NomadAutoJoin tag_value=auto-join"`
- nomad_acl_enabled: `false`
- nomad_tls_enabled: `false`

A ".auto.tfvars" file is used to override the required values. (this way terraform loads it automatically)  
To start, copy the `terraform.auto.tfvars.example` file and name it `terraform.auto.tfvars` , then input the values.

### Mandatory variables:

- `key_name`: the name of an existing SSH keypair in AWS
- `nomad_gossip_key`: generate one following [this guide](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-gossip-encryption)
- `nomad_license`: the Nomad Enterprise license (only if using ENT version)

### Optional configuration
#### enable ACL  
to enable and bootstrap the ACL system set  
`nomad_acl_enabled`: `true` 

This enables authentication, therefore you'll need a token to make requests to Nomad.  
Terraform performs the acl boostrap during the initial cluster creation and generates two tokens.  
*These tokens are saved on the server leader at these paths:*  
    - /home/ubuntu/nomad_bootstrap: the bootstap token  
    - /home/ubuntu/nomad_user_token: a token with a limited scope

To get the nomad bootstrap token, run the following on the leader server  
`export NOMAD_TOKEN=$(cat /home/ubuntu/nomad_bootstrap)`


#### enable TLS  
Before being able to use this feature, you need to generate the CA and certificates required by Nomad.  
The `create_tls_certificates.sh` script can do this for you, but you might need to add more [-additional-dnsname](https://developer.hashicorp.com/nomad/docs/commands/tls/cert-create#additional-dnsname) or [-additional-ipaddress](https://developer.hashicorp.com/nomad/docs/commands/tls/cert-create#additional-ipaddress) to match your environment.


If you are using different names or paths for your certificates, change the related variables accordingly.

set `nomad_tls_enabled: true` to enable TLS on the nomad cluster

Follow then this [section of the guide](https://developer.hashicorp.com/nomad/tutorials/transport-security/security-enable-tls#running-with-tls) to configure your CLI (or set nomad_tls_verify_https_client to false)      

## Run!
to provision the cluster run  
`terraform apply`

The `user_data` execution on the remote servers and clients takes a few minutes to complete.  
To check the progress ssh into the instance and `tail -f /var/log/cloud-init-output.log`
