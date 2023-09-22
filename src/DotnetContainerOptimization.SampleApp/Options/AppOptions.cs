using System.ComponentModel.DataAnnotations;

namespace DotnetContainerOptimization.SampleApp.Options;

public class AppOptions
{
    public const string PropertyName = "App";

    [Required]
    public string Name { get; init; } = string.Empty;
}
