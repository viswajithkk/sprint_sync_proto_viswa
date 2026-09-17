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

Data Wiping Tool — Architecture
This extends the existing wipe-service (Node.js, port 8787) and the index.html frontend to perform real, irreversible data destruction in two modes — Full Drive Destruction and File/Folder wiping — and to feed results into the existing blockchain certificate flow unchanged.

1. High-level flow
Browser (index.html)                    wipe-service (localhost:8787)
─────────────────────                   ──────────────────────────────
1. GET /health          ─────────────▶  returns { status, platform }
   (not running? show start-instructions panel, Retry button)

2. GET /devices          ─────────────▶  enumerate real physical drives
   or GET /browse?path=  ─────────────▶  list files/folders at path

3. POST /wipe/dry-run     ─────────────▶  validate target, compute
   { mode, target, method, verifyMode }   confirmation challenge, return
                          ◀─────────────  { token, warnings, summary,
                                            confirmationChallenge }

4. Modal: show summary + dynamic confirmation prompt
   (e.g. "Type the last 6 digits of serial SN-XXXXXX" or
    "Type 42 to confirm you are destroying 42 items")
   + "I understand this is irreversible" checkbox

5. POST /wipe/execute     ─────────────▶  verify token + confirmationValue
   { token, confirmationValue,            + ack, start async job
     acknowledgeIrreversible: true }
                          ◀─────────────  { jobId }

6. GET /wipe/status/:jobId (poll ~1s) ──▶  { state, progress, result? }
   until state = success | failed

7. On success: result = { logHash, algorithm, operatorId, status,
   timestamp, mode, ...mode-specific fields }
   → feeds directly into existing recordProof() / certificate flow,
     UNCHANGED from how simulated wipes work today.
Every request except /health must include header: X-Wipe-Api-Key: <key> — see §5.

