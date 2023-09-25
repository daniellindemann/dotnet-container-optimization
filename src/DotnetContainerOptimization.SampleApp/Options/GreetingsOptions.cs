using System.ComponentModel.DataAnnotations;

namespace DotnetContainerOptimization.SampleApp.Options;

public class GreetingsOptions
{
    public const string PropertyName = "Greetings";

    [Required]
    public string To { get; init; } = string.Empty;
}
