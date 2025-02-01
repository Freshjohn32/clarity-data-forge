;; DataForge - Platform for data-driven apps

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101)) 
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-data (err u103))
(define-constant err-schema-inactive (err u104))

;; Data structures
(define-map schemas
    { schema-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        version: uint,
        fields: (list 10 (string-ascii 64)),
        field-types: (list 10 (string-ascii 16)),
        field-required: (list 10 bool),
        active: bool
    }
)

(define-map data-entries
    { schema-id: uint, entry-id: uint }
    {
        owner: principal,
        data: (list 10 (string-utf8 256)),
        created-at: uint,
        updated-at: uint,
        verified: bool
    }
)

(define-map permissions
    { schema-id: uint, user: principal }
    { can-read: bool, can-write: bool, can-verify: bool }
)

;; Data vars  
(define-data-var next-schema-id uint u1)
(define-data-var next-entry-id uint u1)

;; Data validation functions
(define-private (validate-field (value (string-utf8 256)) (type (string-ascii 16)))
    (match type
        "number" (match (string-to-uint? value) success true false)
        "date" (match (string-to-uint? value) success true false) 
        "email" (and 
            (is-some (index-of value "@"))
            (> (len value) u5))
        "url" (and
            (is-some (index-of value "http"))
            (> (len value) u8))
        true
    )
)

(define-private (validate-entry-data (data (list 10 (string-utf8 256))) (types (list 10 (string-ascii 16))) (required (list 10 bool)))
    (begin
        (asserts! 
            (fold and true (map validate-field data types))
            err-invalid-data)
        (asserts!
            (fold and true (map #(or (not %2) (> (len %1) u0)) data required))
            err-invalid-data)
        true
    )
)

;; Schema management 
(define-public (create-schema 
    (name (string-ascii 64))
    (fields (list 10 (string-ascii 64)))
    (field-types (list 10 (string-ascii 16)))
    (field-required (list 10 bool)))
    (let (
        (schema-id (var-get next-schema-id))
    )
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set schemas
                { schema-id: schema-id }
                {
                    name: name,
                    owner: tx-sender,
                    version: u1,
                    fields: fields,
                    field-types: field-types,
                    field-required: field-required,
                    active: true
                }
            )
            (var-set next-schema-id (+ schema-id u1))
            (ok schema-id)
        )
        err-owner-only
    ))
)

;; Data entry management
(define-public (create-entry (schema-id uint) (data (list 10 (string-utf8 256))))
    (let (
        (entry-id (var-get next-entry-id))
        (schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
        (can-write (get can-write (default-to { can-read: false, can-write: false, can-verify: false }
            (map-get? permissions { schema-id: schema-id, user: tx-sender }))))
    )
    (asserts! (get active schema) err-schema-inactive)
    (asserts! (or (is-eq tx-sender contract-owner) can-write) err-unauthorized)
    (asserts! (validate-entry-data data (get field-types schema) (get field-required schema)) err-invalid-data)
    (map-set data-entries
        { schema-id: schema-id, entry-id: entry-id }
        {
            owner: tx-sender,
            data: data,
            created-at: block-height,
            updated-at: block-height,
            verified: false
        }
    )
    (var-set next-entry-id (+ entry-id u1))
    (ok entry-id)
    )
)

;; Entry verification
(define-public (verify-entry (schema-id uint) (entry-id uint))
    (let (
        (entry (unwrap! (map-get? data-entries { schema-id: schema-id, entry-id: entry-id }) err-not-found))
        (can-verify (get can-verify (default-to { can-read: false, can-write: false, can-verify: false }
            (map-get? permissions { schema-id: schema-id, user: tx-sender }))))
    )
    (asserts! (or (is-eq tx-sender contract-owner) can-verify) err-unauthorized)
    (ok (map-set data-entries
        { schema-id: schema-id, entry-id: entry-id }
        (merge entry { verified: true })
    )))
)

;; Permission management
(define-public (set-permissions (schema-id uint) (user principal) (can-read bool) (can-write bool) (can-verify bool))
    (let (
        (schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner schema)) err-unauthorized)
    (ok (map-set permissions
        { schema-id: schema-id, user: user }
        { can-read: can-read, can-write: can-write, can-verify: can-verify }
    )))
)

;; Read functions
(define-read-only (get-schema (schema-id uint))
    (ok (map-get? schemas { schema-id: schema-id }))
)

(define-read-only (get-entry (schema-id uint) (entry-id uint))
    (let (
        (entry (map-get? data-entries { schema-id: schema-id, entry-id: entry-id }))
        (can-read (get can-read (default-to { can-read: false, can-write: false, can-verify: false }
            (map-get? permissions { schema-id: schema-id, user: tx-sender }))))
    )
    (asserts! (or (is-eq tx-sender contract-owner) can-read) err-unauthorized)
    (ok entry)
    )
)
