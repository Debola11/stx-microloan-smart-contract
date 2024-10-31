
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

(define-private (is-valid-rate (rate uint))
    (and 
        (> rate u0)
        (<= rate u1000000) ;; Max 100% APR represented as 1000000/1000000
    )
)

(define-read-only (is-contract-active)
    (not (var-get contract-paused))
)

;; Main Functions
(define-public (contribute-to-pool (amount uint))
    (begin
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-loan-amount amount) ERR-INVALID-AMOUNT)

        (let ((new-total (try! (safe-add (var-get total-pool-amount) amount))))
            (asserts! (<= new-total maximum-loan-amount) ERR-OVERFLOW)

            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

            (let ((current-share (default-to 
                    { amount: u0, last-deposit-height: u0 } 
                    (map-get? lending-pool-shares { lender: tx-sender }))))

                (let ((new-amount (try! (safe-add (get amount current-share) amount))))
                    (map-set lending-pool-shares
                        { lender: tx-sender }
                        { 
                            amount: new-amount,
                            last-deposit-height: block-height
                        }
                    )

                    (var-set total-pool-amount new-total)
                    (ok true)
                )
            )
        )
    )
)

(define-public (request-loan (amount uint) (term-blocks uint))
    (let (
        (borrower tx-sender)
        (current-height block-height)
        (end-height (+ current-height term-blocks))
    )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (not (is-eq borrower (as-contract tx-sender))) ERR-ZERO-ADDRESS)

        (asserts! (is-valid-loan-amount amount) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-term term-blocks) ERR-INVALID-TERM)
        (asserts! (<= amount (var-get total-pool-amount)) ERR-INSUFFICIENT-BALANCE)
        (asserts! (is-none (map-get? loans { borrower: borrower })) ERR-LOAN-EXISTS)

        (try! (stx-transfer? amount (as-contract tx-sender) borrower))

        (let (
            (new-pool-amount (try! (safe-subtract (var-get total-pool-amount) amount)))
            (new-active-loans (try! (safe-add (var-get total-active-loans) u1)))
        )
            (map-set loans
                { borrower: borrower }
                {
                    principal-amount: amount,
                    interest-rate: u50000, ;; 5% represented as 50000/1000000
                    start-height: current-height,
                    end-height: end-height,
                    total-repaid: u0,
                    status: "ACTIVE",
                    reputation-score: u100,
                    last-payment-height: current-height
                }
            )

            (var-set total-pool-amount new-pool-amount)
            (var-set total-active-loans new-active-loans)
            (ok true)
        )
    )
)


(define-public (make-repayment (amount uint))
    (let (
        (borrower tx-sender)
        (loan (unwrap! (map-get? loans { borrower: borrower }) ERR-LOAN-NOT-FOUND))
        (current-height block-height)
    )
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq (get status loan) "ACTIVE") ERR-LOAN-NOT-ACTIVE)
        (asserts! (<= current-height (get end-height loan)) ERR-LOAN-EXPIRED)

        (let (
            (new-total-repaid (try! (safe-add (get total-repaid loan) amount)))
            (interest-amount (try! (calculate-interest (get principal-amount loan) (get interest-rate loan))))
            (total-owed (try! (safe-add (get principal-amount loan) interest-amount)))
        )
            (try! (stx-transfer? amount borrower (as-contract tx-sender)))

            (map-set loans
                { borrower: borrower }
                (merge loan {
                    total-repaid: new-total-repaid,
                    last-payment-height: current-height,
                    status: (if (>= new-total-repaid total-owed)
                        "COMPLETED"
                        "ACTIVE"
                    )
                })
            )

            (var-set total-pool-amount (try! (safe-add (var-get total-pool-amount) amount)))

            (if (>= new-total-repaid total-owed)
                (var-set total-active-loans (try! (safe-subtract (var-get total-active-loans) u1)))
                true
            )

            (ok true)
        )
    )
)


;; Read-only Functions
(define-read-only (calculate-interest (principal uint) (rate uint))
    (begin
        (asserts! (is-valid-rate rate) ERR-INVALID-RATE)
        (safe-divide (* principal rate) u1000000)
    )
)

(define-read-only (get-loan-details (borrower principal))
    (map-get? loans { borrower: borrower })
)

(define-read-only (get-pool-share (lender principal))
    (map-get? lending-pool-shares { lender: lender })
)

(define-read-only (get-total-pool-amount)
    (var-get total-pool-amount)
)

;; Admin Functions
(define-public (update-loan-status (borrower principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (asserts! (is-contract-active) ERR-UNAUTHORIZED)
        (match (map-get? loans { borrower: borrower })
            loan (begin
                (map-set loans
                    { borrower: borrower }
                    (merge loan { 
                        status: new-status,
                        last-payment-height: block-height 
                    })
                )
                (ok true)
            )
            ERR-LOAN-NOT-FOUND
        )
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (var-set contract-paused true)
        (ok true)
    )
)

(define-public (resume-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED)
        (var-set contract-paused false)
        (ok true)
    )
)
