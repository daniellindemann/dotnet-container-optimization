using System.Runtime.InteropServices;

namespace DotnetContainerOptimization.SampleApp.Helper;

public class OsInformationRetriever
{
    public string GetOsString()
    {
        string os = "other";
        
        if(RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            os = OSPlatform.Linux.ToString();
        else if(RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            os = OSPlatform.OSX.ToString();
        else if(RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            os = OSPlatform.Windows.ToString();
        else if(RuntimeInformation.IsOSPlatform(OSPlatform.FreeBSD))
            os = OSPlatform.FreeBSD.ToString();
        
        return os.ToLower();
    }

    public string GetArchitecture()
    {
        return RuntimeInformation.ProcessArchitecture.ToString().ToLower();
    }
}