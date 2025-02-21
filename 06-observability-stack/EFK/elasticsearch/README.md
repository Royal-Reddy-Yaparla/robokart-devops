## Steps to Deploy Elasticsearch  

### 1. Create Namespace  
Create a new namespace `elastic-stack` and switch the context to it:  
```sh
kubectl create namespace elastic-stack
kubectl config set-context --current --namespace=elastic-stack
```

### 2. Create Persistent Volume  
Create a **Persistent Volume** (PV) to store Elasticsearch data persistently:  

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-elasticsearch
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/elasticsearch
```

Apply the PV:  
```sh
kubectl apply -f pv.yaml
```

### 3. Create Service  
Expose **Elasticsearch StatefulSet** within the cluster using a **NodePort service**:  

```yaml
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: elastic-stack
spec:
  selector:
    app: elasticsearch
  ports:
    - port: 9200
      targetPort: 9200
      nodePort: 30200
      name: port1
    - port: 9300
      targetPort: 9300
      nodePort: 30300
      name: port2
  type: NodePort
```

Apply the Service:  
```sh
kubectl apply -f elasticsearch-service.yaml
```

### 4. Deploy Elasticsearch using StatefulSet  
Create a **StatefulSet** to manage the Elasticsearch pods:  

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: elastic-stack
spec:
  serviceName: "elasticsearch"
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
        ports:
        - containerPort: 9200
          name: port1
        - containerPort: 9300
          name: port2
        env:
        - name: discovery.type
          value: single-node
        - name: xpack.security.enabled
          value: "false"
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
      initContainers:
      - name: fix-permissions
        image: busybox
        command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
  - metadata:
      name: es-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
```

Apply the StatefulSet:  
```sh
kubectl apply -f elasticsearch-statefulset.yaml
```

### 5. Verify Deployment  
Check if the pods are running:  
```sh
kubectl get pods -n elastic-stack
```

Check if the service is running:  
```sh
kubectl get svc -n elastic-stack
```

### 6. Access Elasticsearch UI  
Once the deployment is successful, you can access Elasticsearch using the **NodePort**:  

```sh
http://<NODE_IP>:30200
```

### 7. Test Elasticsearch  
Run the following **curl** command to check if Elasticsearch is working:  
```sh
curl -X GET "http://<NODE_IP>:30200"
```

You should receive a response with Elasticsearch details.  

---

## Cleanup  
To delete the Elasticsearch deployment, run:  
```sh
kubectl delete namespace elastic-stack
```

---
