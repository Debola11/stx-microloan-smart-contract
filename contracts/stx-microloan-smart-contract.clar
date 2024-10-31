
;; Microloan Smart Contract
;; Fixed version with proper state management and error handling

;; Constants for errors
(define-constant ERR-OVERFLOW (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-LOAN-EXISTS (err u103))
(define-constant ERR-LOAN-NOT-FOUND (err u104))
(define-constant ERR-UNAUTHORIZED (err u105))
(define-constant ERR-INVALID-TERM (err u106))
(define-constant ERR-INVALID-RATE (err u107))
(define-constant ERR-LOAN-EXPIRED (err u108))
(define-constant ERR-LOAN-NOT-ACTIVE (err u109))
(define-constant ERR-ZERO-ADDRESS (err u110))

;; Other constants
(define-constant contract-owner tx-sender)
(define-constant blocks-per-day u144) ;; approximately 144 blocks per day on Stacks
(define-constant minimum-loan-amount u1000000) ;; 1 STX minimum
(define-constant maximum-loan-amount u1000000000) ;; 1000 STX maximum
(define-constant minimum-term-blocks (* blocks-per-day u7)) ;; Minimum 7 days
(define-constant maximum-term-blocks (* blocks-per-day u365)) ;; Maximum 365 days

;; Data Variables - Contract State
(define-data-var contract-paused bool false)
(define-data-var total-pool-amount uint u0)
(define-data-var total-active-loans uint u0)

;; Data Maps
(define-map loans
    { borrower: principal }
    {
        principal-amount: uint,
        interest-rate: uint,
        start-height: uint,
        end-height: uint,
        total-repaid: uint,
        status: (string-ascii 20),
        reputation-score: uint,
        last-payment-height: uint
    }
)

(define-map lending-pool-shares
    { lender: principal }
    { 
        amount: uint,
        last-deposit-height: uint
    }
)

;; Helper Functions
(define-private (safe-add (a uint) (b uint))
    (let ((sum (+ a b)))
        (if (>= sum a)
            (ok sum)
            ERR-OVERFLOW))
)

(define-private (safe-subtract (a uint) (b uint))
    (if (>= a b)
        (ok (- a b))
        ERR-OVERFLOW)
)

(define-private (safe-divide (a uint) (b uint))
    (if (> b u0)
        (ok (/ a b))
        ERR-INVALID-AMOUNT)
)

;; Validation Functions
(define-private (is-valid-loan-amount (amount uint))
    (and 
        (>= amount minimum-loan-amount)
        (<= amount maximum-loan-amount)
    )
)

(define-private (is-valid-term (term-blocks uint))
    (and 
        (>= term-blocks minimum-term-blocks)
        (<= term-blocks maximum-term-blocks)
    )
)
