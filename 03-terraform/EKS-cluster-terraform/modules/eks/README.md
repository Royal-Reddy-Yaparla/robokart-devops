# **EKS Cluster Terraform Module**  

This module provisions an **Amazon EKS (Elastic Kubernetes Service) cluster** along with an **IAM role for the cluster** and **node groups for worker nodes**.  

---

## **📌 Features**  
- Creates an **EKS Cluster** with the provided name and Kubernetes version.  
- Assigns an **IAM Role** to the cluster with the required policies.  
- Configures **worker node groups** using a flexible variable configuration.  
- Attaches necessary **IAM policies** to enable proper cluster and node group functioning.  

---

## **📜 Terraform Resources Explanation**  

### **1️⃣ EKS Cluster IAM Role**
```hcl
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}
```
✔ **Creates an IAM role** for the EKS cluster.  
✔ Allows EKS to assume the role via the `sts:AssumeRole` action.  

---

### **2️⃣ Attach Required IAM Policies for Cluster**
```hcl
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}
```
✔ **Attaches AmazonEKSClusterPolicy** to the IAM role for cluster permissions.  

---

### **3️⃣ Create EKS Cluster**
```hcl
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}
```
✔ **Creates the EKS cluster** with the specified name, version, and IAM role.  
✔ **Configures networking** by attaching the cluster to the provided subnets.  

---

### **4️⃣ EKS Node Group IAM Role**
```hcl
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
```
✔ **Creates an IAM role for worker nodes** to interact with the cluster and AWS services.  

---

### **5️⃣ Attach Required IAM Policies for Worker Nodes**
```hcl
resource "aws_iam_role_policy_attachment" "node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node.name
}
```
✔ Attaches necessary policies to allow worker nodes to:  
✅ Join the EKS cluster (**AmazonEKSWorkerNodePolicy**)  
✅ Use the AWS VPC CNI plugin (**AmazonEKS_CNI_Policy**)  
✅ Pull images from ECR (**AmazonEC2ContainerRegistryReadOnly**)  

---

### **6️⃣ Create EKS Node Group**
```hcl
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_policy
  ]
}
```
✔ **Creates a scalable EKS node group** with the desired instance types, capacity, and scaling configuration.  

---

## **📥 Inputs**  
| Variable Name   | Type   | Default Value | Description |
|----------------|--------|--------------|-------------|
| `cluster_name`  | string | `"robokart"`  | Name of the EKS cluster. |
| `cluster_version` | string | `"1.30"` | Kubernetes version for the cluster. |
| `node_groups` | map(object) | (See Below) | Node group configuration. |
| `subnet_ids` | list(string) | `[]` | List of subnet IDs for EKS. |

### **📌 Example `node_groups` Default Value**
```hcl
default = {
  general = {
    instance_types = ["t3.medium"]
    capacity_type  = "SPOT"
    scaling_config = {
      desired_size = 2
      max_size     = 4
      min_size     = 2
    }
  }
}
```
✔ **Defines a single node group** named `general`.  
✔ Uses `t3.medium` instances on **SPOT pricing** for cost efficiency.  
✔ Configures **auto-scaling** with min: `2`, max: `4`, desired: `2`.  

---

## **📤 Outputs**  
| Output Name     | Description |
|----------------|-------------|
| `cluster_endpoint` | EKS cluster API server endpoint. |
| `cluster_name` | Name of the created EKS cluster. |

### **Example Usage**
After applying the Terraform module, retrieve outputs using:  
```sh
terraform output cluster_endpoint
terraform output cluster_name
```

---

## **🚀 How to Use This Module**
### **1️⃣ Initialize Terraform**
```sh
terraform init
```
### **2️⃣ Apply Configuration**
```sh
terraform apply -auto-approve
```
### **3️⃣ Get Cluster Details**
```sh
terraform output
```
### **4️⃣ Connect to EKS Cluster**
```sh
aws eks update-kubeconfig --name robokart --region <your-region>
```
✅ This allows you to interact with your EKS cluster using `kubectl`.  

---

🎯 **Best Practices Followed:**  
✔ Modular approach  
✔ Security best practices (IAM roles, policies)  
✔ Scalability with auto-scaling node groups  

---

🚀 **Deploy your Kubernetes cluster in AWS using Terraform effortlessly!** 🎯  
📌 **Maintainer:** *Royal Reddy*  
📌 **Version:** `1.0.0`  