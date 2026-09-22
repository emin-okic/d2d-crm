# Salesforce Export Integration

## Product flow

The unlocked Contacts export control now opens a destination picker. CSV preserves the previous behavior. Salesforce opens a guided connection, object selection, field mapping, and export flow for the currently selected Prospects or Customers list.

The first release is a one-way export. It creates Salesforce Lead or Contact records and reports record-level failures. It does not read Salesforce data back into d2d CRM, delete Salesforce records, or silently overwrite existing records.

## One-time Salesforce setup

1. In the target Salesforce org, open **Setup → External Client App Manager** and create an External Client App.
2. Enable OAuth and set the callback URL to `d2dcrm://oauth/salesforce`.
3. Add the **Manage user data via APIs (`api`)** and **Perform requests at any time (`refresh_token`, `offline_access`)** scopes.
4. Require PKCE. Disable the client-secret requirement for the web server and refresh-token flows because an iOS app is a public OAuth client and cannot safely hold a secret.
5. Configure the app's user policy for the intended Salesforce users or permission sets.
6. Copy the Consumer Key. In d2d CRM choose Production, Sandbox, or Developer Edition / My Domain, paste the key, and sign in through Salesforce. Developer Edition organizations should use their `https://...develop.my.salesforce.com` My Domain URL rather than `test.salesforce.com`.

Salesforce can take several minutes to activate a new External Client App. A sandbox needs access to the app configuration; after a sandbox refresh, verify that the app and its policy are still present.

## Sandbox acceptance test

1. Create or use a Salesforce Developer sandbox and add the External Client App above.
2. Add two d2d prospects: one complete record and one record with only a name.
3. Unlock Export Contacts, choose **Salesforce**, select **Sandbox**, and connect.
4. Keep the default Lead mapping, then map any org-specific custom fields using the live Salesforce field list.
5. Export and verify the success count in d2d CRM.
6. In Salesforce, confirm both Leads exist and that name, address, email, phone, and selected custom fields match.
7. Add a Salesforce validation rule that rejects one test value, export another two-record batch, and confirm one succeeds while the rejected record's message appears in d2d CRM.
8. Relaunch d2d CRM and confirm it can load fields without asking for credentials again. Disconnect and confirm a new export requires sign-in.

## Security and API behavior

- OAuth Authorization Code with PKCE is used; no Salesforce password or Consumer Secret is collected.
- The Consumer Key and mapping preferences are stored in app preferences. The refresh token is stored in the iOS Keychain with device-only protection.
- Object fields are loaded from Salesforce's `describe` metadata, so custom fields and org permissions are respected.
- The current Salesforce REST API version is discovered at runtime.
- Records are sent with the sObject Collections endpoint in batches of 200 with partial success enabled.

## Follow-up phases

For a true repeated sync, add a managed Salesforce external-ID field (for example `D2D_Record_ID__c`) and change creation to upsert. That prevents duplicate records and gives the app a durable cross-system identity. A later bidirectional phase can then pull status, owner, and qualification changes back into d2d CRM with an explicit conflict policy.
