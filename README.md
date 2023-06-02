# Cornucopias Minting Contract

This is an open-source contract for minting CIP68 NFTs (Non-Fungible Tokens) for Cornucopias. By design, the contracts are controlled by a single hotkey. Both the NFTs and the reference tokens can be minted or burned at any time with the permission of the hotkey. While the NFTs can be transferred freely, the reference tokens can only be allocated to the metadatum contract.

Let's assume that the purchaser of the token intends to provide the minimum ADA (Cardano) required for the metadatum UTxO (Unspent Transaction Output). In this case, the hotkey's sole responsibility is to sign transactions and is not involved in any transaction payments. If a reference token is burned, the owner of the NFT token should have the right to receive the remaining ADA from the metadatum UTXO. This residual ADA represents the token's intrinsic value, which is stored exclusively in the metadata contract.

## Setup

The `scripts` folder is specifically designed to facilitate a quick setup for the happy path.

### Wallets

To facilitate the setup process, it is necessary to have a folder named `wallets` within the scripts directory. This folder will be used for creating the testnet wallets.

The wallets can be created with these commands:

```bash
mkdir -p wallets
./create_wallet wallets/hot-wallet
./create_wallet wallets/collat-wallet
./create_wallet wallets/receiver-wallet
./create_wallet wallets/reference-wallet
```

With a fully syncd testnet node and correct node environment, we can view the balances of the wallets and send tADA (testnet ADA) to them from a testnet wallet or faucet. The collat wallet should be allocated 5 tADA, while the hot wallet doesn't require tADA as it is solely used for signing transactions. The receiver wallet should have approximately 100 tADA, and the reference wallet should also hold around 100 tADA. The wallet balances can be verified by using the `./all_balances.sh` script. Now that the wallets are created and prepared with tADA, let's proceed with the compilation phase.

### Compile

Inside the parent folder, there is a script called `complete_build.sh`. This script automates the compilation of the contracts using information from the `start_info.json` file. If the wallets have been prepared correctly, the compile script will automatically populate the starting information with the correct hotkey from the wallets folder. However, if the wallets are not prepped correctly, you will need to manually insert the public key hash of the hot wallet into the start_info.json file and comment out the auto populate.

The contracts can be compiled with this command:

```bash
./complete_build.sh
```

Once the complete_build.sh script is executed, it will create two folders inside the parent directory: `contracts` and `hashes`. These folders will be used to store the compiled contracts and their corresponding hashes, respectively. At this stage, the scripts are successfully compiled and ready to be used.

### Script References

To begin interacting with the contracts on the testnet, let's navigate back to the scripts folder and update the `scripts/data` folder to match the current node environment. Within the data directory, you'll find the following files: `path_to_cli.sh`, `path_to_socket.sh`, and `testnet.magic`. Update these files with the appropriate information for the current node environment.

To organize the execution of scripts on the happy path, each script is prefixed with an integer to indicate the sequence of actions. With the environment correctly set up, we can create the reference scripts that store the contract data on-chain. To streamline the process, I suggest opening one terminal within the scripts folder, another within the `scripts/mint` folder, and a third terminal within the `scripts/cip68` folder. This way, one terminal can be used for balance checking, another for minting, and the third for metadatum operations.

The script references can be created with this command:

```bash
./00_createScriptReferences.sh
```

This chained transaction is designed to automatically populate the reference wallet with unique UTxOs that hold each contract. Once this set of transactions is successfully included in the chain, the minting and metadata contracts will be ready for use.

The chained transaction ensures that the reference wallet receives distinct UTxOs for each contract, enabling easy access and management of the contracts on-chain. By executing this transaction, the minting and metadata contracts become operational, allowing you to proceed with further interactions and operations.

### Minting

Within the scripts/mint folder, you will find four scripts that handle minting and burning operations in different ways. These scripts are designed to facilitate the minting and burning of the reference token (ref) and non-fungible token (NFTs).

The mint token scripts are responsible for creating new tokens. They provide a straightforward way to mint new tokens and add them to the blockchain.

On the other hand, the burning of tokens can occur in different scenarios. You have the flexibility to choose whether to burn only the reference tokens, only the NFTs, or both simultaneously, depending on the specific requirements or circumstances.

These scripts provide a versatile approach to handle the minting and burning operations, allowing you to adapt to different situations and efficiently manage the tokens on the blockchain.

The tokens can be minted with this command:

```bash
./01_mintTokens.sh
```

The specified operation involves minting one reference token to the cip68 contract and one NFT to the receiver address. In this scenario, the owner of the token has the ability to construct a transaction to burn their token. However, it's important to note that for the transaction to be valid, it must be signed by the hotkey.

Typically, if a receiver wishes to burn the tokens, it is common to burn both the NFT and reference token simultaneously. This action results in the remaining ada being returned to the receiver address. To accomplish this, you can utilize the `04_burnAll.sh` script, which is specifically designed to facilitate the burning of both the NFT and reference token at the same time, while ensuring the leftover ada is sent back to the receiver address.


The reference and nft token can be burned simultaneously with this command:

```bash
./04_burnAll.sh
```

