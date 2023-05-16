#!/bin/bash

source /tmp/workspace/env.txt

  #echo "デバッグ用"
  #cat /tmp/workspace/env.txt

# LeanSeeksの環境変数を指定してファイルに書き出す
build_num=$(echo ${image} | cut -d ':' -f 2)
echo "app_name=ECR_SCAN_${build_num}" > param.txt
echo 'app_priority="H"' >> param.txt
echo "scanner=255" >> param.txt

  #echo "デバッグ用"
  #cat param.txt

source param.txt

# ECRから脆弱性スキャンのデータをAWSCLIで取得して、CVE IDとセベリティをフィルタして保存する
echo "------- ECRから脆弱性データを取得中"
mkdir -p work
#build_num=$(echo ${image} | cut -d ':' -f 2)
aws ecr describe-image-scan-findings --repository-name ${CIRCLE_PROJECT_REPONAME,,} --image-id imageTag=${build_num} | jq -c ".imageScanFindings.findings[] |[ .name, .severity ]" > work/ecr_vlun.txt

# CVE IDとセベリティをLeanSeeksのフォーマットに割り当てる
echo "------- ECRの脆弱性データをLeanSeeksフォーマットに変換中"
it=1
number=$(cat work/ecr_vlun.txt | grep -c "CVE-")

#ls_data='['
echo '[' > "ecr_vlun_LS.json"
while read row; do
  cveId=$(echo ${row} | cut -d '"' -f 2)
  severity=$(echo ${row} | cut -d '"' -f 4)
  #ls_data+="{
  echo "{
    \"cveId\": \"${cveId}\",
    \"packageName\": \"\",
    \"packageVersion\": \"\",
    \"severity\": \"$(echo "${severity}" | tr "[A-Z]" "[a-z]")\",
    \"cvssScore\": \"\",
    \"title\": \"\",
    \"description\": \"\",
    \"link\": \"\",
    \"AV\": \"\",
    \"AC\": \"\",
    \"C\": \"\",
    \"I\": \"\",
    \"A\": \"\",
    \"hasFix\": \"\",
    \"exploit\": \"\",
    \"publicExploits\": \"\",
    \"published\": \"\",
    \"updated\": \"\",
    \"type\": \"\"" >> "ecr_vlun_LS.json"
  if [ ${it} -eq ${number} ]; then
    #ls_data+="}]"
    echo "}]" >> "ecr_vlun_LS.json"
    #echo ${ls_data}  > "ecr_vlun_LS.json"
    
    #echo "デバッグ ecr_vlun_LS.jsonの中身"
    #cat ecr_vlun_LS.json
    
    #rm -r "${dirname}/"
  else
    #ls_data+="},"
    echo "}," >> "ecr_vlun_LS.json"
  fi
  echo "${it}/${number}"
  it=$((it+1))

done < work/ecr_vlun.txt

# LeanSeeks用のアップロードデータを生成する
echo "------- LeanSeeksのアップロードデータを生成中"
  echo '[{"id": "ci_scan.json","scanner": 255,"payload":' > vuln_data.json
  echo $(cat "ecr_vlun_LS.json") >> vuln_data.json
  echo "}]" >> vuln_data.json
  #echo "${vuln_data}" | jq > vuln_data.json