# LFS458 course - Student playground

This terraform script will create the following resources:

- GCP VPC
- GCP Firewall rule
- For each student two GCP instances with a public IP (the public ips are stored under `ips`)
- For each student an indiviual ssh keypair will be generated (and be stored under `keys`)

## Prerequisite

- terraform (`v0.11.7`)
- GCP Account

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

See [here](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) how to setup GCP and terraform

Now we can verify everything with the `plan` step: `terraform plan` if everything looks fine just apply the changes: `terraform apply`

## Package all information for the students

Run `create_package.sh` to create a tar file including the ip and key file for each student.

## Clean up

In order to clean up everything just run: `terraform destroy`
