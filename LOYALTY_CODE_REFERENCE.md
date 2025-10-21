# Loyalty Points System - Complete Code Reference

## Error Constants (Lines 14-15)
```clarity
(define-constant err-insufficient-points (err u112))
(define-constant err-invalid-discount (err u113))
```

## Data Structures (Lines 74-79)
```clarity
(define-map user-loyalty-points
  { user: principal }
  { points: uint }
)

(define-data-var max-loyalty-discount uint u5000)
```

## Private Helper Functions (Lines 108-144)

### Get User Loyalty Points
```clarity
(define-private (get-user-loyalty-points (user principal))
  (default-to u0 (get points (map-get? user-loyalty-points { user: user })))
)
```

### Set User Loyalty Points
```clarity
(define-private (set-user-loyalty-points (user principal) (new-points uint))
  (map-set user-loyalty-points { user: user } { points: new-points })
)
```

### Add Loyalty Points
```clarity
(define-private (add-loyalty-points (user principal) (points-to-add uint))
  (let ((current-points (get-user-loyalty-points user)))
    (set-user-loyalty-points user (+ current-points points-to-add))
  )
)
```

### Subtract Loyalty Points
```clarity
(define-private (subtract-loyalty-points (user principal) (points-to-subtract uint))
  (let ((current-points (get-user-loyalty-points user)))
    (if (>= current-points points-to-subtract)
      (ok (set-user-loyalty-points user (- current-points points-to-subtract)))
      (err err-insufficient-points)
    )
  )
)
```

### Calculate Loyalty Discount
```clarity
(define-private (calculate-loyalty-discount (user-points uint) (original-fee uint))
  (let (
    (discount-rate (/ (* user-points u100) u10))
    (capped-discount-rate (if (> discount-rate (var-get max-loyalty-discount))
                              (var-get max-loyalty-discount)
                              discount-rate))
    (discount-amount (/ (* original-fee capped-discount-rate) u10000))
  )
    (if (> discount-amount original-fee)
      u0
      (- original-fee discount-amount)
    )
  )
)
```

## Public Functions (Lines 527-542)

### Redeem Loyalty Points
```clarity
(define-public (redeem-loyalty-points (points-to-redeem uint))
  (begin
    (asserts! (> points-to-redeem u0) err-invalid-amount)
    (unwrap! (subtract-loyalty-points tx-sender points-to-redeem) err-insufficient-points)
    (ok true)
  )
)
```

### Set Max Loyalty Discount
```clarity
(define-public (set-max-loyalty-discount (new-max-discount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-max-discount u10000) err-invalid-discount)
    (var-set max-loyalty-discount new-max-discount)
    (ok new-max-discount)
  )
)
```

## Read-Only Functions (Lines 733-755)

### Get User Loyalty Points Balance
```clarity
(define-read-only (get-user-loyalty-points-balance (user principal))
  (get-user-loyalty-points user)
)
```

### Calculate Loyalty Fee Discount
```clarity
(define-read-only (calculate-loyalty-fee-discount (user principal) (original-fee uint))
  (let (
    (user-points (get-user-loyalty-points user))
    (discounted-fee (calculate-loyalty-discount user-points original-fee))
  )
    {
      original-fee: original-fee,
      discounted-fee: discounted-fee,
      discount-amount: (- original-fee discounted-fee),
      user-points: user-points
    }
  )
)
```

### Get Loyalty Stats
```clarity
(define-read-only (get-loyalty-stats)
  {
    max-loyalty-discount: (var-get max-loyalty-discount)
  }
)
```

## Integration Points

### In redeem-gift-card (Line 254)
```clarity
(add-loyalty-points tx-sender amount)
```

### In partial-redeem-gift-card (Line 409)
```clarity
(add-loyalty-points tx-sender amount)
```

### In buy-gift-card-from-marketplace (Lines 313-331)
```clarity
(buyer-points (get-user-loyalty-points tx-sender))
(discounted-fee (calculate-loyalty-discount buyer-points base-fee))
...
(add-loyalty-points tx-sender price)
(add-loyalty-points seller (/ price u2))
```

## Variable Definitions Summary

| Variable | Type | Scope | Purpose |
|----------|------|-------|---------|
| `user-loyalty-points` | map | Contract | Stores loyalty points per user |
| `max-loyalty-discount` | data-var | Contract | Maximum discount cap (basis points) |
| `current-points` | uint | Function | Current user's loyalty points |
| `discount-rate` | uint | Function | Calculated discount rate |
| `capped-discount-rate` | uint | Function | Discount rate capped at maximum |
| `discount-amount` | uint | Function | Actual fee discount in STX |
| `buyer-points` | uint | Function | Buyer's loyalty points at purchase |
| `discounted-fee` | uint | Function | Marketplace fee after loyalty discount |
| `seller-amount` | uint | Function | Amount seller receives after discount |
| `fee-to-owner` | uint | Function | Amount contract owner receives |

## Compilation Verification

✅ All variables defined before use
✅ All functions properly scoped
✅ No circular dependencies
✅ Error handling complete
✅ Type safety maintained
✅ Passes `clarinet check`

