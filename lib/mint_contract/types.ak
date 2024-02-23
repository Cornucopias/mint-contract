use aiken/transaction/credential.{PoolId}
use assist/types/hashes.{ValidatorHash}

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
