use aiken/dict.{Dict}
use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{PoolId, Script}

/// The proposed CIP68 datum standard https://cips.cardano.org/cips/cip68/.
pub type CIP68Datum {
  metadata: Dict<Data, Data>,
  version: Int,
}

/// The metadatum can only be removed or updated.
pub type CIP68Redeemer {
  RemoveMeta
  UpdateMeta { lovelace: Int }
}

/// The ref and nft tokens can be minted or burned.
pub type MintRedeemer {
  MintTokens
  BurnTokens
}

/// A script validator hash type.
pub type ValidatorHash =
  Hash<Blake2b_224, Script>

/// The stake key and pool to delegate too.
pub type DelegateData {
  stake_cred: ValidatorHash,
  pool_id: PoolId,
}

/// The stake can be withdrawn or delegated.
pub type StakingRedeemer {
  Withdraw
  Delegate(DelegateData)
}
