#!/usr/bin/env python3
from __future__ import annotations

import tempfile
from pathlib import Path

import battle_mtga_player_log_parser as parser


SAMPLE_LOG = """
[UnityCrossThreadLogger] <== GreToClientEvent {"greToClientEvent":{"gameStateMessage":{"gameStateId":42,"turnInfo":{"turnNumber":3,"phase":"combat","step":"declare_attackers","activePlayerSystemSeatId":1},"gameObjects":[{"instanceId":10,"grpId":123},{"instanceId":11,"grpId":456}],"annotations":[{"type":"AnnotationType_ZoneTransfer"}],"actions":[{"actionType":"ActionType_Attack"}],"zones":[{"zoneId":1}]}}}
[UnityCrossThreadLogger] ==> ClientToGREMessage {"clientToGreMessage":{"type":"CLIENT_ACTION","action":{"actionType":"ActionType_Cast"}}}
[UnityCrossThreadLogger] <== GREMessageType_GameStateMessage {"gameStateMessage":{"gameStateId":43,"turnInfo":{"turnNumber":4,"phase":"ending","step":"end"},"gameObjects":[],"annotations":[],"actions":[]}}
not json but mentions GRE
"""


def test_iter_json_values_extracts_embedded_objects() -> None:
    values = list(parser.iter_json_values(SAMPLE_LOG))

    assert len(values) == 3
    assert parser.classify_payload(values[0]) == "game_state_message"
    assert parser.classify_payload(values[1]) == "client_to_gre_message"


def test_build_report_summarizes_player_log_without_raw_payloads() -> None:
    with tempfile.TemporaryDirectory() as tmp_name:
        source = Path(tmp_name) / "Player.log"
        source.write_text(SAMPLE_LOG, encoding="utf-8")

        report = parser.build_report([source], max_state_samples=4)

    summary = report["summary"]
    assert report["postgres_writes"] is False
    assert report["privacy_policy"]["raw_log_lines_persisted"] is False
    assert summary["files_processed"] == 1
    assert summary["json_objects_seen"] == 3
    assert summary["game_state_messages_seen"] == 2
    assert summary["message_counts"]["client_to_gre_message"] == 1
    assert summary["turn_counts"] == {"3": 1, "4": 1}
    assert len(report["game_state_samples"]) == 2
    first = report["game_state_samples"][0]
    assert first["game_state_id"] == "42"
    assert first["turn_number"] == "3"
    assert first["phase"] == "combat"
    assert first["step"] == "declare_attackers"
    assert first["game_objects_count"] == 2
    assert first["annotations_count"] == 1
    assert first["actions_count"] == 1


if __name__ == "__main__":
    test_iter_json_values_extracts_embedded_objects()
    test_build_report_summarizes_player_log_without_raw_payloads()
    print("2 tests passed")
