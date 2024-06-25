param acrName string = 'acamissample'



param location string = resourceGroup().location
param virtualNetworkName string = 'msftaliveaca-vnet'

@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Container App environment subnet name')
param containerAppEnvSubnetName string = 'acasubnet'

@description('Container App environment subnet prefix')
param containerAppEnvSubnetPrefix string = '10.0.0.0/27'

param ImageTag string = 'blue5'



module law 'modules/log-analytics.bicep' = {
    name: 'log-analytics-workspace'
    params: {
        location: location
        name: 'law-aca-msi-sample'
    }
}

module useridentity 'modules/useridentity.bicep' = {
  name: 'fta-aca-msi'
  params: {
    location: location
    name: 'fta-aca-msi'
  }
}

module acr 'modules/acr.bicep' = {
    name: 'acr'
    params: {
      containerRegistryName: acrName
      location: location
    }
}

module acrrbac 'modules/acrrole.bicep' = {
    name: 'acr-rbac'
    params: {
      principalId: useridentity.outputs.msiid
      roleGuid: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
      acrName: acrName
    }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
    name: virtualNetworkName
    location: location
    properties: {
      addressSpace: {
        addressPrefixes: [
          vnetAddressPrefix
        ]
      }
      subnets: [
        {
          name: containerAppEnvSubnetName
          properties: {
            addressPrefix: containerAppEnvSubnetPrefix
            delegations: [
              {
                name: 'envdelegation'
                properties: {
                  serviceName: 'Microsoft.App/environments'
                }
              }
            ]
          }
        }
      ]
    }
  }

  

module containerAppEnvironment 'modules/container-app-env.bicep' = {
    name: 'container-app-environment'
    params: {
        name: 'acaenv-fta-demo'
        location: location
        lawClientId: law.outputs.clientId
        lawClientSecret: law.outputs.clientSecret
        subnetId: vnet.properties.subnets[0].id
    }
}

/*
module containerApp 'modules/container-app.bicep' = {
    name: 'container-app'
    params: {
        name: 'msftalivedemo'
        location: location
        containerAppEnvironmentId: containerAppEnvironment.outputs.id
        containerImage: containerImage
        containerPort: containerPort
        acrName: acrName
        identityId: useridentity.outputs.msirid
        useExternalIngress: true
        azureContainerRegistryImageTag: ImageTag
    }
}

output fqdn string = containerApp.outputs.fqdn
*/
