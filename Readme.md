# LFS458 course - Student playground

This terraform script will create the following resources:

- Openstack network
- Openstack security group rules
- For each student two (or five) Openstack instances with a public IP (the public ips are stored under `ips`)
- For each student an individual ssh key pair will be generated (and be stored under `keys`)
- For each student an zip file will be created (and stored under `packages`)

If you look for the GCP terraform configuration, take a look at the folder `gcp_setup`.

## Prerequisite

- terraform (`v0.12.+`)
- [puttygen](https://www.puttygen.com/) (tested with Release 0.71)
- Openstack Account

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
# Otherwise the project from OS_CLOUD will be used
unset OS_CLOUD
terraform init
```

See [here](https://docs.openstack.org/openstacksdk/latest/user/guides/connect_from_config.html) how to setup a `clouds.yaml` for Openstack and terraform.
Ensure that the `OS_CLOUD` environment variable is unset otherwise the value of this environment variable will be used to located the cloud config.
Now we can verify everything with the `plan` step: `terraform plan` if everything looks fine just apply the changes: `terraform apply`
After the creation of the instances run `./scripts/check_connection.sh` to check that all instances are reachable with the ssh key.

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

In order to clean up everything just run: `terraform destroy && rm ./keys/*.ppk`

### Save Homes

If you want to save the homes for your students, run the script `save_homes.sh`. This will copy all the contents of `/home/student` from the machines onto your machine. Then zip the files up and place them in `$(pwd)/homes`.
