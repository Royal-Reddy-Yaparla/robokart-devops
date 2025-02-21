            
### Install Prometheus in EKS cluster
  - using helm charts
    - add and update the prometheus-community Helm repository
      ```
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
      ```
    - prometheus is a stateful application , for stateful application 
      - Add EBS driver and storage class
        1. install EBS drivers 
          ```
            helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
            helm repo update

            helm upgrade --install aws-ebs-csi-driver \
            --namespace kube-system \
            aws-ebs-csi-driver/aws-ebs-csi-driver
          ```
        2. add storage class by sc.yaml 
            ```
              apiVersion: storage.k8s.io/v1
              kind: StorageClass
              metadata:
                name: ebs-sc
              provisioner: ebs.csi.aws.com
              volumeBindingMode: WaitForFirstConsumer

            ```

            ```
              kubectl apply -f sc.yaml
            ```
            - here k8 takes storage class by default , need to change default storage class
              - Mark the default StorageClass as non-default
                ```
                kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
                ```
                here **gps** is by default sc.
              - Mark a StorageClass as default
                ```
                  kubectl patch storageclass ebs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

                ```
              resource: https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/
      
      - provides permission to EC2 to EBS access
        IAM role *AmazonEBSCSIDeliverPolicy*

      - Check security groups
          create new inbound rule with *All TCP* and *0.0.0.0/0*

    - Install the charts
      ```
      helm install prometheus prometheus-community/prometheus
      ```
    - check
      ```
      kubectl get pods 
      ```
    - promethues has default clusterIP need modify as loadbalance to access to the internet
      ```
        kubectl get svc 
        kubectl edit svc <promethues_server>
      ```
      change from *ClusterIP* to *LoadBalancer*

### Install Grafana in EKS
  source: https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/
  
```
      helm repo add grafana https://grafana.github.io/helm-charts
      helm repo list
      helm repo update
      kubectl create namespace monitoring
      helm search repo grafana/grafana
      helm install my-grafana grafana/grafana --namespace monitoring 
      
```

  - promethues has default clusterIP need modify as loadbalance to access to the internet
      - method:1
        ```
          kubectl get svc 
          kubectl edit svc <grafana_server>
        ```
        change from *ClusterIP* to *LoadBalancer*
      - method:2
        ```
          helm install my-grafana grafana/grafana --namespace monitoring --set service.type="LoadBalancer"
          kubectl get svc
        ```
    

### Opensource Grafana dashboards
- grafana provides some default dashboards for monitoring