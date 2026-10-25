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