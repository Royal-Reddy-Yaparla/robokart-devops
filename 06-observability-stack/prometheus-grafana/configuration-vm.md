
## prometheus - grafana  

<img src="./images/prometheus-grafana.png" alt="Getting started" />

### 1. **Prometheus**

- **Time Series Database**: This is the core component of Prometheus, where all the time-series data collected from exporters (e.g., `node_exporter`) is stored.
- **HTTPD (HTTP Daemon)**: Prometheus provides an HTTP API endpoint for querying data, which allows users and applications to interact with the stored metrics.
- **Service Discovery**: Prometheus uses service discovery mechanisms to automatically find and scrape targets (e.g., Node Exporters) at regular intervals.
- **Alert Manager**: This component handles alerts based on the rules defined in Prometheus. It sends notifications via different channels (email, Slack, PagerDuty, etc.).

### 2. **Node Exporters**

- These are lightweight agents installed on the nodes (e.g., Node-1 and Node-2) to expose system metrics like CPU usage, memory utilization, disk I/O, and network statistics.
- Node Exporters expose these metrics on an HTTP endpoint, which Prometheus scrapes periodically.

### 3. **User Interaction**

- Users can access raw metrics via Prometheus.
- Users can visualize metrics via Grafana.

### 4. **Data Flow**

- Node Exporters send data in periodic intervals (via scraping, not pushing) to Prometheus.
- Prometheus collects this data using HTTP requests to the endpoints exposed by Node Exporters.
- Prometheus stores this data in the time-series database for analysis and querying.

### **Grafana**:

- **Purpose**: Grafana is a visualization tool used to create interactive dashboards and visualizations for metrics stored in Prometheus.
- **Connection**:
    - Grafana queries the **Prometheus Time Series Database** using PromQL (Prometheus Query Language) through its HTTP API.
    - The data fetched from Prometheus is used to generate customizable charts and dashboards for monitoring system performance.

**User Interaction**: Users access Grafana via its web UI to explore, analyze, and visualize metrics.

