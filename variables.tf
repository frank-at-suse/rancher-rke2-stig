variable "node" {
  description = "Properties for MachinePool node types"
  type = object({
    ctl_plane = map(any)
    worker    = map(any)
  })
}

variable "rancher_env" {
  description = "Variables for Rancher environment"
  type = object({
    cloud_credential    = string
    cluster_annotations = map(string)
    cluster_labels      = map(string)
    rke2_version        = string
  })
}

variable "vsphere_env" {
  description = "Variables for vSphere environment"
  type = object({
    cloud_image_name = string
    datacenter       = string
    datastore        = string
    library_name     = string
    server           = string
    vm_network       = string
  })
}