## Cosmos / Identity
az group create -n rg-cosmosrbac -l westeurope

az identity create --name umid-cosmosid --resource-group rg-cosmosrbac --location westeurope

MI_PRINID=$(az identity show -n umid-cosmosid -g rg-cosmosrbac --query "principalId" -o tsv)

az deployment group create -f deploy.bicep -g rg-cosmosrbac --parameters principalId=$MI_PRINID

## Create AKS

az aks create -g rg-cosmosrbac -n cosmosrbac --enable-pod-identity --network-plugin azure -c 1 --generate-ssh-keys

MI_APPID=$(az identity show -n umid-cosmosid -g rg-cosmosrbac --query "clientId" -o tsv)
MI_ID=$(az identity show -n umid-cosmosid -g rg-cosmosrbac --query "id" -o tsv)

NODE_GROUP=$(az aks show -g rg-cosmosrbac -n cosmosrbac --query nodeResourceGroup -o tsv)
NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role "Virtual Machine Contributor" --assignee "$MI_APPID" --scope $NODES_RESOURCE_ID

az aks pod-identity add --resource-group rg-cosmosrbac --cluster-name cosmosrbac --namespace default  --name "cosmos-pod-identity" --identity-resource-id $MI_ID

apiVersion: v1
kind: Pod
metadata:
  name: demo
  labels:
    aadpodidbinding: "cosmos-pod-identity"
spec:
  containers:
  - name: demo
    image: chrisdennig/cosmos-mi:1.1
    env:
      - name: Cosmos__Uri
        value: "https://cosmos-2varraanuegcs.documents.azure.com:443/"
      - name: Cosmos__Db
        value: "rbacsample"
      - name: Cosmos__Container
        value: "data"
  nodeSelector:
    kubernetes.io/os: linux