# Deploying LibreTranslate to DigitalOcean App Platform

This guide explains how to deploy LibreTranslate to DigitalOcean App Platform.

## Prerequisites

- A DigitalOcean account
- Access to the [verteco/LibreTranslate](https://github.com/verteco/LibreTranslate) GitHub repository

## Deployment Steps

1. **Fork or clone the repository** if you haven't already done so

2. **Push the updated configuration files**
   - The `.do/app.yaml` configuration file
   - The custom `docker/Dockerfile.do` file
   - The `entrypoint.sh` script
   - The `Procfile`

3. **Deploy to DigitalOcean App Platform**
   - Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
   - Click "Create App"
   - Select "GitHub" as the source
   - Connect your GitHub account if not already connected
   - Select the `verteco/LibreTranslate` repository
   - Select the branch with your changes (e.g., main)
   - DigitalOcean will automatically detect the `.do/app.yaml` configuration
   - Review the configuration and click "Next"
   - Choose your preferred pricing plan
   - Click "Create Resources"

## Configuration Options

You can customize the deployment by modifying the `.do/app.yaml` file:

- `instance_size_slug`: Change the droplet size (e.g., `basic-xs`, `basic-s`, `professional-xs`)
- `instance_count`: Set the number of instances for high availability
- `envs`: Configure environment variables such as:
  - `LT_API_KEYS`: Enable/disable API keys
  - `LT_LOAD_ONLY`: Specify languages to load (e.g., "en,es,fr")

## Managing API Keys

After deployment:

1. Access your app's web terminal from the DigitalOcean console
2. Run the following command to create an API key:
   ```
   ./venv/bin/ltmanage keys add 120
   ```
   This creates an API key valid for 120 days
3. List existing API keys:
   ```
   ./venv/bin/ltmanage keys
   ```

## Troubleshooting

- **Build failures**: Check the build logs in the DigitalOcean console
- **Runtime errors**: Check the app logs in the DigitalOcean console
- **High memory usage**: Consider upgrading to a larger instance size or limiting the number of language models with `LT_LOAD_ONLY`
