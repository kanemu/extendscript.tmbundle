#!/usr/bin/env bash
[[ -f "${TM_SUPPORT_PATH}/lib/bash_init.sh" ]] && . "${TM_SUPPORT_PATH}/lib/bash_init.sh"
[[ -f "${TM_SUPPORT_PATH}/lib/webpreview.sh" ]] && . "${TM_SUPPORT_PATH}/lib/webpreview.sh"

#PS_APP_PATH="/Applications/Adobe Photoshop CS5/Adobe Photoshop CS5.app"
#AI_APP_PATH="/Applications/Adobe Illustrator CS5/Adobe Illustrator.app"
#ID_APP_PATH="/Applications/Adobe InDesign CS5/Adobe InDesign CS5.app"

extendscriptmate_log="${TMPDIR}extendscriptmate.log"
#ログファイルを作成
: > "${extendscriptmate_log}"

extendscriptmate_jsx="${TM_FILEPATH}.tmp.jsx"
#スクリプトを複製

#$.write、$.writelnをオーバーライド
echo "(function(){var logFile=new File(\"${extendscriptmate_log}\");logFile.encoding=\"UTF8\";logFile.lineFeed=\"Mac\";logFile.open('e');var entityMap={\"&\":\"&amp;\",\"<\":\"&lt;\",\">\":\"&gt;\",'\"':'&quot;',\"'\":'&#39;',\"/\":'&#x2F;'};var escapeXml=function(string){return String(string).replace(/[&<>\"'\/]/g,function(s){return entityMap[s]})}$.write=function(s){logFile.seek(0,2);logFile.write(escapeXml(s))};$.writeln=function(s){logFile.seek(0,2);logFile.writeln(escapeXml(s))}}());" > "${extendscriptmate_jsx}"

#Scriptの内容を書き込み
cat "${TM_FILEPATH}" >> "${extendscriptmate_jsx}"
echo '' >> "${extendscriptmate_jsx}"

#Scriptを1行づつ読み込んで#targetを探す
_target=`grep '^#target' ${TM_FILEPATH} | sed -e "s/^#target \{1,\}[\"']\(.\{1,\}\)[\"'] *$/\1/g"`
arr=(`echo $_target | tr -s ' ' ' '`)
target=${arr[0]}

#targetの検索結果から条件分岐して、実行するアプリを選択(CS5_JP)
if echo "$target" | fgrep -iq 'photoshop' ; then
  target="Photoshop"
  app="${PS_APP_PATH}"
  run="do javascript file (fileName as POSIX file)"
elif echo "$target" | fgrep -iq 'illustrator' ; then
  target="Illustrator"
  app="${AI_APP_PATH}"
  run="do javascript file (fileName as POSIX file)"
else
  target="InDesign"
  app="${ID_APP_PATH}"
  run="do script file (fileName as POSIX file) language javascript"
fi

START=0
END=0

html_header "Running \"${TM_FILENAME}\" ..." "APP: ${app}"
echo '<pre>'

#アプリの起動チェック
all_apps=`ps -e -o comm | fgrep -v grep | fgrep -v Crash | fgrep -i "$target"`
now_app=`echo $all_apps | fgrep "$app"`
if [ "$now_app" ] || [ ! "$all_apps" ] ; then
    #ログを監視
    tail -f "${extendscriptmate_log}" &
    tail_pid=$!
    #開始時間
    START=`date +%s`
    #osascriptからAppleScriptを実行 タイムアウトまで30分
    echo "on run argv
     set fileName to item 1 of argv
     tell application \"$app\"
     with timeout of 1800 seconds
       $run
     end timeout
     end tell
    end run" | osascript - "${extendscriptmate_jsx}" >> "${extendscriptmate_log}" 2>&1
    #終了時間
    END=`date +%s`
    #tailを止める
    sleep 1s
    kill -s SIGKILL $tail_pid
else
    echo "Caution: Close all apps of the following, and try again."
    echo "$all_apps"
fi

echo '</pre>'
#処理時間を表示
SS=`expr ${END} - ${START}`
echo "Program exited after $SS seconds."
html_footer

#スクリプトを削除
rm "${extendscriptmate_jsx}"
rm "${extendscriptmate_log}"
