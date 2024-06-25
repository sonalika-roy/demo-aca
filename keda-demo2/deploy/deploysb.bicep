param serviceBusNamespaceName string = 'sb-fta-demo'
param containerAppsPortalName string = 'aca-demos-keda-apps-portal'
param containerAppsOrderProcessorName string = 'aca-demos-keda-apps-processor'
param containerAppsEnvironmentName string = 'acaenv-fta-demo'

var secretNamesServiceBusConnectionStringPortal = 'servicebus-connectionstring'
var secretNamesServiceBusConnectionStringAutoscaler = 'servicebus-connectionstring-autoscaler'
var secretNamesServiceBusConnectionStringWorker = 'servicebus-connectionstring-worker'
var serviceBusQueueName = 'orders'
var serviceBusAuthorizationAutoscalerName = 'orders-autoscaler'
var serviceBusAuthorizationPortalName = 'orders-portal'
var serviceBusAuthorizationWorkerName = 'orders-worker'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
}

resource serviceBusNamespaceqa 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  name: serviceBusQueueName
  parent: serviceBusNamespace
  properties: {
  }
}

resource serviceBusAuthorizationAutoscaler 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: '${serviceBusNamespaceName}${serviceBusAuthorizationAutoscalerName}'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
 
}

resource serviceBusAuthorizationPortal 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: '${serviceBusNamespaceName}${serviceBusAuthorizationPortalName}'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Send'
      'Listen'
      'Manage'
    ]
  }
}

resource serviceBusAuthorizationWorker 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-10-01-preview' = {
  name: '${serviceBusNamespaceName}${serviceBusAuthorizationWorkerName}'
  parent: serviceBusNamespace
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource containerAppsPortal 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: containerAppsPortalName
  location: resourceGroup().location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppsEnvironmentName)
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
      }
      secrets: [
        {
          name: secretNamesServiceBusConnectionStringPortal
          value: listKeys(serviceBusAuthorizationPortal.id, '2015-08-01').primaryConnectionString
         // value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', '${serviceBusNamespaceName}${serviceBusAuthorizationPortalName}'), '2015-08-01').primaryConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'kedasamples/sample-dotnet-web'
          name: 'portal'
          env: [
            {
              name: 'KEDA_SERVICEBUS_QUEUE_CONNECTIONSTRING'
              secretRef: secretNamesServiceBusConnectionStringPortal
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-autoscaling-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    serviceBusNamespace
     ]
}

resource containerAppsOrderProcessor 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: containerAppsOrderProcessorName
  location: resourceGroup().location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppsEnvironmentName)
    configuration: {
      activeRevisionsMode: 'single'
      secrets: [
        {
          name: secretNamesServiceBusConnectionStringAutoscaler
          value: listKeys(serviceBusAuthorizationAutoscaler.id, '2015-08-01').primaryConnectionString
          //value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', '${serviceBusNamespaceName}${serviceBusAuthorizationAutoscalerName}'), '2015-08-01').primaryConnectionString
        }
        {
          name: secretNamesServiceBusConnectionStringWorker
          value: listKeys(serviceBusAuthorizationWorker.id, '2015-08-01').primaryConnectionString
          //value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', '${serviceBusNamespaceName}${serviceBusAuthorizationWorkerName}'), '2015-08-01').primaryConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'ghcr.io/kedacore/sample-dotnet-worker-servicebus-queue:latest'
          name: 'queue-worker'
          env: [
            {
              name: 'KEDA_SERVICEBUS_AUTH_MODE'
              value: 'ConnectionString'
            }
            {
              name: 'KEDA_SERVICEBUS_QUEUE_NAME'
              value: serviceBusQueueName
            }
            {
              name: 'KEDA_SERVICEBUS_QUEUE_CONNECTIONSTRING'
              secretRef: secretNamesServiceBusConnectionStringWorker
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'queue-based-autoscaling'
            custom: {
              type: 'azure-servicebus'
              metadata: {
                queueName: serviceBusQueueName
                messageCount: '20'
              }
              auth: [
                {
                  secretRef: secretNamesServiceBusConnectionStringAutoscaler
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
      
    }
  }
  dependsOn: [
    serviceBusNamespace
  ]
}
