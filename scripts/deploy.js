// scripts/deploy.js

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const XPassToken = await ethers.getContractFactory("XPASSToken");
  const xpassToken = await XPassToken.deploy();

  console.log("XPassToken deployed to:", xpassToken.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });