
api_url    = // Enter the url of the rancher ui that is presented when you create the api keys for the rancher
access_key = // Rancher Access Token 
secret_key = // Rancher Secret Token
insecure_connection = true // To allow the https connections 



cluster_name = // Name of the Rancher Downstream Cluster
kubernetes_version = // kubernetes version as supported by the Rancher For example - "v1.26.6+rke2r1"
enable_network_policy = false
default_cluster_role_for_project_members = "admin"  // Default role for the project members 


/* 
   This section specifies the T-shirt sizing of the nodes as per the roles
   There are some roles defined below 
   Here one thing to consider that ram & disks are measured in the MB
*/

node = {
  ingress = { name = "ingress", quantity = 2, cpu = 2, ram = 4096, disk_size = 20000 }  
  ctl_plane = { name = "ctl-plane", quantity = 1, cpu = 2, ram = 8000, disk_size = 20000 }
  worker    = { name = "worker", quantity = 2, cpu = 2, ram = 8000, disk_size = 20000 }
  storage = { name = "storage", quantity = 2, cpu = 2, ram = 8000, disk_size = 20000 }
  }

/* These are vcenter related details that has to be used by the rancher to be able to deploy nodes on the vcenter */

vsphere_env = {
  cloud_image_name = "/DATACENTER_NAME/vm/Rancher/RancherTemplateName"
  datacenter       = "/DATACENTER_NAME"
  datastore        = "/DATACENTER_NAME/datastore/PURE/FA01/Rancher/POC/DATASTORE_NAME"
  vm_network       = ["/DATACENTER_NAME/network/NETWORK_NAME"]
  folder        = "/DATACENTER_NAME/vm/Rancher/RancherFolderName"
  pool  = "/DATACENTER_NAME/host/VCENTER_CLUSTER_NAME/Resources"
}
