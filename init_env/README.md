# Project Documentation

## Overview

This project is designed to manage network configurations using Terraform for a virtualized environment. The primary focus is on creating application port profiles that facilitate communication for various services.

## Directory Structure

- **bastion-env/**: Contains the original Terraform configuration file (`edge.tf`) from which application port profiles are extracted.
- **init_env/**: This directory contains the Terraform configurations for creating application port profiles.
  - **main.tf**: This file includes the definitions for the following application port profiles:
    - DNS
    - DHCP
    - NTP
    - HTTP-8080-Custom
    - HAProxy admin Port
    - Custom_api_6443
    - Custom_ssh_8446
  - **variables.tf**: This file defines the necessary variables used in the `main.tf` file, including:
    - `vcd.org`
    - `networking.edge_gateway`
    - `networking.fw_rules.allow_ssh_source`
    - `vcd.external_network.ip`
    - `services.lb.vip_ip`
    - Any other variables required for the application port profiles.

## Usage

1. Navigate to the `init_env` directory.
2. Initialize Terraform with the command:
   ```
   terraform init
   ```
3. Review the execution plan with:
   ```
   terraform plan
   ```
4. Apply the configuration to create the application port profiles:
   ```
   terraform apply
   ```

## Requirements

- Terraform installed on your machine.
- Access to the necessary cloud provider and permissions to create resources.

## Conclusion

This project provides a structured approach to managing application port profiles in a virtualized environment using Terraform. The configurations are modular and can be easily modified to accommodate additional services or changes in requirements.