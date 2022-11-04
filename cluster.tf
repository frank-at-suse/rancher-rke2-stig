resource "random_pet" "cluster_name" {
  length = 2
}

resource "rancher2_machine_config_v2" "nodes" {
  for_each      = var.node
  generate_name = replace(each.value.name, "_", "-")

  vsphere_config {
    cfgparam   = ["disk.enableUUID=TRUE"] # Disk UUID is Required for vSphere Storage Provider
    clone_from = var.vsphere_env.cloud_image_name

    cloud_config = templatefile("${path.cwd}/files/user_data_${each.key}.tftmpl",
      {
        ssh_user       = "rancher",
        ssh_public_key = file("${path.cwd}/files/.ssh_public_key", )
    }) # End of templatefile values

    content_library = var.vsphere_env.library_name
    cpu_count       = each.value.vcpu
    creation_type   = "library"
    datacenter      = var.vsphere_env.datacenter
    datastore       = var.vsphere_env.datastore
    disk_size       = each.value.hdd_capacity
    memory_size     = each.value.vram
    network         = [each.value.network]
    vcenter         = var.vsphere_env.server
  }
} # End of rancher2_machine_config_v2

resource "rancher2_cluster_v2" "rke2" {
  annotations        = var.rancher_env.cluster_annotations
  kubernetes_version = var.rancher_env.rke2_version
  labels             = var.rancher_env.cluster_labels
  name               = random_pet.cluster_name.id

  rke_config {
    additional_manifest = file("${path.cwd}/files/stig_suc_plan.yaml") # STIG Rule ID: SV-254564r859262_rule  (This is a manifest for a System Upgrade PLan that will remediate RKE2 file & directory permissions)

    chart_values = <<EOF
      rke2-calico:
        felixConfiguration:
          wireguardEnabled: true
    EOF

    machine_global_config = <<EOF
      cni: calico

      etcd-arg: [ 
        "experimental-initial-corrupt-check=true" ] # Can be removed with etcd v3.6, which will enable corruption check by default (see: https://github.com/etcd-io/etcd/issues/13766)

      kube-apiserver-arg: [ 
        "anonymous-auth=false", # STIG Rule ID: SV-254562r859256_rule
        "audit-log-maxage=30", # STIG RULE ID: SV-254563r859259_rule
        "audit-log-mode=blocking-strict", # STIG Rule ID: SV-254555r870265_rule
        "audit-policy-file=/etc/rancher/rke2/audit-policy.yaml", # STIG Rule ID: SV-254555r870265_rule
        "enable-admission-plugins=AlwaysPullImages,NodeRestriction",
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers")}", # STIG Rule ID: SV-254553r870263_rule
        "tls-min-version=VersionTLS13" ] # STIG Rule ID: SV-254553r870263_rule

      kube-controller-manager-arg: [
        "bind-address=127.0.0.1", # STIG Rule ID: SV-254556r859238_rule
        "terminated-pod-gc-threshold=10",
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers")}", # STIG Rule ID: SV-254553r870263_rule
        "tls-min-version=VersionTLS13", # STIG Rule ID: SV-254553r870263_rule
        "use-service-account-credentials=true" ] # STIG Rule ID: SV-254554r859232_rule

      kube-scheduler-arg: [
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers")}", # STIG Rule ID: SV-254553r870263_rule
        "tls-min-version=VersionTLS13" ]

      kubelet-arg: [
        "anonymous-auth=false", # STIG Rule ID: SV-254557r859241_rule
        "cgroup-driver=systemd",
        "authorization-mode=Webhook", # STIG RUle ID: SV-254561r870256_rule 
        "event-qps=0",
        "make-iptables-util-chains=true",
        "read-only-port=0", # STIG RULE ID: SV-254559r870254_rule
        "streaming-connection-idle-timeout=5m", # STIG Rule ID: SV-254568r870258_rule
        "tls-min-version=VersionTLS13" ] # STIG Rule ID: SV-254553r870263_rule

      write-kubeconfig-mode: "640"
    EOF

    dynamic "machine_pools" {
      for_each = var.node
      content {
        cloud_credential_secret_name = data.rancher2_cloud_credential.auth.id
        control_plane_role           = machine_pools.key == "ctl_plane" ? true : false
        etcd_role                    = machine_pools.key == "ctl_plane" ? true : false
        name                         = machine_pools.value.name
        quantity                     = machine_pools.value.quantity
        worker_role                  = machine_pools.key != "ctl_plane" ? true : false

        machine_config {
          kind = rancher2_machine_config_v2.nodes[machine_pools.key].kind
          name = replace(rancher2_machine_config_v2.nodes[machine_pools.key].name, "_", "-")
        }
      } # End of dynamic for_each content
    }   # End of machine_pools

    machine_selector_config {
      config = {
        profile                 = "cis-1.6" # STIG Rule ID: SV-254555r870265_rulea
        protect-kernel-defaults = true      # STIG Rule ID: SV-254569r859277_rule (Required to install RKE2 with CIS Profile enabled)
      }
    } # End machine_selector_config
  }   # End of rke_config

  lifecycle {
    precondition {
      condition     = var.node.ctl_plane.quantity % 2 != 0 && var.node.worker.quantity > 0
      error_message = "Err: Invalid quantity for Node Pool. Check that Control Plane node quantity is odd number and Worker node quantity is > 0."
    }
  } # End of lifecycle
}   # End of rancher2_cluster_v2