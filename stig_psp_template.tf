resource "rancher2_pod_security_policy_template" "stig_psp_template" {
  name = "stig-psp-template"
  description = "PSP in Alignment with STIG RuleID SV-254571r870280_rule."
  annotations = {
    "seccomp.security.alpha.kubernetes.io/allowedProfileNames" = "docker/default,runtime/default"
    "apparmor.security.beta.kubernetes.io/allowedProfileNames" = "runtime/default"
    "seccomp.security.alpha.kubernetes.io/defaultProfileName"  = "runtime/default"
    "apparmor.security.beta.kubernetes.io/defaultProfileName"  = "runtime/default"
  }
  
  allow_privilege_escalation = false
 
  default_allow_privilege_escalation = false

  fs_group {
    rule = "MustRunAs"
    range {
      min = 1
      max = 65535
    }
  }

  host_ipc = false

  host_network = false

  host_pid = false
  
  privileged = false

  read_only_root_filesystem = false

  required_drop_capabilities = ["ALL"]

  run_as_user {
    rule = "MustRunAsNonRoot"
  }

  se_linux {
    rule = "RunAsAny"
  }
  supplemental_group {
    rule = "MustRunAs"
    range {
      min = 1
      max = 65535
    }
  }

  volumes = [ "configMap", "emptyDir", "projected", "secret", "downwardAPI", "persistentVolumeClaim" ]
}