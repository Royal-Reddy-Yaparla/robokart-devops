# Fluentd Setup in Kubernetes Cluster

## Prerequisites
- Kubernetes Cluster running with `kubectl` access.
- An existing **Elasticsearch** cluster.
- `fluent/fluentd-kubernetes-daemonset:v1.14.1-debian-elasticsearch7-1.0` image available.

---

## 1. Create ServiceAccount for Fluentd
Fluentd requires a **ServiceAccount** to interact with the cluster securely.

**Note**: using a ServiceAccount helps manage and secure the interactions Fluentd has within the Kubernetes environment.

Create a file **`fluentd-sa.yaml`**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: elastic-stack
  labels:
    app: fluentd
```

Apply the configuration:
```sh
kubectl apply -f fluentd-sa.yaml
```

---

## 2. Create ClusterRole for Fluentd
Fluentd requires **get, list, and watch** permissions to access logs from pods and namespaces.

**Note**: Fluentd needs to collect logs from various pods and namespaces in the cluster. To do this, it requires permissions to access these resources. A ClusterRole provides these permissions at the cluster level, allowing Fluentd to perform actions like get, list, and watch on the necessary resources.

Create a file **`fluentd-clusterrole.yaml`**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
  labels:
    app: fluentd
rules:
- apiGroups: [""]
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
```

Apply the configuration:
```sh
kubectl apply -f fluentd-clusterrole.yaml
```

---

## 3. Create ClusterRoleBinding
Bind the **ClusterRole** to the **ServiceAccount** so Fluentd can access cluster logs.

A ClusterRoleBinding is necessary to grant the permissions defined in a ClusterRole to a user, group, or service account across the entire Kubernetes cluster. Here's why it's important:

	- Cluster-wide Permissions: Unlike RoleBindings, which are limited to a specific namespace, ClusterRoleBindings apply permissions cluster-wide. This is crucial for services like Fluentd that need to access resources across multiple namespaces.

	- Access Control: It helps in managing who can perform what actions on the cluster resources, ensuring that only authorized entities have the necessary permissions.

	- Security: By binding a ClusterRole to a ServiceAccount, you ensure that the service has the least privilege necessary to perform its tasks, enhancing the security posture of your cluster.

Create a file **`fluentd-clusterrolebinding.yaml`**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: elastic-stack
```

Apply the configuration:
```sh
kubectl apply -f fluentd-clusterrolebinding.yaml
```

---

## 4. Configure Fluentd Log Collection
Refer to the official Fluentd documentation on how to create this file:
	https://docs.fluentd.org/configuration/config-file

Create the Fluentd configuration file at:
```sh
mkdir -p etc
vi /etc/fluent.conf
```

Paste the following Fluentd configuration:
```xml
<label @FLUENT_LOG>
  <match fluent.**>
    @type null
    @id ignore_fluent_logs
  </match>
</label>

<source>
  @type tail
  @id in_tail_container_logs
  path "/var/log/containers/*.log"
  pos_file "/var/log/fluentd-containers.log.pos"
  tag "kubernetes.*"
  exclude_path /var/log/containers/fluent*
  read_from_head true
  <parse>
    @type "/^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/"
    time_format "%Y-%m-%dT%H:%M:%S.%NZ"
    unmatched_lines
    expression ^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$
    ignorecase false
    multiline false
  </parse>
</source>

<match **>
  @type elasticsearch
  @id out_es
  @log_level "info"
  include_tag_key true
  host "elasticsearch.elastic-stack.svc.cluster.local"
  port 9200
  path ""
  scheme http
  ssl_verify false
  ssl_version TLSv1_2
  user
  password xxxxxx
  reload_connections false
  reconnect_on_error true
  reload_on_failure true
  log_es_400_reason false
  logstash_prefix "fluentd"
  logstash_dateformat "%Y.%m.%d"
  logstash_format true
  index_name "logstash"
  type_name "fluentd"
  suppress_type_name true
  enable_ilm false
  ilm_policy_id logstash-policy
  <buffer>
    flush_thread_count 8
    flush_interval 5s
    chunk_limit_size 2M
    queue_limit_length 32
    retry_max_interval 30
    retry_forever true
  </buffer>
</match>
```

---

## 5. Deploy Fluentd as DaemonSet
Fluentd runs as a **DaemonSet** to collect logs from all nodes.

Use ServiceAccount fluentd in the configuration.

For the fluentd container, use the following image:
fluent/fluentd-kubernetes-daemonset:v1.14.1-debian-elasticsearch7-1.0

Use appropriate environment variables for the elasticsearch address and port above.
Also, add a variable FLUENT_ELASTICSEARCH_LOGSTASH_PREFIX with the value fluentd.

Mount the /var/log and /var/lib/docker/containers directories from the host to the pods, with the /var/lib/docker/containers directory mounted as read-only.

Also, mount the config file located under the fluentd/etc folder to the pod.

Create a file **`fluentd.yaml`**:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: elastic-stack
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1.14.1-debian-elasticsearch7-1.0
        env:
          - name: FLUENT_ELASTICSEARCH_HOST
            value: "elasticsearch.elastic-stack.svc.cluster.local"
          - name: FLUENT_ELASTICSEARCH_PORT
            value: "9200"
          - name: FLUENT_ELASTICSEARCH_SCHEME
            value: "http"
          - name: FLUENTD_SYSTEMD_CONF
            value: disable
          - name: FLUENT_CONTAINER_TAIL_EXCLUDE_PATH
            value: /var/log/containers/fluent*
          - name: FLUENT_ELASTICSEARCH_SSL_VERIFY
            value: "false"
          - name: FLUENT_CONTAINER_TAIL_PARSER_TYPE
            value: /^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/ 
          - name: FLUENT_ELASTICSEARCH_LOGSTASH_PREFIX
            value: "fluentd"
        resources:
          limits:
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: configpath
          mountPath: /fluentd/etc
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: configpath
        hostPath:
          path: /root/fluentd/etc
```

Apply the configuration:
```sh
kubectl apply -f fluentd.yaml
```

---

## 6. Verify Fluentd Logs
Check if Fluentd is running:
```sh
kubectl get pods -n elastic-stack
```

Check Fluentd logs:
```sh
kubectl logs -l app=fluentd -n elastic-stack
```

Verify logs are forwarded to **Elasticsearch**:
```sh
curl -X GET "http://<NODE_IP>:30200/_search?q=*:*&size=10000&pretty"
```

---

## Conclusion
By following this guide, we have:
1. Created a **ServiceAccount** for Fluentd.
2. Defined a **ClusterRole** and **ClusterRoleBinding** for access control.
3. Configured Fluentd to collect logs and send them to **Elasticsearch**.
4. Deployed Fluentd as a **DaemonSet**.
5. Verified that Fluentd is forwarding logs to Elasticsearch.

Now, Fluentd will automatically collect logs from all pods and send them to **Elasticsearch**, where they can be visualized in **Kibana**. 🚀