use aiken/transaction.{Mint, ScriptContext, Transaction}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId}
use assist/addresses
use assist/find
use assist/minting
use assist/payout
use assist/signing
use assist/types/cip68.{CIP68}
use assist/types/hashes.{PublicKeyHash, TxHash, ValidatorHash}
use assist/values
use mint_contract/types.{BurnTokens, MintRedeemer, MintTokens}

// This allows a hot key to mint 1 reference and 1 nft for a cip 68 token or
// the hot key may be either the reference or nft.
validator(
  // this key controls everything
  hot_key: PublicKeyHash,
  // the cip 68 and stake data
  cip68_hash_data: Data,
  stake_hash_data: Data,
  // this allows many policy ids
  _random_string: ByteArray,
) {
  fn params(redeemer: MintRedeemer, context: ScriptContext) -> Bool {
    // this transaction
    let tx: Transaction = context.transaction
    // the minted value from the tx
    let mint: List<(PolicyId, AssetName, Int)> =
      tx.mint
        |> value.from_minted_value()
        |> value.flatten()
    // mint only
    when context.purpose is {
      // mint 1 ref and 1 nft
      Mint(own_currency_symbol) ->
        when redeemer is {
          MintTokens -> {
            // cip68 address know at compile time
            expect cip68_hash: ValidatorHash = cip68_hash_data
            expect stake_hash: ValidatorHash = stake_hash_data
            // staking at this address
            let cip68_addr: Address =
              addresses.create_script_address(cip68_hash, stake_hash)
            // get first input info from the tx in lexographical order
            let first_index: Int = find.first_input_index(tx.inputs)
            let first_tx_hash: TxHash = find.first_input_txid(tx.inputs)
            // use the reference prefix
            let ref_tkn: AssetName =
              values.unique_token_name(
                first_tx_hash,
                first_index,
                cip68.prefix_100,
              )
            // use the nft prefix
            let nft_tkn: AssetName =
              values.unique_token_name(
                first_tx_hash,
                first_index,
                cip68.prefix_222,
              )
            // this should prevent utxos without cip68 datum to go to the cip68 storage contract
            // This Forces An Inline Datum!
            expect _: CIP68 = find.output_datum_by_addr(tx.outputs, cip68_addr)
            //
            // The hot key has to sign the tx to mint 1 ref and 1 nft. There
            // is destination validation for the cip68 token but not for the 
            // nft. This should allow a lot of flexability.
            //
            and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key)?,
              // prevent roll over double nft attack
              (first_index < 256)?,
              // must mint 1 reference token
              minting.exact(mint, own_currency_symbol, ref_tkn, 1)?,
              // the nft can go anywhere; ref must go to metadatum contract
              // must mint 1 non-fungible token
              minting.exact(mint, own_currency_symbol, nft_tkn, 1)?,
              // reference token must go to cip contract
              payout.at_least(
                cip68_addr,
                value.from_asset(own_currency_symbol, ref_tkn, 1),
                tx.outputs,
              )?,
            }
          }
          // burn the ref or the nft or both at the same time
          BurnTokens -> and {
              // cornucopias must sign it
              signing.verify_sig(tx.extra_signatories, hot_key)?,
              // this allows optional burning of either or both
              or {
                // burn only 1 ref token
                minting.by_prefix(
                  mint,
                  own_currency_symbol,
                  cip68.prefix_100,
                  -1,
                )?,
                // burn only 1 nft
                minting.by_prefix(
                  mint,
                  own_currency_symbol,
                  cip68.prefix_222,
                  -1,
                )?,
              }?,
            }
        }
      // Mint Only
      _ -> False
    }
  }
}
