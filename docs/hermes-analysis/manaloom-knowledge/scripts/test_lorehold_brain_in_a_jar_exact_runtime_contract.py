import lorehold_brain_in_a_jar_exact_runtime_contract as contract


XMAGE_SOURCE = """
public final class BrainInAJar extends CardImpl {
    public BrainInAJar(UUID ownerId, CardSetInfo setInfo) {
        super(ownerId, setInfo, new CardType[]{CardType.ARTIFACT}, "{2}");
        Ability ability = new SimpleActivatedAbility(
                new AddCountersSourceEffect(CounterType.CHARGE.createInstance()), new GenericManaCost(1)
        );
        ability.addEffect(new BrainInAJarCastEffect());
        ability.addCost(new TapSourceCost());
        this.addAbility(ability);
        ability = new SimpleActivatedAbility(new ScryEffect(GetXValue.instance), new GenericManaCost(3));
        ability.addCost(new TapSourceCost());
        ability.addCost(new RemoveVariableCountersSourceCost(CounterType.CHARGE));
        this.addAbility(ability);
    }
}
class BrainInAJarCastEffect extends OneShotEffect {
    public boolean apply(Game game, Ability source) {
        int counters = sourceObject.getCounters(game).getCount(CounterType.CHARGE);
        FilterCard filter = new FilterInstantOrSorceryCard();
        filter.add(new ManaValuePredicate(ComparisonType.EQUAL_TO, counters));
        return CardUtil.castSpellWithAttributesForFree(controller, source, game, controller.getHand(), filter);
    }
}
"""


RUNTIME_WITH_PRIMITIVES = """
def resolve_add_counters_source_effect(): pass
activated_add_counters = True
def scry_library_for_controller(player, count): pass
charge_counters = 0
def invoke_calamity_free_cast_candidates():
    allowed_zones = ["hand", "graveyard"]
cast_without_paying_mana = True
zero_mana_cost_snapshot = True
"""


def _route_planner():
    return {"summary": {"selected_card": "Brain in a Jar"}}


def _preflight():
    return {"summary": {"decision_status": "brain_blocked"}}


def _build(xmage=XMAGE_SOURCE, runtime=RUNTIME_WITH_PRIMITIVES):
    return contract.build_report(
        xmage_source_text=xmage,
        battle_runtime_text=runtime,
        route_planner=_route_planner(),
        preflight=_preflight(),
        paths={},
    )


def test_contract_drafted_when_xmage_complete_and_adapter_missing() -> None:
    payload = _build()

    assert payload["summary"]["decision_status"] == (
        "brain_exact_runtime_contract_drafted_adapter_missing_keep_607"
    )
    assert payload["summary"]["contract_drafted"] is True
    assert payload["summary"]["brain_exact_scope_adapter_present"] is False
    assert payload["summary"]["xmage_missing_signal_count"] == 0
    effect = payload["effect_json_contract"]
    assert effect["battle_model_scope"] == contract.SCOPE
    assert effect["free_cast_mana_value_match"] == "source_charge_counters_after_add"
    assert effect["secondary_activation_scry_count_source"] == "removed_charge_counters"
    assert payload["decision"]["postgres_writes_allowed"] is False
    assert payload["decision"]["deck_action_allowed"] is False


def test_missing_xmage_free_cast_signal_blocks_contract() -> None:
    payload = _build(xmage=XMAGE_SOURCE.replace("CardUtil.castSpellWithAttributesForFree", ""))

    assert payload["summary"]["decision_status"] == (
        "brain_exact_runtime_contract_blocked_incomplete_xmage_signal"
    )
    assert "casts_from_hand_for_free" in payload["missing_xmage_signals"]
    assert payload["decision"]["deck_action_allowed"] is False


def test_detected_adapter_changes_next_action_to_preflight() -> None:
    payload = _build(runtime=RUNTIME_WITH_PRIMITIVES + f"\n{contract.SCOPE}\n")

    assert payload["summary"]["decision_status"] == (
        "brain_exact_runtime_contract_adapter_detected_preflight_required_keep_607"
    )
    assert payload["summary"]["brain_exact_scope_adapter_present"] is True
    assert payload["summary"]["recommended_next_action"] == (
        "rerun_brain_runtime_cut_preflight_before_any_deck_action"
    )
    assert payload["decision"]["runtime_adapter_required_before_pg_package"] is False
    assert "adapter is detectable" in payload["decision"]["reason"]
    assert "does not expose the Brain-specific adapter" not in payload["decision"]["reason"]


def test_markdown_surfaces_closed_gates_and_test_vectors() -> None:
    markdown = contract.render_markdown(_build())

    assert "Deck 607 mutated: `false`" in markdown
    assert "PostgreSQL writes allowed now: `false`" in markdown
    assert "first_activation_casts_exact_mana_value_one" in markdown
    assert "runtime_adapter_required_before_pg_package: `true`" in markdown
