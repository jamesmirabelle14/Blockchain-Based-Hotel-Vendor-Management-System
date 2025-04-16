;; Service Level Contract
;; Defines performance expectations for hotel vendors

(define-data-var admin principal tx-sender)

;; Service level agreement structure
(define-map service-agreements
  { agreement-id: uint }
  {
    supplier-id: uint,
    service-type: (string-utf8 50),
    response-time-hours: uint,
    quality-threshold: uint,
    min-satisfaction-score: uint,
    penalties: uint,
    start-date: uint,
    end-date: uint,
    is-active: bool
  }
)

(define-data-var next-agreement-id uint u1)

;; Read-only function to get agreement details
(define-read-only (get-agreement (agreement-id uint))
  (map-get? service-agreements { agreement-id: agreement-id })
)

;; Check if an agreement is active
(define-read-only (is-agreement-active (agreement-id uint))
  (let ((agreement (get-agreement agreement-id)))
    (and
      (is-some agreement)
      (get is-active (unwrap-panic agreement))
      (>= (get end-date (unwrap-panic agreement)) block-height)
    )
  )
)

;; Create a new service level agreement
(define-public (create-agreement
  (supplier-id uint)
  (service-type (string-utf8 50))
  (response-time-hours uint)
  (quality-threshold uint)
  (min-satisfaction-score uint)
  (penalties uint)
  (duration-blocks uint))

  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (let ((agreement-id (var-get next-agreement-id)))
      (map-insert service-agreements
        { agreement-id: agreement-id }
        {
          supplier-id: supplier-id,
          service-type: service-type,
          response-time-hours: response-time-hours,
          quality-threshold: quality-threshold,
          min-satisfaction-score: min-satisfaction-score,
          penalties: penalties,
          start-date: block-height,
          end-date: (+ block-height duration-blocks),
          is-active: true
        }
      )
      (var-set next-agreement-id (+ agreement-id u1))
      (ok agreement-id)
    )
  )
)

;; Update an existing agreement
(define-public (update-agreement
  (agreement-id uint)
  (response-time-hours uint)
  (quality-threshold uint)
  (min-satisfaction-score uint)
  (penalties uint)
  (extend-blocks uint))

  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? service-agreements { agreement-id: agreement-id })
      agreement (begin
        (asserts! (get is-active agreement) (err u400))
        (map-set service-agreements
          { agreement-id: agreement-id }
          (merge agreement {
            response-time-hours: response-time-hours,
            quality-threshold: quality-threshold,
            min-satisfaction-score: min-satisfaction-score,
            penalties: penalties,
            end-date: (+ (get end-date agreement) extend-blocks)
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Terminate an agreement
(define-public (terminate-agreement (agreement-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? service-agreements { agreement-id: agreement-id })
      agreement (begin
        (asserts! (get is-active agreement) (err u400))
        (map-set service-agreements
          { agreement-id: agreement-id }
          (merge agreement { is-active: false })
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
