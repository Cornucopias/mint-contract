use aiken/dict.{Dict}

// https://cips.cardano.org/cips/cip68/
pub type CIP68Datum {
  metadata: Dict<Data, Data>,
  version: Int,
}

// can only remove or update
pub type CIP68Redeemer {
  RemoveMeta
  UpdateMeta { lovelace: Int, direction: Int }
}

// can only mint or burn
pub type MintRedeemer {
  MintTokens
  BurnTokens
}