In cases where only the NFT or the reference token needs to be burned, you can utilize the `02_burnNft.sh` and `03_burnRef.sh` scripts. These scripts are specifically designed for situations where the receiver wallet holds only one of those tokens at a time.

When using the `03_burnRef.sh` script to burn the reference token, it is important to note that you need to remove the reference token from the metadata contract before initiating the burning process. This ensures that the burning operation is carried out correctly and without any conflicts.

By using the appropriate script based on your specific requirements, you can effectively burn either the NFT or the reference token, depending on the situation at hand.

### Metadata

Metadata pre-cip68 was typically in 721 format like below:

```json
{
  "721": {
    "policy_id": {
      "token_name": {
        "album_title": "A Song",
        "artists": [
          {
            "name": "You"
          }
        ],
        "copyright": [
          "© 2022 Fake LLC"
        ],
        "country_of_origin": "United States",
        "track_number": 1
      }
    },
    "version": 1
  }
}
```

With cip68 this metadata becomes metadatum.

```json
{
    "constructor": 0,
    "fields": [
        {
            "map": [
                {
                    "k": {
                        "bytes": "616c62756d5f7469746c65"
                    },
                    "v": {
                        "bytes": "4120536f6e67"
                    }
                },
                {
                    "k": {
                        "bytes": "61727469737473"
                    },
                    "v": {
                        "list": [
                            {
                                "map": [
                                    {
                                        "k": {
                                            "bytes": "6e616d65"
                                        },
                                        "v": {
                                            "bytes": "596f75"
                                        }
                                    }
                                ]
                            }
                        ]
                    }
                },
                {
                    "k": {
                        "bytes": "636f70797269676874"
                    },
                    "v": {
                        "list": [
                            {
                                "bytes": "c2a920323032322046616b65204c4c43"
                            }
                        ]
                    }
                },
                {
                    "k": {
                        "bytes": "636f756e7472795f6f665f6f726967696e"
                    },
                    "v": {
                        "bytes": "556e6974656420537461746573"
                    }
                },
                {
                    "k": {
                        "bytes": "747261636b5f6e756d626572"
                    },
                    "v": {
                        "int": 1
                    }
                }
            ]
        },
        {
            "int": 1
        }
    ]
}
```

Inside the scripts folder, there is an experimental metadata to metadatum converter written in Python called `convert_metadata.py`. This converter has the capability to convert standard 721 metadata into CIP68 metadatum format. The converter function requires the following inputs:

- Metadata path: The path to the original 721 metadata file.
- Metadatum path: The desired path for the converted metadatum file.
- Tag standard: The tag standard used in the original metadata.
- Policy ID: The policy ID associated with the token.
- Token name: The name of the token.
- Version: The version number of the metadatum.

By providing these inputs, the converter function will convert the standard 721 metadata into the CIP68 metadatum format. This allows for compatibility and usage of the converted metadatum in the CIP68 contract.

Please note that this converter is experimental and may require further refinement or customization based on your specific requirements. Feel free to explore and utilize the converter based on your needs.

```py
from convert_metadata import convert_metadata
file_path  = "../data/meta/example.metadata.json"
datum_path = "../data/meta/example.metadatum.json"
tag        = '721'
pid        = '<policy_id_hex>'
tkn        = '<asset_name_ascii>'
version    = 1
convert_metadata(file_path, datum_path, tag, pid, tkn, version)
```

### Updating Metadatum

The CIP68 contract incorporates an update function that enables the modification of the metadatum, but with the permission of the hot key wallet. This functionality is designed to accommodate different minimum UTxO values.

Essentially, if a new metadatum requires less ADA than the previous one, the difference can be extracted from the contract. Conversely, if the new metadatum requires more ADA, it can be added to the contract. This dynamic behavior allows the metadatum to be updated without the loss of ADA.

However, it's important to note that the update validation is only allowed if the new metadatum adheres to the correct format specified by the contract. This ensures the integrity and compatibility of the metadatum.

By leveraging this feature, you can maintain a flexible and dynamic metadatum while ensuring the contract's ADA balance remains intact.

The metadatum can be updated with this command from the cip68 folder:

```bash
./01_updateMetadata.sh
```

### Removing Metadatum

The ability to remove metadatum can be necessary in various scenarios such as contract forks, bans, or legal requirements. The CIP68 contract is designed to provide flexibility in handling metadatum removal, offering options that are at the discretion of the hotkey wallet.

One option is to burn the reference token associated with the metadatum upon its removal. This ensures that the metadatum is permanently removed from the contract. Alternatively, the reference token can be sent to another designated address instead of being burned. This flexibility allows for interesting interactions and actions, empowering the hotkey wallet to make decisions based on specific circumstances.

By incorporating such flexibility, the contract enables the hotkey wallet to act in a manner that aligns with the desired outcome, without imposing rigid constraints. This can be advantageous in situations where adaptability and responsiveness are required.

The metadatum can be removed and burned with this command:

```bash
./02_removeAndBurnMetadata.sh
```

The metadatumc an just be removed with this command:

```bash
./03_removeMetadata.sh
```