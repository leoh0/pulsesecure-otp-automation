#!/usr/bin/env bash

MINUTE=${MINUTE:-5}
SMS_PHONE_NUMBER=${SMS_PHONE_NUMBER:-$1}

wait=0
while true; do
    otp=$(sqlite3 "$HOME/Library/Messages/chat.db" \
            "SELECT text FROM message \
                INNER JOIN chat ON chat.account_id = message.account_guid \
                WHERE chat.guid='SMS;-;${SMS_PHONE_NUMBER}' \
                AND Datetime(message.date/1000000000 + \
                                strftime('%s', '2001-01-01') , \
                                'unixepoch', 'localtime') > \
                Datetime('now', '-${MINUTE} minutes', 'localtime');" | \
                    # 본인 설정에 맞게 변경 필요 --------------------------
                    tail -n1)
                    # -----------------------------------------------

    if [[ "${otp}" != "" ]]; then
        echo "${otp}"
        exit 0
    elif [[ "${wait}" -lt 10 ]]; then
        wait=$((wait+1))
        sleep "${wait}"
    else
        exit 1
    fi
done
