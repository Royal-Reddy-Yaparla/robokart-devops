
# Provison VPC and EKS by using custom modules

This Terraform module provisions an **Amazon EKS (Elastic Kubernetes Service) cluster** with worker nodes using AWS IAM roles, VPC configuration, and node groups.

## Features

- Creates an **EKS cluster** with a specified version.
- Configures **IAM roles and policies** for both the control plane and worker nodes.
- Supports **multiple node groups** with customizable scaling options.
- Provisions a **VPC with public and private subnets**.
- Supports **VPC peering** if required.
- Stores Terraform state remotely using an **S3 backend**.

---

## Architecture

This module consists of two submodules:

1. **VPC Module** (`modules/vpc`)
   - Creates a **VPC** with specified CIDR blocks.
   - Provisions **public and private subnets**.
   - Supports **VPC peering** if needed.

2. **EKS Module** (`modules/eks`)
   - Creates an **EKS cluster** using IAM roles.
   - Deploys **node groups** for running workloads.
   - Attaches necessary **IAM policies** for node communication.

---

## Terraform Resources Created

This module provisions the following AWS resources:

### **VPC Resources**
- `aws_vpc` – Creates a Virtual Private Cloud (VPC).
- `aws_subnet` – Public and private subnets in different availability zones.
- `aws_vpc_peering_connection` – (Optional) Establishes VPC peering if enabled.

### **EKS Cluster**
- `aws_eks_cluster` – Creates an EKS cluster.
- `aws_iam_role` – IAM role for the EKS control plane.
- `aws_iam_role_policy_attachment` – Attaches EKS cluster policies.
- `aws_eks_node_group` – Defines node groups with scaling configurations.

---

## **Usage**

### 1. Clone the Repository

```bash
git clone <repository-url>
cd terraform-eks-module
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply -auto-approve
```

### 5. Destroy the Infrastructure (if needed)

```bash
terraform destroy -auto-approve
```

---

## **Inputs**

| Variable Name         | Type   | Default Value         | Description                                      |
|----------------------|--------|---------------------|--------------------------------------------------|
| `cluster_name`       | string | `"robokart"`        | Name of the EKS cluster.                        |
| `cluster_version`    | string | `"1.30"`           | Kubernetes version for EKS.                     |
| `node_groups`        | map    | See below          | Configuration for EKS node groups.              |
| `cidr_block`         | string | `"10.0.0.0/16"`    | CIDR block for the VPC.                         |
| `cidr_public`        | list   | `["10.0.1.0/24", "10.0.2.0/24"]` | Public subnet CIDR ranges. |
| `cidr_private`       | list   | `["10.0.11.0/24", "10.0.12.0/24"]` | Private subnet CIDR ranges. |
| `is_peering_required` | bool   | `false`              | Whether VPC peering is required.                |
| `accepters_vpc_id`   | string | `""`                | VPC ID for peering connection.                  |

### **Node Group Configuration**

```hcl
node_groups = {
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

---

## **Outputs**

| Output Name         | Description                       |
|---------------------|---------------------------------|
| `vpc_id`           | ID of the created VPC.         |
| `cluster_endpoint` | API server endpoint for EKS.   |
| `cluster_name`     | Name of the created EKS cluster. |

---

## **Terraform Backend Configuration**
This module uses an **S3 backend** for remote state management.

```hcl
terraform {
  backend "s3" {
    bucket = "eks-control-plane-s3"
    key    = "LockID"
    region = "us-east-1"
  }
}
```

---
### Connect to EKS Cluster
```sh
aws eks update-kubeconfig --name robokart --region <your-region>
```
✅ This allows you to interact with your EKS cluster using `kubectl`.  