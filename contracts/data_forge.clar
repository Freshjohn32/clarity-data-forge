;; DataForge - Platform for data-driven apps

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-schema-inactive (err u104))
(define-constant err-batch-operation-failed (err u105))

;; Data structures
(define-map schemas
    { schema-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        version: uint,
        previous-version: (optional uint),
        fields: (list 10 (string-ascii 64)),
        field-types: (list 10 (string-ascii 16)),
        field-required: (list 10 bool),
        active: bool,
        created-at: uint
    }
)

;; [Previous data structures remain unchanged...]

;; Enhanced schema management
(define-public (create-schema-version 
    (schema-id uint)
    (fields (list 10 (string-ascii 64)))
    (field-types (list 10 (string-ascii 16)))
    (field-required (list 10 bool)))
    (let (
        (current-schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
        (new-schema-id (var-get next-schema-id))
    )
    (asserts! (is-eq tx-sender (get owner current-schema)) err-unauthorized)
    (map-set schemas
        { schema-id: new-schema-id }
        {
            name: (get name current-schema),
            owner: tx-sender,
            version: (+ (get version current-schema) u1),
            previous-version: (some schema-id),
            fields: fields,
            field-types: field-types,
            field-required: field-required,
            active: true,
            created-at: block-height
        }
    )
    (var-set next-schema-id (+ new-schema-id u1))
    (ok new-schema-id))
)

;; Batch operations
(define-public (create-entries (schema-id uint) (entries (list 20 (list 10 (string-utf8 256)))))
    (let (
        (schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
        (results (map create-single-entry entries))
    )
    (ok results))
)

(define-private (create-single-entry (data (list 10 (string-utf8 256))))
    (let (
        (entry-id (var-get next-entry-id))
    )
    (var-set next-entry-id (+ entry-id u1))
    entry-id)
)

;; Query functionality
(define-read-only (get-entries-by-owner (schema-id uint) (owner principal) (limit uint))
    (ok (filter get-entry-if-owner 
        (map uint-to-int (enumerate limit))))
)

(define-private (get-entry-if-owner (index int))
    (match (map-get? data-entries 
        { schema-id: schema-id, entry-id: (to-uint index) })
        entry (is-eq (get owner entry) owner)
        false)
)

;; [Previous functions remain unchanged...]
