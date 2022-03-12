#!/bin/bash

# Variables
appid='c4ac49cd-af2c-471b-b215-asdasdasdasd'
secret='ko~ZlHb3-_FalW36qdzxczxczxczxc--'
scope="https%3A%2F%2Fgraph.microsoft.com%2F%2Fmail.readwrite.shared%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fmail.send%20offline_access%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fpeople.read%20https%3A%2F%2Fgraph.microsoft.com%2F%2Fuser.readwrite"
header1="application/json"
header2="application/x-www-form-urlencoded"

## Trigger (1 hour check)
time=$(($(date +%s)-3600)); t=$(date -d @${time} '+%FT%I:%M:%SZ')
tkn=$(curl -sS -H "Content-Type: $header2" https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token -d 'client_id='"${appid}"'&scope='"${scope}"'&client_secret='"${secret}"'&refresh_token=0.ASsAvE7VwIlFXkuIb0YQg7DmoM1JrMQsrxtHshWPPWDqZCUrAF0.asdasdasdadasdzxczxczxczxczxczxc&grant_type=refresh_token' | jq '.access_token')
a=$(curl -sS -H "Authorization: Bearer ${tkn//\"}" -H "Accept: $header1" 'https://graph.microsoft.com/v1.0/me/mailfolders/inbox/messages?$select=subject%2Cfrom%2CwebLink%2CtoRecipients%2CccRecipients&$filter=ReceivedDateTime+ge+'"${t//:/%3A}"'')

### Filter
b=$(echo $a | jq '.value[] | select(.from.emailAddress.address | endswith("company1.com") or endswith("company2.com") or endswith("vendor1.com") or endswith("vendor2.com"))' ) #filter sender
c=$(echo $b | jq 'select(.toRecipients[].emailAddress.address == "thisemail@com")') #filter receiver
d=$(echo $c | jq 'select(if (.subject | startswith("Re:") or startswith("Fw:") | not) then true elif (.from.emailAddress.address =="specialsndr@com") and (.subject | startswith ("specialsubj") or test ("specialsubj2")) then true else empty end)') #filter subject
to=$(echo $d | jq '[select(.toRecipients[])] | length | tonumber'); cc=$(echo $d | jq '[select(.ccRecipients[])] | length | tonumber')
while IFS=\" read -d \" k v; do id+=( "${k}" ); done < <(echo $d | jq '.id' )
while IFS=\" read -d \" k v; do lnk+=( "${k}" ); done < <(echo $d | jq '.webLink' ); while IFS=\" read -d \" k v; do sub+=( "${k}" ); done < <(echo $d | jq '.subject' )

#### Action
payload="payload={\"channel\": \"DQ3P6LRP1\", \"username\": \"thisemail@com\", \"icon_emoji\": \":smile:\", \"blocks\": ["
if [[ -n ${d} ]]; then for i in ${!lnk[*]}; do if [[ $((i%2)) -ne 0 ]]; then
if [[ $to > 1 ]]||[[ $cc > 0 ]]; then curl -sS -H "Authorization: Bearer ${tkn//\"}" -H "Content-Type: $header1" -d '{"Comment":"insta</br>reply"}' 'https://graph.microsoft.com/v1.0/me/messages/'"${id[$i]}"'/reply'
else curl -sS -H "Authorization: Bearer ${tkn//\"}" -H "Content-Type: $header1" -d '{"Comment":"insta</br>reply"}' 'https://graph.microsoft.com/v1.0/me/messages/'"${id[$i]}"'/replyall'; fi
lines+=" <${lnk[$i]}|${sub[$i]}> \n"
fi; done; fi
payload+="{\"type\": \"section\", \"text\": {\"type\":\"mrkdwn\", \"text\":\"${lines}\"}}]}"
if [[ -n ${lines} ]]; then curl -sS --data-urlencode "${payload}" https://hooks.slack.com/services/$TENANT/$CHANNEL/$WEBHOOK; fi
