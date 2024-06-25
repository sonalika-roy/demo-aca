param location string = resourceGroup().location
param name string
param containerAppEnvironmentId string

param containerImage string
param useExternalIngress bool = true
param containerPort int

param azureContainerRegistryImageTag string

param acrName string


param identityId string

resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
    name: name
    location: location
    identity: {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${identityId}': {}
        }
    }
    properties: {
        managedEnvironmentId: containerAppEnvironmentId
        workloadProfileName: 'fta'
        configuration: {
            registries: [
                {
                    server: '${acrName}.azurecr.io'
                    identity: identityId
                }
            ]
            ingress: {
                external: useExternalIngress
                targetPort: containerPort
            }
        }
        template: {
            containers: [
                {
                    image: '${containerImage}:${azureContainerRegistryImageTag}'
                    name: acrName
                    resources: {
                      cpu: 1
                      memory: '2Gi'
                    }
                }
            ]
            scale: {
                minReplicas: 1
            }
        }
    }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
