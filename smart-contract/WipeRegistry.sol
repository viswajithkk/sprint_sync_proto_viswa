// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WipeRegistry {
    address public owner;

    struct WipeRecord {
        string deviceId;
        string logHash;
        string algorithm;
        string operatorId;
        string status;
        uint256 timestamp;
        bool exists;
    }

    mapping(string => WipeRecord) private recordsByLogHash;
    mapping(string => string[]) private hashesByDevice;
    mapping(address => bool) public authorizedWriters;

    event WriterAuthorized(address indexed writer);
    event WriterRevoked(address indexed writer);
    event WipeRecorded(
        string indexed deviceId,
        string indexed logHash,
        string algorithm,
        string operatorId,
        string status,
        uint256 timestamp
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyWriter() {
        require(msg.sender == owner || authorizedWriters[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedWriters[msg.sender] = true;
    }

    function authorizeWriter(address writer) external onlyOwner {
        authorizedWriters[writer] = true;
        emit WriterAuthorized(writer);
    }

    function revokeWriter(address writer) external onlyOwner {
        authorizedWriters[writer] = false;
        emit WriterRevoked(writer);
    }

    function recordWipe(
        string calldata deviceId,
        string calldata logHash,
        string calldata algorithm,
        string calldata operatorId,
        string calldata status
    ) external onlyWriter {
        require(bytes(deviceId).length > 0, "Device required");
        require(bytes(logHash).length > 0, "Hash required");
        require(!recordsByLogHash[logHash].exists, "Duplicate log hash");

        recordsByLogHash[logHash] = WipeRecord({
            deviceId: deviceId,
            logHash: logHash,
            algorithm: algorithm,
            operatorId: operatorId,
            status: status,
            timestamp: block.timestamp,
            exists: true
        });

        hashesByDevice[deviceId].push(logHash);
        emit WipeRecorded(deviceId, logHash, algorithm, operatorId, status, block.timestamp);
    }

    function getCertificate(string calldata logHash) external view returns (WipeRecord memory) {
        require(recordsByLogHash[logHash].exists, "Record not found");
        return recordsByLogHash[logHash];
    }

    function verifyWipe(string calldata logHash) external view returns (bool) {
        return recordsByLogHash[logHash].exists;
    }

    function getDeviceHashes(string calldata deviceId) external view returns (string[] memory) {
        return hashesByDevice[deviceId];
    }
}
