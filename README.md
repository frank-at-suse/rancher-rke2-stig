> :warning: ***WARNING:*** Pod Security Policy (PSP) was deprecated in K8s v1.21 and is fully removed as of K8s v1.25.  RKE2 STIG does not (yet) provide guidance on the PSP replacement - Pod Security Admission (PSA).  A boiler-plate PSP template aligned with RKE2 STIG is still provided as part of this Terraform plan, despite upcoming PSP removal. To help prepare for this change, Pod Security Admission documentation is [HERE](https://kubernetes.io/docs/concepts/security/pod-security-admission/) and PSP to PSA migration process documentation is [HERE](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/).

## CIS Benchmark 1.6

The STIG conformant cluster deployed by this Terraform plan includes additional configuration to make it CIS 1.6 conformant as well. The documentation for RKE2 CIS benchmark settings is found [HERE](https://rancher.github.io/rke2-docs/security/cis_self_assessment16).

## Cluster Plan

For clarity, the STIG settings througout the cluster plan (`cluster.tf`) are commented with their STIG Rule ID.

## Filesystem Permissions

Changing filesystem permissions expost facto is onerous and error-prone.  Luckily for us, deploying RKE2 via Rancher sets most STIG permissions correctly for us.
There are a couple of directories & files that fall through the cracks and this plan automatically remediates them by leveraging RKE2's System Upgrade Controller (`stig_suc_plan.yaml`).  On all cluster nodes the plan executes a quick, simple bash script that's mounted from the `stig-filesystem-remediation` secret (`stig_suc_secret.tf`).  For the sake of being thorough, the secret is annotated with the appropriate STIG Rule ID & Name.

## K8s API Control Plane Arguments

> :memo: ***NOTE:*** This is not an exhastive list of server arguments used in this plan; just those directly relating to RKE2 STIG conformance.

| `kube-apiserver` | STIG Rule ID |
| ---------------- | :----------: |
| anonymous-auth=false | SV-254562r859256_rule |
| audit-log-maxage=30 | SV-254563r859259_rule |
| audit-log-mode=blocking-strict | SV-254555r870265_rule |
| audit-policy-file=/etc/rancher/rke2/audit-policy.yaml | SV-254555r870265_rule |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r870263_rule |
| tls-min-version=VersionTLS13 | SV-254553r870263_rule |

---

| `kube-controller-manager` | STIG Rule ID |
| ------------------------- | :----------: |
| bind-address=127.0.0.1 | SV-254556r859238_rule |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r870263_rule |
| tls-min-version=VersionTLS13 | SV-254553r870263_rule |
| use-service-account-credentials=true | SV-254554r859232_rule |

---

| `kube-scheduler` | STIG Rule ID |
| ---------------- | :----------: |
| tls-cipher-suites=stig_tls_ciphers.list | SV-254553r870263_rule |
| tls-min-version=VersionTLS13 | SV-254553r870263_rule |

---

| `kubelet` | STIG Rule ID |
| --------- | :----------: |
| anonymous-auth=false | SV-254557r859241_rule |
| authorization-mode=Webhook | SV-254561r870256_rule |
| read-only-port=0 | SV-254559r870254_rule |
| streaming-connection-idle-timeout=5m | SV-254568r870258_rule |
| tls-min-version=VersionTLS13 | SV-254553r870263_rule |

---