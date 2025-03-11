;; Prescription Issuance Contract
;; Records doctor-issued prescriptions

(define-map prescriptions
  { prescription-id: uint }
  {
    patient: principal,
    doctor: principal,
    medication: (string-ascii 64),
    dosage: (string-ascii 32),
    quantity: uint,
    refills: uint,
    issue-date: uint,
    expiration-date: uint,
    is-controlled: bool
  }
)

(define-data-var last-prescription-id uint u0)

(define-constant contract-owner tx-sender)

(define-read-only (get-prescription (prescription-id uint))
  (map-get? prescriptions { prescription-id: prescription-id })
)

(define-public (issue-prescription
    (patient principal)
    (medication (string-ascii 64))
    (dosage (string-ascii 32))
    (quantity uint)
    (refills uint)
    (expiration-days uint)
    (is-controlled bool))
  (let
    (
      (new-prescription-id (+ (var-get last-prescription-id) u1))
      (expiration-date (+ block-height (* expiration-days u144))) ;; Assuming 144 blocks per day
    )
    (asserts! (is-eq tx-sender contract-owner) (err u403)) ;; Only contract owner (hospital) can issue prescriptions
    (var-set last-prescription-id new-prescription-id)
    (ok (map-set prescriptions
      { prescription-id: new-prescription-id }
      {
        patient: patient,
        doctor: tx-sender,
        medication: medication,
        dosage: dosage,
        quantity: quantity,
        refills: refills,
        issue-date: block-height,
        expiration-date: expiration-date,
        is-controlled: is-controlled
      }
    ))
  )
)

(define-read-only (is-prescription-valid (prescription-id uint))
  (match (get-prescription prescription-id)
    prescription (< block-height (get expiration-date prescription))
    false
  )
)

