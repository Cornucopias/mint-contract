const fs = require('fs');
const Arweave = require('arweave');

async function sendPayment(walletPath, address, amount) {
    try {
        console.log("Loading Key from", walletPath);
        // load the JWK wallet key file from disk
        let key = JSON.parse(fs.readFileSync(walletPath).toString());

        // Create an Arweave instance
        const arweave = Arweave.init({
            host: 'arweave.net',
            port: 443,
            protocol: 'https',
        });

        console.log("Building Tx")
        let transaction = await arweave.createTransaction({
            target: address,
            quantity: arweave.ar.arToWinston(amount)
        }, key);
        
        console.log("Signing Tx")
        await arweave.transactions.sign(transaction, key);
        
        await arweave.transactions.post(transaction);
        console.log("Tx Id:", transaction.id);
    } catch (error) {
        console.error('Error Getting Wallet Balance:', error);
    }
}

// Usage: node send.js <walletPath> <address> <amount>
const walletPath = process.argv[2];
const address = process.argv[3];
const amount = process.argv[4];

sendPayment(walletPath, address, amount).then(() => { });