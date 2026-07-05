# Secure Device Wiping and Blockchain Certification System

This is a local prototype based on the DPR and System Design Document. It can run in two proof modes:

- Local demo ledger: no install required, useful for UI demos.
- WipeRegistry contract: records wipe proofs on a real local Hardhat blockchain through ethers.js.

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
- Optional WipeRegistry contract mode using ethers.js

## Run with a real local blockchain

Install dependencies:

```bash
npm install
```

Start a local Ethereum dev chain:

```bash
npm run chain
```

In a second terminal, deploy the registry:

```bash
npm run deploy:local
```

The deploy script writes `contract-config.js` with the deployed address and ABI. Open `index.html`, go to Settings, set Proof Mode to `WipeRegistry contract`, confirm the RPC URL is `http://127.0.0.1:8545`, and save.

When contract mode is enabled, the wipe workflow calls:

- `recordWipe(deviceId, logHash, algorithm, operatorId, status)`
- `verifyWipe(logHash)`
- `getCertificate(logHash)`

## Safety note

The app does not wipe real disks. It intentionally performs a safe wipe simulation against virtual demo records only. This is the correct behavior for a prototype/demo build.

## Blockchain note

The browser-local proof chain remains available for offline demos. For genuine blockchain-backed proof, use the Hardhat workflow above and keep the deployed `WipeRegistry` address in `contract-config.js` or Settings.

## Maintenance

This folder is a Git repository. Use small commits for each feature or fix, and update `CHANGELOG.md` when a user-visible workflow changes.

## Suggested production upgrade path

1. Replace the browser-local chain with a private Ethereum PoA or Hyperledger Fabric network.
2. Connect the certificate workflow to the deployed `WipeRegistry` smart contract.
3. Replace the safe wipe simulator with a privileged, audited wiping service that only targets explicitly mounted devices.
4. Add hardware secure erase support where available.
5. Move users and audit storage into a server-backed database with encrypted backups.
