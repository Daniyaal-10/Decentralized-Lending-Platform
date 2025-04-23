// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LendingPlatform {
    address public owner;

    struct Loan {
        uint amount;
        uint interest;
        uint dueDate;
        bool repaid;
    }

    mapping(address => Loan) public loans;

    constructor() {
        owner = msg.sender;
    }

    // Lender provides a loan
    function provideLoan(address borrower, uint amount, uint interest, uint duration) external {
        require(msg.sender == owner, "Only owner can provide loans");
        require(loans[borrower].amount == 0, "Existing loan must be repaid first");
        
        loans[borrower] = Loan({
            amount: amount,
            interest: interest,
            dueDate: block.timestamp + duration,
            repaid: false
        });
    }

    // Borrower repays the loan
    function repayLoan() external payable {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No active loan found");
        require(!loan.repaid, "Loan already repaid");

        uint totalDue = loan.amount + (loan.amount * loan.interest) / 100;
        require(msg.value >= totalDue, "Insufficient amount to repay");

        loan.repaid = true;
    }
}

