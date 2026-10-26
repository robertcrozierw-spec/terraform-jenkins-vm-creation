# terraform-jenkins-vm-creation

This is a follow up from [terraform-jenkins-remote-backend](https://github.com/robertcrozierw-spec/terraform-jenkins-remote-backend).

The main purpose here will be to carry on building out infrastructure via terraform Jenkins along with clearing up some underlying issues from the previous build.
Main topics will be:
-   Clearing up interpolation warning.
-   Trigger build through Git commit.
-   Build VM.
-   Add additional .tf files to improve readability and management.

## Prerequisites

The following is required before getting started:
-   A new Jenkins pipeline using the existing main.tf and Jenkinsfile from the [terraform-jenkins-remote-backend](https://github.com/robertcrozierw-spec/terraform-jenkins-remote-backend).

## String Interpolation

The warning I received is actually linking to a page on the [Jenkins site](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#string-interpolation) with more information.
The specific section on [Interpolation of sensitive environment variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#interpolation-of-sensitive-environment-variables), is advising that the current syntax is expanding the contents of "${AZURE_CREDS_CLIENT_ID}" and the other environment variables.
The concern is if the string stored in the environment variable contained any special or command characters, Jenkins will then run this as a command. This has has security implications(SQL injection style attack) or operational(random cmds running breaking the pipeline).

After some troubleshooting and experimenting I found resolving this via a simple syntax change wasn't likely. So instead I took a look at the actual variable naming required for the ARM provider. Initially I was naming my variable below: 
```
environment{
        AZURE_CREDS = credentials('terraform-jenkins-rg-creation')
        .....
```
This meant that credentials module was using the variable name as a suffix then appending the relevant components of the Service Principle to it.

So my solution was actually quite simple, I just needed to change the name of this variable to `ARM`.

I can then drop the renaming of all the variables as they now match the format required for the ARM provider:
```
   environment{
        ARM = credentials('terraform-jenkins-rg-creation')
        ARM_ACCESS_KEY = credentials('terraform-jenkins-remote-backend-key')
        }
```

Running again I can now see no Interpolation warnings!

## Automated build triggering

This will allow me to trigger a Jenkins build each time we push to the Repo.

It needs to configured in 2 places, or 3 if you count the Firewall:
-   Jenkins - Github integration plugin needs to be install, the Pipeline needs to have "GitHub hook trigger for GITScm polling" enabled.
-   Github - Enable webhook and confirm it can connect.
-   Cloud provider - Make sure Firewall protecting the Jenkins server is allowing connections from Github webhooks, when first configured I was receiving an error on the Github side that it could not connect.

The Jenkins Github integration can be found [here](https://plugins.jenkins.io/github-pullrequest/). I made sure it was installed on my Jenkins instance.

We can configure the Github webhook here, make sure to include the /github-webhook/ as part of the URL:
![alt text](../terraform-jenkins-vm-creation/Images/imagegh.png)

Confirm that all the IPs are whitelisted on the Firewall, a list can be found [here](https://api.github.com/meta) under the the "hooks" section.

Once configured on Github and Firewall issues resolved we can see a successful ping:
![alt text](../terraform-jenkins-vm-creation/Images/image.png)

Now whenever I push to the repo and I can see a build starting on the Jenkins Pipeline and that it was triggered by my github account:
![alt text](../terraform-jenkins-vm-creation/Images/imagejp.png)

## Build VM

Looking at the examples from the Terraform site I decided to movie forward with this basic [linux VM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine).

I updated the main.tf and made one small addition, for the ssh access to the VM it needs a public key. 
With this in mind I went ahead and generated a keypair manually on the Jenkins server using `ssh-keygen -t rsa -b 4096 -C "adminuser"` and copied the public key to the below location:
```
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/opt/tf-keys/adminuser.pub")
  }
```
Once completed it runs successfully, creating the VM as per the resource definitions in the main.tf.

To remove the resources I can just delete them from the main.tf or in this case I just commented them out. Now simply committing the changes Terraform will destroy the resources. 

## Additional Terraform files

A Terraform deployment or configuration will typically contain multiple files. So far I have only been using one. This is fine for demo and small projects, however as we are now building VMs and the support components it is better to start adding some support files.


### provider.tf

This is were all the provider information will go, it's useful to have in a separate file as it makes collaboration easier. We now have a single file that can determine the Terraform version, provider version and Statefile location. This file can be shared to other developers.

I created the [provider.tf](../terraform-jenkins-vm-creation/provider.tf) and moved the contents from main.tf.

### variables.tf and .tfvars 

Allows me to define variables within the code. 
[variables.tf](../terraform-jenkins-vm-creation/variables.tf) is the initial declaration of the variables, and it will provide a default value if I do not provide one.
The .tfvars file and in my case the where I can define the value of these variables, typically this is were actual changes are made to the existing Terraform code.
Using .tfvars allows us to configure separate environments for each stage, for example we can have dev.tfvars, staging.tfvars and prod.tfvars. In muy case for now I created one the [dev.auto.tfvars](../terraform-jenkins-vm-creation/dev.auto.tfvars)

To confirm this is working I initially just did it with a resource group:
```
//This time we defined the name in the variables.tf
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "eastus2"

  tags = {
    owner = "JenkinsPipeline"
  }
```
Before applying this to the VM I changed the naming slightly, the variable definition is now "environment" and inside `dev.auto.tfvars` it is set to "dev".
I then appended this name to each of the components, after push to my repo I can now see that the components have been created using this new naming convention as defined in the variables files:
![alt text](../terraform-jenkins-vm-creation/Images/imagecomps.png)

### outputs.tf

In some cases it is necessary for us to output information on the deployed resources.
A good example might the public IP if I had created one.
For this [example](../terraform-jenkins-vm-creation/output.tf) I have outputted the resource ID of the resource group containing all of the VM components:
```
output "resource_group_azure_id" {
  description = "The fully qualified Azure Resource ID of the resource group."
  value       = azurerm_resource_group.vm_rg.id
}
```
Although this is a trivial example it does show how its possible to output certain values, these values can then be referenced by terraform itself in other parts of the deployment. This will be used in later projects.

## Conclusion

I would have preferred to resolve the interpolation warning using the correct syntax however im not sure that was possible, one other solution would be to build a helper function that. I can then call this helper function each time I need the credentials. This would be of some benefit as it would allow greater flexibility in naming the variables.

One detail regarding the Github triggering, currently it´s trigger for every push, including changes to the README.md. This is acceptable for this project however I think moving forward it would be better to filter it to just changes made to the Terraform files or Jenkinsfile.
Regarding the additional Terraform files this will be implemented in all future projects, as it is a much cleaner approach and adds much more flexibility to deployments.