- Configuration
    - **Prometheus**
        
        ### **Prometheus-server:**
        
        - EC2
            - instance type: t3.medium
            - 30GB
        - installation
            - go to /opt
            - download from
                - https://prometheus.io/download/
                
                ```bash
                wget https://github.com/prometheus/prometheus/releases/download/v3.0.1/prometheus-3.0.1.linux-amd64.tar.gz
                tar -xf prometheus-3.0.1.linux-amd64.tar.gz
                mv prometheus-3.0.1.linux-amd64.tar.gz prometheus
                ```
                
            - go to /prometheus
                - there are two file
                    - `prometheus` which is the script file, we run the Prometheus, but we make it service
                    - `prometheus.yaml`  which configuration file
                - Prometheus service
                    - vim `/etc/systemd/system/prometheus.service`
                    
                    ```bash
                    [Unit]
                    Description=prometheus service.
                    [Service]
                    ExecStart= /opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus/prometheus.yml
                    [Install]
                    WantedBy=multi-user.target
                    ```
                    
                - start service
                    
                    ```bash
                    systemctl start prometheus
                    systemctl enable prometheus
                    systemctl status prometheus
                    ```
                    
                - service will run on port 9090
                - we can access HTTP://<IP>:9090
                - Prometheus server collects own and target servers metrics
                    
                    ```bash
                    few promeql commands
                    - up 
                    - up[2m]
                    ```
                    
                - see `prometheus.yaml` file to know configuration and add targets
        
        ### **Prometheus-node:**
        
        - EC2
            - instance type: t2.micro
            - 10GB
        - installation of node exporter
            - go to /opt
            - download from  **node_exporter**
                - https://prometheus.io/download/
            
            ```bash
            wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
            tar -xf node_exporter-1.8.2.linux-amd64.tar.gz
            mv node_exporter-1.8.2.linux-amd64.tar.gz node_exporter
            ```
            
            - exporter file in repo to run , but implementing as service
                - Prometheus_node_exporter service
                    - vim `/etc/systemd/systen/`node_exporter`.service`
                    
                    ```bash
                    [Unit]
                    Description=node_exporter service.
                    [Service]
                    ExecStart= /opt/node_exporter/node_exporter
                    [Install]
                    WantedBy=multi-user.target
                    ```
                    
                - start service
                    
                    ```bash
                    systemctl start node_exporter
                    systemctl enable node_exporter
                    systemctl status node_exporter
                    ```
                    
                - port will be 9100
                    - http://<IP>:9100/metrics
                    
                    show metrics dynamically
                    
        
        Make the connection between master and nord_exporter
        
        we have to update node_exporter IP in prometheus master prometheus.yaml file
        
        ```yaml
        # my global config
        global:
          scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
          evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
          # scrape_timeout is set to the global default (10s).
        
        # Alertmanager configuration
        alerting:
          alertmanagers:
            - static_configs:
                - targets:
                  # - alertmanager:9093
        
        # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
        rule_files:
          # - "first_rules.yml"
          # - "second_rules.yml"
        
        # A scrape configuration containing exactly one endpoint to scrape:
        # Here it's Prometheus itself.
        scrape_configs:
          # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
          - job_name: "prometheus"
            # metrics_path defaults to '/metrics'
            # scheme defaults to 'http'.
        
            static_configs:
              - targets: ["localhost:9090"]
        
          - job_name: "node-exporter"
            static_configs:
              - targets: ["<private_ip>:9100"]
        
        ```
        
        Note: restart Prometheus.service and refresh webpage and up check there node_exporter
        
    - **grafana**
        
         a nice tool . it can get the data from multiple resources. Prometheus is one of the resources, grafana takes data from Prometheus and visualizes the data in different ways
        
        simple way: 
        
        - Prometheus is data storage
        - grafana visualize tool
        
        ### installation:
        
        - source: https://grafana.com/docs/grafana/latest/setup-grafana/installation/redhat-rhel-fedora/
        - install in Prometheus server for reduce latency
        
        ```bash
        systemctl start grafana-server
        systemctl enable grafana-server
        systemctl status grafana-server
        ```
        
        - access HTTP://<IP>:3000
            - username: admin password: admin
            - select connection → data source → Prometheus → URL (Prometheus itself )
            - here we can run prometheus query in grafana
            - select prometheus in connection in grafana
    - **dynamic scrapping**
        - in cloud and dynamic environments IP addresses are temporary
        - The IAM credentials used must have the `ec2:DescribeInstances` permission to discover scrape targets, and may optionally have the `ec2:DescribeAvailabilityZones` permission if you want the availability zone ID available as a label
        - installation of node exporter
            - go to /opt
            - download from  **node_exporter**
                - https://prometheus.io/download/
            
            ```bash
            wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
            tar -xf node_exporter-1.8.2.linux-amd64.tar.gz
            mv node_exporter-1.8.2.linux-amd64.tar.gz node_exporter
            ```
            
            - exporter file in repo to run , but implementing as service
                - Prometheus_node_exporter service
                    - vim `/etc/systemd/systen/`node_exporter`.service`
                    
                    ```bash
                    [Unit]
                    Description=node_exporter service.
                    [Service]
                    ExecStart= /opt/node_exporter/node_exporter
                    [Install]
                    WantedBy=multi-user.target
                    ```
                    
                - start service
                    
                    ```bash
                    systemctl start node_exporter
                    systemctl enable node_exporter
                    systemctl status node_exporter
                    ```
                    
                - port will be 9100
                    - http://<IP>:9100/metrics
                    
                    show metrics dynamically
                    
        
        Make the connection between master and nord_exporter
        
        we have to update node_exporter IP in Prometheus master Prometheus.yml file
        
        ```yaml
        # my global config
        global:
          scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
          evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
          # scrape_timeout is set to the global default (10s).
        
        # Alertmanager configuration
        alerting:
          alertmanagers:
            - static_configs:
                - targets:
                  # - alertmanager:9093
        
        # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
        rule_files:
          # - "first_rules.yml"
          # - "second_rules.yml"
        
        # A scrape configuration containing exactly one endpoint to scrape:
        # Here it's Prometheus itself.
        scrape_configs:
          # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
          - job_name: "prometheus"
            # metrics_path defaults to '/metrics'
            # scheme defaults to 'http'.
        
            static_configs:
              - targets: ["localhost:9090"]
        
          - job_name: "ec2-scrapping"
            ec2_sd_configs:
              - region: us-east-1
                port: 9100
        ```
        
        Note: restart Prometheus.service and refresh webpage and up check there node_exporter
        
        - resources:
            - https://prometheus.io/docs/prometheus/latest/configuration/configuration/#ec2_sd_config
            - https://gist.github.com/anthonydahanne/014ab52f69c3e50aad8bff65d4b5ddf0
            - update in prometheus.yaml
            
            ```bash
            - job_name: ec2-scrapping
            	ec2_sd_configs:
            	      - region: us-east-1
            	        port: 9100
            ```
            
            - restart Prometheus
            - we will see the list of  all ec2 here in Grafana and Prometheus , check once
            - we can filter, instances
                - but here need to give the below tags name for ec2-instance
                
                ```bash
                # my global config
                global:
                  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
                  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
                  # scrape_timeout is set to the global default (10s).
                
                # Alertmanager configuration
                alerting:
                  alertmanagers:
                    - static_configs:
                        - targets:
                          # - alertmanager:9093
                
                # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
                rule_files:
                  # - "first_rules.yml"
                  # - "second_rules.yml"
                
                # A scrape configuration containing exactly one endpoint to scrape:
                # Here it's Prometheus itself.
                scrape_configs:
                  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
                  - job_name: "prometheus"
                    # metrics_path defaults to '/metrics'
                    # scheme defaults to 'http'.
                
                    static_configs:
                      - targets: ["localhost:9090"]
                
                  - job_name: "ec2-scrapping"
                    ec2_sd_configs:
                      - region: us-east-1
                        port: 9100
                        filters:
                          - name: "tag:monitoring"
                            values:
                              - true
                ```
                
                - restart Prometheus
    - **relabeling**
        
        Relabeling in Prometheus is a powerful feature that allows you to modify, add, or drop labels during the scraping process. This is particularly useful when you want to enhance the metadata associated with your metrics or control how metrics are stored in Prometheus.
        
        https://prometheus.io/docs/prometheus/latest/configuration/configuration/#ec2_sd_config 
        
        sample:
        
        ```bash
        - job_name: "ec2-scrapping"
        		ec2_sd_configs:
        		- region: us-east-1
        			port: 9100
        			filters:
        		- name: "tag:monitoring"
        			values:
        			  - true
        		 relabel_configs:
        		- source_labels: [__meta_ec2_public_ip]
        			target_label: public_ip
        		- source_labels: [__meta_ec2_instance_id]
        			target_label: instance_id
        ```
        
        add in prometheus.yml and restart the service
        
    - **Prometheus alert**
        
        according to the monitoring status, send the alert mail to the respective team or person, here we have to few configuration for it
        
        step1️⃣ : raise the alert in the system.
        
        - we have to add the alert rule, prometheus.yml, we can pass alert rules by a single file , or we can send it as a group of files
            
            source: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
            
        - a simple instance down the file to raise an alert , we need update this file info in prometheus.yml  , it check four times ( 1m-60s/15s)
            
            ```yaml
            groups:
            - name: InstanceDown
              rules:
              - alert: HighRequestLatency
                expr: up < 1
                for: 1m
                labels:
                  severity: critical
                annotations:
                  summary: InstanceDownAlert
            ```
            
            in prometheus.yml
            
            ```yaml
            # my global config
            global:
              scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
              evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
              # scrape_timeout is set to the global default (10s).
            
            # Alertmanager configuration
            alerting:
              alertmanagers:
                - static_configs:
                    - targets:
                      # - alertmanager:9093
            
            # Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
            rule_files:
              - "alert_rule/*.yaml
            ```
            
            restart Prometheus. we can check in **alerts** in P**rometheus web.**
            
        
    - **alert manager**
        
        takes some action for raised alerts, like sending notifications.
        
        install alert manager
        
        source: https://github.com/prometheus/alertmanager/releases/download/v0.28.0-rc.0/alertmanager-0.28.0-rc.0.linux-amd64.tar.gz
        
        ```bash
        wget https://github.com/prometheus/alertmanager/releases/download/v0.28.0-rc.0/alertmanager-0.28.0-rc.0.linux-amd64.tar.gz
        tar -xf alertmanager-0.28.0-rc.0.linux-amd64.tar.gz
        mv alertmanager-0.28.0-rc.0.linux-amd64 alertmanager
        ```
        
        make it as service
        
        - vim `/etc/systemd/system/`alertmanager`.service`
        
        ```bash
        [Unit]
        Description=node_exporter service.
        [Service]
        WorkingDirectory=/opt/alertmanager
        ExecStart= /opt/alertmanager/alertmanager
        [Install]
        WantedBy=multi-user.target
        ```
        
        start the service
        
        ```bash
        systemctl start alertmanager
        systemctl enable alertmanager
        systemctl status alertmanager
        
        systemctl daemon-reload
        systemctl restart alertmanager
        ```
        
        check-in browser HTTP://<IP>:9093
        
        configure alert manager in Prometheus
        
        ```bash
        # Alertmanager configuration
        alerting:
          alertmanagers:
            - static_configs:
                - targets:
                  - localhost:9093
        ```
        
        restart Prometheus service 
        
    - **Notification**
        
        source: https://prometheus.io/docs/alerting/latest/configuration/
        
        AWS SES:
        
        - create aws SES and SMPT credentials
        
        https://prometheus.io/docs/alerting/latest/configuration/#email_config
        
        in alertmanager.yaml
        
        ```bash
        email_configs:
              - smarthost: 'smtp.gmail.com:587'
                auth_username: '<your email id here>'
                auth_password: "<your app password here>"
                from: '<your email id here>'
                to: '<receiver's email id here>'
                headers:
                  subject: 'Prometheus Mail Alerts'
        ```
        
        update accordingly 
        
        restart the alert manager service
        
        Slack:
        
        we can try
        
    - **PromQL**
        - data types
            
            ```bash
            up
            up[2m]
            up{job="ec2-scrappijng"}
            up{job!="ec2-scrappijng"}
            up{job="ec2-scrappijng",privateip=172.39.34.56}
            up{job="ec2-scrappijng",privateip=172.39.34.56}[5m]
            up{job="ec2-scrappijng",privateip=172.39.34.56}
            ```
            
        - operators
            
            ```bash
            node_memory_Memfree_bytes /1024 /1024
            ```
            
        - functions
            
            ```bash
            sum()
            max()
            min()
            
            ```
            
        - counter vs guage
            
            
        - metrics
            - up
            - cpu
            - free
            - disc usage
            - network usage
