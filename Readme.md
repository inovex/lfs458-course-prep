# LFS458 course - Student playground

This terraform script will create the following resources:

- Azure resrouce group
- Azure Vnet
- Azure Subnet
- For each student two Azure VMs with a public IP (the public ips are stored under `ips`)
- For each student an indiviual ssh keypair will be generated (and be stored under `keys`)

## Prerequisite

- terraform (`v0.11.7`)
- Azure subscription

## Preparation

We need to create the `terraform.tfvars` file that contains all variables to use this terraform script:

```bash
cp terraform.tfvarsexample terraform.tfvars
```

Now fill in all the required variables (e.g. your student names).

## Run terraform

In the first step we need to initialize all the modules and providers:

```bash
terraform init
```

After we initialized everything we need to login via the [Azure cli](https://docs.microsoft.com/de-de/cli/azure/install-azure-cli?view=azure-cli-latest):

```bash
az login
```

Now we can verify everything with the `plan` step: `terraform plan` if everything looks fine just apply the changes: `terraform apply`

## Package all information for the students

TODO!

## Clean up

In order to clean up everything just run: `terraform destroy`
