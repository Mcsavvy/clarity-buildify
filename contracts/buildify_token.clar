;; Buildify Token Contract
;; Implements tokenized real estate development projects

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-funds (err u103))

;; Define token
(define-fungible-token buildify-token)

;; Data structures
(define-map projects
    { project-id: uint }
    {
        developer: principal,
        total-supply: uint,
        price-per-token: uint,
        status: (string-ascii 20),
        funds-raised: uint
    }
)

(define-map project-investments
    { project-id: uint, investor: principal }
    { amount: uint }
)

;; Data variables
(define-data-var last-project-id uint u0)

;; Create new development project
(define-public (create-project (total-supply uint) (price-per-token uint))
    (let
        (
            (project-id (+ (var-get last-project-id) u1))
        )
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set projects
                    { project-id: project-id }
                    {
                        developer: tx-sender,
                        total-supply: total-supply,
                        price-per-token: price-per-token,
                        status: "active",
                        funds-raised: u0
                    }
                )
                (var-set last-project-id project-id)
                (try! (ft-mint? buildify-token total-supply tx-sender))
                (ok project-id)
            )
            err-owner-only
        )
    )
)

;; Invest in project
(define-public (invest-in-project (project-id uint) (token-amount uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
        (total-cost (* token-amount (get price-per-token project)))
    )
    (if (and 
        (is-eq (get status project) "active")
        (<= token-amount (get total-supply project)))
        (begin
            (try! (stx-transfer? total-cost tx-sender contract-owner))
            (try! (ft-transfer? buildify-token token-amount contract-owner tx-sender))
            (map-set project-investments
                { project-id: project-id, investor: tx-sender }
                { amount: token-amount }
            )
            (map-set projects
                { project-id: project-id }
                (merge project { 
                    funds-raised: (+ (get funds-raised project) total-cost)
                })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Distribute profits
(define-public (distribute-profits (project-id uint) (amount-per-token uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (if (is-eq tx-sender (get developer project))
        (begin
            (try! (stx-transfer? (* amount-per-token (get total-supply project)) tx-sender contract-owner))
            (ok true)
        )
        err-unauthorized
    ))
)

;; Get project details
(define-read-only (get-project (project-id uint))
    (ok (map-get? projects { project-id: project-id }))
)

;; Get investment amount
(define-read-only (get-investment (project-id uint) (investor principal))
    (ok (map-get? project-investments { project-id: project-id, investor: investor }))
)