const Arweave = require('arweave');

async function createWallet() {
    const arweave = Arweave.init({
        host: 'arweave.net',
        port: 443,
        protocol: 'https',
      });
    
    arweave.wallets.generate().then((key) => {
        console.log(JSON.stringify(key, null, 2));
    });
}

createWallet().then(() => {});
