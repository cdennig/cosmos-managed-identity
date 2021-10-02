var location = resourceGroup().location
var dbName = 'rbacsample'
var containerName = 'data'
var roleDefId = guid('sql-role-definition-', principalId, cosmosDbAccount.id)
var roleDefName = 'Custom Read/Write role'
var roleAssignId = guid(roleDefId, principalId, cosmosDbAccount.id)

@description('Object ID of the AAD identity. Must be a GUID.')
param principalId string

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    disableLocalAuth: true
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    publicNetworkAccess: 'Enabled'
  }
}

// Cosmos DB
resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${cosmosDbAccount.name}/${dbName}'
  location: location
  properties: {
    resource: {
      id: dbName
    }
  }
}

// Data Container
resource containerData 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  name: '${cosmosDbDatabase.name}/${containerName}'
  location: location
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-06-15' = {
  name: '${cosmosDbAccount.name}/${roleDefId}'
  properties: {
    roleName: roleDefName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        ]
      }
    ]
  }
}

resource roleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-06-15' = {
  name: '${cosmosDbAccount.name}/${roleAssignId}'
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: principalId
    scope: cosmosDbAccount.id
  }
}
