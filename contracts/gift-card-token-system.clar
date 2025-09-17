(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-expired (err u102))
(define-constant err-already-redeemed (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-unauthorized (err u106))
(define-constant err-gift-card-exists (err u107))
(define-constant err-already-listed (err u108))
(define-constant err-not-listed (err u109))
(define-constant err-invalid-price (err u110))
(define-constant err-cannot-buy-own (err u111))

(define-data-var next-gift-card-id uint u1)
(define-data-var contract-balance uint u0)
(define-data-var total-marketplace-sales uint u0)
(define-data-var marketplace-fee-rate uint u250)

(define-map gift-cards 
  { gift-card-id: uint }
  {
    issuer: principal,
    recipient: principal,
    amount: uint,
    remaining-balance: uint,
    expiration-block: uint,
    is-redeemed: bool,
    is-active: bool,
    created-at: uint
  }
)

(define-map user-balances 
  { user: principal }
  { balance: uint }
)

(define-map gift-card-ownership 
  { gift-card-id: uint }
  { owner: principal }
)

(define-map user-gift-cards
  { user: principal, gift-card-id: uint }
  { exists: bool }
)

(define-map marketplace-listings
  { gift-card-id: uint }
  {
    seller: principal,
    price: uint,
    listed-at: uint,
    is-active: bool
  }
)

(define-map marketplace-sales
  { sale-id: uint }
  {
    gift-card-id: uint,
    seller: principal,
    buyer: principal,
    price: uint,
    completed-at: uint
  }
)

(define-data-var next-sale-id uint u1)

(define-private (get-user-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-private (set-user-balance (user principal) (new-balance uint))
  (map-set user-balances { user: user } { balance: new-balance })
)

(define-private (add-to-user-balance (user principal) (amount uint))
  (let ((current-balance (get-user-balance user)))
    (set-user-balance user (+ current-balance amount))
  )
)

(define-private (subtract-from-user-balance (user principal) (amount uint))
  (let ((current-balance (get-user-balance user)))
    (if (>= current-balance amount)
      (ok (set-user-balance user (- current-balance amount)))
      (err err-insufficient-balance)
    )
  )
)

(define-private (is-expired (expiration-block uint))
  (> stacks-block-height expiration-block)
)

(define-private (add-gift-card-to-user (user principal) (gift-card-id uint))
  (map-set user-gift-cards 
    { user: user, gift-card-id: gift-card-id }
    { exists: true }
  )
)

(define-private (remove-gift-card-from-user (user principal) (gift-card-id uint))
  (map-delete user-gift-cards { user: user, gift-card-id: gift-card-id })
)

(define-read-only (get-gift-card (gift-card-id uint))
  (map-get? gift-cards { gift-card-id: gift-card-id })
)

(define-read-only (get-gift-card-owner (gift-card-id uint))
  (map-get? gift-card-ownership { gift-card-id: gift-card-id })
)

(define-read-only (get-balance (user principal))
  (get-user-balance user)
)

(define-read-only (user-owns-gift-card (user principal) (gift-card-id uint))
  (is-some (map-get? user-gift-cards { user: user, gift-card-id: gift-card-id }))
)

(define-read-only (get-contract-balance)
  (var-get contract-balance)
)

(define-read-only (get-next-gift-card-id)
  (var-get next-gift-card-id)
)

(define-read-only (get-marketplace-listing (gift-card-id uint))
  (map-get? marketplace-listings { gift-card-id: gift-card-id })
)

(define-read-only (get-marketplace-sale (sale-id uint))
  (map-get? marketplace-sales { sale-id: sale-id })
)

(define-read-only (is-listed-on-marketplace (gift-card-id uint))
  (match (get-marketplace-listing gift-card-id)
    listing (get is-active listing)
    false
  )
)

(define-public (issue-gift-card (recipient principal) (amount uint) (expiration-blocks uint))
  (let (
    (gift-card-id (var-get next-gift-card-id))
    (expiration-block (+ stacks-block-height expiration-blocks))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> expiration-blocks u0) err-invalid-amount)
    
    (map-set gift-cards 
      { gift-card-id: gift-card-id }
      {
        issuer: tx-sender,
        recipient: recipient,
        amount: amount,
        remaining-balance: amount,
        expiration-block: expiration-block,
        is-redeemed: false,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    
    (map-set gift-card-ownership 
      { gift-card-id: gift-card-id }
      { owner: recipient }
    )
    
    (add-gift-card-to-user recipient gift-card-id)
    (var-set next-gift-card-id (+ gift-card-id u1))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    
    (ok gift-card-id)
  )
)

(define-public (redeem-gift-card (gift-card-id uint) (amount uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
    (owner-info (unwrap! (get-gift-card-owner gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner owner-info)) err-unauthorized)
    (asserts! (get is-active gift-card) err-not-found)
    (asserts! (not (get is-redeemed gift-card)) err-already-redeemed)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (>= (get remaining-balance gift-card) amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    
    (let ((new-remaining-balance (- (get remaining-balance gift-card) amount)))
      (map-set gift-cards 
        { gift-card-id: gift-card-id }
        (merge gift-card {
          remaining-balance: new-remaining-balance,
          is-redeemed: (is-eq new-remaining-balance u0)
        })
      )
      
      (add-to-user-balance tx-sender amount)
      (var-set contract-balance (- (var-get contract-balance) amount))
      
      (ok amount)
    )
  )
)

(define-public (list-gift-card-on-marketplace (gift-card-id uint) (price uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
    (owner-info (unwrap! (get-gift-card-owner gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner owner-info)) err-unauthorized)
    (asserts! (get is-active gift-card) err-not-found)
    (asserts! (not (get is-redeemed gift-card)) err-already-redeemed)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (> (get remaining-balance gift-card) u0) err-insufficient-balance)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (<= price (get remaining-balance gift-card)) err-invalid-price)
    (asserts! (not (is-listed-on-marketplace gift-card-id)) err-already-listed)
    
    (map-set marketplace-listings
      { gift-card-id: gift-card-id }
      {
        seller: tx-sender,
        price: price,
        listed-at: stacks-block-height,
        is-active: true
      }
    )
    
    (ok true)
  )
)

(define-public (delist-gift-card-from-marketplace (gift-card-id uint))
  (let (
    (listing (unwrap! (get-marketplace-listing gift-card-id) err-not-listed))
  )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (get is-active listing) err-not-listed)
    
    (map-set marketplace-listings
      { gift-card-id: gift-card-id }
      (merge listing { is-active: false })
    )
    
    (ok true)
  )
)

(define-public (buy-gift-card-from-marketplace (gift-card-id uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
    (listing (unwrap! (get-marketplace-listing gift-card-id) err-not-listed))
    (seller (get seller listing))
    (price (get price listing))
    (marketplace-fee (/ (* price (var-get marketplace-fee-rate)) u10000))
    (seller-amount (- price marketplace-fee))
    (sale-id (var-get next-sale-id))
  )
    (asserts! (get is-active listing) err-not-listed)
    (asserts! (get is-active gift-card) err-not-found)
    (asserts! (not (get is-redeemed gift-card)) err-already-redeemed)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (not (is-eq tx-sender seller)) err-cannot-buy-own)
    (asserts! (>= (get-user-balance tx-sender) price) err-insufficient-balance)
    
    (unwrap! (subtract-from-user-balance tx-sender price) err-insufficient-balance)
    (add-to-user-balance seller seller-amount)
    (add-to-user-balance contract-owner marketplace-fee)
    
    (map-set gift-card-ownership 
      { gift-card-id: gift-card-id }
      { owner: tx-sender }
    )
    
    (remove-gift-card-from-user seller gift-card-id)
    (add-gift-card-to-user tx-sender gift-card-id)
    
    (map-set marketplace-listings
      { gift-card-id: gift-card-id }
      (merge listing { is-active: false })
    )
    
    (map-set marketplace-sales
      { sale-id: sale-id }
      {
        gift-card-id: gift-card-id,
        seller: seller,
        buyer: tx-sender,
        price: price,
        completed-at: stacks-block-height
      }
    )
    
    (var-set next-sale-id (+ sale-id u1))
    (var-set total-marketplace-sales (+ (var-get total-marketplace-sales) u1))
    
    (ok sale-id)
  )
)

(define-public (transfer-gift-card (gift-card-id uint) (new-owner principal))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
    (owner-info (unwrap! (get-gift-card-owner gift-card-id) err-not-found))
    (current-owner (get owner owner-info))
  )
    (asserts! (is-eq tx-sender current-owner) err-unauthorized)
    (asserts! (get is-active gift-card) err-not-found)
    (asserts! (not (get is-redeemed gift-card)) err-already-redeemed)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (> (get remaining-balance gift-card) u0) err-insufficient-balance)
    
    (map-set gift-card-ownership 
      { gift-card-id: gift-card-id }
      { owner: new-owner }
    )
    
    (remove-gift-card-from-user current-owner gift-card-id)
    (add-gift-card-to-user new-owner gift-card-id)
    
    (ok true)
  )
)

