use aiken/crypto.{ScriptHash}
use cardano/certificate.{StakePoolId}

/// The metadatum can only be removed or updated.
pub type StorageRedeemer {
  RemoveMeta
  UpdateMeta { lovelace: Int }
}

/// The ref and nft tokens can be minted or burned.
pub type MinterRedeemer {
  MintTokens
  BurnTokens
}

/// The stake key and pool to delegate too.
pub type DelegateData {
  stake_cred: ScriptHash,
  pool_id: StakePoolId,
}

/// The stake can be withdrawn or delegated.
pub type StakingRedeemer {
  Withdraw
  DelegateStake(DelegateData)
  RegisterStake(DelegateData)
  UnRegisterStake(DelegateData)
}
