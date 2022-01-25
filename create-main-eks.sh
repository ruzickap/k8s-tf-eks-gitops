#!/usr/bin/env bash

set -euxo pipefail

if [ "$#" -eq 0 ]; then
  sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p" docs/src/part-??.md | sed "/^\`\`\`*/d" | bash -euxo pipefail
else
  sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p" docs/src/part-??.md | sed "/^\`\`\`*/d"
fi
