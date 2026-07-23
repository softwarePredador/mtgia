/// Canonical inventory semantics shared by Collection, Deckbuilder and Trade.
///
/// `cards.oracle_id` is the playable identity. A printing without Oracle data
/// falls back to its own `cards.id`, so no row is silently discarded.
/// Allocation is the sum required by every active deck; active trade offers are
/// commitments. A copy can only be advertised when it remains free after both.
const collectionAvailabilityViewsSql = r'''
CREATE OR REPLACE VIEW collection_availability_snapshot AS
WITH owned AS (
  SELECT
    bi.user_id,
    COALESCE(c.oracle_id, c.id) AS playable_card_id,
    MIN(c.name) AS canonical_name,
    COALESCE(SUM(bi.quantity), 0)::int AS owned_quantity
  FROM user_binder_items bi
  JOIN cards c ON c.id = bi.card_id
  WHERE bi.list_type = 'have'
  GROUP BY bi.user_id, COALESCE(c.oracle_id, c.id)
),
allocated AS (
  SELECT
    d.user_id,
    COALESCE(c.oracle_id, c.id) AS playable_card_id,
    MIN(c.name) AS canonical_name,
    COALESCE(SUM(dc.quantity), 0)::int AS allocated_quantity
  FROM decks d
  JOIN deck_cards dc ON dc.deck_id = d.id
  JOIN cards c ON c.id = dc.card_id
  WHERE d.deleted_at IS NULL
  GROUP BY d.user_id, COALESCE(c.oracle_id, c.id)
),
committed AS (
  SELECT
    ti.owner_id AS user_id,
    COALESCE(c.oracle_id, c.id) AS playable_card_id,
    MIN(c.name) AS canonical_name,
    COALESCE(SUM(ti.quantity), 0)::int AS committed_trade_quantity
  FROM trade_items ti
  JOIN trade_offers trade ON trade.id = ti.trade_offer_id
  JOIN user_binder_items bi ON bi.id = ti.binder_item_id
  JOIN cards c ON c.id = bi.card_id
  WHERE trade.status IN (
    'pending', 'accepted', 'shipped', 'delivered', 'disputed'
  )
    AND bi.list_type = 'have'
  GROUP BY ti.owner_id, COALESCE(c.oracle_id, c.id)
),
wanted AS (
  SELECT
    bi.user_id,
    COALESCE(c.oracle_id, c.id) AS playable_card_id,
    MIN(c.name) AS canonical_name,
    COALESCE(SUM(bi.quantity), 0)::int AS wanted_quantity
  FROM user_binder_items bi
  JOIN cards c ON c.id = bi.card_id
  WHERE bi.list_type = 'want'
  GROUP BY bi.user_id, COALESCE(c.oracle_id, c.id)
),
identities AS (
  SELECT user_id, playable_card_id FROM owned
  UNION
  SELECT user_id, playable_card_id FROM allocated
  UNION
  SELECT user_id, playable_card_id FROM committed
  UNION
  SELECT user_id, playable_card_id FROM wanted
)
SELECT
  identity.user_id,
  identity.playable_card_id,
  COALESCE(
    owned.canonical_name,
    allocated.canonical_name,
    committed.canonical_name,
    wanted.canonical_name
  ) AS canonical_name,
  COALESCE(owned.owned_quantity, 0)::int AS owned_quantity,
  COALESCE(allocated.allocated_quantity, 0)::int AS allocated_quantity,
  COALESCE(committed.committed_trade_quantity, 0)::int
    AS committed_trade_quantity,
  GREATEST(
    COALESCE(owned.owned_quantity, 0)
      - COALESCE(allocated.allocated_quantity, 0)
      - COALESCE(committed.committed_trade_quantity, 0),
    0
  )::int AS free_quantity,
  GREATEST(
    COALESCE(allocated.allocated_quantity, 0)
      - COALESCE(owned.owned_quantity, 0),
    0
  )::int AS missing_quantity,
  COALESCE(wanted.wanted_quantity, 0)::int AS wanted_quantity,
  GREATEST(
    COALESCE(wanted.wanted_quantity, 0)
      - COALESCE(owned.owned_quantity, 0),
    0
  )::int AS wanted_missing_quantity
FROM identities identity
LEFT JOIN owned USING (user_id, playable_card_id)
LEFT JOIN allocated USING (user_id, playable_card_id)
LEFT JOIN committed USING (user_id, playable_card_id)
LEFT JOIN wanted USING (user_id, playable_card_id);

CREATE OR REPLACE VIEW binder_item_availability AS
WITH item_priority AS (
  SELECT
    bi.id AS binder_item_id,
    bi.user_id,
    bi.card_id,
    COALESCE(c.oracle_id, c.id) AS playable_card_id,
    bi.quantity AS item_quantity,
    COALESCE(
      SUM(bi.quantity) OVER (
        PARTITION BY bi.user_id, COALESCE(c.oracle_id, c.id)
        ORDER BY
          CASE WHEN bi.for_trade OR bi.for_sale THEN 0 ELSE 1 END,
          bi.updated_at,
          bi.id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ),
      0
    )::int AS prior_item_quantity
  FROM user_binder_items bi
  JOIN cards c ON c.id = bi.card_id
  WHERE bi.list_type = 'have'
)
SELECT
  item.binder_item_id,
  item.user_id,
  item.card_id,
  item.playable_card_id,
  item.item_quantity,
  availability.owned_quantity,
  availability.allocated_quantity,
  availability.committed_trade_quantity,
  availability.free_quantity,
  availability.missing_quantity,
  GREATEST(
    LEAST(
      item.item_quantity,
      availability.free_quantity - item.prior_item_quantity
    ),
    0
  )::int AS available_quantity
FROM item_priority item
JOIN collection_availability_snapshot availability
  ON availability.user_id = item.user_id
 AND availability.playable_card_id = item.playable_card_id;
''';

const dropCollectionAvailabilityViewsSql = r'''
DROP VIEW IF EXISTS binder_item_availability;
DROP VIEW IF EXISTS collection_availability_snapshot;
''';

int collectionQuantity(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
