# How Authorization Works For The D2D CRM
The d2d crm uses AWS Cognito to create and sign users in. Currently, the crm doesn't provide much user based experiences yet. Used mainly as an entry point to the marketing funnel on release.

## Libraries

### App Auth
https://github.com/openid/AppAuth-iOS/tree/master/Examples/Example-iOS_Swift-Carthage

### Amazon Cognito
https://docs.aws.amazon.com/cognito/

### Carthage
https://github.com/Carthage/Carthage


## Environment Configuration

### Example Secrets.xconfig

```

ISSUER_URL = your_issuer_url
CLIENT_ID = your_client_id
REDIRECT_URI = com.yourapp.d2dcrm://callback
LOGOUT_URI = yourapp://logout

```
