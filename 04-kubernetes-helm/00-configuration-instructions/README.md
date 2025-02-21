### Helm Configuration

```
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
```

**resource**:  https://helm.sh/docs/intro/install/


### EBS drivers Install by Helm


Helm
Add the aws-ebs-csi-driver Helm repository.
```    
    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
    helm repo update
```
Install the latest release of the driver.
```
    helm upgrade --install aws-ebs-csi-driver \
        --namespace kube-system \
        aws-ebs-csi-driver/aws-ebs-csi-driver
```


**resource**: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md


### Attach Policy attach to Nodes IAM role for EBS csi driver access
    - AmazonEBSCSIDriverPolicy
    - AmazonEC2FullAccess
    
### Create storage class

```
    kubectl create -f EBS-storage-class.yaml
```    

### Create Namespace
```
    kubectl apply -f namespace.yaml
```

### Change Default namespace 
```
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

```
kubens robokart
```

**resource**: https://github.com/ahmetb/kubectx


### K9 install for UI view of pods

```
curl -sS https://webinstall.dev/k9s | bash

```
steps:

    - take new tab

    - command k9s


**resource**:  https://github.com/derailed/k9s





```
sudo yum install httpd-tools -t
ab -n 100000 -c 1000 -k http://robokart.royalreddy.site/


```

---
Ingres config

- ec2 full access IAM role attach to Nodes IAM 



resource: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/

- Create an IAM OIDC provider. You can skip this step if you already have one for your cluster.
```
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster robokart-dev \
    --approve

```
- If our cluster is in any other region
```
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

```

- Create an IAM policy named AWSLoadBalancerControllerIAMPolicy. If you downloaded a different policy, replace iam-policy with the name of the policy that you downloaded.

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

Create an IAM role and Kubernetes ServiceAccount for the LBC. Use the ARN from the previous step.
```
eksctl create iamserviceaccount \
--cluster=robokart-dev \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::258860052228:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--region us-east-1 \
--approve

```

- Add the EKS chart repo to Helm

```
helm repo add eks https://aws.github.io/eks-charts
```

- Helm install command for clusters with IRSA:

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=robokart-dev --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

```

- we check 
```
kubectl get pods -n kube-system
```

- we need to provide annotation
sources: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/examples/echo_server/

```
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/tags: Environment=dev,Team=test,Project=robokart

```

```
alb.ingress.kubernetes.io/group.name: robokart
```
Note: here we are grouping same servers to avoid seperate load balancer to each

---

To install **wrk** on Amazon Linux, you can follow these steps:

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