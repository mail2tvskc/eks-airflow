echo UNINSTALLING
helm uninstall airflow
kubectl delete pvc redis-db-airflow-redis-0
kubectl delete secret airflow-git-key
echo INSTALLING
kubectl create secret generic airflow-git-keys \
    --from-file=id_rsa=/Users/${USER}/.ssh/id_rsa \
    --from-file=id_rsa.pub=/Users/${USER}/.ssh/id_rsa.pub \
    --from-file=known_hosts=/Users/${USER}/.ssh/known_hosts
helm install airflow -n airflow .
