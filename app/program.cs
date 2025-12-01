using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// ✅ Health check (for ECS target group)
app.MapGet("/health", () => Results.Ok("healthy"));

// ✅ API endpoint (triggered via Nginx proxy)
app.MapGet("/api/request", () => Results.Ok("Your request is sent!"));

// ✅ Run app on port 8080 (inside container)
app.Run("http://0.0.0.0:8080");
