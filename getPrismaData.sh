#!/bin/bash

#source /tmp/workspace/env.txt
image=${repo}/${CIRCLE_PROJECT_REPONAME,,}:${CIRCLE_BUILD_NUM}

# LeanSeeksの環境変数を指定してファイルに書き出す
echo "app_name=PRISMA_SCAN_${image}">param.txt
echo 'app_priority="H"'>>param.txt
echo "scanner=0">>param.txt

#Prisma Cloudに対象イメージの脆弱性情報を問い合わせる
curl -k -u "${pc_user}:${pc_pass}" -H "Content-Type: application/json" "${pc_url}/api/v1/scans?search=buildimage:temp" | jq -r '[ .[].entityInfo ]' > "ci_scan.json"

# LeanSeeks用のアップロードデータを生成する
echo "------- LeanSeeksのアップロードデータを生成中"
vuln_data='[{"id": "ci_scan.json","scanner": 0,"payload":'
vuln_data+=$(cat "ci_scan.json")
vuln_data+="}]"
echo "${vuln_data}" | jq > vuln_data.json
