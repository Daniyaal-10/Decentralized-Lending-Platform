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
        require(loans[borrower].amount == 0 || loans[borrower].repaid, "Existing loan must be repaid first");
        
        loans[borrower] = Loan({
            amount: amount,
            interest: interest,
            dueDate: block.timestamp + duration,
            repaid: false
        });

        payable(borrower).transfer(amount); // transfer loan to borrower
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

    // Get loan details
    function getLoanDetails(address borrower) external view returns (uint, uint, uint, bool) {
        Loan memory loan = loans[borrower];
        return (loan.amount, loan.interest, loan.dueDate, loan.repaid);
    }

    // Withdraw collected funds by the owner
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    // Check loan status
    function checkLoanStatus(address borrower) external view returns (string memory) {
        Loan memory loan = loans[borrower];
        if (loan.amount == 0) return "No loan found";
        return loan.repaid ? "Repaid" : "Active";
    }

    // Accept ETH fallback
    receive() external payable {}
}
