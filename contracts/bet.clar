;; BetStacks: Decentralized Sports Betting Platform

;; Error Constants
(define-constant contract-owner tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-WAGER-ALREADY-EXISTS (err u101))
(define-constant ERR-WAGER-DOES-NOT-EXIST (err u102))
(define-constant ERR-WAGER-CLOSED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-WAGER-ALREADY-RESOLVED (err u105))
(define-constant ERR-WAGER-NOT-READY-TO-CLOSE (err u106))
(define-constant ERR-WAGER-NOT-CANCELABLE (err u107))
(define-constant ERR-INVALID-OUTCOME-COUNT (err u108))
(define-constant ERR-INVALID-END-BLOCK (err u109))
(define-constant ERR-INVALID-WAGER-TYPE (err u110))
(define-constant ERR-MISSING-ODDS-DATA (err u111))
(define-constant ERR-INVALID-OUTCOME-SELECTION (err u112))
(define-constant ERR-WAGER-EXPIRED (err u113))
(define-constant ERR-NO-WINNING-OUTCOMES (err u114))
(define-constant ERR-TOO-MANY-WINNERS (err u115))
(define-constant ERR-INVALID-WINNER-SELECTION (err u116))
(define-constant ERR-NOT-WINNING-SELECTION (err u117))
(define-constant ERR-PAYOUT-FAILED (err u118))
(define-constant ERR-REFUND-ACTIVE (err u119))
(define-constant ERR-INVALID-WAGER-DESCRIPTION (err u120))
(define-constant ERR-INVALID-BET-AMOUNT (err u121))

;; Data variables
(define-data-var next-wager-id uint u0)

;; Betting types
(define-data-var supported-wager-types (list 10 (string-ascii 20)) (list "winner-take-all" "proportional" "fixed-odds"))

;; Define wager structure
(define-map wagers
  { wager-id: uint }
  {
    creator: principal,
    description: (string-ascii 256),
    outcomes: (list 10 (string-ascii 64)),
    total-pool: uint,
    active: bool,
    winning-outcomes: (list 5 uint),
    end-block: uint,
    wager-type: (string-ascii 20),
    odds: (optional (list 10 uint))
  }
)

;; Define bettor positions structure
(define-map bettor-positions
  { wager-id: uint, bettor: principal }
  { chosen-outcome: uint, bet-amount: uint }
)

;; Read-only functions
(define-read-only (get-wager (wager-id uint))
  (map-get? wagers { wager-id: wager-id })
)

(define-read-only (get-bettor-position (wager-id uint) (bettor principal))
  (map-get? bettor-positions { wager-id: wager-id, bettor: bettor })
)

(define-read-only (get-current-block-height)
  block-height
)

;; Private functions

(define-private (calculate-payout (wager { creator: principal, description: (string-ascii 256), outcomes: (list 10 (string-ascii 64)), total-pool: uint, active: bool, winning-outcomes: (list 5 uint), end-block: uint, wager-type: (string-ascii 20), odds: (optional (list 10 uint)) }) (position { chosen-outcome: uint, bet-amount: uint }) (winners (list 5 uint)))
  (let
    (
      (bet-type (get wager-type wager))
      (total-wager-pool (get total-pool wager))
      (bettor-amount (get bet-amount position))
    )
    (if (is-eq bet-type "winner-take-all")
      ;; For winner-take-all, divide total pot by number of winning options
      (/ total-wager-pool (len winners))
      (if (is-eq bet-type "proportional")
        ;; For proportional, payout based on stake ratio
        (/ (* bettor-amount total-wager-pool) total-wager-pool)
        ;; Fixed-odds payout
        (let
          (
            (odds-list (unwrap! (get odds wager) u0))
            (chosen-odds (unwrap! (element-at odds-list (- (get chosen-outcome position) u1)) u0))
          )
          (+ bettor-amount (* bettor-amount (/ chosen-odds u100)))
        )
      )
    )
  )
)



