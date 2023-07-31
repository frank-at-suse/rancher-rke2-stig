# STIG & CIS Conformant vSphere RKE2 Cluster

> :warning: Pod Security Policy (PSP) was deprecated in K8s v1.21 and fully removed as of K8s v1.25. Pod Security Admission (PSA), fully introduced in K8s v1.25, is the replacement.

## STIG Viewer

The ins & outs of using STIG viewer aren't covered, but it can be downloaded [HERE](https://public.cyber.mil/stigs/srg-stig-tools/) and the RKE2 STIG that this Terraform plan references can be downloaded [HERE](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RGS_RKE2_V1R3_STIG.zip).

To run the latest STIG viewer on Mac, use `brew` to first install Java stuff:

>```zsh
>brew tap bell-sw/liberica
>brew install --cask liberica-jdk16-full
>```

and then download/extract the generic viewer `.zip` file from the link above.

## CIS Benchmarks

> :memo: CIS will soon be abondoning their current versioning schema (that aligns a CIS version with a Kubernetes minor release version) and returning to the "original" format.

The STIG conformant cluster deployed by this Terraform plan includes additional configuration to make it CIS 1.6 (v1.24andBelow branch) or 1.23 (v1.25+ branch) conformant as well. The documentation for RKE2 CIS benchmark settings is [HERE](https://rancher.github.io/rke2-docs/security/cis_self_assessment123).

## Filesystem Permissions

Changing filesystem permissions expost facto is onerous and error-prone.  Luckily, deploying RKE2 via Rancher sets most STIG permissions correctly for us.
There are a couple of directories & files that fall through the cracks and this plan automatically remediates them by leveraging RKE2's System Upgrade Controller (`stig_suc_plan.yaml`).  On all cluster nodes the plan executes a quick, simple bash script that's mounted from the `stig-filesystem-remediation` secret (`stig_suc_secret.tf`).  For the sake of being thorough, the secret is annotated with the appropriate STIG Rule ID & Name.

## vSphere User Permissions

The minimum vSphere permissions Rancher requires for downstream cluster deployments are [HERE](https://github.com/rancher/barn/blob/main/Walkthroughs/vSphere/Permissions/README.md). These permissions are not related to any particular STIG guideline.

## K8s API Control Plane Arguments Reference

> :memo: This is not an exhastive list of server arguments used in this plan; just those directly relating to RKE2 STIG conformance.

| `kube-apiserver` | STIG Rule ID |
| ---------------- | :----------: |
| anonymous-auth=false | SV-254562r918256_rule |
| audit-log-maxage=30 | SV-254563r918257_rule |
| audit-log-mode=blocking-strict | SV-254555r894454_rule |
| audit-policy-file=/etc/rancher/rke2/audit-policy.yaml | SV-254555r894454_rule |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r894451_rule |
| tls-min-version=VersionTLS13 | SV-254553r894451_rule |

---

| `kube-controller-manager` | STIG Rule ID |
| ------------------------- | :----------: |
| bind-address=127.0.0.1 | SV-254556r918253_rule |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r894451_rule |
| tls-min-version=VersionTLS13 | SV-254553r894451_rule |
| use-service-account-credentials=true | SV-254554r918252_rule |

---

| `kube-scheduler` | STIG Rule ID |
| ---------------- | :----------: |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r894451_rule |
| tls-min-version=VersionTLS13 | SV-254553r894451_rule |

---

| `kubelet` | STIG Rule ID |
| --------- | :----------: |
| anonymous-auth=false | SV-254557r879530_rule |
| authorization-mode=Webhook | SV-254572r879751_rule & SV-254561r918255_rule |
| read-only-port=0 | SV-254559r879530_rule |
| streaming-connection-idle-timeout=5m | SV-254568r894464_rule |
| tls-min-version=VersionTLS13 | SV-254553r894451_rule |

---
