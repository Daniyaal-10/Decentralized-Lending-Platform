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
    address[] public borrowers;

    event LoanProvided(address indexed borrower, uint amount, uint interest, uint dueDate);
    event LoanRepaid(address indexed borrower, uint totalPaid);
    event LoanExtended(address indexed borrower, uint newDueDate);
    event Withdrawn(uint amount);
    event PenaltyAdded(address indexed borrower, uint newAmount);

    constructor() {
        owner = msg.sender;
    }

    function provideLoan(address borrower, uint amount, uint interest, uint duration) external {
        require(msg.sender == owner, "Only owner can provide loans");
        require(loans[borrower].amount == 0 || loans[borrower].repaid, "Existing loan must be repaid first");

        loans[borrower] = Loan({
            amount: amount,
            interest: interest,
            dueDate: block.timestamp + duration,
            repaid: false
        });

        borrowers.push(borrower);
        payable(borrower).transfer(amount);
        emit LoanProvided(borrower, amount, interest, block.timestamp + duration);
    }

    function repayLoan() external payable {
        Loan storage loan = loans[msg.sender];
        require(loan.amount > 0, "No active loan found");
        require(!loan.repaid, "Loan already repaid");

        uint totalDue = loan.amount + (loan.amount * loan.interest) / 100;
        require(msg.value >= totalDue, "Insufficient amount to repay");

        loan.repaid = true;
        emit LoanRepaid(msg.sender, msg.value);
    }

    function getLoanDetails(address borrower) external view returns (uint, uint, uint, bool) {
        Loan memory loan = loans[borrower];
        return (loan.amount, loan.interest, loan.dueDate, loan.repaid);
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        uint balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Withdrawn(balance);
    }

    function checkLoanStatus(address borrower) external view returns (string memory) {
        Loan memory loan = loans[borrower];
        if (loan.amount == 0) return "No loan found";
        return loan.repaid ? "Repaid" : "Active";
    }

    function extendLoanDuration(address borrower, uint additionalTime) external {
        require(msg.sender == owner, "Only owner can extend loan");
        require(loans[borrower].amount > 0, "Loan not found");
        require(!loans[borrower].repaid, "Cannot extend a repaid loan");

        loans[borrower].dueDate += additionalTime;
        emit LoanExtended(borrower, loans[borrower].dueDate);
    }

    function calculateTotalDue(address borrower) external view returns (uint) {
        Loan memory loan = loans[borrower];
        require(loan.amount > 0, "No loan found");
        return loan.amount + (loan.amount * loan.interest) / 100;
    }

    function hasActiveLoan(address user) external view returns (bool) {
        return loans[user].amount > 0 && !loans[user].repaid;
    }

    function getRemainingTime(address borrower) external view returns (int) {
        Loan memory loan = loans[borrower];
        require(loan.amount > 0, "No loan found");
        return int(loan.dueDate) - int(block.timestamp);
    }

    function isLoanOverdue(address borrower) external view returns (bool) {
        Loan memory loan = loans[borrower];
        require(loan.amount > 0, "No loan found");
        return (block.timestamp > loan.dueDate) && !loan.repaid;
    }

    function penalizeOverdueLoan(address borrower, uint penaltyPercentage) external {
        require(msg.sender == owner, "Only owner can penalize");
        require(block.timestamp > loans[borrower].dueDate, "Loan not overdue");
        require(!loans[borrower].repaid, "Loan already repaid");

        uint penalty = (loans[borrower].amount * penaltyPercentage) / 100;
        loans[borrower].amount += penalty;

        emit PenaltyAdded(borrower, loans[borrower].amount);
    }

    function totalActiveLoans() external view returns (uint count) {
        for (uint i = 0; i < borrowers.length; i++) {
            if (loans[borrowers[i]].amount > 0 && !loans[borrowers[i]].repaid) {
                count++;
            }
        }
    }

    // New functions below

    function getAllBorrowers() external view returns (address[] memory) {
        return borrowers;
    }

    function getUnpaidBorrowers() external view returns (address[] memory) {
        uint count = 0;
        for (uint i = 0; i < borrowers.length; i++) {
            if (!loans[borrowers[i]].repaid) {
                count++;
            }
        }

        address[] memory unpaid = new address[](count);
        uint index = 0;

        for (uint i = 0; i < borrowers.length; i++) {
            if (!loans[borrowers[i]].repaid) {
                unpaid[index++] = borrowers[i];
            }
        }

        return unpaid;
    }

    function getTotalLoanedAmount() external view returns (uint totalLoaned) {
        for (uint i = 0; i < borrowers.length; i++) {
            totalLoaned += loans[borrowers[i]].amount;
        }
    }

    function getTotalRepaidAmount() external view returns (uint totalRepaid) {
        for (uint i = 0; i < borrowers.length; i++) {
            Loan memory loan = loans[borrowers[i]];
            if (loan.repaid) {
                totalRepaid += loan.amount + (loan.amount * loan.interest) / 100;
            }
        }
    }

    function getPlatformBalance() external view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {}
}
