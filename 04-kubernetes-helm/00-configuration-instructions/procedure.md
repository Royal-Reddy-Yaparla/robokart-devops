## Robokart Project Deployment

This guide explains the steps to deploy the Robokart project using Kubernetes and Helm.

---

### **1. Helm Installation**
Helm is used for managing Kubernetes applications. To install Helm:
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
**Resource**: [Helm Documentation](https://helm.sh/docs/intro/install/)

---

### **2. Install AWS EBS CSI Drivers**
To manage persistent storage for your Kubernetes cluster using AWS EBS:

1. Add the Helm repository for the AWS EBS CSI Driver:
   ```bash
   helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
   helm repo update
   ```

2. Install the latest release of the AWS EBS CSI Driver:
   ```bash
   helm upgrade --install aws-ebs-csi-driver \
       --namespace kube-system \
       aws-ebs-csi-driver/aws-ebs-csi-driver
   ```
**Resource**: [AWS EBS CSI Driver GitHub](https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md)

---

### **3. Attach IAM Policies to Node Role**
For the EBS CSI Driver to access AWS resources, attach the following IAM policies to the node role:
- `AmazonEBSCSIDriverPolicy`
- `AmazonEC2FullAccess`

---

### **4. Create a Storage Class**
Apply the storage class configuration for AWS EBS:
```bash
kubectl create -f EBS-storage-class.yaml
```

---

### **5. Create Namespace**
Create a dedicated namespace for the Robokart project:
```bash
kubectl apply -f namespace.yaml
```

---

### **6. Set the Default Namespace**
Use `kubectx` and `kubens` for easy namespace management:
1. Install `kubectx` and `kubens`:
   ```bash
   sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
   sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
   sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
   ```

2. Switch to the `robokart` namespace:
   ```bash
   kubens robokart
   ```
**Resource**: [kubectx Repository](https://github.com/ahmetb/kubectx)

---

### **7. Install K9s for UI View**
K9s is a terminal-based UI for managing Kubernetes clusters:
```bash
curl -sS https://webinstall.dev/k9s | bash
```
- Launch K9s:
  ```bash
  k9s
  ```
**Resource**: [K9s GitHub](https://github.com/derailed/k9s)

---

---
---

### AWS Load Balancer Controller (ALB) Setup
The AWS Load Balancer Controller is required for managing Application Load Balancers (ALBs) in Kubernetes.

#### ** Create IAM OIDC Provider**
Associate an OIDC provider with your cluster:
```bash
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster robokart-dev \
    --approve
```
If your cluster is in a different region, ensure the `--region` value matches your setup.

#### ** Download IAM Policy**
Download the IAM policy required for the Load Balancer Controller:
```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

#### **Create IAM Policy**
Create a new IAM policy named `AWSLoadBalancerControllerIAMPolicy`:
```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

#### **Create ServiceAccount with IAM Role**
Create an IAM role and Kubernetes ServiceAccount for the controller:
```bash
eksctl create iamserviceaccount \
    --cluster=robokart-dev \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region us-east-1 \
    --approve
```

#### **Add EKS Helm Chart Repository**
Add the EKS Helm chart repository:
```bash
helm repo add eks https://aws.github.io/eks-charts
```

#### **Install AWS Load Balancer Controller**
Install the AWS Load Balancer Controller in the `kube-system` namespace:
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=robokart-dev \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller
```

#### **Verify Deployment**
Check the status of the Load Balancer Controller pods:
```bash
kubectl get pods -n kube-system
```

#### **2.8 Ingress Annotations for ALB**
Add the following annotations to your Ingress configuration for ALB setup:
```yaml
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/tags: Environment=dev,Team=test,Project=robokart
alb.ingress.kubernetes.io/group.name: robokart
```
**Note**: Using `alb.ingress.kubernetes.io/group.name` groups servers to share the same load balancer and avoid creating separate ALBs.

**Resource**: [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)

---

### **Storage Setup**
1. **Install AWS EBS CSI Driver**:
   Add the Helm repository and install the AWS EBS CSI driver:
   ```bash
   helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
   helm repo update
   helm upgrade --install aws-ebs-csi-driver \
       --namespace kube-system \
       aws-ebs-csi-driver/aws-ebs-csi-driver
   ```

2. **Create Storage Class**:
   Apply the storage class configuration:
   ```bash
   kubectl create -f EBS-storage-class.yaml
   ```
---

### **Deploy Application Components**
Follow the sequence to deploy project components, starting with the ingress setup, as web components rely on it.

1. **Web Component**:
   - Deploy Ingress with ALB annotations.
   - Deploy the web application using Helm or `kubectl apply`.

2. **Backend and Database**:
   - Deploy services (`catalog`, `cart`, `user`, `shipping`, `payment`).
   - Deploy databases (`MongoDB`, `MySQL`, `Redis`, `RabbitMQ`).

---

### **Verification**
1. **Check Pods**:
   ```bash
   kubectl get pods -n robokart
   ```

2. **Access Application**:
   Verify the ingress setup by accessing the domain:
   ```
   http://robokart.royalreddy.site
   ```

---
### Apply load

### 1. **Install Dependencies**
Amazon Linux does not have `wrk` available in its default repositories, so you need to build it from source. Install the required dependencies:

```bash
sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install gcc git libgcc glibc-devel -y
```

---

### 2. **Clone the `wrk` Repository**
Clone the official `wrk` repository from GitHub:

```bash
git clone https://github.com/wg/wrk.git
cd wrk
```

---

### 3. **Build `wrk`**
Run the build command to compile `wrk`:

```bash
make
```

---

### 4. **Move the Binary to `/usr/local/bin`**
Move the compiled binary to a directory in your `PATH`:

```bash
sudo mv wrk /usr/local/bin/
```

---

### 5. **Verify Installation**
Check if `wrk` is successfully installed:

```bash
wrk --version
```

---

### 6. **Run a Test**
You can now use `wrk` to perform load testing. For example:

```bash
wrk -t1000 -c1000 -d300s http://robokart.royalreddy.site

wrk -t1000 -c1000 -d120s http://robokart.royalreddy.site/shipping

```

- `-t`: Number of threads.
- `-c`: Number of concurrent connections.
- `-d30s`: Duration of the test.

---

### Troubleshooting
If you encounter errors during the build process, ensure you have all required dependencies installed and the `make` command available. You can also clean the repository and rebuild using:

```bash
make clean
make
```