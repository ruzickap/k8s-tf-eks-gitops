#!/usr/bin/env bash

set -euo pipefail

sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p" docs/src/clenaup.md | sed "/^\`\`\`*/d" | bash -euxo pipefail
