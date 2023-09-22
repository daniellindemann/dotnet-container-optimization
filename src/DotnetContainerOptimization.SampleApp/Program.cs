using DotnetContainerOptimization.SampleApp.Options;

using Microsoft.Extensions.Logging.Console;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

/*
 * Configured
 *   - logging
 *   - environment variables
 *   - health probes
 */

// configure logging
if (builder.Environment.IsProduction())
{
    builder.Logging.ClearProviders();
    // https://learn.microsoft.com/en-us/dotnet/core/extensions/console-log-formatter
    builder.Logging.AddConsole(options => options.FormatterName = ConsoleFormatterNames.Json);
}
else
{
    builder.Logging.ClearProviders();
    builder.Logging.AddConsole();
}

// Add custom configurations that can be changed by environment settings
builder.Services.AddOptions<AppOptions>()
    .Bind(builder.Configuration.GetSection(AppOptions.PropertyName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

// https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-7.0
builder.Services.AddHealthChecks();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();
}

// add cors config
// allow everything
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy.AllowAnyHeader()
    .AllowAnyMethod()
    .AllowAnyOrigin()));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors();  // use cors

app.MapGet("/hello", (IOptions<AppOptions> appOptions, ILogger<Program> logger) =>
{
    logger.LogInformation("Return hello");
    return $"Hello {appOptions.Value.Name}";
})
.WithName("Hello")
.WithOpenApi();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();

app.MapHealthChecks("/healthz");

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
