# Minecraft on OCI with Terraform + Minepanel

Personal infrastructure template for a Minecraft host on Oracle Cloud Infrastructure (OCI).

Terraform creates the OCI network, firewall rules, Ubuntu ARM64 A1 instance, and an independent persistent data volume. Cloud-init installs Docker and mounts that volume at `/srv/minepanel`. Minepanel then owns Minecraft servers, worlds, mods, and their generated Docker Compose files.

## Responsibility boundary

```txt
Terraform: OCI VCN, subnet, NSG, VM, data volume, host bootstrap
Minepanel: Minecraft server versions, settings, worlds, mods, plugins, backups
```

Do not manage `servers/`, `data/`, Minepanel `server.json`, or individual Minecraft containers with Terraform. Minepanel is their source of truth.

## What this creates

- Ubuntu 24.04 ARM64 instance, `VM.Standard.A1.Flex`
- VCN, public subnet, internet gateway, routing, and host network security group
- SSH and panel HTTPS limited to `admin_cidrs`
- Public HTTP only for Caddy certificate issuance
- Public Java port `25565/tcp`; optional Bedrock port `19132/udp`
- 50 GB boot disk plus an attached, Terraform-protected data volume

The template defaults to 2 OCPUs, 12 GB RAM, and 150 GB persistent data. Verify the current Always Free quota in your OCI tenancy before applying; capacity can be unavailable in a home region.

## Prerequisites

1. An OCI account, home region, and an available Ampere A1 shape.
2. Terraform 1.6+ and OCI CLI configured locally (`oci setup config`). The Terraform OCI provider reads the normal OCI config/profile; no credentials are committed here.
3. An SSH key pair, such as `~/.ssh/id_ed25519`.
4. A domain with two DNS records, for example `panel.example.com` and `api.example.com`. Add the records after `terraform apply`, pointing to the output IP.

## Deploy infrastructure

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Before `plan`, edit `terraform.tfvars`:

- Replace both OCIDs.
- Select an availability domain shown in the OCI Console.
- Paste your public SSH key.
- Replace the example `admin_cidrs` IP with your own current public IP/CIDR.

Copy the `instance_public_ip` output. Wait a few minutes for cloud-init and the data-volume mount to complete, then connect using the emitted `ssh_command`.

## Deploy Minepanel

1. Create DNS `A` records for `PANEL_DOMAIN` and `API_DOMAIN`, both pointing to `instance_public_ip`. Wait for DNS propagation.
2. Copy this repository's `deploy/` directory to the VM (or clone your private GitHub repository there).
3. On the VM:

```bash
cd ~/minecraft-oci-sv/deploy
cp .env.example .env
openssl rand -base64 32
```

Paste that generated value into `JWT_SECRET` in `.env`, and set your real panel/API domains. Then start it:

```bash
docker compose up -d
docker compose ps
```

Open `https://panel.example.com` and create the initial Minepanel admin account. Caddy obtains HTTPS certificates automatically. Minepanel's data is under `/srv/minepanel`, not in the Git checkout.

## After deployment

1. Create a small Paper server in Minepanel and test joining via `instance_public_ip:25565`.
2. Configure Minepanel automatic backups. Also copy backups off the VM; OCI volume backups are helpful but not a complete disaster-recovery strategy.
3. If you need Bedrock, set `enable_bedrock = true`, run `terraform apply`, and then create the Bedrock server in Minepanel.
4. If your public IP changes, update `admin_cidrs` and run `terraform apply` before you lose panel/SSH access.
5. Pin tested Minepanel image versions before relying on the installation long-term; `latest` is convenient for first setup but is not a reproducible production release strategy.

## Operations

```bash
# Panel status and logs, run on the VM from deploy/
docker compose ps
docker compose logs -f

# Update only after taking a backup and reviewing the release notes
docker compose pull
docker compose up -d

# Verify mounted persistent storage
findmnt /srv/minepanel
```

Never run `terraform destroy` casually. The data volume has `prevent_destroy`, so Terraform will stop rather than delete it. To intentionally remove everything, first back up your worlds and explicitly remove that lifecycle protection.

## Security notes

- Keep `terraform.tfvars`, `.env`, Terraform state, and private keys out of Git. The supplied `.gitignore` excludes them.
- The panel can control Docker through `/var/run/docker.sock`; panel administrator access is effectively host-administrator access.
- This template permits HTTP from the public internet only so Caddy can complete certificate challenges. HTTPS and SSH are limited to `admin_cidrs`; Minecraft is public.
- OCI Network Security Groups and UFW are both configured. Add mod/plugin ports deliberately in both layers.

## License note

This repository is an infrastructure template; Minepanel remains its own project and license. Minepanel's Community License permits personal use but has restrictions on commercial hosting and competing products.
