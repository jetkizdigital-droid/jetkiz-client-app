# Payment client

JETKIZ mobile remains provider-agnostic: Flutter talks only to the JETKIZ backend.

## Security boundaries

- PayLink API keys and merchant credentials exist only on backend.
- PAN/CVV are entered only on the PayLink hosted HTTPS page and never pass through Flutter or JETKIZ backend.
- Saved-card provider tokens never leave backend and are encrypted at rest there. Flutter receives only display metadata such as brand, last4 and issuer bank.
- Hosted checkout URLs are treated as sensitive session data: they are redacted from app debug logging and are not persisted locally.
- A PayLink redirect/browser return is never proof of payment. Flutter accepts success only after `GET /payments/orders/:orderId` returns `fundsSecured=true`.

## Production checkout flow

1. Sync cart and revalidate prices/availability.
2. Create a CARD order with an idempotency key.
3. Call `POST /payments` with the order ID and either `savedPaymentMethodId` or explicit `saveCard=true` for a new card.
4. Open only an HTTPS checkout URL returned by JETKIZ backend.
5. Poll JETKIZ backend for the payment state after returning from PayLink.
6. Treat `AUTHORIZED` (or `PAID`) as secured funds; restaurant acceptance triggers backend CAPTURE.
7. Keep the cart when payment fails/pends; clear it only after backend confirms secured funds.
8. Persist only order/payment IDs for interrupted-flow recovery.

## Saved cards

- `GET /payments/methods` lists display-safe methods.
- `PATCH /payments/methods/:id/default` changes the default method.
- `DELETE /payments/methods/:id` removes a method.
- New cards are tokenized during a real PayLink checkout. JETKIZ intentionally does not implement a fake/zero-amount standalone add-card transaction.
