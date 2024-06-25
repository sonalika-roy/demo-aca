
    ```bash
    export RESOURCE_GROUP_NAME=ms-fta-demo
    export LOCATION=eastus
    export ENVIRONMENT_NAME=acaenv-fta-demo
    export ACR_NAME=acamissample

    export SERVICE_BUS_NAMESPACE=sb-ms-fta-demo

    export QUEUE_NAME=job-queue
    export JOB_NAME=azure-servicebus-job

    az servicebus namespace create --name $SERVICE_BUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION

    az servicebus queue create --name $QUEUE_NAME --namespace-name $SERVICE_BUS_NAMESPACE \
        --resource-group $RESOURCE_GROUP_NAME --lock-duration PT1M

    export SERVICE_BUS_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list --name RootManageSharedAccessKey --namespace-name $SERVICE_BUS_NAMESPACE --resource-group $RESOURCE_GROUP_NAME --query primaryConnectionString -o tsv)

    az acr build --registry $ACR_NAME --image azure-servicebus-job:1.

    az containerapp job create --name $JOB_NAME --environment $ENVIRONMENT_NAME \
        --resource-group $RESOURCE_GROUP_NAME --image $ACR_NAME.azurecr.io/azure-servicebus-job:1.0 \
        --registry-server $ACR_NAME.azurecr.io \
        --trigger-type Event \
        --min-executions 0 --max-executions 10 \
        --secrets "connection-string-secret=$SERVICE_BUS_CONNECTION_STRING" \
        --env-vars "SERVICE_BUS_CONNECTION_STRING=secretref:connection-string-secret" "QUEUE_NAME=$QUEUE_NAME" \
        --scale-rule-name service-bus \
        --scale-rule-type azure-servicebus \
        --scale-rule-metadata "queueName=$QUEUE_NAME" "messageCount=1" \
        --scale-rule-auth "connection=connection-string-secret"

    