2. wipe-service file structure
wipe-service/
  server.js              Express app, route wiring, CORS, API-key middleware
  config.js              generates/loads the API key, protected-path list
  lib/
    devices.js           (existing) cross-platform physical drive enumeration
    browse.js             NEW — local filesystem browsing for file/folder mode
    wipe-drive.js         (existing) OS-native whole-drive erasure
    wipe-files.js         (existing) multi-pass overwrite + unlink, extended
                           for recursive folders + symlink following
    audit.js              (existing) SHA-256 hashed append-only audit log
    jobs.js                NEW — in-memory job registry + progress tracking
    security.js             NEW — API key check, protected-path / system-drive
                           guards (applied to resolved real paths, so symlinks
                           can't be used to reach a protected path)
  data/
    audit-log.json        append-only hashed audit trail
    apikey.txt             generated shared secret (see §5)
3. API endpoints
GET /health
No auth required (so the frontend can detect the service before it has a key configured).

{ "status": "ok", "platform": "linux", "version": "0.3.0" }
GET /devices
Real physical drives only (no network volumes).

[
  {
    "id": "disk2",
    "path": "/dev/disk2",
    "model": "Samsung SSD 870",
    "serial": "SN-442901",
    "sizeBytes": 512110190592,
    "isSystemDrive": false
  }
]
GET /browse?path=<encoded path>
Omit path to get platform roots (drive letters on Windows; / plus common mount points on Linux/macOS — local physical drives only, network shares filtered out).

{
  "path": "/Users/tech/Documents",
  "entries": [
    { "name": "old-reports", "path": "/Users/tech/Documents/old-reports", "type": "dir", "isSymlink": false },
    { "name": "notes.txt", "path": "/Users/tech/Documents/notes.txt", "type": "file", "sizeBytes": 4096, "isSymlink": false }
  ]
}
POST /wipe/dry-run
// Drive mode
{ "mode": "drive", "target": { "deviceId": "disk2" }, "method": "NIST 800-88 Purge simulation", "verifyMode": "Full checksum verification" }

// File mode
{ "mode": "files", "target": { "paths": ["/Users/tech/Documents/old-reports"], "recursive": true },
  "method": "DoD 5220.22-M 3-pass overwrite", "verifyMode": "Sample sector verification" }
Response:

{
  "token": "dryrun_9f3a...",
  "expiresAt": "2026-09-17T12:05:00Z",
  "warnings": [],
  "summary": { "fileCount": 42, "totalBytes": 194823012 },
  "confirmationChallenge": { "type": "fileCount", "prompt": "Type 42 to confirm you are permanently destroying 42 items." }
}
Rejects immediately (403) if target resolves (after following symlinks) to a protected path or the system/boot drive.

POST /wipe/execute
{ "token": "dryrun_9f3a...", "confirmationValue": "42", "acknowledgeIrreversible": true }
Response: { "jobId": "job_7b21..." } — starts the async job.

GET /wipe/status/:jobId
{
  "jobId": "job_7b21...",
  "state": "running",
  "progress": { "percent": 63, "bytesDone": 122000000, "totalBytes": 194823012 }
}
On completion:

{
  "jobId": "job_7b21...",
  "state": "success",
  "result": {
    "mode": "files",
    "method": "DoD 5220.22-M 3-pass overwrite",
    "operatorId": "USR-002",
    "status": "Success",
    "timestamp": "2026-09-17T12:07:44Z",
    "fileCount": 42,
    "totalBytesWiped": 194823012,
    "pathHashes": ["9f2c1a...", "77bd44...", "..."],
    "logHash": "b6a0e3f1..."
  }
}
logHash is exactly what gets passed into the existing recordProof() call — no changes needed there.

Batch failure behavior: if any file fails mid-batch, the job aborts immediately (per your decision). Anything already wiped before the failure stays wiped — it cannot be rolled back — so the audit log still records a Failed entry noting how many items completed before the abort, for compliance purposes, even though no certificate is issued for an aborted job.

4. Safety mechanisms carried over / extended
System/boot drive detection — unchanged, applies to drive mode
Protected-path blocking (/etc, C:\Windows, etc.) — now checked against the resolved real path (fs.realpath) of every entry, so a symlink can't be used to sneak past it, even though symlinks are otherwise followed
Dry-run token, single-use, expiring — unchanged
Typed confirmation — now dynamic per job (serial digits for drives, item count for files) instead of a fixed phrase, so the operator has to actually look at what they're confirming
Local-only browsing — /browse and /devices filter out network/mounted shares
5. API key hardening
On first run, config.js generates a random key (e.g. 32-byte hex) and writes it to data/apikey.txt, printing it once to the console
Every route except /health requires header X-Wipe-Api-Key: <key>, checked in security.js middleware
The frontend gets a one-time Settings → Wipe Service API Key field to paste it into; stored in the app's existing local state (same place contractAddress lives today)
This is defense-in-depth on top of localhost binding — stops any other local process/tab from silently triggering a wipe
6. index.html changes
New Wipe view layout: mode switch (File/Folder ⟷ Full Drive Destruction) at the top, replacing the current single form
Health-check panel: shown instead of the wipe form when GET /health fails, with OS-specific start command and a Retry button
Drive mode: device dropdown now populated from GET /devices instead of state.devices
File mode: new file-browser modal (breadcrumbs + entries from GET /browse), multi-select files/folders, recursive by default
Dry-run → confirm → execute: replaces the current fake setTimeout step loop; confirmation modal renders the dynamic confirmationChallenge from the dry-run response
Progress: polls GET /wipe/status/:jobId every ~1s, updates the existing progress bar with progress.percent
On success: existing recordProof() / certificate generation code runs unchanged, fed by result.logHash and the other returned fields
Certificates for file-mode jobs: display file count, total bytes, method, verification mode — never raw paths (only their hashes, kept in the audit log for internal traceability)
Settings: add the Wipe Service API Key field
7. Open implementation details to nail down while coding
These weren't decision points, just things that'll need real values once you're in the code:

Exact device-enumeration commands per OS (likely already in the existing devices.js — extend rather than replace)
Chunk size / progress-reporting granularity for large single files
Job registry cleanup (expire finished jobs from memory after some time)
Where data/audit-log.json lives relative to the packaged service (so it survives restarts)
2. Connect the certificate workflow to the deployed `WipeRegistry` smart contract.
3. Replace the safe wipe simulator with a privileged, audited wiping service that only targets explicitly mounted devices.
4. Add hardware secure erase support where available.
5. Move users and audit storage into a server-backed database with encrypted backups.
