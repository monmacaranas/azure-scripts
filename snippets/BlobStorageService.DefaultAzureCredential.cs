// Reference pattern: authenticate to Azure Blob Storage with DefaultAzureCredential
// instead of a connection string or account key.
//
// Local development: authenticate with Azure CLI or another supported developer credential.
// In Azure: use a managed identity with the required Storage Blob Data role.
//
// No tenant IDs, subscription IDs, resource names, credentials or secrets are hardcoded.

using Azure.Identity;
using Azure.Storage.Blobs;

public class BlobStorageService
{
    private readonly string _storageAccountUrl;

    public BlobStorageService(string storageAccountUrl)
    {
        _storageAccountUrl = storageAccountUrl;
    }

    public async Task<string> UploadPackageAsync(string containerName, string blobName, Stream content)
    {
        var credential = new DefaultAzureCredential();
        var containerUri = new Uri($"{_storageAccountUrl}/{containerName}");
        var containerClient = new BlobContainerClient(containerUri, credential);
        var blobClient = containerClient.GetBlobClient(blobName);
        await blobClient.UploadAsync(content, overwrite: true);
        return blobClient.Uri.ToString();
    }

    public async Task<Stream> DownloadPackageAsync(string containerName, string blobName)
    {
        var credential = new DefaultAzureCredential();
        var blobUri = new Uri($"{_storageAccountUrl}/{containerName}/{blobName}");
        var blobClient = new BlobClient(blobUri, credential);
        var download = await blobClient.DownloadAsync();
        return download.Value.Content;
    }
}

// Example DI registration:
// builder.Services.AddSingleton(sp =>
//     new BlobStorageService("https://<storage-account>.blob.core.windows.net"));
