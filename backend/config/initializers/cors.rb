# Configure CORS for API access.
# Adjust origins for production deployment.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In production, replace with your frontend domain(s)
    origins ENV.fetch("CORS_ORIGINS", "*").split(",")

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"],
      max_age: 600
  end
end
