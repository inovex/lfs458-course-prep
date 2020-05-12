# LFS458 course - Student playground

This terraform script will create the following resources:

- GCP VPC
- GCP Firewall rule
- For each student two GCP instances with a public IP (the public ips are stored under `ips`)
- For each student an indiviual ssh keypair will be generated (and be stored under `keys`)
- For each student an zip file will be created (and stored under `packages`)

## Prerequisite

- terraform (`v0.12.7`)
- [puttygen](https://www.puttygen.com/) (tested with Release 0.71)
- GCP Account
  - Every student requires 10 vCPUs and 5 public IP addresses. You will run into your quotas very quickly. [Raise GCP quotas process](https://cloud.google.com/compute/quotas#requesting_additional_quota).

## Preparation

We need to create the `terraform.tfvars` file that contains all variables to use this terraform script:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Now fill in all the required variables (e.g. your student names).
If you want to also send mails with the provided Python script add all information to `mail_info.yaml` in the `mail` folder.
The student list can be read from the yaml file with the following command: `yq r ./mail/mail_info.yaml 'attendees.[*].Short' -c -j`.

## Run terraform

In the first step we need to initialize all the modules and providers:

```bash
terraform init
```

See [here](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) how to setup GCP and terraform

Now we can verify everything with the `plan` step: `terraform plan` if everything looks fine just apply the changes: `terraform apply`

### Run in Docker

The provided dockerfile set up a system with all required software. To deploy the training environment run:

```bash
docker build -t lfs458-prep
docker run -it -u "$(id -u):$(id -g)" --rm -v $(pwd):/wd -w /wd lfs458-prep init
docker run -it -u "$(id -u):$(id -g)" --rm -v $(pwd):/wd -w /wd lfs458-prep apply
```

## Sending Mails

Ensure that the [Gmail API](https://developers.google.com/gmail/api/quickstart/python#step_1_turn_on_the) is activated.

```bash
virtualenv --python=python3.7 .venv
. .venv/bin/activate
cd mail
pip install -r requirements.txt
```

Adjust the files under `mail`:

- Add all your attendees to the `mail_info.yaml` file
- Adjust the mail text in `mail_template.txt`

Finally send the mails and thee attachments with: `python3 send_mails.py`

## Clean up

In order to clean up everything just run: `terraform destroy`

### Cleanup in Docker

In order to clean up everything using the docker setup, run:

```bash
docker run -it -u "$(id -u):$(id -g)" --rm -v $(pwd):/wd -w /wd lfs458-prep terraform destroy
```

### Save Homes

If you want to save the homes for your students, run the script `save_homes.sh`. This will copy all the contents of `/home/student` from the machines onto your machine. Then zip the files up and place them in `$(pwd)/homes`.
