# LFS458 course - Student playground

This terraform script will create the following resources:

- Azure resrouce group
- Azure Vnet
- Azure Subnet
- For each student two Azure VMs with a public IP (the public ips are stored under `ips`)
- For each student an indiviual ssh keypair will be generated (and be stored under `keys`)

## Prerequisite

- terraform (`v0.11.7`)
- Python (`3.6.5`)
- Azure subscription

## Preparation

In order to generate the `main.tf`, which will be used as input for terraform, you need to copy the `students.yml.example` file to `students.yml`:

```bash
cp students.yml.example students.yml
```

Now fill in all your student names. After you finished this step you can render the actual `main.tf` file for terraform (we are using Python to render the `main.tf` because terraform doesn't support looping with modules -> <https://github.com/hashicorp/terraform/issues/953> as soon as this feature is available we can get rid of the Python script):

```bash
./render.py
```

Finally we need to create the `terraform.tfvars` file that contains all variables to use this terraform script:

```bash
cp terraform.tfvarsexample terraform.tfvars
```

Now fill in all the requiered variables.

## Run terraform

In the first step we need to initialize all the modules and providers:

```bash
terraform init
```

After we initialized everything we need to login via the [Azure cli](https://docs.microsoft.com/de-de/cli/azure/install-azure-cli?view=azure-cli-latest):

```bash
az login
```

Now we can verify everything with the `plan` step: `terraform plan` if everythings looks fine just apply the changes: `terraform apply`

## Package all information for the students

TODO!

## Clean up

In order to clean up everything just run: `terraform destroy`
