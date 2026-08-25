// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IAttestcoinVerifier.sol";

/**
 * @title SovereignAttestLending
 * @notice AI-TRIZ Sovereign Autonomous Lending Contract on Creditcoin.
 * Consumes Attestcoin Protocol proofs to grant credit and execute loans without human intervention.
 */
contract SovereignAttestLending {
    address public owner;
    address public attestcoinValidator;
    bytes32 public constant RWA_CREDIT_SCHEMA = keccak256("AI_TRIZ_SOVEREIGN_CREDIT_V1");

    mapping(bytes32 => bool) public executedAttestations;
    mapping(address => uint256) public userCreditLimits;
    mapping(address => uint256) public userBorrowedAmounts;

    event AttestationProcessed(address indexed borrower, uint256 creditAmount, uint256 nonce);
    event LoanDisbursed(address indexed borrower, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner authorized");
        _;
    }

    constructor(address _validator) {
        owner = msg.sender;
        attestcoinValidator = _validator;
    }

    function setValidator(address _newValidator) external onlyOwner {
        attestcoinValidator = _newValidator;
    }

    /**
     * @notice Autonomous execution triggered by S6+ Agent via Attestcoin Protocol.
     * @param recipient The borrower receiving the credit.
     * @param creditLimit The credit limit computed by AI-TRIZ Su-Field engine.
     * @param validUntil Expiry timestamp.
     * @param nonce Anti-replay nonce.
     * @param signature Cryptographic signature by Attestcoin validator.
     */
    function executeAttestedCredit(
        address recipient,
        uint256 creditLimit,
        uint256 validUntil,
        uint256 nonce,
        bytes calldata signature
    ) external {
        require(block.timestamp <= validUntil, "Attestation expired");
        
        bytes32 attestationHash = keccak256(
            abi.encodePacked(RWA_CREDIT_SCHEMA, recipient, creditLimit, validUntil, nonce, block.chainid)
        );
        require(!executedAttestations[attestationHash], "Attestation already executed");

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", attestationHash)
        );
        address recoveredSigner = recoverSigner(ethSignedMessageHash, signature);
        require(recoveredSigner == attestcoinValidator, "Invalid Attestcoin signature");

        executedAttestations[attestationHash] = true;
        userCreditLimits[recipient] = creditLimit;

        emit AttestationProcessed(recipient, creditLimit, nonce);
    }

    function borrow(uint256 amount) external {
        require(userBorrowedAmounts[msg.sender] + amount <= userCreditLimits[msg.sender], "Exceeds credit limit");
        userBorrowedAmounts[msg.sender] += amount;
        emit LoanDisbursed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(userBorrowedAmounts[msg.sender] >= amount, "Repaying more than borrowed");
        userBorrowedAmounts[msg.sender] -= amount;
        emit LoanRepaid(msg.sender, amount);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
