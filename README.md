# Cube Contracts 🧊

- Github Organisation: [Cube](https://github.com/usecube)
- Deployed Website: https://usecube.vercel.app

## Contracts

1. Registry.sol: [0x2b4836d81370e37030727e4dcbd9cc5a772cf43a](https://sepolia.basescan.org/address/0x2b4836d81370e37030727e4dcbd9cc5a772cf43a)
2. Exchange.sol (V1): [0xd9004Edc4bdEB308C4A40fdCbE320bbE5DF4AF77](https://sepolia.basescan.org/address/0xd9004edc4bdeb308c4a40fdcbe320bbe5df4af77)
3. Exchange.sol (V2): [0x92F5D70ffBE0988DEcD5c1E7A6cb8A048a3Fe75D](https://sepolia.basescan.org/address/0x92F5D70ffBE0988DEcD5c1E7A6cb8A048a3Fe75D)
4. Vault.sol: [0xd580248163CDD5AE3225A700E9f4e7CD525b27b0](https://sepolia.basescan.org/address/0xd580248163cdd5ae3225a700e9f4e7cd525b27b0)
5. XSGD.sol: [0xd7260d7063fE5A62A90E6A8DD5A39Ab27A05986B](https://sepolia.basescan.org/token/0xd7260d7063fe5a62a90e6a8dd5a39ab27a05986b)

## Deployment

1. Registry.sol

```
forge script script/deploy/Registry.s.sol:DeployRegistry --rpc-url <PRC_URL> --broadcast
```

2. Exchange.sol

```
forge script script/deploy/Exchange.s.sol:DeployExchange --rpc-url <PRC_URL> --broadcast
```

3. Vault.sol

```
forge script script/deploy/Vault.s.sol:DeployVault --rpc-url <PRC_URL> --broadcast
```

4. XSGD.sol

```
forge script script/deploy/XSGD.s.sol:DeployXSGD --rpc-url <PRC_URL> --broadcast
```

## Tests

```
forge test -vv
```

## Actions

### Check Registry

```
forge script script/actions/checkRegistry.s.sol:CheckRegistry --rpc-url <RPC_URL>
```

### Remove Merchant

```
forge script script/actions/removeMerchant.s.sol:RemoveMerchant --rpc-url <RPC_URL> --broadcast
```

### Add Merchant

```
forge script script/actions/addMerchant.s.sol:AddMerchant --rpc-url <RPC_URL> --broadcast
```

### Withdraw USDC From Vault

#### Check Shares

```
forge script script/actions/withdrawUSDCFromVault.s.sol:WithdrawUSDCFromVault --sig "checkShares(address,address)" <EXCHANGE_ADDRESS> <MERCHANT_ADDRESS> --rpc-url <RPC_URL>
```

#### Convert Shares to Assets

```
forge script script/actions/withdrawUSDCFromVault.s.sol:WithdrawUSDCFromVault --sig "convertSharesToAssets(address,uint256)" <EXCHANGE_ADDRESS> <SHARES> --rpc-url <RPC_URL>
```

#### Withdraw USDC From Vault

```
forge script script/actions/withdrawUSDCFromVault.s.sol:WithdrawUSDCFromVault --sig "run(address,uint256)" <EXCHANGE_ADDRESS> <SHARES> --rpc-url <RPC_URL> --broadcast
```
