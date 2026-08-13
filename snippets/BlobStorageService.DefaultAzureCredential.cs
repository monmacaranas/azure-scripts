// Reference pattern: authenticating to Azure Blob Storage with DefaultAzureCredential
// instead of a connection string / account key.
//
// Used as the target pattern for the Coursalator storage-auth migration (connection
// string -> Managed Identity). Kept here as a copy-paste starting point for any other
// service making the same move -- not wired into a specific project.
//
// Local dev: `az login` first; DefaultAzureCredential picks up that session automatically.
// In Azure: works unmodified once the App Service's system-assigned managed identity has
// the "Storage Blob Data Contributor" role on the target storage account.

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
        try
        {
            var credential = new DefaultAzureCredential();
            var containerUri = new Uri($"{_storageAccountUrl}/{containerName}");
            var containerClient = new BlobContainerClient(containerUri, credential);

            var blobClient = containerClient.GetBlobClient(blobName);
            await blobClient.UploadAsync(content, overwrite: true);

            return blobClient.Uri.ToString();
        }
        catch (Azure.Identity.AuthenticationFailedException ex)
        {
            throw new InvalidOperationException(
                "Failed to authenticate with Managed Identity. " +
                "Verify Managed Identity has 'Storage Blob Data Contributor' role on the storage account.",
                ex);
        }
        catch (Azure.RequestFailedException ex)
        {
            throw new InvalidOperationException(
                $"Failed to upload blob to storage: {ex.Message}", ex);
        }
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

// Dependency injection registration (Program.cs / Startup.cs):
//
// builder.Services.AddSingleton(sp =>
//     new BlobStorageService("https://<storage-account>.blob.core.windows.net"));
