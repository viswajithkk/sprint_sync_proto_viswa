const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("WipeRegistry", () => {
  it("records, verifies, blocks duplicates and unauthorized writers", async () => {
    const [owner, other] = await ethers.getSigners();
    const r = await ethers.deployContract("WipeRegistry");
    const h = "a".repeat(64);
    await (await r.recordWipe("DEV-001", h, "NIST 800-88 Clear", "USR-002", "Success")).wait();
    expect(await r.verifyWipe(h)).to.equal(true);
    expect(await r.verifyWipe("b".repeat(64))).to.equal(false);
    const c = await r.getCertificate(h);
    expect(c.deviceId).to.equal("DEV-001");
    await expect(r.recordWipe("DEV-001", h, "x", "y", "z")).to.be.revertedWith("Duplicate log hash");
    await expect(r.connect(other).recordWipe("D", "h2", "x", "y", "z")).to.be.revertedWith("Not authorized");
    await r.authorizeWriter(other.address);
    await r.connect(other).recordWipe("D", "h2", "x", "y", "z");
    await expect(r.getCertificate("nope")).to.be.revertedWith("Record not found");
  });
});
