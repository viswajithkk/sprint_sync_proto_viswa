# Secure Device Wiping and Blockchain Certification System

This is a complete no-install local prototype based on the DPR and System Design Document.

## Open the app

Open `index.html` in a browser.

Demo accounts:

- Admin: `admin` / `admin123`
- Technician: `tech` / `tech123`
- Auditor: `auditor` / `audit123`

## What works

- Role-based login
- Device registration and inventory
- Safe simulated wipe workflow
- SHA-256 wipe log hashing through the browser Web Crypto API
- Local immutable blockchain-style ledger with linked proof blocks
- Certificate generation with printable certificate view
- Local verification by certificate ID, device ID, log hash, or transaction hash
- Admin user management
- Audit trail
- CSV exports
- Settings for organization, local proof endpoint, and certificate text

## Safety note

The app does not wipe real disks. It intentionally performs a safe wipe simulation against virtual demo records only. This is the correct behavior for a prototype/demo build.

## Blockchain note

The running app includes a browser-local proof chain so it works offline without installing dependencies. A Solidity smart contract model is included in `smart-contract/WipeRegistry.sol` for a future Hardhat/Ethereum PoA integration.

## Suggested production upgrade path

1. Replace the browser-local chain with a private Ethereum PoA or Hyperledger Fabric network.
2. Connect the certificate workflow to the deployed `WipeRegistry` smart contract.
3. Replace the safe wipe simulator with a privileged, audited wiping service that only targets explicitly mounted devices.
4. Add hardware secure erase support where available.
5. Move users and audit storage into a server-backed database with encrypted backups.
