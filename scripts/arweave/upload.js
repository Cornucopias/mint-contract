const fs = require('fs');
const Arweave = require('arweave');

async function uploadImage(walletPath, imagePath) {
  try {
    // load the JWK wallet key file from disk
    let key = JSON.parse(fs.readFileSync(walletPath).toString());

    // Create an Arweave instance
    const arweave = Arweave.init({
      host: 'arweave.net',
      port: 443,
      protocol: 'https',
    });

    // load the data from disk
    const imageData = fs.readFileSync(imagePath);

    // create a data transaction
    let transaction = await arweave.createTransaction({
	data: imageData
    }, key);

    // add a custom tag that tells the gateway how to serve this data to a browser
    transaction.addTag('Content-Type', 'image/jpg');

    // Sign the transaction
    await arweave.transactions.sign(transaction, key);
    
    // Get the transaction ID
    const transactionId = transaction.id;

    // create an uploader that will seed your data to the network
    let uploader = await arweave.transactions.getUploader(transaction);

    // run the uploader until it completes the upload.
    while (!uploader.isComplete) {
	await uploader.uploadChunk();
    }

    // Return the URL
    return transactionId;
  } catch (error) {
    console.error('Error uploading image:', error);
    return null;
  }
}

// Usage: node upload.js <walletPath> <imagePath>
const walletPath = process.argv[2];
const imagePath = process.argv[3];
uploadImage(walletPath, imagePath)
  .then(txid => {
    if (txid) {
      console.log('Image uploaded successfully!');
      console.log('Transaction ID:', txid);
      console.log('View Image:', 'https://arweave.net/'+txid);
    } else {
      console.log('Image upload failed.');
    }
  });