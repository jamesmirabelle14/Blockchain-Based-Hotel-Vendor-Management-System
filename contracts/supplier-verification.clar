;; Supplier Verification Contract
;; This contract validates legitimate service providers for the hotel

(define-data-var admin principal tx-sender)

;; Supplier status: 0 = unverified, 1 = verified, 2 = rejected, 3 = suspended
(define-map suppliers
  { supplier-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    service-type: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

(define-data-var next-supplier-id uint u1)

;; Read-only function to get supplier details
(define-read-only (get-supplier (supplier-id uint))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Check if a supplier is verified
(define-read-only (is-verified (supplier-id uint))
  (let ((supplier (get-supplier supplier-id)))
    (and
      (is-some supplier)
      (is-eq (get status (unwrap-panic supplier)) u1)
    )
  )
)

;; Register a new supplier (unverified by default)
(define-public (register-supplier (name (string-utf8 100)) (service-type (string-utf8 50)))
  (let ((supplier-id (var-get next-supplier-id)))
    (begin
      (map-insert suppliers
        { supplier-id: supplier-id }
        {
          principal: tx-sender,
          name: name,
          service-type: service-type,
          status: u0,
          verification-date: u0
        }
      )
      (var-set next-supplier-id (+ supplier-id u1))
      (ok supplier-id)
    )
  )
)

;; Only admin can verify suppliers
(define-public (verify-supplier (supplier-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? suppliers { supplier-id: supplier-id })
      supplier (begin
        (map-set suppliers
          { supplier-id: supplier-id }
          (merge supplier {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Reject a supplier
(define-public (reject-supplier (supplier-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? suppliers { supplier-id: supplier-id })
      supplier (begin
        (map-set suppliers
          { supplier-id: supplier-id }
          (merge supplier { status: u2 })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Suspend a verified supplier
(define-public (suspend-supplier (supplier-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? suppliers { supplier-id: supplier-id })
      supplier (begin
        (asserts! (is-eq (get status supplier) u1) (err u400))
        (map-set suppliers
          { supplier-id: supplier-id }
          (merge supplier { status: u3 })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
