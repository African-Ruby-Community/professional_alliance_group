# Member and Group File Generator

This directory contains scripts to generate individual member and group files from the data in `_data/new_remote/`.

## Purpose

Jekyll uses collections to generate individual pages for members and groups. The collections are configured in `_config.local.yml`:

```yaml
collections:
  members:
    output: true
    permalink: /members/:name/
  groups:
    output: true
    permalink: /groups/:name/
```

These scripts generate the necessary files in the `_members/` and `_groups/` directories based on the data in `_data/new_remote/`.

## Scripts

### sync_google_sheets.rb

This script fetches data from Google Sheets and saves it to YAML files in the `_data/new_remote/` directory. It also downloads and optimizes images.

Usage:
```bash
ruby _build/sync_google_sheets.rb
```

### generate_member_files.rb

This script generates individual member files from the data in `_data/new_remote/members.yml`.

Usage:
```bash
ruby _build/generate_member_files.rb
```

### generate_group_files.rb

This script generates individual group files from the data in `_data/new_remote/groups.yml`.

Usage:
```bash
ruby _build/generate_group_files.rb
```

## Manual Workflow (Development)

### Using the Makefile (Recommended)

The project includes a Makefile with targets for all the necessary development tasks:

```bash
# Sync data from Google Sheets
make sync

# Generate member files
make generate-members

# Generate group files
make generate-groups

# Generate all files (members and groups)
make generate

# Sync data and generate all files
make sync-and-generate

# Complete development workflow: sync data, generate files, and serve
make dev
```

For most development work, you can simply run `make dev` to:
1. Sync data from Google Sheets
2. Generate member and group files
3. Build and serve the Jekyll site

### Manual Commands

If you prefer not to use the Makefile, you can run these scripts manually in the following order:

1. Update the data in `_data/new_remote/` using the `sync_google_sheets.rb` script:
   ```bash
   ruby _build/sync_google_sheets.rb
   ```
2. Run the member and group file generators to create the individual files:
   ```bash
   ruby _build/generate_member_files.rb
   ruby _build/generate_group_files.rb
   ```
3. Build the Jekyll site:
   ```bash
   bundle exec jekyll serve
   ```

## GitHub Actions Workflow (Automated)

For production deployments, these scripts are automatically run as part of the GitHub Actions workflow defined in `.github/workflows/deploy.yml`. The workflow:

1. Checks out the code
2. Sets up Ruby
3. Syncs data from Google Sheets using the `SERVICE_ACCOUNT_JSON` secret
4. Generates member and group files
5. Builds and deploys the Jekyll site

To set up GitHub Actions:

1. Add the following secrets to your GitHub repository:
   - `SERVICE_ACCOUNT_JSON`: The JSON content of your Google service account key
   - `SPREADSHEET_ID`: The ID of your Google Spreadsheet

## Notes

- The generated group files have empty `members` and `projects` arrays. To display members and projects on the group pages, you would need to update the `generate_group_files.rb` script to include the appropriate relationships.
- The relationship between groups, members, and projects is not directly available in the data. You would need to determine this relationship based on your specific requirements.
