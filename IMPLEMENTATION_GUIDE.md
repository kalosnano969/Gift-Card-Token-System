# Loyalty Points System - Implementation Guide

## Step-by-Step Implementation

### Step 1: Add Error Constants
Added two new error constants for loyalty operations:
```clarity
(define-constant err-insufficient-points (err u112))
(define-constant err-invalid-discount (err u113))
```

### Step 2: Define Data Structures
Added loyalty points storage and configuration:
```clarity
(define-map user-loyalty-points
  { user: principal }
  { points: uint }
)

(define-data-var max-loyalty-discount uint u5000)
```

### Step 3: Implement Helper Functions
Created private functions for loyalty point management:

**get-user-loyalty-points** - Retrieves points with default of 0
```clarity
(define-private (get-user-loyalty-points (user principal))
  (default-to u0 (get points (map-get? user-loyalty-points { user: user })))
)
```

**set-user-loyalty-points** - Updates user's points
```clarity
(define-private (set-user-loyalty-points (user principal) (new-points uint))
  (map-set user-loyalty-points { user: user } { points: new-points })
)
```

**add-loyalty-points** - Increments user's points
```clarity
(define-private (add-loyalty-points (user principal) (points-to-add uint))
  (let ((current-points (get-user-loyalty-points user)))
    (set-user-loyalty-points user (+ current-points points-to-add))
  )
)
```

**subtract-loyalty-points** - Decrements user's points with validation
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

**calculate-loyalty-discount** - Computes fee discount from points
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

### Step 4: Integrate with Redemption Functions
Modified `redeem-gift-card` and `partial-redeem-gift-card` to award points:
```clarity
(add-loyalty-points tx-sender amount)
```

### Step 5: Integrate with Marketplace
Updated `buy-gift-card-from-marketplace` to:
- Calculate loyalty discount on marketplace fee
- Award points to buyer and seller
- Apply discounted fee to transaction

### Step 6: Add Public Management Functions
**redeem-loyalty-points** - Manual point redemption
```clarity
(define-public (redeem-loyalty-points (points-to-redeem uint))
  (begin
    (asserts! (> points-to-redeem u0) err-invalid-amount)
    (unwrap! (subtract-loyalty-points tx-sender points-to-redeem) err-insufficient-points)
    (ok true)
  )
)
```

**set-max-loyalty-discount** - Owner configuration
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

### Step 7: Add Query Functions
**get-user-loyalty-points-balance** - Check user's points
```clarity
(define-read-only (get-user-loyalty-points-balance (user principal))
  (get-user-loyalty-points user)
)
```

**calculate-loyalty-fee-discount** - Preview discount
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

**get-loyalty-stats** - System configuration
```clarity
(define-read-only (get-loyalty-stats)
  {
    max-loyalty-discount: (var-get max-loyalty-discount)
  }
)
```

## Verification

Run compilation check:
```bash
clarinet check
```

Expected result: ✅ No errors

## Integration Summary

- **Total Lines Added**: ~150 lines
- **Breaking Changes**: None
- **Backward Compatible**: Yes
- **Dependencies**: None (self-contained)

