# Airflow Deployment for EKS

This folder contains the configuration required for deploying Airflow on the EKS cluster using [Helm](https://helm.sh).

We use the official [Airflow Helm Chart](https://github.com/apache/airflow/tree/master/chart), currently using airflow version 2.1.0


## Requirements

* AWS CLI
* Kubectl
* Helm

## Deployment

### Cluster

Follow the steps with terraform at the main [README.md](../README.md)

### Airflow
https://github.com/airflow-helm/charts/tree/main/charts/airflow

* Set namespace
```bash
  kubectl create namespace airflow
  kubectl config set-context --current --namespace=airflow
```


**Note:** the folder chart has been downloaded from airflow repository

* Download the chart folder from the airflow repository at [https://github.com/apache/airflow/tree/master/chart](https://github.com/apache/airflow/tree/master/chart) with the following command:

```bash
  pip install git+git://github.com/HR/github-clone#egg=ghclone
   ghclone https://github.com/apache/airflow/tree/master/chart
```

The following files has been modified: 
- requirements.yml 
- add folder postgres
- values.yml 

* Add repo
```bash
  helm repo add apache-airflow https://airflow.apache.org
```

* Install the chart    

```bash
  cd chart
  helm install airflow -n airflow .
```
* Update the chart
```bash
  helm upgrade airflow -n airflow .
```

* Validate service and pods and check the Status 
```bash
  kubectl get all -n airflow 
```
* Access Airflow console by port-forwarding
```bash
  export POD_NAME=$(kubectl get pods --field-selector=status.phase=Running -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep 'web')
  kubectl port-forward --namespace airflow $POD_NAME 8080:8080
```

* Retrieve LB endpoint
```bash
  kubectl describe ingress airflow-airflow-ingress 
```

* Create CNAME in Route53 console for LB:

    `airflow.sandbox.net`    


## Logs

* Identify pod ids:
```bash
  $ kubectl get pods
    NAME                                 READY   STATUS    RESTARTS   AGE
  airflow-flower-6d6bb84fcc-dpnx4      1/1     Running   0          11m
  airflow-postgres-5f5575d874-kgq76    1/1     Running   0          11m
  airflow-redis-0                      1/1     Running   0          11m
  airflow-scheduler-7df6b55dc9-vpz89   3/3     Running   0          11m
  airflow-statsd-84f4f9898-kb9hj       1/1     Running   0          11m
  airflow-webserver-59f7f57d74-8hb66   1/1     Running   0          11m
  airflow-worker-5845dc5799-df7g8      2/2     Running   0          11m
```
* Web
```bash
  kubectl logs airflow-webserver-59f7f57d74-8hb66 
```
* Scheduler
```bash
  kubectl logs airflow-scheduler-7df6b55dc9-vpz89 -c scheduler-gc 
```
* Worker
```bash
  kubectl logs airflow-worker-5845dc5799-df7g8  
```

* New users 

```bash
  aws eks update-kubeconfig --name sandbox-eks-cluster --region us-west-2

  kubectl config set-context --current --namespace=airflow

  kubectl get pods 

```

## Login into database 

```bash
  export POD_NAME=$(kubectl get pods --field-selector=status.phase=Running -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep 'postgres')
  kubectl exec -ti $POD_NAME -- psql -d airflow -U airflow
```

List tables: 
```bash
 \dt
```

## Support Apache Livy Operator    

Needs the folling dependency as described in the [doc](https://airflow.apache.org/docs/apache-airflow-providers-apache-livy/stable/index.html).        

In order to support it, the image rootstrap/airflow:2.1.0 is created with the following [Dockerfile](https://github.com/rootstrap/eks-airflow/blob/main/airflow/docker/Dockerfile)      

Notice that if you want to add more dependencies, just use that Dockerfile adding in the pip install the necessary dependencies. 

Build and push the image and update the image version at [values.yaml](https://github.com/rootstrap/eks-airflow/blob/main/airflow/chart/values.yaml) file.    






