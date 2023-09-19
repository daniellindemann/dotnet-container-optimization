using System.ComponentModel.DataAnnotations;

namespace DotnetContainerOptimization.DotnetConfig.Options;

public class AppOptions
{
    public const string PropertyName = "App";

    [Required]
    public string Name { get; init; } = string.Empty;
}
