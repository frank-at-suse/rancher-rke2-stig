resource "random_pet" "cluster_name" {
  length = 2
}

resource "rancher2_machine_config_v2" "nodes" {
  for_each      = var.node
  generate_name = replace(each.value.name, "_", "-")

  vsphere_config {
    cfgparam   = ["disk.enableUUID=TRUE"]
    clone_from = var.vsphere_env.cloud_image_name

    cloud_config = templatefile("${path.cwd}/files/user_data_${each.key}.tftmpl",
      {
        pss_config     = file("${path.cwd}/files/pss-admission-config.yaml"),
        ssh_user       = "rancher",
        ssh_public_key = file("${path.cwd}/files/.ssh-public-key")
    }) # End of templatefile values

    content_library = var.vsphere_env.library_name
    cpu_count       = each.value.vcpu
    creation_type   = "library"
    datacenter      = var.vsphere_env.datacenter
    datastore       = var.vsphere_env.datastore
    disk_size       = each.value.hdd_capacity
    memory_size     = each.value.vram
    network         = [var.vsphere_env.vm_network]
    vcenter         = var.vsphere_env.server
  }
} # End of rancher2_machine_config_v2

resource "rancher2_cluster_v2" "rke2" {
  annotations        = var.rancher_env.cluster_annotations
  kubernetes_version = var.rancher_env.rke2_version
  labels             = var.rancher_env.cluster_labels
  name               = random_pet.cluster_name.id

  rke_config {
    additional_manifest = file("${path.cwd}/files/stig-suc-plan.yaml") # STIG Rule ID: SV-254564r918258_rule (This is a manifest for a System Upgrade Plan that will remediate RKE2 file & directory permissions)

    chart_values = <<EOF
      rke2-canal:
        flannel:
          backend: "wireguard"
    EOF

    machine_global_config = <<EOF
      cni: canal

      etcd-arg: [ 
        "experimental-initial-corrupt-check=true" ] # Can be removed with etcd v3.6, which will enable corruption check by default (see: https://github.com/etcd-io/etcd/issues/13766)

      kube-apiserver-arg: [ 
        "admission-control-config-file=/etc/rancher/rke2/rancher-deployment-pss.yaml",
        "anonymous-auth=false",
        "audit-log-maxage=30",
        "audit-log-mode=blocking-strict",
        "audit-policy-file=/etc/rancher/rke2/audit-policy.yaml",
        "enable-admission-plugins=AlwaysPullImages,NodeRestriction",
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers.list")}",
        "tls-min-version=VersionTLS13" ]

      kube-controller-manager-arg: [
        "bind-address=127.0.0.1",
        "terminated-pod-gc-threshold=10",
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers.list")}",
        "tls-min-version=VersionTLS13",
        "use-service-account-credentials=true" ]

      kube-scheduler-arg: [
        "tls-cipher-suites=${file("${path.cwd}/files/stig_tls_ciphers.list")}",
        "tls-min-version=VersionTLS13" ]

      kubelet-arg: [
        "anonymous-auth=false",
        "authorization-mode=Webhook",
        "event-qps=0",
        "make-iptables-util-chains=true",
        "read-only-port=0",
        "streaming-connection-idle-timeout=5m",
        "tls-min-version=VersionTLS13" ]

      write-kubeconfig-mode: "640" # STIG Rule ID: SV-254564r918258_rule
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
        profile                 = "cis-1.23" # STIG Rule ID: SV-254555r870265_rule
        protect-kernel-defaults = true       # STIG Rule ID: SV-254569r879643_rule (Required to install RKE2 with CIS Profile enabled)
      }
    } # End machine_selector_config
  }   # End of rke_config

  lifecycle {
    precondition {
      condition     = var.node.ctl_plane.quantity % 2 != 0 && var.node.worker.quantity > 0
      error_message = "ERR: Invalid quantity for Node Pool. Check that Control Plane node quantity is odd number and Worker node quantity is > 0."
    }
  } # End of lifecycle
}   # End of rancher2_cluster_v2
