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

- **First Time Setup:**  
  Run `make setup` to install dependencies and start the Jekyll server.

- **Complete Project Setup:**  
  Run `make setup-project` to install dependencies, clean old generated files, sync data from Google Sheets, and generate all necessary files. This is the recommended command for setting up the project from scratch.

- **Install Dependencies:**  
  Run `make install` to install or update the project's dependencies.

- **Data Synchronization and File Generation:**
  - Run `make sync` to fetch data from Google Sheets.
  - Run `make generate-members` to generate member files.
  - Run `make generate-groups` to generate group files.
  - Run `make generate` to generate both member and group files.
  - Run `make sync-and-generate` to sync data and generate all files.
  - Run `make dev` for the complete development workflow (sync, generate, serve).

- **Serve the Site:**  
  Run `make serve` to start the Jekyll server for local development.

- **Clean Up:**  
  Run `make clean` to remove the vendor directory, the `_site` folder, and all generated files (YAML data files, member and group Markdown files, and downloaded images).

## Deployment

To build the site for deployment, you can run:

```bash
bundle exec jekyll build -d public
```

## Google Sheets Integration

The site uses data from Google Sheets for members, groups, projects, and project contributors. To update this data:

1. Make sure your `.env` file is set up with the correct credentials and spreadsheet ID.
2. Run `make sync` to fetch the latest data from Google Sheets.
3. Run `make generate` to create the member and group files from the fetched data.
4. Run `make serve` to start the Jekyll server and view the updated site.

Or simply run `make dev` to perform all these steps in one command.

For more detailed information about the data synchronization and file generation process, see the [_build/README.md](_build/README.md) file.
