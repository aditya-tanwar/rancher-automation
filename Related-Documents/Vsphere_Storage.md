# VSPHERE Storage (  CPI & CSI )

### **Components and working of the Vsphere CSI ( VERY IMPORTANT )**

[A Deep Dive into the Kubernetes vSphere CSI Driver with TKGI and TKG](https://tanzu.vmware.com/content/blog/a-deep-dive-into-the-kubernetes-vsphere-csi-driver-with-tkgi-and-tkg)

### **For pvc visibility on the vcenter**

[Using vSphere CSI 2.0 with native Kubernetes to encrypt individual Persistent Volumes on vSAN](https://www.youtube.com/watch?v=2Kh875OlQNk)

<img src="https://content.cdntwrk.com/files/aHViPTYzOTc1JmNtZD1pdGVtZWRpdG9yaW1hZ2UmZmlsZW5hbWU9aXRlbWVkaXRvcmltYWdlXzVlZTIzMmY0Y2EwOTQuanBlZyZ2ZXJzaW9uPTAwMDAmc2lnPWViNTQyZTQ4NTQyMDY1NWZlYzM5Y2FmM2Q4MDYxYjFm">

## **NOTE : When doing the vsphere storage deployment on the existing cluster there is no need to install the CPI as by default it is deployed on both centralized cluster and downstream cluster.**

## **Pre-requisite**

- Use the below command to validate the ProviderID’s are being provided to every node registered in the cluster . As the cluster provisioned from rancher has default cloud provider built in that assigns the IDs to the nodes. Once Validated , proceed with the installation of the CSI

```
kubectl describe nodes | grep "ProviderID"
```

![Untitled](VSPHERE%20Storage%20(%20CPI%20&%20CSI%20)%2058a908534ee64b7da89506835f2b8eaf/Untitled%201.png)

## **Installing the Vsphere CSI on the existing rke2 cluster**

1. Create the namespace “**vmware-system-csi**”
2. Create a secret “**vsphere-config-secret**” in the above namespace
3. **Secret file**
   
```
csi-vsphere.conf
[Global]
cluster-id = "< cluster id >"
user = "<username>"
password = "<password>"
port = "<port>"
insecure-flag = "1"
[VirtualCenter "<vc.example.com>"]
datacenters = "<datacenter name>"
```
    
    **Note** : The data should look similar to what has been shown below. Copy the cluster-id from the kubeconfig in Rancher. Username & Password is the service account & it’s password
    
5. Once the secret is created deploy the csi manifests in the above namespace

  6. download [https://raw.githubusercontent.com/kubernetes-sigs/vsphere-csi-driver/v3.0.0/manifests/vanilla/vsphere-csi-driver.yaml](https://raw.githubusercontent.com/kubernetes-sigs/vsphere-csi-driver/v3.0.0/manifests/vanilla/vsphere-csi-driver.yaml)

1. There are certain changes that has to be added on to the manifest to make it work , the modified file is shown below 

```yaml
apiVersion: storage.k8s.io/v1
kind: CSIDriver
metadata:
  name: csi.vsphere.vmware.com
spec:
  attachRequired: true
  podInfoOnMount: false
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: vsphere-csi-controller
  namespace: vmware-system-csi
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-controller-role
rules:
- apiGroups: [""]
  resources: ["nodes", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch", "create"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch", "update"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims/status"]
  verbs: ["patch"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["coordination.k8s.io"]
  resources: ["leases"]
  verbs: ["get", "watch", "list", "delete", "update", "create"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses", "csinodes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["volumeattachments"]
  verbs: ["get", "list", "watch", "patch"]
- apiGroups: ["cns.vmware.com"]
  resources: ["triggercsifullsyncs"]
  verbs: ["create", "get", "update", "watch", "list"]
- apiGroups: ["cns.vmware.com"]
  resources: ["cnsvspherevolumemigrations"]
  verbs: ["create", "get", "list", "watch", "update", "delete"]
- apiGroups: ["cns.vmware.com"]
  resources: ["cnsvolumeinfoes"]
  verbs: ["create", "get", "list", "watch", "delete"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "create", "update"]
- apiGroups: ["storage.k8s.io"]
  resources: ["volumeattachments/status"]
  verbs: ["patch"]
- apiGroups: ["cns.vmware.com"]
  resources: ["cnsvolumeoperationrequests"]
  verbs: ["create", "get", "list", "update", "delete"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots"]
  verbs: ["get", "list"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshotclasses"]
  verbs: ["watch", "get", "list"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshotcontents"]
  verbs: ["create", "get", "list", "watch", "update", "delete", "patch"]
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshotcontents/status"]
  verbs: ["update", "patch"]
- apiGroups: ["cns.vmware.com"]
  resources: ["csinodetopologies"]
  verbs: ["get", "update", "watch", "list"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-controller-binding
subjects:
- kind: ServiceAccount
  name: vsphere-csi-controller
  namespace: vmware-system-csi
roleRef:
  kind: ClusterRole
  name: vsphere-csi-controller-role
  apiGroup: rbac.authorization.k8s.io
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: vsphere-csi-node
  namespace: vmware-system-csi
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-node-cluster-role
rules:
- apiGroups: ["cns.vmware.com"]
  resources: ["csinodetopologies"]
  verbs: ["create", "watch", "get", "patch"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-node-cluster-role-binding
subjects:
- kind: ServiceAccount
  name: vsphere-csi-node
  namespace: vmware-system-csi
roleRef:
  kind: ClusterRole
  name: vsphere-csi-node-cluster-role
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-node-role
  namespace: vmware-system-csi
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: vsphere-csi-node-binding
  namespace: vmware-system-csi
subjects:
- kind: ServiceAccount
  name: vsphere-csi-node
  namespace: vmware-system-csi
roleRef:
  kind: Role
  name: vsphere-csi-node-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
data:
  "csi-migration": "true"
  "csi-auth-check": "true"
  "online-volume-extend": "true"
  "trigger-csi-fullsync": "false"
  "async-query-volume": "true"
  "block-volume-snapshot": "true"
  "csi-windows-support": "true"
  "use-csinode-id": "true"
  "list-volumes": "true"
  "pv-to-backingdiskobjectid-mapping": "false"
  "cnsmgr-suspend-create-volume": "true"
  "topology-preferential-datastores": "true"
  "max-pvscsi-targets-per-vm": "true"
  "multi-vcenter-csi-topology": "true"
  "csi-internal-generated-cluster-id": "true"
  "listview-tasks": "false"
kind: ConfigMap
metadata:
  name: internal-feature-states.csi.vsphere.vmware.com
  namespace: vmware-system-csi
---
apiVersion: v1
kind: Service
metadata:
  name: vsphere-csi-controller
  namespace: vmware-system-csi
  labels:
    app: vsphere-csi-controller
spec:
  ports:
  - name: ctlr
    port: 2112
    targetPort: 2112
    protocol: TCP
  - name: syncer
    port: 2113
    targetPort: 2113
    protocol: TCP
  selector:
    app: vsphere-csi-controller
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: vsphere-csi-controller
  namespace: vmware-system-csi
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 0
  selector:
    matchLabels:
      app: vsphere-csi-controller
  template:
    metadata:
      labels:
        app: vsphere-csi-controller
        role: vsphere-csi
    spec:
      priorityClassName: system-cluster-critical # Guarantees scheduling for critical system pods
      serviceAccountName: vsphere-csi-controller
      nodeSelector:
        node-role.kubernetes.io/control-plane: 'true'
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - effect: NoExecute
        # Added this to the code 
        key: node-role.kubernetes.io/etcd
        operator: Exists
      # uncomment below toleration if you need an aggressive pod eviction in case when
      # node becomes not-ready or unreachable. Default is 300 seconds if not specified.
      #- key: node.kubernetes.io/not-ready
      #  operator: Exists
      #  effect: NoExecute
      #  tolerationSeconds: 30
      #- key: node.kubernetes.io/unreachable
      #  operator: Exists
      #  effect: NoExecute
      #  tolerationSeconds: 30
      dnsPolicy: "Default"
      containers:
      - name: csi-attacher
        image: k8s.gcr.io/sig-storage/csi-attacher:v4.2.0
        args:
        - "--v=4"
        - "--timeout=300s"
        - "--csi-address=$(ADDRESS)"
        - "--leader-election"
        - "--leader-election-lease-duration=120s"
        - "--leader-election-renew-deadline=60s"
        - "--leader-election-retry-period=30s"
        - "--kube-api-qps=100"
        - "--kube-api-burst=100"
        env:
        - name: ADDRESS
          value: /csi/csi.sock
        volumeMounts:
        - mountPath: /csi
          name: socket-dir
      - name: csi-resizer
        image: k8s.gcr.io/sig-storage/csi-resizer:v1.7.0
        args:
        - "--v=4"
        - "--timeout=300s"
        - "--handle-volume-inuse-error=false"
        - "--csi-address=$(ADDRESS)"
        - "--kube-api-qps=100"
        - "--kube-api-burst=100"
        - "--leader-election"
        - "--leader-election-lease-duration=120s"
        - "--leader-election-renew-deadline=60s"
        - "--leader-election-retry-period=30s"
        env:
        - name: ADDRESS
          value: /csi/csi.sock
        volumeMounts:
        - mountPath: /csi
          name: socket-dir
      - name: vsphere-csi-controller
        image: gcr.io/cloud-provider-vsphere/csi/release/driver:v3.0.0
        args:
        - "--fss-name=internal-feature-states.csi.vsphere.vmware.com"
        - "--fss-namespace=$(CSI_NAMESPACE)"
        imagePullPolicy: "Always"
        env:
        - name: CSI_ENDPOINT
          value: unix:///csi/csi.sock
        - name: X_CSI_MODE
          value: "controller"
        - name: X_CSI_SPEC_DISABLE_LEN_CHECK
          value: "true"
        - name: X_CSI_SERIAL_VOL_ACCESS_TIMEOUT
          value: 3m
        - name: VSPHERE_CSI_CONFIG
          value: "/etc/cloud/csi-vsphere.conf"
        - name: LOGGER_LEVEL
          value: "PRODUCTION" # Options: DEVELOPMENT, PRODUCTION
        - name: INCLUSTER_CLIENT_QPS
          value: "100"
        - name: INCLUSTER_CLIENT_BURST
          value: "100"
        - name: CSI_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - mountPath: /etc/cloud
          name: vsphere-config-volume
          readOnly: true
        - mountPath: /csi
          name: socket-dir
        ports:
        - name: healthz
          containerPort: 9808
          protocol: TCP
        - name: prometheus
          containerPort: 2112
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /healthz
            port: healthz
          initialDelaySeconds: 30
          timeoutSeconds: 10
          periodSeconds: 180
          failureThreshold: 3
      - name: liveness-probe
        image: k8s.gcr.io/sig-storage/livenessprobe:v2.9.0
        args:
        - "--v=4"
        - "--csi-address=/csi/csi.sock"
        volumeMounts:
        - name: socket-dir
          mountPath: /csi
      - name: vsphere-syncer
        image: gcr.io/cloud-provider-vsphere/csi/release/syncer:v3.0.0
        args:
        - "--leader-election"
        - "--leader-election-lease-duration=120s"
        - "--leader-election-renew-deadline=60s"
        - "--leader-election-retry-period=30s"
        - "--fss-name=internal-feature-states.csi.vsphere.vmware.com"
        - "--fss-namespace=$(CSI_NAMESPACE)"
        imagePullPolicy: "Always"
        ports:
        - containerPort: 2113
          name: prometheus
          protocol: TCP
        env:
        - name: FULL_SYNC_INTERVAL_MINUTES
          value: "30"
        - name: VSPHERE_CSI_CONFIG
          value: "/etc/cloud/csi-vsphere.conf"
        - name: LOGGER_LEVEL
          value: "PRODUCTION" # Options: DEVELOPMENT, PRODUCTION
        - name: INCLUSTER_CLIENT_QPS
          value: "100"
        - name: INCLUSTER_CLIENT_BURST
          value: "100"
        - name: GODEBUG
          value: x509sha1=1
        - name: CSI_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - mountPath: /etc/cloud
          name: vsphere-config-volume
          readOnly: true
      - name: csi-provisioner
        image: k8s.gcr.io/sig-storage/csi-provisioner:v3.4.0
        args:
        - "--v=4"
        - "--timeout=300s"
        - "--csi-address=$(ADDRESS)"
        - "--kube-api-qps=100"
        - "--kube-api-burst=100"
        - "--leader-election"
        - "--leader-election-lease-duration=120s"
        - "--leader-election-renew-deadline=60s"
        - "--leader-election-retry-period=30s"
        - "--default-fstype=ext4"
        # needed only for topology aware setup
        #- "--feature-gates=Topology=true"
        #- "--strict-topology"
        env:
        - name: ADDRESS
          value: /csi/csi.sock
        volumeMounts:
        - mountPath: /csi
          name: socket-dir
      - name: csi-snapshotter
        image: k8s.gcr.io/sig-storage/csi-snapshotter:v6.2.1
        args:
        - "--v=4"
        - "--kube-api-qps=100"
        - "--kube-api-burst=100"
        - "--timeout=300s"
        - "--csi-address=$(ADDRESS)"
        - "--leader-election"
        - "--leader-election-lease-duration=120s"
        - "--leader-election-renew-deadline=60s"
        - "--leader-election-retry-period=30s"
        env:
        - name: ADDRESS
          value: /csi/csi.sock
        volumeMounts:
        - mountPath: /csi
          name: socket-dir
      volumes:
      - name: vsphere-config-volume
        secret:
          secretName: vsphere-config-secret
      - name: socket-dir
        emptyDir: {}
---
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: vsphere-csi-node
  namespace: vmware-system-csi
spec:
  selector:
    matchLabels:
      app: vsphere-csi-node
  updateStrategy:
    type: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: vsphere-csi-node
        role: vsphere-csi
    spec:
      priorityClassName: system-node-critical
      nodeSelector:
        kubernetes.io/os: linux
        node-role.kubernetes.io/control-plane: 'true'
      serviceAccountName: vsphere-csi-node
      hostNetwork: true
      dnsPolicy: "ClusterFirstWithHostNet"
      containers:
      - name: node-driver-registrar
        image: k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.7.0
        args:
        - "--v=5"
        - "--csi-address=$(ADDRESS)"
        - "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)"
        env:
        - name: ADDRESS
          value: /csi/csi.sock
        - name: DRIVER_REG_SOCK_PATH
          value: /var/lib/kubelet/plugins/csi.vsphere.vmware.com/csi.sock
        volumeMounts:
        - name: plugin-dir
          mountPath: /csi
        - name: registration-dir
          mountPath: /registration
        livenessProbe:
          exec:
            command:
            - /csi-node-driver-registrar
            - --kubelet-registration-path=/var/lib/kubelet/plugins/csi.vsphere.vmware.com/csi.sock
            - --mode=kubelet-registration-probe
          initialDelaySeconds: 3
      - name: vsphere-csi-node
        image: gcr.io/cloud-provider-vsphere/csi/release/driver:v3.0.0
        args:
        - "--fss-name=internal-feature-states.csi.vsphere.vmware.com"
        - "--fss-namespace=$(CSI_NAMESPACE)"
        imagePullPolicy: "Always"
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: CSI_ENDPOINT
          value: unix:///csi/csi.sock
        - name: MAX_VOLUMES_PER_NODE
          value: "59" # Maximum number of volumes that controller can publish to the node. If value is not set or zero Kubernetes decide how many volumes can be published by the controller to the node.
        - name: X_CSI_MODE
          value: "node"
        - name: X_CSI_SPEC_REQ_VALIDATION
          value: "false"
        - name: X_CSI_SPEC_DISABLE_LEN_CHECK
          value: "true"
        - name: LOGGER_LEVEL
          value: "PRODUCTION" # Options: DEVELOPMENT, PRODUCTION
        - name: GODEBUG
          value: x509sha1=1
        - name: CSI_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODEGETINFO_WATCH_TIMEOUT_MINUTES
          value: "1"
        securityContext:
          privileged: true
          capabilities:
            add: ["SYS_ADMIN"]
          allowPrivilegeEscalation: true
        volumeMounts:
        - name: plugin-dir
          mountPath: /csi
        - name: pods-mount-dir
          mountPath: /var/lib/kubelet
          # needed so that any mounts setup inside this container are
          # propagated back to the host machine.
          mountPropagation: "Bidirectional"
        - name: device-dir
          mountPath: /dev
        - name: blocks-dir
          mountPath: /sys/block
        - name: sys-devices-dir
          mountPath: /sys/devices
        ports:
        - name: healthz
          containerPort: 9808
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /healthz
            port: healthz
          initialDelaySeconds: 10
          timeoutSeconds: 5
          periodSeconds: 5
          failureThreshold: 3
      - name: liveness-probe
        image: k8s.gcr.io/sig-storage/livenessprobe:v2.9.0
        args:
        - "--v=4"
        - "--csi-address=/csi/csi.sock"
        volumeMounts:
        - name: plugin-dir
          mountPath: /csi
      volumes:
      - name: registration-dir
        hostPath:
          path: /var/lib/kubelet/plugins_registry
          type: Directory
      - name: plugin-dir
        hostPath:
          path: /var/lib/kubelet/plugins/csi.vsphere.vmware.com
          type: DirectoryOrCreate
      - name: pods-mount-dir
        hostPath:
          path: /var/lib/kubelet
          type: Directory
      - name: device-dir
        hostPath:
          path: /dev
      - name: blocks-dir
        hostPath:
          path: /sys/block
          type: Directory
      - name: sys-devices-dir
        hostPath:
          path: /sys/devices
          type: Directory
      tolerations:
      - effect: NoExecute
        operator: Exists
      - effect: NoSchedule
        operator: Exists
```

**ConfigMap**

 

```yaml
apiVersion: v1
data:
  async-query-volume: 'true'
  block-volume-snapshot: 'false'
  cnsmgr-suspend-create-volume: 'false'
  csi-auth-check: 'false'
  csi-internal-generated-cluster-id: 'true'
  csi-migration: 'false'
  csi-windows-support: 'false'
  list-volumes: 'true'
  listview-tasks: 'false'
  max-pvscsi-targets-per-vm: 'false'
  multi-vcenter-csi-topology: 'true'
  online-volume-extend: 'true'
  pv-to-backingdiskobjectid-mapping: 'false'
  topology-preferential-datastores: 'true'
  trigger-csi-fullsync: 'true'
  use-csinode-id: 'true'
kind: ConfigMap
metadata:
  annotations:
    objectset.rio.cattle.io/applied: >-
      H4sIAAAAAAAA/3xSwZLaMAz9F59ROmSBEK4999q7YiuJG8d2LTkss8O/dwzsEqYze8x70st7z/pQGO1vSmyDVye1bNVGGRRUpw+FfPEa/mZKF1iCyzOpk5KUSW1U54KeHiiwx8hjkCetPc9DAs4cyRvQiVDoPxHNFjDLCHokPb3i1gsljw4G8pRQyIB2mYUSWPM6OtshodwDrOCz9SacGTjHGNLKnLMsDy/8ii6WziDIU8F7dFyIGd8hLlwkBdNAwhApwTI/d+fsxMKiqZiG22SIwYXh8pwJ3ln/2QHQu5Bf5YgLSIAO9WT9YCxPoftDWqyBGWO0flgZ+tSGmKinRF4sOiivxhLSOpMkOwwPR312rjzoSigzFcoHQ6tSrxs12Zu3n8H3dviFsUQkwa/D8D7IrXEun3erTFIlGyqNIo4qG37cJBuz39fU76DfawO7uj5Aq48I1B4PbVs3te6w/NJhR+5buRF5VCdV7zpqWrPFRh9w2+CR9s2bwbp/a3cNUtdtscNDfyyiHm/n9nVLPaHkRMCCQlxpttXCcaRE1TKfMVGlw6zuexxRl+U7AXxhobnUpa7XfwEAAP//gdIJMTYDAAA
    objectset.rio.cattle.io/id: 7d552ef4-f5cd-4226-9c8a-e98699272cba
  creationTimestamp: '2023-09-07T11:22:03Z'
  labels:
    objectset.rio.cattle.io/hash: 24be79d1a7c6a17a8e573da2f3947aebb1aba6f8
  managedFields:
    - apiVersion: v1
      fieldsType: FieldsV1
      fieldsV1:
        f:data:
          .: {}
          f:async-query-volume: {}
          f:block-volume-snapshot: {}
          f:cnsmgr-suspend-create-volume: {}
          f:csi-auth-check: {}
          f:csi-internal-generated-cluster-id: {}
          f:csi-migration: {}
          f:csi-windows-support: {}
          f:list-volumes: {}
          f:listview-tasks: {}
          f:max-pvscsi-targets-per-vm: {}
          f:multi-vcenter-csi-topology: {}
          f:online-volume-extend: {}
          f:pv-to-backingdiskobjectid-mapping: {}
          f:topology-preferential-datastores: {}
          f:trigger-csi-fullsync: {}
          f:use-csinode-id: {}
        f:metadata:
          f:annotations:
            .: {}
            f:objectset.rio.cattle.io/applied: {}
            f:objectset.rio.cattle.io/id: {}
          f:labels:
            .: {}
            f:objectset.rio.cattle.io/hash: {}
      manager: agent
      operation: Update
      time: '2023-09-07T11:45:12Z'
  name: internal-feature-states.csi.vsphere.vmware.com
  namespace: vmware-system-csi
  resourceVersion: '1487213'
  uid: 3e5e7c80-7a04-4e1c-81eb-5c22911416ac
```

**Note : Once it is successfully deployed , we can use it as the provisioner in the storage class** 

1. Create storage class under the same namespace. Go to Storage → Storage Class. Click on Create, give a unique name.
    1. For non prod clusters, select Reclaim Policy as “Delete volumes and underlying device when volume claim is deleted“
    2. For prod clusters, select Reclaim Policy as “Retain the volume for manual cleanup“
    3. Select Allow Volume Expansion to “Enabled”
