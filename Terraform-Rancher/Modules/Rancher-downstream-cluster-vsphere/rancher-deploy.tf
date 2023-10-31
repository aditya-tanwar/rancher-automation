
// Fetching the vsphere credential metadata from the rancher using the data module. 

data "rancher2_cloud_credential" "auth" {
  name = var.cloud_credential
}


// Creating a cluster using the node pools 

resource "rancher2_cluster_v2" "foo-rke2" {
  name                                     = var.cluster_name
  kubernetes_version                       = var.kubernetes_version
  enable_network_policy                    = var.enable_network_policy
  default_cluster_role_for_project_members = var.default_cluster_role_for_project_members

// This is section for configuring the authorized endpoint ( ACE )

  local_auth_endpoint {
    ca_certs = file("./test.pem", )
    enabled  = true
    fqdn     = "rancher.rancherlab02.rancher.prgx.com:6443"
  }

// This section below defines the lifecycle of the authorized endpoint ( ACE ) & cloud_credential_secret_name to protect the drifting of its configuration
  
  lifecycle {
    ignore_changes = [local_auth_endpoint, cloud_credential_secret_name] 
  }

  rke_config {

    // Creating the machine global config in the rke_config block 

    machine_global_config = <<EOF
      cni: ${var.cni}
      disable-kube-proxy: false
      etcd-expose-metrics: false
    
    // The below setting allows a node to be able to schedule 250 pods 
    
      kubelet-arg:
        - max-pods=250
    EOF

    // This section is for etcd backups scheduling using cron jobs  
    
    etcd {
      snapshot_schedule_cron = "0 */24 * * *"   // cron format
      snapshot_retention = 5
    }

// Creating dynamic machine pools 

    dynamic "machine_pools" {
      for_each = var.node
      content {
        cloud_credential_secret_name = data.rancher2_cloud_credential.auth.id
        control_plane_role           = machine_pools.key == "ctl_plane" ? true : false
        etcd_role                    = machine_pools.key == "ctl_plane" ? true : false
        name                         = machine_pools.value.name
        quantity                     = machine_pools.value.quantity
        worker_role                  = machine_pools.key != "ctl_plane" ? true : false
        machine_labels  = (machine_pools.key == "storage") || (machine_pools.key == "ingress")  ? "${lookup(var.labels, machine_pools.key, )}" : null
        dynamic "taints"{ // Adding the taints dynamically to the nodes ( ingress / storage ) 
          for_each = (machine_pools.key == "storage") || (machine_pools.key == "ingress") ?  [1] : []
          content {
                key = "dedicated"
                value = machine_pools.value.name
                effect = "NoSchedule"
             }
        }
        machine_config {
          kind = rancher2_machine_config_v2.machineconfig[machine_pools.key].kind
          name = replace(rancher2_machine_config_v2.machineconfig[machine_pools.key].name, "_", "-")
        }
      } // End of dynamic for_each content
    }   // End of machine_pools
  }
}

// Using the locals to split the network name to be used in the machine config vapp section

locals {
    filter_out = split("/",var.vsphere_env.vm_network[0])[3]
}

output "extracted_content" {
    value = local.filter_out
}


// Creating a machine config to be used while creating the cluster

resource "rancher2_machine_config_v2" "machineconfig" {
  for_each      = var.node
  generate_name = "${each.value.name}-config"

  vsphere_config {
    cfgparam      = ["disk.enableUUID=TRUE"] // Disk UUID is Required for vSphere Storage Provider ( mandatory for the cluster to work )
    clone_from    = var.vsphere_env.cloud_image_name
    cloud_config  = file("/root/aditya/Modules/lab_rancher/cloud.yaml", ) // This is basically the path where the cloud.yaml is stored 
    cpu_count     = each.value.cpu
    creation_type = "template"
    datacenter    = var.vsphere_env.datacenter
    datastore     = var.vsphere_env.datastore
    disk_size     = each.value.disk_size
    memory_size   = each.value.ram
    network       = var.vsphere_env.vm_network
    folder        = var.vsphere_env.folder
    pool          = var.vsphere_env.pool

    // The section below defines the vapp configuration for the cluster 

    vapp_ip_allocation_policy = "fixedAllocated"
    vapp_ip_protocol=  "IPv4"
    vapp_property = [
      "guestinfo.interface.0.ip.0.address=ip:${local.filter_out}",
      "guestinfo.interface.0.ip.0.netmask=$${netmask:${local.filter_out}}",
      "guestinfo.interface.0.route.0.gateway=$${gateway:${local.filter_out}}",
      "guestinfo.dns.servers=$${dns:${local.filter_out}}"
    ]
    vapp_transport = "com.vmware.guestInfo"
  }

  // This is a lifecycle management to prevent automatic drifts in the cloud_config ( LINE 104 ) 
  lifecycle {
    ignore_changes = [
        vsphere_config[0].cloud_config,
    ]
 }
}
