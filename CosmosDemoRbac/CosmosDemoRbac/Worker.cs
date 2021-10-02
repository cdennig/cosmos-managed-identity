using System;
using System.Threading;
using System.Threading.Tasks;
using Azure.Identity;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace CosmosDemoRbac
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConfiguration _configuration;

        public Worker(ILogger<Worker> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var credential = new DefaultAzureCredential();

            var cosmosClient = new CosmosClient(_configuration["Cosmos:Uri"], credential);
            var container = cosmosClient.GetContainer(_configuration["Cosmos:Db"], _configuration["Cosmos:Container"]);

            var newId = Guid.NewGuid().ToString();
            await container.CreateItemAsync(new {id = newId, partitionKey = newId, name = "Ted Lasso"},
                new PartitionKey(newId), cancellationToken: stoppingToken);
            _logger.LogInformation("Successfully connected to Cosmos DB via Managed Identity. Test data added.");
        }
    }
}