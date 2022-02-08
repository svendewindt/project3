# Goal

With the Windows part we want to provide a way to access the Linux environment of the project and get some general back office services running. These services are Mail, Storage, User management, ...

To access the Linux environment we will use a remote desktop environment. The components of an RDS evironment are typically

- RD host(s)
- RD broker (session reconnect & load balancing)
- RD license server
- RD web application server
- RD gateway

### Challenges when deploying a scenario like this

- Monitoring of infrastructure
  - Updates
  - Performance
  - Changes
  - Dependencies
- Network access protection (NAC) / Network access control (NAC)
- Internet connectivity
  - Multi homed networks
    - Inbound DNS
- Provision access
  - Security
- Redundancy
- Integrate with "Bring Your Own Device" (BYOD)

You can see the final screencast [here](https://www.youtube.com/watch?v=nfwz8vIf_zg).

## Setup of the environment

This document describes how to setup the Windows environment. 
Because of the number of steps, the installation process is devided in multiple parts.

## Components

The Windows environment consists of serveral components.

An overview of the components

- Azure Automation account
- Azure Operations Manager Suite (OMS) workspace
- A set of domain controllers
- An RDS environment
- An Office 365 subscription
- An Azure Active Directory tenant
- An Azure Active Directory proxy
- An Azure Active Directory Application
- An Azure Identity Protection subscription
- An Intune subscription

To run all scripts in the correct order, I've supplied a `start.ps1` [:memo:](./Start.ps1) script. This is a script that calls all other scripts. To tear down all resources created in Azure, I also provided a `DeleteAzureResources.ps1` [:memo:](./DeleteAzureResources.ps1) script. Besides these two scripts all other scripts are located in the `./scripts` folder.

[Index](./docs/index.md) - [Volgende](./docs/1.CreateAnAzureAutomationAccount.md)