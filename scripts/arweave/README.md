# Arweave Instructions

Install packages with

```bash
npm install
```

## Wallet Creation

A new wallet can be created by running the command below from inside the arweave folder. This will generate a wallet file that can send and receive AR.

```bash
mkdir -p wallet
[ ! -f "wallet/wallet.json" ] && node create_wallet.js > wallet/wallet.json
```

Be sure to keep this wallet safe and not to overwrite it.

## Checking Wallet Balance

```bash
node balance.js wallet/wallet.json
```

## Sending Funds

```bash
node send.js wallet/wallet.json ${receiver_address} ${amount}
```

## Uploading Images

```bash
node upload.js wallet/wallet.json path/to/image.file
```