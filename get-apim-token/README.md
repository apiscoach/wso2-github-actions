# Get WSO2 APIM OAuth Token Action

A reusable GitHub Action that registers an OAuth2 client and obtains an access token for WSO2 API Manager API operations.

## Features

- Registers an OAuth2 client with WSO2 APIM
- Obtains an access token using the password grant type
- Configurable client name and OAuth scopes
- Secure handling of sensitive credentials
- Error handling with detailed error messages

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `apim_base_url` | WSO2 APIM base URL | Yes | - |
| `admin_username` | WSO2 APIM admin username | Yes | - |
| `admin_password` | WSO2 APIM admin password | Yes | - |
| `client_name` | OAuth2 client name for registration | No | `github_actions_client` |
| `scopes` | OAuth2 scopes to request | No | `apim:api_publish apim:api_view` |

## Outputs

| Output | Description |
|--------|-------------|
| `access_token` | The OAuth2 access token for APIM API operations |
| `client_id` | The registered OAuth2 client ID |

## Usage

### Basic Usage

```yaml
- name: Get APIM Token
  id: apim-auth
  uses: ./get-apim-token
  with:
    apim_base_url: ${{ secrets.WSO2_APIM_BASE_URL }}
    admin_username: ${{ secrets.WSO2_APIM_ADMIN_USERNAME }}
    admin_password: ${{ secrets.WSO2_APIM_ADMIN_PASSWORD }}

- name: Use APIM Token
  run: |
    echo "Access token: ${{ steps.apim-auth.outputs.access_token }}"
    # Use the token for API operations
    curl -H "Authorization: Bearer ${{ steps.apim-auth.outputs.access_token }}" \
         "${{ secrets.WSO2_APIM_BASE_URL }}/api/am/publisher/v4/apis"
```

### Advanced Usage with Custom Settings

```yaml
- name: Get APIM Token with Custom Settings
  id: apim-auth
  uses: ./get-apim-token
  with:
    apim_base_url: ${{ secrets.WSO2_APIM_BASE_URL }}
    admin_username: ${{ secrets.WSO2_APIM_ADMIN_USERNAME }}
    admin_password: ${{ secrets.WSO2_APIM_ADMIN_PASSWORD }}
    client_name: "my_custom_client"
    scopes: "apim:api_publish apim:api_view apim:admin"

- name: Change API Lifecycle State
  run: |
    curl -s -X POST \
      -H "Authorization: Bearer ${{ steps.apim-auth.outputs.access_token }}" \
      "${{ secrets.WSO2_APIM_BASE_URL }}/api/am/publisher/v4/apis/change-lifecycle?apiId=$API_ID&action=Publish"
```

## Security Considerations

- Store all sensitive information (URLs, usernames, passwords) as GitHub repository secrets
- The action automatically cleans up sensitive variables from memory after use
- Access tokens are only output to the GitHub Actions context, not logged
- Use appropriate OAuth scopes to limit token permissions

## Error Handling

The action will fail and provide detailed error messages if:
- OAuth2 client registration fails
- Access token request fails
- Required inputs are missing or invalid

## Requirements

- WSO2 API Manager with client registration enabled
- Admin credentials for WSO2 APIM
- `jq` utility (available in GitHub Actions runners by default)
- `curl` utility (available in GitHub Actions runners by default)