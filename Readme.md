# LFS458 course - Student playground

This terraform script will create the following resources:

- Openstack network
- Openstack security group rules
- For each student two (or five) Openstack instances with a public IP (the public ips are stored under `ips`)
- For each student an individual ssh key pair will be generated (and be stored under `keys`)
- For each student an zip file will be created (and stored under `packages`)

If you look for the GCP terraform configuration, take a look at the folder `gcp_setup`.

## Prerequisites

- terraform (`v1.1.7+`)
- [puttygen](https://www.puttygen.com/) (tested with Release 0.71)
- Openstack Account

## Preparation

We need to create the `terraform.tfvars` file that contains all variables to use this terraform script:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Now fill in all the required variables (e.g. your student names).
If you want to also send mails with the provided Python script add all information to `mail_info.yaml` in the `mail` folder.
The student list can be read from the yaml file with the following command: `yq -r '.attendees | map("\"" + .Short + "\"") | join(", ")' mail/mail_info.yaml`.

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


### Remote state

Terraform state is stored locally by default. The `main.tf` contains the required backend config snippet to enable remote state with a single command.
This could be useful if you have to hand over the training environment to someone else.

## Automatically download and unpack solutions

In order to automatically download and unpack solutions, set the variable `solutions_url` to the URL provided by the Linux Foundation. The solutions will be unpacked on every machine in the `/home/student/LF*` directory.

see [terraform.tfvars.example](terraform.tfvars.example) for an example, you'll have to provide the Linux Foundation provided username and password inside the url.

### Bonus: Automatically patching solutions

If you find that the official solutions contain errors, you can also automatically fix them and patch all the solutions you automatically downloaded.

To do that:

1. Download the solutions on your machine using the official URL (of course use the correct username and password)
   ```
   wget https://training.linuxfoundation.org/cm/LFS458/LFS458_V1.22.1_SOLUTIONS.tar.xz  --user=**USERNAME** --password=**PASSWORD**
   ```
1. Unpack the tarball
1. Duplicate the unpacked directory:
   ```
   cp -a LFS458 LFS458patched
   ```
1. In the `LFS458patched` directory (or whatever you named it), edit, delete and create all files as needed
1. create a patch for the whole tree:
   ```
   diff -ruN LFS458 LFS458patched > solutions.patch
   ```
1. Copy the `solutions.patch` file (using exactly this name) to the terraform base dir (next to your `terraform.tfvars` file)

## Sending Mails

Ensure that the [Gmail API](https://developers.google.com/gmail/api/quickstart/python#step_1_turn_on_the) is activated.

```bash
virtualenv --python=python3.10 .venv
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
