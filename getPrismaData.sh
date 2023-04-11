#!/bin/bash

            app_name="PRISMA_SCAN_${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BUILD_NUM}"
            app_priority="H"
            curl -k -u "${pc_user}:${pc_pass}" -H "Content-Type: application/json" "${pc_url}/api/v1/scans?search=buildimage:temp" | jq -r '[ .[].entityInfo ]' > "ci_scan.json"

            echo "------- LeanSeeksのアップロードデータを生成中"
            vuln_data='[{"id": "ci_scan.json","scanner": 0,"payload":'
            vuln_data+=$(cat "ci_scan.json")
            vuln_data+="}]"
            echo "${vuln_data}" > vuln_data.json
