#!/usr/bin/osascript

-- 기본적인 뼈대는 여기를 참고
-- https://github.com/roymarantz/junos-pulse/blob/master/vpn_reconnect.applescript
-- 사용하기 전에 vpn 패스워드를 입력
-- e.g. security add-internet-password -s vpn -a 'Pulse Secure' -w "$SECRET"
set appname to "Pulse Secure"
set dialogappname to "PulseTray"
set myPassword to do shell script "security find-internet-password -s vpn -a 'Pulse Secure' -w"

-- 중요 -------------------------------------------
-- 본인 설정에 맞게 변경 필요 --------------------------
-- 연결할 vpn 이름
set dialogname to "VPNNAME_CHANGEME"
-- 연결할 vpn 유저 이름
set myUser to "USERNAME_CHANGEME"
-- 중요 -------------------------------------------

-- 만약 pulse secure가 존재 하지 않으면 시작하고 뜰때까지 1초 대기
tell application appname
    if it is not running then
        activate
        delay 1
    end if
end tell

-- 가끔씩 system event에서 응답이 느려서 못찾는 케이스들이 있어서 테스트 해서 확인
tell application "System Events" to tell process dialogappname
    if not (exists menu bar item 1 of menu bar 2) then
        do shell script "killall System\\ Events"
        delay 1
    end if
end tell

-- 메뉴바 클릭시 5초를 무조건 기다리는 버그가 있어서 아래와 같은 방법을 이용
-- https://stackoverflow.com/questions/16492839/applescript-on-clicking-menu-bar-item-via-gui-script
tell application "System Events" to tell process dialogappname
    ignoring application responses
        -- 메뉴 바 에서 pulse secure 클릭
        click menu bar item 1 of menu bar 2
    end ignoring
end tell

do shell script "killall System\\ Events"
delay 0.5

tell application "System Events"
    tell process dialogappname
        tell menu bar item 1 of menu bar 2
            tell menu item dialogname of menu 1
            -- 메뉴 바 메뉴중 vpn을 클릭 후
            click
            -- 연결을 클릭
            click menu item "연결" of menu dialogname
            end tell
        end tell
    end tell

    -- 입력 창이 뜰때 까지 대기
    repeat until (exists window dialogname of application process dialogappname)
        delay 0.1
    end repeat

    -- not eht password dialog is opened, fill in the static stuff
    tell window dialogname of application process dialogappname
        tell sheet 1
            set value of text field 1 to myUser
            -- Connect button doesn't go live till something is really typed!
            set focused of text field 2 to true
            tell text field 2
                keystroke myPassword
            end tell
            click button "연결"
        end tell
    end tell

    -- 입력 다이어로그가 뜰때까지 잠시 대기
    delay 1

    -- otp를 받아서 입력
    tell window dialogname of application process dialogappname
        tell sheet 1
            set focused of text field 2 to true
-- 중요 -------------------------------------------
-- 본인 설정에 맞게 변경 필요 --------------------------
            -- set otp to do shell script "/usr/bin/python /usr/local/bin/mail-otp.py"
            set otp to do shell script "/bin/bash /usr/local/bin/sms-otp.sh"
-- 중요 -------------------------------------------
            set value of text field 2 to otp
            click button "연결"
        end tell
    end tell
end tell

return
