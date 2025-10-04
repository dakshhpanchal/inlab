#!/bin/bash

kitty --session <(cat <<EOF
# First window: Docker (~/probes/inlab)
cd ~/probes/inlab
launch --type=window sh -c "cd ~/probes/inlab && docker compose down && docker compose up --build"

# Second window: Flutter (~/probes/inlab/frontend)
cd ~/probes/inlab/frontend
launch --type=window sh -c "cd ~/probes/inlab/frontend && flutter run"
EOF
)

