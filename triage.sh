#!/bin/bash

            app_name="CCI_Build_${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BUILD_NUM}"
            app_priority="H"
            curl -k -u "${pc_user}:${pc_pass}" -H "Content-Type: application/json" "${pc_url}/api/v1/scans?search=${imagename}/${CIRCLE_PROJECT_REPONAME,,}:${CIRCLE_BUILD_NUM}" | jq -r '[ .[].entityInfo ]' > "ci_scan.json"
            echo "------- LeanSeeksのアップロードURLを情報取得中"
            cred=`curl -X "GET" "${ls_url}/api/vulnerability-scan-results/upload-destination" -H "accept: application/json" -H "Accept-Language: ja" -H "Authorization: Bearer ${ls_token}" -H "${ua}"`
            s3_url=`echo "${cred}" | jq .uploadDestination.url | sed -e 's/\"//g'`
            s3_jwt=`echo "${cred}" | jq .uploadDestination.key | sed -e 's/\"//g'`
            echo "------- LeanSeeksのアップロードデータを生成中"
            vuln_data='[{"id": "ci_scan.json","scanner": 0,"payload":'
            vuln_data+=$(cat "ci_scan.json")
            vuln_data+="}]"
            echo "------- データをLeanSeeksにアップロード中"
            echo "${vuln_data}" > vuln_data.json
            curl -X 'PUT' "${s3_url}" --data-binary @vuln_data.json
            echo "------- トリアージリクエストパラメーターの準備中"
            param='{"application_name":"'${app_name}'","importance":"'${app_priority}'","is_template":false,"pods":'
            param+=`jq -R -s -f mapping.jq params.csv | jq -r -c '[.[] |select(.pod_name != null and .is_root != "is_root" )]'| sed -e 's/"¥r"//g'`"}"
            echo $param | sed 's/"TRUE"/true/g' | sed -e 's/"FALSE"/false/g' | sed -e 's/\r//g'> "param.json"
            echo "------- トリアージリクエスト実行中"
            curl -X 'POST' "${ls_url}/api/triage-requests" -H 'accept: application/json' -H 'Accept-Language: ja' -H "Vulnerability-Scan-Result-Resource-Id: ${s3_jwt}" -H "Authorization: Bearer ${ls_token}" -H 'Content-Type: application/json' -H "${ua}" -d @param.json > result.json
            triage_id=$(cat result.json | jq -r ".triage.triageId")
            i=1
            while true
            do
              echo "---- 処理待ち_${i}"
              curl -X 'GET' "${ls_url}/api/triage-results/${triage_id}/status" -H 'accept: application/json' -H 'Accept-Language: ja' -H "Authorization: Bearer ${ls_token}" -H 'Content-Type: application/json' -H "$ua" -o t_result.json
              status=$(cat t_result.json | jq -r ".triage.status")
              echo "statusは「${status}」です"
              if [ "${status}" == "成功" ]; then
                cat t_result.json | jq -r ".triage"
                exit 0
              fi
              sleep 10
              i=$((i+1))
            done