(define-public (partial-redeem-gift-card (gift-card-id uint) (amount uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
    (owner-info (unwrap! (get-gift-card-owner gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner owner-info)) err-unauthorized)
    (asserts! (get is-active gift-card) err-not-found)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (>= (get remaining-balance gift-card) amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    
    (let ((new-remaining-balance (- (get remaining-balance gift-card) amount)))
      (map-set gift-cards 
        { gift-card-id: gift-card-id }
        (merge gift-card {
          remaining-balance: new-remaining-balance,
          is-redeemed: (is-eq new-remaining-balance u0)
        })
      )
      
      (add-to-user-balance tx-sender amount)
      (var-set contract-balance (- (var-get contract-balance) amount))
      
      (ok new-remaining-balance)
    )
  )
)

(define-public (deactivate-gift-card (gift-card-id uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set gift-cards 
      { gift-card-id: gift-card-id }
      (merge gift-card { is-active: false })
    )
    
    (ok true)
  )
)

(define-public (withdraw-expired-funds (gift-card-id uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-expired (get expiration-block gift-card)) err-not-found)
    (asserts! (> (get remaining-balance gift-card) u0) err-insufficient-balance)
    
    (let ((expired-amount (get remaining-balance gift-card)))
      (map-set gift-cards 
        { gift-card-id: gift-card-id }
        (merge gift-card {
          remaining-balance: u0,
          is-redeemed: true,
          is-active: false
        })
      )
      
      (add-to-user-balance contract-owner expired-amount)
      (var-set contract-balance (- (var-get contract-balance) expired-amount))
      
      (ok expired-amount)
    )
  )
)

(define-public (fund-contract (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    
    (ok amount)
  )
)

(define-public (withdraw-from-balance (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    
    (let ((user-balance (get-user-balance tx-sender)))
      (asserts! (>= user-balance amount) err-insufficient-balance)
      
      (unwrap! (subtract-from-user-balance tx-sender amount) err-insufficient-balance)
      (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
      
      (ok amount)
    )
  )
)

(define-public (batch-issue-gift-cards (recipients (list 10 principal)) (amount uint) (expiration-blocks uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> expiration-blocks u0) err-invalid-amount)
    
    (ok (map issue-single-gift-card recipients))
  )
)

(define-private (issue-single-gift-card (recipient principal))
  (let (
    (gift-card-id (var-get next-gift-card-id))
    (expiration-block (+ stacks-block-height u144)) 
  )
    (map-set gift-cards 
      { gift-card-id: gift-card-id }
      {
        issuer: contract-owner,
        recipient: recipient,
        amount: u100,
        remaining-balance: u100,
        expiration-block: expiration-block,
        is-redeemed: false,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    
    (map-set gift-card-ownership 
      { gift-card-id: gift-card-id }
      { owner: recipient }
    )
    
    (add-gift-card-to-user recipient gift-card-id)
    (var-set next-gift-card-id (+ gift-card-id u1))
    (var-set contract-balance (+ (var-get contract-balance) u100))
    
    gift-card-id
  )
)

(define-read-only (is-gift-card-valid (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (and 
      (get is-active gift-card)
      (not (get is-redeemed gift-card))
      (not (is-expired (get expiration-block gift-card)))
      (> (get remaining-balance gift-card) u0)
    )
    false
  )
)

(define-read-only (get-gift-card-status (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (some {
      gift-card-id: gift-card-id,
      amount: (get amount gift-card),
      remaining-balance: (get remaining-balance gift-card),
      is-active: (get is-active gift-card),
      is-redeemed: (get is-redeemed gift-card),
      is-expired: (is-expired (get expiration-block gift-card)),
      is-valid: (is-gift-card-valid gift-card-id),
      expiration-block: (get expiration-block gift-card),
      blocks-until-expiry: (if (> (get expiration-block gift-card) stacks-block-height)
                              (- (get expiration-block gift-card) stacks-block-height)
                              u0)
    })
    none
  )
)

(define-read-only (get-user-gift-card-count (user principal))
  (len (filter is-user-gift-card (list 
    u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20
  )))
)

(define-private (is-user-gift-card (gift-card-id uint))
  (user-owns-gift-card tx-sender gift-card-id)
)

(define-read-only (get-total-issued-value)
  (fold + (map get-gift-card-amount (list 
    u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20
  )) u0)
)

(define-private (get-gift-card-amount (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (get amount gift-card)
    u0
  )
)

(define-read-only (get-total-redeemed-value)
  (fold + (map get-redeemed-amount (list 
    u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20
  )) u0)
)

(define-private (get-redeemed-amount (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (- (get amount gift-card) (get remaining-balance gift-card))
    u0
  )
)

(define-public (emergency-pause-all)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map deactivate-card (list 
      u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20
    ))
    
    (ok true)
  )
)

(define-private (deactivate-card (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (map-set gift-cards 
      { gift-card-id: gift-card-id }
      (merge gift-card { is-active: false })
    )
    true
  )
)

(define-public (reactivate-gift-card (gift-card-id uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (is-expired (get expiration-block gift-card))) err-expired)
    (asserts! (> (get remaining-balance gift-card) u0) err-insufficient-balance)
    
    (map-set gift-cards 
      { gift-card-id: gift-card-id }
      (merge gift-card { is-active: true })
    )
    
    (ok true)
  )
)

(define-public (extend-expiration (gift-card-id uint) (additional-blocks uint))
  (let (
    (gift-card (unwrap! (get-gift-card gift-card-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> additional-blocks u0) err-invalid-amount)
    
    (map-set gift-cards 
      { gift-card-id: gift-card-id }
      (merge gift-card {
        expiration-block: (+ (get expiration-block gift-card) additional-blocks)
      })
    )
    
    (ok (+ (get expiration-block gift-card) additional-blocks))
  )
)

(define-read-only (calculate-bulk-issue-cost (count uint) (amount uint))
  (* count amount)
)

(define-public (set-marketplace-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u1000) err-invalid-amount)
    
    (var-set marketplace-fee-rate new-rate)
    (ok new-rate)
  )
)

(define-public (force-delist-gift-card (gift-card-id uint))
  (let (
    (listing (unwrap! (get-marketplace-listing gift-card-id) err-not-listed))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get is-active listing) err-not-listed)
    
    (map-set marketplace-listings
      { gift-card-id: gift-card-id }
      (merge listing { is-active: false })
    )
    
    (ok true)
  )
)

(define-read-only (calculate-marketplace-fee (price uint))
  (/ (* price (var-get marketplace-fee-rate)) u10000)
)

(define-read-only (get-marketplace-stats)
  {
    total-sales: (var-get total-marketplace-sales),
    current-fee-rate: (var-get marketplace-fee-rate),
    next-sale-id: (var-get next-sale-id)
  }
)

(define-read-only (get-gift-card-with-listing (gift-card-id uint))
  (match (get-gift-card gift-card-id)
    gift-card (some {
      gift-card: gift-card,
      owner: (get owner (default-to { owner: contract-owner } (get-gift-card-owner gift-card-id))),
      listing: (get-marketplace-listing gift-card-id),
      is-listed: (is-listed-on-marketplace gift-card-id),
      is-valid: (is-gift-card-valid gift-card-id)
    })
    none
  )
)

(define-read-only (get-contract-stats)
  {
    total-gift-cards: (- (var-get next-gift-card-id) u1),
    contract-balance: (var-get contract-balance),
    total-issued-value: (get-total-issued-value),
    total-redeemed-value: (get-total-redeemed-value),
    marketplace-stats: (get-marketplace-stats)
  }
)
