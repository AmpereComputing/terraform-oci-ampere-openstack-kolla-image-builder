# On demand build infrastructure in OCI using Ampere A1 and Terraform

Keeping up with the pace of sofware development can be difficult.  And In the cloud native world, being able to generate artifacts from build resources on the fly can sometimes accelerate your efforts.  In today's cloud-native world free resources exist like an [Oracle Cloud Infrastructure "Always Free" Account](https://www.oracle.com/cloud/free/#always-free), which provides free on demand Ampere computing resources that enable developers to do exactly this type of work.   Today I'm going to show you how to dynamically build [OpenStack](https://openstack.org) from source and make them easily available for installation via remote hosts.

[OpenStack Kolla](https://opendev.org/openstack/kolla) is a sub project of the larger [OpenStack](https://openstack.org) project.  It provides a way to build all the [OpenStack](https://openstack.org) services as containers.  [OpenStack](https://openstack.org) is a framework to allow you to build a private cloud infrastructure.
Now personally speaking I have work on and with OpenStack throughout my carrer. Deploying OpenStack on Ampere(R) Altra(TM) Arm64 processors is alway fun. I never get tired of seeing all those cores avaiable in a private cloud, virtual machines, and bare-metal instances dancing across the network.  And as always seeing if "it just works" is even more fun.

In a prevous post i've deployed [OpenStack](https://openstack.org) using [kolla](https://opendev.org/openstack/kolla) and [kolla-ansible](https://opendev.org/openstack/kolla-ansible) using on premise technologies.  Today we're going to take part of that idea  and now instead of building our containers locally on an Ampere paltform, we're going to do it on demand in the cloud.

In this post, we will [build upon prevous work](https://github.com/AmpereComputing/OpenStack-on-ampere/blob/main/All-in-One.md) to quickly build [OpenStack Kolla](https://opendev.org/openstack/kolla) from source dynamically using Ampere(R) Altra(TM) Arm64 processors within Oracle Cloud Infrastructure and Ampere A1 shapes.


## Requirements

Obviously to begin you will need a couple things.  Personally I'm a big fan of the the DevOPs tools that support lots of api, and different use cases. [Terraform](https://www.terraform.io/downloads.html) is one of those types of tools.  If you have seen my [prevous session with some members of the Oracle Cloud Infrastracture team](https://youtu.be/3F5EnHRPCI4), I build a terraform module to quickly get you started using Ampere plaforms on OCI.  Today we are going to use that module to launch a [OpenStack Kolla](Instance) virtual machine while passing in some metadata to configure it.

 * [Terraform](https://www.terraform.io/downloads.html) will need be installed on your system. 
 * [Oracle OCI "Always Free" Account](https://www.oracle.com/cloud/free/#always-free) and credentials for API use

## Forking the oci-ampere-a1 terraform module to create something new

The [oci-ampere-a1](https://github.com/amperecomputing/terraform-oci-ampere-a1) terraform module code supplies the minimal ammount of information to quickly have working Ampere A1 instances on OCI ["Always Free"](https://www.oracle.com/cloud/free/#always-free).  It has been forked as [oci-ampree-openstack-kolla-image-builder](https://github.com/amperecomputing/terraform-oci-ampere-openstack-kolla-image-builder) and functionality added to quickly build [OpenStack Kolla](https://opendev.org/openstack/kolla) with a series a parameters.  The built container images are exposted for consumption via a docker registry running on the host and accessable from the external IP address of the virtual machine.  Additionally a docker.json is outputed within the project directory to allow for drop in configuration on the development station to consume the freshly build container images.    To keep things simple from an OCI perspective, the root compartment will be used (compartment id and tenancy id are the same) when launching any instances.  Addtional tasks performed by the [oci-ampree-openstack-kolla-image-builder](https://github.com/amperecomputing/terraform-oci-ampere-openstack-kolla-image-builder) terraform code.

* Operating system image id discovery in the user region.
* Dynamically creating sshkeys to use when logging into the instance.
* Dynamically getting region, availability zone and image id.
* Creating necessary core networking configurations for the tenancy
* Rendering dynamic values into metadata, scripts to pass into the Ampere A1 instance.
* Rendering dynamic values into files to write to the management station running terraform.
* Launch on Ampere A1 instances with metadata and ssh keys.
* After metadata run is complete pass in rendered scripts then execute scripts on remote host.
* Output IP information to connect to the instance.

### Cloneing the repository

To begin we must clone the terraform code repository. You will need to have git installed. Open your terminal and type the following commands to clone the repository:

```
git clone https://github.com/amperecomputing/terraform-oci-ampere-openstack-kolla-image-builder
cd terraform-oci-ampere-openstack-kolla-image-builder
```

### Configuration with terraform.tfvars

Next we will need to configure authentication credentials for Terraform. For the purpose of this we will quickly configure Terraform using a terraform.tfvars in the project directory.  
Please note that Compartment OCID are the same as Tenancy OCID for Root Compartment.
The following is an example of what terraform.tfvars should look like:

```
tenancy_ocid = "ocid1.tenancy.oc1..aaaaaaaabcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopq"
user_ocid = "ocid1.user.oc1..aaaaaaaabcdefghijklmnopqrstuvwxyz0987654321zyxwvustqrponmlkj"
fingerprint = "a1:01:b2:02:c3:03:e4:04:10:11:12:13:14:15:16:17"
private_key_path = "/home/bwayne/.oci/oracleidentitycloudservice_bwayne-08-09-14-59.pem"
```

For more information regarding how to get your OCI credentials please refer to the following reading material:

* [https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm)
* [Where to Get the Tenancy's OCID and User's OCID](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five)
* [API Key Authentication](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#APIKeyAuth)
* [Instance Principal Authorization](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#instancePrincipalAuth)
* [Security Token Authentication](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm#securityTokenAuth)
* [How to Generate an API Signing Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two)

### Running Terraform

Executing terraform is broken into three commands.   The first you must initialize the terraform project with the modules and necessary plugins to support proper execution.   The following command will do that:

```
terraform init
```

Below is output from a 'terraform init' execution within the project directory.

<script id="asciicast-517195" src="https://asciinema.org/a/517195.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

After 'terraform init' is executed it is necessary to run 'plan' to see the tasks, steps and objects. that will be created by interacting with the cloud APIs.
Executing the following from a command line will do so:

```
terraform plan
```

The ouput from a 'terraform plan' execution in the project directy will look similar to the following:

<script id="asciicast-517194" src="https://asciinema.org/a/517194.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

Finally you will execute the 'apply' phase of the terraform exuction sequence.   This will create all the objects, execute all the tasks and display any output that is defined.   Executing the following command from the project directory will automatically execute without requiring any additional interaction:

```
terraform apply -auto-approve
```

The following is an example of output from a 'apply' run of terraform from within the project directory:


<script id="asciicast-517196" src="https://asciinema.org/a/517196.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

### Logging in

Next you'll need to login with the dynamically generated sshkey that will be sitting in your project directory.
To log in take the ip address from the output above and run the following ssh command:

```
ssh -i ./oci-is_rsa opc@155.248.228.151
```

You should be automatically logged in after running the the command.  The following is output from sshing into an instance and then running  'sudo cat /var/log/messages' to verify cloud-init execution and package installation:

<script id="asciicast-517197" src="https://asciinema.org/a/517197.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

### Destroying when done

You now should have a fully running and configured OpenStack Kolla instance.   When finished you will need to execute the 'destroy' command to remove all created objects in a 'leave no trace' manner.  Execute the following from a command to remove all created objects when finished:

```
terraform destroy -auto-approve
```

The following is example output of the 'terraform destroy' when used on this project.

<script id="asciicast-517198" src="https://asciinema.org/a/517198.js" async data-autoplay="true" data-size="small" data-speed="2"></script>

Modifing the cloud-init file and then performing the same workflow will allow you to get interating quickly. At this point you should definately know how to quickly get automating using OpenStack Kolla with Ampere on the Cloud!  
