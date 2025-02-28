;; Buildify Token Contract
;; Implements tokenized real estate development projects

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-invalid-amount (err u104))

;; Define token
(define-fungible-token buildify-token)

;; Data structures
(define-map projects
    { project-id: uint }
    {
        developer: principal,
        total-supply: uint,
        available-supply: uint,
        price-per-token: uint,
        status: (string-ascii 20),
        funds-raised: uint,
        total-profits-distributed: uint
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
        (asserts! (> total-supply u0) err-invalid-amount)
        (asserts! (> price-per-token u0) err-invalid-amount)
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (map-set projects
            { project-id: project-id }
            {
                developer: tx-sender,
                total-supply: total-supply,
                available-supply: total-supply,
                price-per-token: price-per-token,
                status: "active",
                funds-raised: u0,
                total-profits-distributed: u0
            }
        )
        (var-set last-project-id project-id)
        (try! (ft-mint? buildify-token total-supply tx-sender))
        (ok project-id)
    )
)

;; Invest in project
(define-public (invest-in-project (project-id uint) (token-amount uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
        (total-cost (* token-amount (get price-per-token project)))
    )
    (asserts! (> token-amount u0) err-invalid-amount)
    (asserts! (is-eq (get status project) "active") err-unauthorized)
    (asserts! (<= token-amount (get available-supply project)) err-insufficient-funds)
    
    (try! (stx-transfer? total-cost tx-sender contract-owner))
    (try! (ft-transfer? buildify-token token-amount contract-owner tx-sender))
    
    (map-set project-investments
        { project-id: project-id, investor: tx-sender }
        { amount: token-amount }
    )
    (map-set projects
        { project-id: project-id }
        (merge project { 
            funds-raised: (+ (get funds-raised project) total-cost),
            available-supply: (- (get available-supply project) token-amount)
        })
    )
    (ok true)
    ))
)

;; Distribute profits
(define-public (distribute-profits (project-id uint) (amount-per-token uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
        (total-amount (* amount-per-token (get total-supply project)))
    )
    (asserts! (is-eq tx-sender (get developer project)) err-unauthorized)
    (asserts! (> amount-per-token u0) err-invalid-amount)
    
    (try! (stx-transfer? total-amount tx-sender contract-owner))
    (map-set projects
        { project-id: project-id }
        (merge project {
            total-profits-distributed: (+ (get total-profits-distributed project) total-amount)
        })
    )
    (ok true)
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
