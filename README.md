# Microloan Smart Contract

## Overview
This smart contract enables a decentralized microloan system where users can contribute to a lending pool, request loans, and repay them with interest. The contract offers mechanisms to manage loan terms, validate loan amounts and interest rates, and ensure secure repayments. The contract owner can also pause and resume the contract as needed.

## Key Features
- **Lending Pool Management**: Contributors can add funds to the pool, and their shares are tracked.
- **Loan Processing**: Borrowers can request loans based on certain term limits and amount constraints.
- **Repayment System**: Borrowers can repay their loans, with the contract automatically updating loan statuses and redistributing repayments to the lending pool.
- **Error Management**: Custom error codes improve error handling and debugging.
- **Contract Lifecycle Control**: The contract owner can pause and resume operations as necessary.
- **Extensive Validations**: Ensures appropriate loan terms, interest rates, and proper state management.

## Prerequisites
- **Stacks Blockchain**: This contract is designed for deployment on the Stacks blockchain.
- **Clarity Language**: Written in Clarity, the smart contract language of the Stacks blockchain.

## Constants
- **Error Codes**: Defines error codes for specific error types such as overflows, unauthorized access, invalid amounts, etc.
- **Contract Owner**: Defined as the sender of the transaction (`tx-sender`).
- **Pool and Loan Limits**: Sets limits for minimum and maximum loan amounts, as well as term durations (in blocks).

## Error Code Details
| Error Code           | Description                              |
|----------------------|------------------------------------------|
| `ERR-OVERFLOW`       | Overflow error in calculations           |
| `ERR-INVALID-AMOUNT` | Invalid amount provided                  |
| `ERR-INSUFFICIENT-BALANCE` | Insufficient funds in the lending pool |
| `ERR-LOAN-EXISTS`    | Loan already exists for borrower         |
| `ERR-LOAN-NOT-FOUND` | Loan not found for borrower              |
| `ERR-UNAUTHORIZED`   | Unauthorized access                      |
| `ERR-INVALID-TERM`   | Loan term is not within acceptable range |
| `ERR-INVALID-RATE`   | Interest rate is not valid               |
| `ERR-LOAN-EXPIRED`   | Loan has expired                         |
| `ERR-LOAN-NOT-ACTIVE`| Loan is not active                       |
| `ERR-ZERO-ADDRESS`   | Invalid (zero) borrower address          |

## Data Structures
### Data Variables
- `contract-paused`: Boolean variable indicating if the contract is paused.
- `total-pool-amount`: The total amount of STX in the lending pool.
- `total-active-loans`: Tracks the total number of active loans.

### Data Maps
- `loans`: Stores loan details per borrower, such as principal amount, interest rate, loan term, repayment status, and reputation score.
- `lending-pool-shares`: Tracks the amount contributed by each lender to the lending pool.

## Functions
### Public Functions
- `contribute-to-pool`: Allows a user to add funds to the lending pool. Updates the lender's share and the total pool amount.
- `request-loan`: Enables a borrower to request a loan, transferring the loan amount from the contract to the borrower if approved.
- `make-repayment`: Allows a borrower to repay a portion of their loan. The contract updates the repayment amount and status based on the loan’s total owed amount.

### Read-Only Functions
- `calculate-interest`: Calculates interest on a loan principal based on the rate provided.
- `get-loan-details`: Retrieves details of a loan for a given borrower.
- `get-pool-share`: Fetches the amount contributed by a lender to the pool.
- `get-total-pool-amount`: Returns the total amount available in the lending pool.

### Admin Functions
- `update-loan-status`: Allows the contract owner to update the status of a loan manually.
- `pause-contract`: Enables the contract owner to pause the contract, halting all loan and contribution actions.
- `resume-contract`: Resumes the contract, allowing contributions and loan actions to proceed.

### Helper Functions
- `safe-add`, `safe-subtract`, `safe-divide`: Arithmetic functions that prevent overflow errors.
- `is-valid-loan-amount`, `is-valid-term`, `is-valid-rate`: Validation functions ensuring loan amount, term, and rate are within the contract's defined limits.

## Error Handling
Each function has robust error handling using `asserts!` and `try!` to provide meaningful feedback when certain conditions aren't met (e.g., unauthorized access, invalid loan amounts, or insufficient pool balance). The error codes ensure clear debugging and adherence to contract logic.

## Contract Deployment and Testing
### Deployment
This contract should be deployed using a Clarity-compatible environment on the Stacks blockchain.

### Testing
Before deploying, conduct the following tests:
- **Contribution Tests**: Ensure that multiple users can contribute to the pool and that their shares update accurately.
- **Loan Request Tests**: Validate that loan requests follow the defined constraints on amount, term, and interest rates.
- **Repayment Tests**: Verify that loan repayments update the loan status accurately and affect the lending pool correctly.
- **Pause/Resume Tests**: Confirm that contract lifecycle actions (pause/resume) function as expected and restrict operations accordingly.

## Future Enhancements
- **Dynamic Interest Rates**: Allow dynamic calculation based on borrower reputation.
- **Improved Loan Status Updates**: Incorporate automated checks on loan expiration and repayment updates to minimize manual intervention.
- **Enhanced Reputation System**: Develop a scoring system for borrowers based on their repayment history.

## License
This project is open-source under the MIT license.

This README provides a full overview of the contract’s features, functionality, data management, and instructions for setup and usage, ensuring clarity and ease of understanding.