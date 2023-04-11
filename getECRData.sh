#!/bin/bash

echo "app_name=ECR_SCAN_${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BUILD_NUM}">env.txt
echo 'app_priority="H"'>>env.txt

echo "------- ECRから脆弱性データを取得中"
mkdir -p work
aws ecr describe-image-scan-findings --repository-name ${CIRCLE_PROJECT_REPONAME,,} --image-id imageTag=${build_num} | jq -c ".imageScanFindings.findings[] |[ .name, .severity ]" > work/ecr_vlun.txt

echo "------- ECRの脆弱性データをLeanSeeksフォーマットに変換中"
it=1
number=$(cat work/ecr_vlun.txt | grep -c "CVE-")
ls_data='['
while read row; do
  cveId=$(echo ${row} | cut -d '"' -f 2)
  severity=$(echo ${row} | cut -d '"' -f 4)
  ls_data+='{
    "cveId": "'"${cveId}"'",
    "packageName": "",
    "packageVersion": "",
    "severity": "'$(echo "${severity}" | tr "[A-Z]" "[a-z]")'",
    "cvssScore": "",
    "title": "",
    "description": "",
    "link": "",
    "AV": "",
    "AC": "",
    "C": "",
    "I": "",
    "A": "",
    "hasFix": "",
    "exploit": "",
    "publicExploits": "",
    "published": "",
    "updated": "",
    "type": ""'
  if [ ${it} -eq ${number} ]; then
    vuln_data+="}]"
    echo ${ls_data} | jq > "work/ecr_vlun_LS.json"
    #rm -r "${dirname}/"
  else
    vuln_data+="},"
  fi
  echo "${it}/${number}"
  it=$((it+1))

done < work/ecr_vlun.txt

echo "------- LeanSeeksのアップロードデータを生成中"
vuln_data='[{"id": "ci_scan.json","scanner": 255,"payload":'
            vuln_data+=$(cat "work/ecr_vlun_LS.json")
            vuln_data+="}]"
            echo "${vuln_data}" > vuln_data.json
