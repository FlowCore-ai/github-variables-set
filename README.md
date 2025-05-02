# Create a GitHub repository variable or update an existing one in a specific GitHub repository

This action checks whether a variable or a set of variables exist in the specified GitHub repository. In case of existence, the value is updated in accordance to the user input. In case of non-existance, the action will create a new variable in accordance to the key, value pair provided by the user.

## Usage

### `workflow.yml` Example

Place in a `.yml` file such as this one in your `.github/workflows` folder. [Refer to the documentation on workflow YAML syntax here.](https://help.github.com/en/articles/workflow-syntax-for-github-actions)

```yaml
---
name: Set GitHub Repository Variables
on:
  push:
    branches:
      - <my-branch>
permissions:
  contents: read
  statuses: write
jobs:
  set_secrets_in_frontend_repo:
    runs-on: ubuntu-latest
    name: Set GitHub Secrets in Frontend Repository
    permissions:
      contents: read
    steps:
      - name: Set Environment Variables for the Frontend Repository
        run: |
          api_url="https://<my-api-url>"
          msal_authority="<my-msal-authority-url>"
          msal_known_authorities="<my-msal-known-authorities>"
          azure_ad_b2c_client_id="<my-azure-ad-b2c-client-id>"
          azure_ad_b2c_app_scope_uri="<my-azure-ad-b2c-app-scope-uri>"
          msal_reader_role="<my-msal-reader-role>"
          msal_admin_role="<my-msal-admin-role>"
          jq -n --arg api_url "$api_url" \
                --arg msal_authority "$msal_authority" \
                --arg azure_ad_b2c_client_id "$azure_ad_b2c_client_id" \
                --arg msal_known_authorities "$msal_known_authorities" \
                --arg azure_ad_b2c_app_scope_uri "$azure_ad_b2c_app_scope_uri" \
                --arg reader_role "$reader_role" \
                --arg admin_role "$admin_role" \
                '[
                  {
                    "key": "API_URL",
                    "value": $api_url
                  },
                  {
                    "key": "MSAL_AUTHORITY",
                    "value": $msal_authority
                  },
                  {
                    "key": "AZURE_AD_B2C_CLIENT_ID",
                    "value": $azure_ad_b2c_client_id
                  },
                  {
                    "key": "MSAL_KNOWN_AUTHORITIES",
                    "value": $msal_known_authorities
                  },
                  {
                    "key": "AZURE_AD_B2C_APP_SCOPE_URI",
                    "value": $azure_ad_b2c_app_scope_uri
                  },
                  {
                    "key": "MSAL_READER_ROLE",
                    "value": $msal_reader_role
                  },
                  {
                    "key": "MSAL_ADMIN_ROLE",
                    "value": $msal_admin_role
                  }
                ]' > repo_vars.json
          echo "JSON file 'repo_vars.json' created successfully."

      - name: Set up GitHub environment variables
        uses: FlowCore-ai/github-variables-set@v1.0.0
        with:
          REPOSITORY_OWNER: <my-org>
          REPOSITORY_NAME: <my-frontend-repo>
          GITHUB_PAT: ${{ secrets.PAT_TOKEN }}
          GITHUB_VARIABLES_FILE: './repo_vars.json'
```

## Action inputs

The following settings must be passed as environment variables as shown in the example.

| name                    | description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| `REPOSITORY_OWNER`      | (Required) The GitHub repository owner.                       |
| `REPOSITORY_NAME`       | (Required) The GitHub repository where you want to set/update your environment variables|
| `GITHUB_PAT`            | (Required) The GitHub Personal Access Token with `repo`, `read:org`, and `admin:repo_hookscope` scopes. This is used to authenticate the action to the GitHub API. |
| `GITHUB_VARIABLES_FILE`   | (Required) The file where the variables have been stored. Only JSON files are accepted. |
