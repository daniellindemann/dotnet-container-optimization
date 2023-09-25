using DotnetContainerOptimization.SampleApp.Dto.Responses;
using DotnetContainerOptimization.SampleApp.Helper;
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
builder.Services.AddOptions<GreetingsOptions>()
    .Bind(builder.Configuration.GetSection(GreetingsOptions.PropertyName))
    .ValidateDataAnnotations()
    .ValidateOnStart();

// https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-7.0
builder.Services.AddHealthChecks();

// add other services
builder.Services.AddSingleton<OsInformationRetriever>();

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

app.MapGet("/hello", (IOptions<GreetingsOptions> appOptions, ILogger<Program> logger) =>
{
    logger.LogInformation("Return hello");
    return $"Hello {appOptions.Value.To}";
})
.WithName("Hello")
.WithOpenApi();

app.MapGet("/arch", (OsInformationRetriever osInformationRetriever, ILogger<Program> logger) =>
{
    logger.LogInformation("Return architecture");
    return new ArchitectureInfo(osInformationRetriever.GetOsString(),
        osInformationRetriever.GetArchitecture());
})
.WithName("Arch")
.WithOpenApi();

app.MapHealthChecks("/healthz");

app.Run();
