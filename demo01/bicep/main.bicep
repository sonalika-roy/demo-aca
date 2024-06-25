param acrName string = 'acamissample'

param containerImage string = '${acrName}.azurecr.io/samples/blue'
param containerPort int = 80

param location string = resourceGroup().location

param containerenvname string = 'acaenv-fta-demo'

param ImageTag string = 'latest'



resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'fta-aca-msi'
  scope: resourceGroup() 
}


  

  resource env 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
    name: containerenvname
    scope: resourceGroup()
}

// dd
module containerApp 'modules/container-app.bicep' = {
    name: 'container-app'
    params: {
        name: 'msftalivedemo'
        location: location
        containerAppEnvironmentId: env.id
        containerImage: containerImage
        containerPort: containerPort
        acrName: acrName
        identityId: managedIdentity.id
        useExternalIngress: true
        azureContainerRegistryImageTag: ImageTag
    }
}

output fqdn string = containerApp.outputs.fqdn
