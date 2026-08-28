# Payment client foundation

The mobile app must remain provider-agnostic.

## Security boundaries

- Flutter talks only to the JETKIZ backend.
- Provider API keys, webhook secrets and merchant credentials stay on the backend.
- Full card PAN and CVV are never persisted by JETKIZ.
- If the provider supports card-on-file, JETKIZ stores only provider tokens/IDs plus display metadata such as brand and last4.
- Payment success is authoritative only after backend verification/webhook processing. Returning to the app from a hosted checkout is not proof of payment.

## Expected checkout flow

1. Sync cart and validate availability/prices.
2. Create CARD order with an idempotency key.
3. Request checkout from `POST /payments` using the created order ID.
4. Open provider checkout URL / SDK supplied by the provider.
5. Return to the app via a verified app link when provider integration is known.
6. Re-read order/payment status from JETKIZ backend.
7. Clear cart only after backend confirms the payment/order state expected by the final contract.
8. Persist a non-sensitive pending order/payment reference so an interrupted app can recover the flow.

## Saved cards

The current card screens are UI foundation only. The repository intentionally returns no cards and does not implement create/delete/default operations until PayLink confirms tokenization/card-on-file support and its exact API contract.
