import lorehold_brain_in_a_jar_pg_package_preflight as pkg


def _exact_contract(*, adapter_present=True):
    return {
        "summary": {
            "contract_drafted": True,
            "brain_exact_scope_adapter_present": adapter_present,
            "effect_json_scope": pkg.BRAIN_SCOPE,
        },
        "effect_json_contract": {
            "effect": "topdeck_manipulation",
            "battle_model_scope": pkg.BRAIN_SCOPE,
            "source_card": pkg.BRAIN_NAME,
            "activation_requires_tap": True,
            "activation_cost_mana": "{1}",
            "activation_cost_generic": 1,
            "activated_add_counters": True,
            "activated_add_counters_target": "self",
            "activated_add_counters_counter_type": "charge",
            "activated_add_counters_count": 1,
            "brain_in_a_jar_free_cast": True,
            "free_cast_from_zone": "hand",
            "free_cast_card_types": ["instant", "sorcery"],
            "free_cast_mana_value_match": "source_charge_counters_after_add",
            "cast_without_paying_mana_cost": True,
            "secondary_activation_requires_tap": True,
            "secondary_activation_cost_mana": "{3}",
            "secondary_activation_cost_generic": 3,
            "secondary_activation_remove_counter_type": "charge",
            "secondary_activation_remove_x_counters": True,
            "secondary_activation_scry_count_source": "removed_charge_counters",
        },
    }


def _preflight():
    return {
        "status": "brain_in_a_jar_runtime_cut_preflight_blocked_adapter_present_no_active_rule_no_safe_cut_keep_607",
        "summary": {
            "brain_active_rule_count": 0,
            "safe_cut_count": 0,
            "brain_exact_adapter_present": True,
        },
    }


def test_proposed_rule_uses_current_oracle_hash_and_brain_scope() -> None:
    rule = pkg.build_proposed_rule(_exact_contract())

    assert rule["card_name"] == "Brain in a Jar"
    assert rule["normalized_name"] == "brain in a jar"
    assert rule["oracle_hash"] == "41468898bf6400763de517269fdeb456"
    assert rule["logical_rule_key"].startswith("battle_rule_v1:")
    assert rule["effect_json"]["battle_model_scope"] == pkg.BRAIN_SCOPE
    assert rule["effect_json"]["free_cast_optional"] is True
    assert rule["effect_json"]["free_cast_max_cards"] == 1
    assert rule["effect_json"]["x_value_default_when_cast_without_paying_mana_cost"] == 0
    assert rule["deck_role_json"]["lane"] == "topdeck_miracle_engine"


def test_manifest_is_review_only_and_keeps_deck_607_closed() -> None:
    manifest = pkg.build_manifest(
        exact_contract=_exact_contract(),
        preflight=_preflight(),
        paths={},
    )

    assert manifest["status"] == "prepared_read_only_pending_apply_approval"
    assert manifest["postgres_writes"] is False
    assert manifest["deck_607_mutated"] is False
    assert manifest["summary"]["apply_ready_for_manual_review"] is True
    assert manifest["summary"]["postgres_writes_allowed_now"] is False
    assert manifest["summary"]["deck_action_allowed_now"] is False
    assert manifest["decision"]["package_apply_requires_explicit_approval"] is True
    assert "Nontrivial additional costs" in manifest["decision"]["known_runtime_followup"]


def test_adapter_missing_blocks_apply_readiness() -> None:
    manifest = pkg.build_manifest(
        exact_contract=_exact_contract(adapter_present=False),
        preflight=_preflight(),
        paths={},
    )

    assert manifest["status"] == "blocked_adapter_missing_no_pg_package_apply"
    assert manifest["summary"]["apply_ready_for_manual_review"] is False


def test_sql_package_has_precheck_upsert_postcheck_and_narrow_rollback() -> None:
    rule = pkg.build_proposed_rule(_exact_contract())
    precheck = pkg.build_precheck_sql(rule)
    apply_sql = pkg.build_apply_sql(rule)
    postcheck = pkg.build_postcheck_sql(rule)
    rollback = pkg.build_rollback_sql(rule)

    assert "md5(coalesce(c.oracle_text, '')) = p.oracle_hash" in precheck
    assert "target_card_rows" in precheck
    assert "INSERT INTO public.card_battle_rules" in apply_sql
    assert "ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE" in apply_sql
    assert "Brain in a Jar package abort" in apply_sql
    assert "promoted_verified_auto_rows" in postcheck
    assert "promoted_brain_free_cast_rows" in postcheck
    assert "DELETE FROM public.card_battle_rules r" in rollback
    assert f"r.logical_rule_key = '{rule['logical_rule_key']}'" in rollback
    assert "DELETE FROM public.card_battle_rules\nWHERE normalized_name IN" not in rollback


def test_markdown_surfaces_closed_gates_and_files() -> None:
    manifest = pkg.build_manifest(
        exact_contract=_exact_contract(),
        preflight=_preflight(),
        paths={"exact_contract": pkg.DEFAULT_EXACT_CONTRACT},
    )
    markdown = pkg.render_markdown(manifest)

    assert "PostgreSQL writes: `false`" in markdown
    assert "Deck 607 mutated: `false`" in markdown
    assert "package_apply_requires_explicit_approval: `true`" in markdown
    assert "Brain in a Jar" in markdown
    assert "41468898bf6400763de517269fdeb456" in markdown
