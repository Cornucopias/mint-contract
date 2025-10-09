////
////

use aiken/crypto.{ScriptHash, VerificationKeyHash}
use cardano/address.{Address}
use cardano/addresses
use cardano/assets.{AssetName, PolicyId}
use cardano/minting
use cardano/transaction.{Transaction, TransactionId}
use cardano/tx as signing
use cardano/value
use redeemers.{BurnTokens, MintTokens, MinterRedeemer}
use types/cip68.{CIP68}
use validation/find
use validation/payout

// This allows a hot key to mint 1 reference and 1 nft for a cip 68 token or
// the hot key may be either the reference or nft.
validator contract(
  // this key controls everything
  hot_key: VerificationKeyHash,
  // the storage and stake data
  storage_hash: ScriptHash,
  stake_hash: ScriptHash,
  // this allows many policy ids
  _random_string: Data,
) {
  mint(
    redeemer: MinterRedeemer,
    currency_symbol: PolicyId,
    transaction: Transaction,
  ) {
    // this transaction
    let Transaction { inputs, outputs, extra_signatories, mint, .. } =
      transaction
    // the minted value from the tx
    let mint: List<(PolicyId, AssetName, Int)> =
      mint
        |> assets.flatten()
    // mint only
    when redeemer is {
      MintTokens -> {
        // storage address know at compile time
        let storage_addr: Address =
          addresses.create_script_address(storage_hash, stake_hash)
        // get first input info from the tx in lexographical order
        let first_index: Int = find.first_input_index(inputs)
        let first_tx_hash: TransactionId = find.first_input_txid(inputs)
        // use the reference prefix
        let ref_tkn: AssetName =
          value.unique_token_name(
            first_tx_hash,
            first_index,
            cip68.prefix_100,
            #"",
          )
        // use the nft prefix
        let nft_tkn: AssetName =
          value.unique_token_name(
            first_tx_hash,
            first_index,
            cip68.prefix_222,
            #"",
          )
        // this should prevent utxos without cip68 datum to go to the cip68 storage contract
        // This Forces An Inline Datum!
        expect _: CIP68 = find.output_datum_by_addr(outputs, storage_addr)
        //
        // The hot key has to sign the tx to mint 1 ref and 1 nft. There
        // is destination validation for the cip68 token but not for the 
        // nft. This should allow a lot of flexability.
        //
        and {
          // hot key must sign it
          signing.verify_signature(extra_signatories, hot_key)?,
          // must mint 1 reference token
          minting.exact(mint, currency_symbol, ref_tkn, 1)?,
          // the nft can go anywhere; ref must go to metadatum contract
          // must mint 1 non-fungible token
          minting.exact(mint, currency_symbol, nft_tkn, 1)?,
          // reference token must go to storage contract
          payout.at_least(
            storage_addr,
            assets.from_asset(currency_symbol, ref_tkn, 1),
            outputs,
          )?,
        }
      }
      // burn the ref or the nft or both at the same time
      BurnTokens -> and {
          // hot key must sign it
          signing.verify_signature(extra_signatories, hot_key)?,
          // this allows optional burning of either or both
          or {
            // burn only 1 ref token
            minting.by_prefix(mint, currency_symbol, cip68.prefix_100, -1)?,
            // burn only 1 nft
            minting.by_prefix(mint, currency_symbol, cip68.prefix_222, -1)?,
          }?,
        }
    }
  }

  else(_) {
    fail
  }
}
