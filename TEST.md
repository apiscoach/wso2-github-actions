# Testing the Get APIM Token Action

This document explains how to test the `get-apim-token` action individually to ensure it works correctly.

## Test Workflow

The test workflow `test-get-apim-token.yml` validates the action by:

1. **Basic Token Retrieval** - Tests with default settings
2. **Custom Settings Test** - Tests with custom client name and scopes
3. **Token Validation** - Verifies outputs are not empty
4. **API Call Test** - Optional test that makes a real API call using the token

## Prerequisites

Before running the test, ensure you have:

1. **Repository Secrets** configured:
   - `WSO2_APIM_ADMIN_USERNAME` - WSO2 APIM admin username
   - `WSO2_APIM_ADMIN_PASSWORD` - WSO2 APIM admin password

2. **Access to a WSO2 APIM instance** with:
   - Client registration enabled
   - Admin user with appropriate permissions
   - Accessible base URL

## Running the Test

### Method 1: GitHub Actions UI

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. Select **Test Get APIM Token Action** workflow
4. Click **Run workflow**
5. Fill in the required inputs:
   - `apim_base_url`: Your WSO2 APIM base URL (e.g., `https://your-apim.com`)
   - `test_api_call`: Enable/disable API testing (default: true)
6. Click **Run workflow**

### Method 2: GitHub CLI

```bash
gh workflow run test-get-apim-token.yml \
  -f apim_base_url="https://your-apim.com" \
  -f test_api_call=true
```

## Test Results Interpretation

### ✅ Success Indicators

- **Token retrieval successful**: Action outputs valid access_token and client_id
- **API call successful (200)**: Token can be used to make API calls
- **Custom settings work**: Action accepts and uses custom parameters

### ⚠️ Warning Indicators

- **API call 403 Forbidden**: Token is valid but user lacks permissions
- **Unexpected HTTP codes**: May indicate APIM configuration issues

### ❌ Error Indicators

- **Empty token outputs**: Action failed to register client or get token
- **API call 401 Unauthorized**: Token is invalid or expired
- **Action failure**: Check logs for curl errors or APIM connectivity issues

## Manual Testing

You can also test the action manually by creating a simple test workflow:

```yaml
name: Manual Test
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Test Token Action
        id: token-test
        uses: ./get-apim-token
        with:
          apim_base_url: "https://your-apim.com"
          admin_username: ${{ secrets.WSO2_APIM_ADMIN_USERNAME }}
          admin_password: ${{ secrets.WSO2_APIM_ADMIN_PASSWORD }}

      - name: Verify Output
        run: |
          echo "Token received: ${{ steps.token-test.outputs.access_token != '' }}"
          echo "Client ID: ${{ steps.token-test.outputs.client_id }}"
```

## Troubleshooting

### Common Issues

1. **Client Registration Fails**
   - Check APIM URL and admin credentials
   - Ensure client registration is enabled in APIM
   - Verify network connectivity

2. **Token Request Fails**
   - Check admin user permissions
   - Verify password grant type is enabled
   - Check requested scopes are available

3. **API Call Fails (401)**
   - Token might be expired (check token lifetime settings)
   - Invalid token format
   - APIM authentication issues

4. **API Call Fails (403)**
   - Admin user lacks required permissions
   - Requested scopes not granted
   - API access restrictions

### Debug Steps

1. **Check workflow logs** for detailed error messages
2. **Verify APIM configuration** for client registration and OAuth settings
3. **Test connectivity** to APIM endpoints manually
4. **Validate credentials** by logging into APIM admin console
5. **Check APIM logs** for server-side errors

## Expected Test Duration

- **Basic test**: ~30-60 seconds
- **With API calls**: ~60-120 seconds

The test duration depends on APIM response times and network latency.