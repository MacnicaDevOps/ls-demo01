#!/bin/bash

#source /tmp/workspace/env.txt
repo=$(echo ${awsEndpoint} | cut -d / -f 3)
image=${repo}/${CIRCLE_PROJECT_REPONAME,,}:${CIRCLE_BUILD_NUM}
build_num=$(echo ${image} | cut -d ':' -f 2)

# LeanSeeksの環境変数を指定してファイルに書き出す
echo "image=\"${image}\"" > param.txt
echo "app_name=\"PRISMA_SCAN_${CIRCLE_BUILD_NUM}\"" > param.txt
echo "app_priority=\"H\"" >> param.txt
echo "scanner=0" >> param.txt

#Prisma Cloudに対象イメージの脆弱性情報を問い合わせる
curl -u "${pc_user}:${pc_pass}" -H "Content-Type: application/json" "${pc_url}/api/v1/scans?search=buildimage:${build_num}" | jq -r '[ .[].entityInfo ]' > "ci_scan.json"

# LeanSeeks用のアップロードデータを生成する
echo "------- LeanSeeksのアップロードデータを生成中"
echo '[{"id": "ci_scan.json","scanner": 0,"payload":' > vuln_data.json
cat "ci_scan.json" >> vuln_data.json
eecho "}]" >> vuln_data.json
  #echo "${vuln_data}" > vuln_data.json

  #echo "デバッグ : LeanSeeksのアップロードデータのCVEカウント"
  #cat vuln_data.json | jq | grep -c "CVE-"