(define-private (get-total-bet-on-outcome (outcome-id uint))
  (get-bet-amount-for-outcome outcome-id (var-get next-wager-id))
)

(define-private (process-refunds (wager-id uint))
  (let
    ((bettor-position (get-bettor-position wager-id tx-sender)))
    (match bettor-position
      position-details (match (as-contract (stx-transfer? (get bet-amount position-details) tx-sender tx-sender))
        success (begin
          (map-delete bettor-positions { wager-id: wager-id, bettor: tx-sender })
          (ok true)
        )
        error ERR-PAYOUT-FAILED
      )
      ERR-REFUND-ACTIVE
    )
  )
)

(define-private (validate-winners (winners (list 5 uint)) (max-valid-outcome uint))
  (let
    (
      (first-outcome (element-at winners u0))
      (second-outcome (element-at winners u1))
      (third-outcome (element-at winners u2))
      (fourth-outcome (element-at winners u3))
      (fifth-outcome (element-at winners u4))
    )
    (and
      ;; Check if first option exists and is valid
      (match first-outcome
        value (and (> value u0) (<= value max-valid-outcome))
        true)
      ;; For remaining options, they're either valid or none
      (match second-outcome
        value (and (> value u0) (<= value max-valid-outcome))
        true)
      (match third-outcome
        value (and (> value u0) (<= value max-valid-outcome))
        true)
      (match fourth-outcome
        value (and (> value u0) (<= value max-valid-outcome))
        true)
      (match fifth-outcome
        value (and (> value u0) (<= value max-valid-outcome))
        true)
    )
  )
)

;; Public functions
(define-public (close-wager (wager-id uint))
  (let
    (
      (wager (unwrap! (get-wager wager-id) ERR-WAGER-DOES-NOT-EXIST))
    )
    (asserts! (or (is-eq (get creator wager) tx-sender) (is-eq contract-owner tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (get active wager) ERR-WAGER-CLOSED)
    (asserts! (>= block-height (get end-block wager)) ERR-WAGER-NOT-READY-TO-CLOSE)
    (map-set wagers
      { wager-id: wager-id }
      (merge wager { active: false })
    )
    (ok true)
  )
)

(define-public (cancel-wager (wager-id uint))
  (let
    (
      (wager (unwrap! (get-wager wager-id) ERR-WAGER-DOES-NOT-EXIST))
    )
    (asserts! (is-eq (get creator wager) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (get active wager) ERR-WAGER-CLOSED)
    (asserts! (< block-height (get end-block wager)) ERR-WAGER-NOT-CANCELABLE)
    
    ;; First set the wager as closed
    (map-set wagers
      { wager-id: wager-id }
      (merge wager { active: false })
    )
    
    ;; Then process refunds
    (process-refunds wager-id)
  )
)

(define-public (resolve-wager (wager-id uint) (winning-outcomes (list 5 uint)))
  (let
    (
      (wager (unwrap! (get-wager wager-id) ERR-WAGER-DOES-NOT-EXIST))
    )
    (asserts! (is-eq contract-owner tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get active wager)) ERR-WAGER-CLOSED)
    (asserts! (is-eq (len (get winning-outcomes wager)) u0) ERR-WAGER-ALREADY-RESOLVED)
    (asserts! (> (len winning-outcomes) u0) ERR-NO-WINNING-OUTCOMES)
    (asserts! (<= (len winning-outcomes) u5) ERR-TOO-MANY-WINNERS)
    
    ;; Validate each winning outcome
    (asserts! (validate-winners winning-outcomes (len (get outcomes wager))) ERR-INVALID-WINNER-SELECTION)
    
    (map-set wagers
      { wager-id: wager-id }
      (merge wager { winning-outcomes: winning-outcomes })
    )
    (ok true)
  )
)

;; Contract initialization
(begin
  (var-set next-wager-id u0)
)

;; Export the Component function
(define-public (Component)
  (ok true))