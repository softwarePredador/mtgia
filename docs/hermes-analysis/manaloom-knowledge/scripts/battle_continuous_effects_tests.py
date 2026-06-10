"""Continuous effects and layer-ordering regressions."""


def register_tests(battle):
    def test_continuous_effects_apply_layers_and_sublayers_in_order():
        creature = {
            "name": "Layer Test",
            "type_line": "Creature",
            "colors": ["red"],
            "abilities": ["trample"],
            "power": 2,
            "toughness": 2,
        }
        result = battle.apply_continuous_effects(
            creature,
            [
                {
                    "effect_id": "switch",
                    "layer": 7,
                    "sublayer": "7e",
                    "effect_type": "switch_pt",
                    "timestamp": 1,
                },
                {
                    "effect_id": "set-pt",
                    "layer": 7,
                    "sublayer": "7b",
                    "effect_type": "set_pt",
                    "value": {"power": 1, "toughness": 4},
                    "timestamp": 5,
                },
                {
                    "effect_id": "modify",
                    "layer": 7,
                    "sublayer": "7c",
                    "effect_type": "modify_pt",
                    "value": {"power": 2, "toughness": 0},
                    "timestamp": 2,
                },
                {
                    "effect_id": "counter",
                    "layer": 7,
                    "sublayer": "7d",
                    "effect_type": "counter_pt",
                    "value": {"power": 0, "toughness": 1},
                    "timestamp": 3,
                },
            ],
        )

        assert result["power"] == 5
        assert result["toughness"] == 3
        assert result["_continuous_effects_applied"] == [
            "set-pt",
            "modify",
            "counter",
            "switch",
        ]

    def test_continuous_effects_apply_type_color_text_and_ability_layers():
        card_state = {
            "name": "Layer Utility",
            "type_line": "Creature",
            "oracle_text": "Target creature gains flying.",
            "colors": ["white"],
            "abilities": ["flying", "vigilance"],
        }

        result = battle.apply_continuous_effects(
            card_state,
            [
                {
                    "effect_id": "text",
                    "layer": 3,
                    "effect_type": "replace_text",
                    "value": {"from": "flying", "to": "trample"},
                    "timestamp": 4,
                },
                {
                    "effect_id": "type",
                    "layer": 4,
                    "effect_type": "add_type",
                    "value": ["Artifact"],
                    "timestamp": 3,
                },
                {
                    "effect_id": "color",
                    "layer": 5,
                    "effect_type": "set_color",
                    "value": ["blue"],
                    "timestamp": 2,
                },
                {
                    "effect_id": "add",
                    "layer": 6,
                    "effect_type": "add_ability",
                    "value": ["hexproof"],
                    "timestamp": 1,
                },
                {
                    "effect_id": "remove",
                    "layer": 6,
                    "effect_type": "remove_ability",
                    "value": ["flying"],
                    "timestamp": 5,
                },
            ],
        )

        assert result["oracle_text"] == "Target creature gains trample."
        assert result["type_line"] == "Creature Artifact"
        assert result["colors"] == ["blue"]
        assert "hexproof" in result["abilities"]
        assert "flying" not in result["abilities"]
        assert "vigilance" in result["abilities"]

    def test_continuous_effect_dependencies_override_timestamp_within_layer():
        card_state = {
            "name": "Dependency Test",
            "type_line": "Creature",
            "abilities": [],
        }

        result = battle.apply_continuous_effects(
            card_state,
            [
                {
                    "effect_id": "remove-flying",
                    "layer": 6,
                    "effect_type": "remove_ability",
                    "value": ["flying"],
                    "timestamp": 1,
                    "depends_on": ["add-flying"],
                },
                {
                    "effect_id": "add-flying",
                    "layer": 6,
                    "effect_type": "add_ability",
                    "value": ["flying"],
                    "timestamp": 9,
                },
            ],
        )

        assert result["abilities"] == []
        assert result["_continuous_effects_applied"] == [
            "add-flying",
            "remove-flying",
        ]

    return [
        test_continuous_effects_apply_layers_and_sublayers_in_order,
        test_continuous_effects_apply_type_color_text_and_ability_layers,
        test_continuous_effect_dependencies_override_timestamp_within_layer,
    ]
