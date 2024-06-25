az login
az deployment group create --name supporting --resource-group ms-fta-demo --template-file 'demo01/bicep/main copy.bicep' 

az acr login -n acamissample.azurecr.io

docker pull sonalikaroy/containerapps:blue5

docker tag sonalikaroy/containerapps:blue5 acamissample.azurecr.io/samples/blue

docker push acamissample.azurecr.io/samples/blue


docker pull sonalikaroy/containerapps:green

docker tag sonalikaroy/containerapps:green acamissample.azurecr.io/samples/green

docker push acamissample.azurecr.io/samples/green

