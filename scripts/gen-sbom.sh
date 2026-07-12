#!/usr/bin/env bash
#
# Generate a minimal SPDX 2.3 SBOM for usb-creator on stdout.
# Usage: scripts/gen-sbom.sh > usb-creator.spdx.json   (or: make sbom)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ver=$(sed -n 's/^VERSION="\(.*\)"/\1/p' usb-creator)
sha=$(sha256sum usb-creator | awk '{print $1}')
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n --arg ver "$ver" --arg sha "$sha" --arg created "$created" '
{
  spdxVersion: "SPDX-2.3",
  dataLicense: "CC0-1.0",
  SPDXID: "SPDXRef-DOCUMENT",
  name: ("usb-creator-" + $ver),
  documentNamespace: ("https://github.com/Reventlow/usb-creator/spdx/" + $ver),
  creationInfo: {
    created: $created,
    creators: ["Tool: scripts/gen-sbom.sh", "Person: Gorm Reventlow"]
  },
  packages: ([
    {
      name: "usb-creator",
      SPDXID: "SPDXRef-Package-usb-creator",
      versionInfo: $ver,
      downloadLocation: "git+https://github.com/Reventlow/usb-creator.git",
      licenseConcluded: "MIT",
      licenseDeclared: "MIT",
      filesAnalyzed: false,
      checksums: [{algorithm: "SHA256", checksumValue: $sha}],
      primaryPackagePurpose: "APPLICATION"
    }
  ] + (["bash", "coreutils", "util-linux", "curl", "jq", "gnupg"] | map({
      name: .,
      SPDXID: ("SPDXRef-Package-" + .),
      versionInfo: "NOASSERTION",
      downloadLocation: "NOASSERTION",
      licenseConcluded: "NOASSERTION",
      filesAnalyzed: false
  }))),
  relationships: ([
    {
      spdxElementId: "SPDXRef-DOCUMENT",
      relationshipType: "DESCRIBES",
      relatedSpdxElement: "SPDXRef-Package-usb-creator"
    }
  ] + (["bash", "coreutils", "util-linux", "curl", "jq"] | map({
      spdxElementId: "SPDXRef-Package-usb-creator",
      relationshipType: "DEPENDS_ON",
      relatedSpdxElement: ("SPDXRef-Package-" + .)
  })) + [
    {
      spdxElementId: "SPDXRef-Package-gnupg",
      relationshipType: "OPTIONAL_DEPENDENCY_OF",
      relatedSpdxElement: "SPDXRef-Package-usb-creator"
    }
  ])
}'
