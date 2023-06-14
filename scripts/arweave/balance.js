const fs = require('fs');
const Arweave = require('arweave');

async function walletBalance(walletPath) {
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

        arweave.wallets.jwkToAddress(key).then((address) => {
            console.log("Wallet Address:", address);
            arweave.wallets.getBalance(address).then((balance) => {
                let winston = balance;
                let ar = arweave.ar.winstonToAr(balance);

                console.log("Winston:", winston);
                console.log("AR:", ar);
            });
        });

    } catch (error) {
        console.error('Error Getting Wallet Balance:', error);
    }
}

// Usage: node balance.js <walletPath>
const walletPath = process.argv[2];

walletBalance(walletPath).then(() => { });