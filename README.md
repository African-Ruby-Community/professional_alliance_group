[![CI](https://github.com/African-Ruby-Community/professional_alliance_group/actions/workflows/ci.yml/badge.svg)](https://github.com/African-Ruby-Community/professional_alliance_group/actions/workflows/ci.yml)
![Jekyll](https://img.shields.io/badge/Jekyll-4.3.3-blue.svg?logo=jekyll)
![Ruby](https://img.shields.io/badge/ruby-3.4.4-red.svg?logo=ruby)

# Professional Alliance Group

## Setup

To set up the project for the first time, follow these steps:

1. Fork and clone the project

2. Run the setup command:
   ```bash
   make setup-project
   ```

   This will:
   - Install the necessary dependencies
   - Clean any existing generated files
   - Sync data from Google Sheets
   - Generate all member and group files

3. Start the development server:
   ```bash
   make serve
   ```

Alternatively, you can use `make setup` to just install dependencies and start the Jekyll server without syncing data.

## Update Instructions

If you need to update the project, you can follow these instructions:

1. **Pull the latest changes:**

   ```bash
   git pull origin main
   ```

2. **Update your local dependencies:**

   ```bash
   make install
   ```

3. **Start the server:**
   ```bash
   make serve
   ```

### Commands Overview

Run `make help` to view setup commands

## Deployment

To build the site for deployment with optimizations, you can run:

```bash
make build
```

This will:
1. Build the site with Jekyll in production mode
2. Run PurgeCSS to remove unused CSS
3. Apply minification to HTML, CSS, and JavaScript files

### Minification

The site uses the `jekyll-minifier` plugin to minify HTML, CSS, and JavaScript files. The minification settings are configured in `_config.yml` and `_config.local.yml`. 

To test if the minification is working correctly, you can run:

```bash
make test-minification
```

This will:
1. Build the site if it hasn't been built yet
2. Check all HTML, CSS, and JavaScript files in the `public` directory
3. Report their sizes and minification status

The test will help you identify any files that aren't being properly minified and provide suggestions for further optimization.

## Google Sheets Integration

The site uses data from Google Sheets for members, groups, projects, and project contributors. To update this data:

1. Make sure your `.env` file is set up with the correct credentials and spreadsheet ID.
2. Run `make sync` to fetch the latest data from Google Sheets.
3. Run `make serve` to start the Jekyll server and view the updated site.


For more detailed information about the data synchronization and file generation process, see the [_build/README.md](_build/README.md) file.
