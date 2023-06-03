use aiken/dict.{Dict}

/// The proposed CIP68 datum standard https://cips.cardano.org/cips/cip68/
/// 
pub type CIP68Datum {
  metadata: Dict<Data, Data>,
  version: Int,
}

/// The metadatum can only be removed or updated.
///
pub type CIP68Redeemer {
  RemoveMeta
  UpdateMeta { lovelace: Int, direction: Int }
}

/// The ref and nft tokens can be minted or burned.
///
pub type MintRedeemer {
  MintTokens
  BurnTokens
}
