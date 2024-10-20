# Cube Contracts 🧊

- Github Organisation: [Cube](https://github.com/usecube)
- Deployed Website: https://usecube.vercel.app

## Contracts

1. Registry.sol: [0x2b4836d81370e37030727e4dcbd9cc5a772cf43a](https://sepolia.basescan.org/address/0x2b4836d81370e37030727e4dcbd9cc5a772cf43a)
2. Exchange.sol: [0xd9004Edc4bdEB308C4A40fdCbE320bbE5DF4AF77](https://sepolia.basescan.org/address/0xd9004edc4bdeb308c4a40fdcbe320bbe5df4af77)
3. Vault.sol: [0xd580248163CDD5AE3225A700E9f4e7CD525b27b0](https://sepolia.basescan.org/address/0xd580248163cdd5ae3225a700e9f4e7cd525b27b0)

## Deployment

1. Registry.sol

```
forge script script/deploy/Registry.s.sol:DeployRegistry --rpc-url <PRC_URL> --broadcast --private-key <PRIVATE_KEY>
```

2. Exchange.sol

```
forge script script/deploy/Exchange.s.sol:DeployExchange --rpc-url <PRC_URL> --broadcast --private-key <PRIVATE_KEY>
```

3. Vault.sol

```
forge script script/deploy/Vault.s.sol:DeployVault --rpc-url <PRC_URL> --broadcast --private-key <PRIVATE_KEY>
```
