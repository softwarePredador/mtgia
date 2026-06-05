#!/bin/sh
# Auto-sync wrapper: sempre aplica no PG (cron mode)
exec python3 /opt/data/scripts/auto_sync_learned_decks.py --apply
