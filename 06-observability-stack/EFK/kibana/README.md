# **Kibana Deployment and Configuration in Kubernetes**

Kibana serves as a powerful front-end to Elasticsearch, allowing users to visualize the stored logs through various types of charts and graphs, which can be organized into dashboards for easy access and analysis.

## **Prerequisites**
- A running **Kubernetes cluster**
- `kubectl` configured with appropriate permissions
- Elasticsearch deployed and accessible
- **elastic-stack namespace** created (`kubectl create namespace elastic-stack`)

---

## **Step 1: Deploy Kibana in Kubernetes**
We will create a **Kibana deployment** with the following specifications:
- **Name:** `kibana`
- **Namespace:** `elastic-stack`
- **Label:** `kibana`
- **Replicas:** `1`
- **Image:** `docker.elastic.co/kibana/kibana:8.13.0`
- **Container Port:** `5601`

### **Create the deployment file**
Create a file named **`kibana-deployment.yaml`** and add the following configuration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: elastic-stack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.13.0
        ports:
        - containerPort: 5601
```

### **Apply the deployment**
Run the following command to deploy Kibana:

```bash
kubectl apply -f kibana-deployment.yaml
```

---

## **Step 2: Expose Kibana Using a Kubernetes Service**
To access Kibana from outside the cluster, we will create a **NodePort service**.

- **Service Name:** `kibana`
- **Namespace:** `elastic-stack`
- **Service Type:** `NodePort`
- **Container Port:** `5601`
- **NodePort:** `30601`

### **Create the service file**
Create a file named **`kibana-service.yaml`** and add the following configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: elastic-stack
spec:
  type: NodePort
  selector:
    app: kibana
  ports:
  - protocol: TCP
    port: 5601
    targetPort: 5601
    nodePort: 30601
```

### **Apply the service**
Run the following command:

```bash
kubectl apply -f kibana-service.yaml
```

---

## **Step 3: Access Kibana's Dashboard**
Once deployed, Kibana can be accessed using the **NodePort**.

### **Find the Node IP**
Run the following command to get the external IP of any worker node:

```bash
kubectl get nodes -o wide
```

Find the **EXTERNAL-IP** of any worker node.

### **Access Kibana**
In a web browser, open:

```
http://<NODE_IP>:30601
```

For example, if your worker node's IP is `192.168.1.100`, access Kibana at:

```
http://192.168.1.100:30601
```

---

## **Step 4: Verify the Deployment**
Check if the Kibana pod is running:

```bash
kubectl get pods -n elastic-stack
```

Check the Kibana logs:

```bash
kubectl logs -l app=kibana -n elastic-stack
```

Check the Kibana service:

```bash
kubectl get svc -n elastic-stack
```

---
