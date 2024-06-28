# infra-aws


## 1. export the aws account
```sh
export AWS_PROFILE=csye7125dev   
```

## 2. deploy
```sh
terraform fmt && terraform init && terraform plan --var-file="secrets.tfvars.dev"
terraform apply --var-file="secrets.tfvars.dev"
terraform destroy --var-file="secrets.tfvars.dev"
```

## 3. Following kubectl check
List all the pods running in the Kubernetes namespace named `kafka`:
```sh
kubectl get pods -n kafka
```
Get the services:
```sh
kubectl get svc -n kafka
```



