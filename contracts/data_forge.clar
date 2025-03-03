;; DataForge - Platform for data-driven apps

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-schema-inactive (err u104))
(define-constant err-batch-operation-failed (err u105))
(define-constant err-invalid-field-type (err u106))
(define-constant err-field-length-exceeded (err u107))
(define-constant err-required-field-missing (err u108))

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
    (asserts! (validate-field-types field-types) err-invalid-field-type)
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

;; Enhanced batch operations with validation
(define-public (create-entries (schema-id uint) (entries (list 20 (list 10 (string-utf8 256))))
    (let (
        (schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
        (validation-result (validate-entries schema entries))
    )
    (asserts! (is-ok validation-result) (unwrap-err! validation-result err-invalid-data))
    (ok (map create-single-entry entries)))
)

;; Validation functions
(define-private (validate-entries (schema { name: (string-ascii 64),
    owner: principal,
    version: uint,
    previous-version: (optional uint),
    fields: (list 10 (string-ascii 64)),
    field-types: (list 10 (string-ascii 16)),
    field-required: (list 10 bool),
    active: bool,
    created-at: uint }) 
    (entries (list 20 (list 10 (string-utf8 256)))))
    (begin
        (asserts! (get active schema) err-schema-inactive)
        (ok true))
)

(define-private (validate-field-types (types (list 10 (string-ascii 16))))
    (let ((valid-types (list "text" "number" "boolean" "date")))
        (fold check-type types true))
)

;; Enhanced query functionality with pagination
(define-read-only (get-entries-by-owner 
    (schema-id uint) 
    (owner principal) 
    (limit uint)
    (offset uint))
    (ok (filter get-entry-if-owner 
        (map uint-to-int 
            (get-page-indices offset limit))))
)

(define-private (get-page-indices (offset uint) (limit uint))
    (enumerate-from-to offset (+ offset limit)))

[Previous functions remain unchanged...]
