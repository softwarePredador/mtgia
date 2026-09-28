// Canonical inventory semantics shared by Collection, Deckbuilder and Trade.
//
// `cards.oracle_id` is the playable identity. A printing without Oracle data
// falls back to its own `cards.id`, so no row is silently discarded.
// Allocation is the sum required by every active deck; active trade offers are
// commitments. A copy can only be advertised when it remains free after both.
//
// The views `collection_availability_snapshot` and `binder_item_availability`
// are created by migration 045 and by `database_setup.sql`. BT-DB-004: schema
// SQL lives only in the migrations and the baseline.

/// Reads a quantity column from the availability views as an int.
int collectionQuantity(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
