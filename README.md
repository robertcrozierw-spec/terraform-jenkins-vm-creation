# terraform-jenkins-vm-creation

This is a follow up from [terraform-jenkins-remote-backend](https://github.com/robertcrozierw-spec/terraform-jenkins-remote-backend).

The main purpose here will be to carry on building out infrastructure via terraform and Jenkins and clearing up some underlying issues from the previous build.
Main topics will be:
-   Clearing up interpolation warning.
-   Trigger build through Git commit.
-   Build VM in existing resource group.
-   Add additional .tf files to improve readability and management.

## Prerequisites

The following is required before getting started:
-   A new Jenkins pipeline using the existing main.tf and Jenkinsfile from the [terraform-jenkins-remote-backend](https://github.com/robertcrozierw-spec/terraform-jenkins-remote-backend).

## String Interpolation

The warning I received is actually linking to a page on the [Jenkins site](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#string-interpolation) with more information.
The specific section on [Interpolation of sensitive environment variables](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#interpolation-of-sensitive-environment-variables), is advising that the current syntax is expanding the contents of "${AZURE_CREDS_CLIENT_ID}" and the other environment variables.
The concern here is that it if the string stored in the environment variable contained any special or command characters, Jenkins will then run this as a command. This has has security implications(SQL injection style attack) or operational(random cmds running breaking the pipeline).

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

This will allow trigger a Jenkins build each time we push to the Repo. It is configured via a webhook on the Github side.

It needs to configured in 2 places, or 3 if you count the Firewall
-   Jenkins - Github integration plugin needs to be install, the Pipeline needs to have "GitHub hook trigger for GITScm polling" enabled.
-   Github - Enable webhook and confirm it can connect.
-   Cloud provider - Make sure Firewall protecting the Jenkins server is allowing connections from Github webhooks, when first configured I was receiving an error on the Github side that it could not connect.

We can configure the github webhook here, make sure to include the /github-webhook/ as part of the URL:
![alt text](../terraform-jenkins-vm-creation/Images/imagegh.png)

Once configured on Github and Firewall issues resolved we can see a successful ping:
![alt text](../terraform-jenkins-vm-creation/Images/image.png)



## Conclusion

I would have preferred to resolve the interpolation warning using the correct syntax however im not sure that was possible, one other solution would be to build a helper function that I could then call in each step that I need the credentials. This would be of some benefit as it would allow greater flexibility in naming the variables. However for now I think the solution works quite well.

