# PayMongo Checkout Setup

The checkout Edge Function supports QRPH, GCash, Maya, and cards. The Flutter Web return route reads `payment=success|cancelled` and `order_id`; it checks the signed-in user's order in Supabase and only reports payment as confirmed after the webhook marks it paid.

## Return URL

Set `PAYMONGO_RETURN_URL` to the deployed Flutter Web app URL, including the trailing slash. The current public app URL is `https://ken-rookie.github.io/app-downloads/lunea/`. PayMongo will receive success and cancel URLs built from this URL.

```powershell
npx supabase secrets set PAYMONGO_RETURN_URL=https://ken-rookie.github.io/app-downloads/lunea/ --project-ref zmclothzxbaaxiedlgvi
```

For local web development, leave this secret unset; the checkout function uses the local request origin. Native app deep links are not configured in this project yet.

## Test and Live Modes

Use `PAYMONGO_MODE=test` with a PayMongo test secret key and the test webhook signing secret. For live payments, set `PAYMONGO_MODE=live` and replace both keys with the live secret key and live webhook signing secret. Never put these values in Flutter source, SQL files, or chat.

```powershell
npx supabase secrets set PAYMONGO_MODE=test --project-ref zmclothzxbaaxiedlgvi
```

The checkout function requires the secret key prefix to match the selected mode (`sk_test_` or `sk_live_`). The webhook verifies the matching PayMongo signature and `livemode` value.

## Webhook

Configure the webhook endpoint in the PayMongo dashboard as:

```text
https://zmclothzxbaaxiedlgvi.supabase.co/functions/v1/paymongo-webhook
```

Subscribe to `checkout_session.payment.paid`. Store that endpoint's signing secret in the Supabase Edge Function secret `PAYMONGO_WEBHOOK_SECRET`. Do not mark an order paid from the browser return URL; the webhook is the source of truth.
