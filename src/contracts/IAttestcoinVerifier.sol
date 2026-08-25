// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAttestcoinVerifier
 * @notice Standard interface for the Attestcoin Protocol (Universal Settlement & Credentialing - USC).
 * Enables oracle-free, cryptographic attestation verification on Creditcoin.
 */
interface IAttestcoinVerifier {
    struct Attestation {
        bytes32 schemaId;        // Schema identifier for RWA / Credit score
        address recipient;       // Borrower or asset holder address
        uint256 value;           // Attested value (e.g. credit limit or asset valuation in wei)
        uint256 validUntil;      // Expiration timestamp
        uint256 nonce;           // Anti-replay nonce
        bytes signature;         // ECDSA signature by authorized Attestcoin validator
    }

    /**
     * @notice Verifies an off-chain attestation issued by the AI-TRIZ Sovereign Agent.
     * @param attestation The attestation payload to verify.
     * @return isValid True if the signature and constraints are valid.
     */
    function verifyAttestation(Attestation calldata attestation) external view returns (bool isValid);
}
