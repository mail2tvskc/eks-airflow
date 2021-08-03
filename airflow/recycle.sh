echo UNINSTALLING
helm uninstall airflow
kubectl delete pvc redis-db-airflow-redis-0
kubectl delete secret airflow-git-key
echo INSTALLING
helm install airflow -n airflow .
