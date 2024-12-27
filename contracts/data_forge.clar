;; DataForge - Platform for data-driven apps

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data structures
(define-map schemas
    { schema-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        version: uint,
        fields: (list 10 (string-ascii 64)),
        active: bool
    }
)

(define-map data-entries
    { schema-id: uint, entry-id: uint }
    {
        owner: principal,
        data: (list 10 (string-utf8 256)),
        created-at: uint,
        updated-at: uint
    }
)

(define-map permissions
    { schema-id: uint, user: principal }
    { can-read: bool, can-write: bool }
)

;; Data vars
(define-data-var next-schema-id uint u1)
(define-data-var next-entry-id uint u1)

;; Schema management
(define-public (create-schema (name (string-ascii 64)) (fields (list 10 (string-ascii 64))))
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
        (can-write (get can-write (default-to { can-read: false, can-write: false }
            (map-get? permissions { schema-id: schema-id, user: tx-sender }))))
    )
    (asserts! (or (is-eq tx-sender contract-owner) can-write) err-unauthorized)
    (map-set data-entries
        { schema-id: schema-id, entry-id: entry-id }
        {
            owner: tx-sender,
            data: data,
            created-at: block-height,
            updated-at: block-height
        }
    )
    (var-set next-entry-id (+ entry-id u1))
    (ok entry-id)
    )
)

;; Permission management
(define-public (set-permissions (schema-id uint) (user principal) (can-read bool) (can-write bool))
    (let (
        (schema (unwrap! (map-get? schemas { schema-id: schema-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner schema)) err-unauthorized)
    (ok (map-set permissions
        { schema-id: schema-id, user: user }
        { can-read: can-read, can-write: can-write }
    )))
)

;; Read functions
(define-read-only (get-schema (schema-id uint))
    (ok (map-get? schemas { schema-id: schema-id }))
)

(define-read-only (get-entry (schema-id uint) (entry-id uint))
    (let (
        (entry (map-get? data-entries { schema-id: schema-id, entry-id: entry-id }))
        (can-read (get can-read (default-to { can-read: false, can-write: false }
            (map-get? permissions { schema-id: schema-id, user: tx-sender }))))
    )
    (asserts! (or (is-eq tx-sender contract-owner) can-read) err-unauthorized)
    (ok entry)
    )
)