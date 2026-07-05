const fs = require("node:fs");
const path = require("node:path");
const hre = require("hardhat");

async function main() {
  const registry = await hre.ethers.deployContract("WipeRegistry");
  await registry.waitForDeployment();

  const address = await registry.getAddress();
  const artifact = await hre.artifacts.readArtifact("WipeRegistry");
  const network = await hre.ethers.provider.getNetwork();

  const config = {
    address,
    chainId: Number(network.chainId),
    networkName: network.name,
    abi: artifact.abi
  };

  const output = `window.WIPE_REGISTRY_CONFIG = ${JSON.stringify(config, null, 2)};\n`;
  fs.writeFileSync(path.join(__dirname, "..", "contract-config.js"), output);

  console.log(`WipeRegistry deployed to ${address}`);
  console.log("Frontend config written to contract-config.js");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
