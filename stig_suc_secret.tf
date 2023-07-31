resource "rancher2_secret_v2" "stig_os_filesystem_script" {
  annotations = { "STIG_Rule_ID" = "SV-254564r918258_rule" }
  cluster_id  = rancher2_cluster_v2.rke2.cluster_v1_id
  name        = "stig-filesystem-remediation"
  namespace   = "cattle-system"
  type        = "Opaque"
  data = { "stig_fs_remediation.sh" = <<EOF
    #!/bin/sh

    set -e
    secrets=$(dirname $0)

    echo "Setting RKE2 directory & file permissions..."

    chmod 640 /var/lib/rancher/rke2/agent/*.kubeconfig
    chmod 750 /var/lib/rancher/rke2/bin/*
    chmod 750 /var/lib/rancher/rke2/data

    if [ -d "/var/lib/rancher/rke2/server" ] 
    then
      echo "Setting permissions for RKE2 server 'logs' & 'manifests' directories..."
      chmod 750 /var/lib/rancher/rke2/server/logs
      chmod 750 /var/lib/rancher/rke2/server/manifests
    else
      echo "Not an RKE2 Server node. Skipping 'server' directory..."
    fi

    echo "RKE2 directory & file permissions have been set successfully."
    EOF
  }
}