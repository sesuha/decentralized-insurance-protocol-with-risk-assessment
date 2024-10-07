// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOracle {
    function getRiskLevel(address _user) external view returns (uint256);
}

contract DecentralizedInsurance {
    struct Policy {
        address policyHolder;
        uint256 coverageAmount;
        uint256 premium;
        uint256 expiration;
        bool active;
    }

    mapping(address => Policy) public policies;
    IOracle public oracle;
    uint256 public basePremiumRate = 1000; 

    event PolicyPurchased(address indexed policyHolder, uint256 coverageAmount, uint256 premium);
    event ClaimPaid(address indexed policyHolder, uint256 payout);

    constructor(address _oracle) {
        oracle = IOracle(_oracle);
    }

    function purchasePolicy(uint256 _coverageAmount, uint256 _duration) external payable {
        require(_duration > 0, "Invalid duration");
        uint256 riskLevel = oracle.getRiskLevel(msg.sender);
        uint256 premium = calculatePremium(_coverageAmount, riskLevel, _duration);
        require(msg.value >= premium, "Insufficient premium payment");

        policies[msg.sender] = Policy({
            policyHolder: msg.sender,
            coverageAmount: _coverageAmount,
            premium: premium,
            expiration: block.timestamp + _duration,
            active: true
        });

        emit PolicyPurchased(msg.sender, _coverageAmount, premium);
    }

    function claim() external {
        Policy storage policy = policies[msg.sender];
        require(policy.active, "No active policy");
        require(block.timestamp < policy.expiration, "Policy expired");

        uint256 payout = policy.coverageAmount;
        policy.active = false;

        payable(msg.sender).transfer(payout);
        emit ClaimPaid(msg.sender, payout);
    }

    function calculatePremium(uint256 _coverageAmount, uint256 _riskLevel, uint256 _duration) public view returns (uint256) {
        return (_coverageAmount * basePremiumRate * _riskLevel * _duration) / 1e6;
    }

    function getPolicyDetails(address _policyHolder) public view returns (uint256, uint256, uint256, bool) {
        Policy memory policy = policies[_policyHolder];
        return (policy.coverageAmount, policy.premium, policy.expiration, policy.active);
    }
}
