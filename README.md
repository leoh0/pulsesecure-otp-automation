# pulse secure + OTP 자동화 가이드

이글은 macos에서 pulse secure에 추가로 OTP를 사용할시 스크립트 하나로 자동화할 수 있는 방법들을 가이드 합니다. 이 방법을 완벽한 도구가 아닌 이런 방법으로 가이드 하는 이유는 각 환경마다 보안 설정, GUI 설정들이 다르기 때문에 각각 맞춰서 설정해야 하는 부분이 있습니다. 그리고 OTP가 없을시 간단하게 스크립들이나 커맨드 들로도 가능하나 OTP가 들어가면 결국 OTP를 받아서 추출해서 이 값을 이용해서 자동화를 해야 해서 비교적 복잡하다보니 결국 가이드 형태로 작성하게 되었습니다.

대부분 크게 2파트로 스크립트를 작성해야 합니다.

1. pulse secure 자동화
  * pulse secure를 macos 에서 자동화 해서 메뉴를 클릭하기 위해서 applescript를 적극적으로 활용 합니다.
  * OTP추출 로직을 applescript에서 shell command를 바로 호출할 수 있으나 복잡해져서 별도 스크립트로 분리해서 사용합니다.
  * 다만 프로세스 인식 버그가 있어서 이를 해결하기 위해 여러가지 방법을 써야합니다.
2. OTP 추출
  * 보통 mail 이나 SMS로 OTP 들을 발송하기 때문에 이를 받아서 파싱하도록 합니다.
  * mail은 일반적인 imap등의 프로토콜로 쉽게 사용 가능 합니다.
  * SMS는 iphone 케이스만 서베이해서 적용해서 android 케이스는 테스트해봐야 합니다만 [mail로 포워딩](https://support.google.com/voice/answer/9182115?co=GENIE.Platform%3DAndroid&hl=en) 해서 쓰면 될것 같습니다.

**중요: 가이드를 보고 진행하더라도 결국 각자 환경에 맞게 임기응변하는 부분들이 아마 크게 필요 할것입니다.**

## 세팅

### pulse secure 세팅

* 우선 pulse secure에서 사용할 패스워드를 등록합니다. *이하 과정에서 아마 `보안 및 개인 정보 보호` -> `개인 정보 보호` -> `손쉬운 사용` 등에서 iTerm 혹은 터미널 들의 권한을 줘야 사용 가능합니다.*

```
$ read -s SECRET

$ security add-internet-password -s vpn -a 'Pulse Secure' -w "$SECRET"
```

* `vpn.applescript` 파일에서 아래 부분의 설정을 자신의 설정에 맞게 고쳐 줍니다. `VPNNAME_CHANGEME`은 vpn 설정 이름을 넣어주면 되고 실제 접속할 ID를 `USERNAME_CHANGEME`로 변경해 주면 됩니다.

```
-- 본인 설정에 맞게 변경 필요 --------------------------
-- 연결할 vpn 이름
set dialogname to "VPNNAME_CHANGEME"
-- 연결할 vpn 유저 이름
set myUser to "USERNAME_CHANGEME"
```

* `vpn.applescript`에서 자신이 사용할 방법으로 선택해서 사용합니다. `mail` 사용시 `mail-otp.py`를 사용하고 `sms` 사용시 `sms-otp.sh`를 사용합니다. `--`가 주석이니 필요한 부분을 사용합니다.

```
-- 본인 설정에 맞게 변경 필요 --------------------------
            -- set otp to do shell script "/usr/bin/python /usr/local/bin/mail-otp.py"
            set otp to do shell script "/bin/bash /usr/local/bin/sms-otp.sh"
```

* 사용할 스크립트를 옮겨줍니다.

```
$ cp vpn.applescript /usr/local/bin/
```

### mail OTP 사용시

우선 android sms를 mail로 포워딩 해서 쓰거나 그냥 mail로 받는 케이스는 이것을 참고 할 수 있을 것입니다.
gmail을 대상으로 스크립트는 작성되어 있으나 아마 상황들의 마다 다른 포맷의 메세지일 것이라 스크립트를 그대로 사용하기는 어려울 것입니다. 추가로 google 같은 경우는 [보안 약화](https://www.google.com/settings/security/lesssecureapps)를 해줘야 imap에 이런 스크립트로 접근이 가능 합니다.

* imap에서 사용할 패스워드를 등록합니다.

```
$ read -s SECRET

$ security add-internet-password -s 'imap.gmail.com' -a 'imap' -w "$SECRET"
```

* 그리고 아래와 같은 환경변수들이 필요합니다. 각각 `mailhost`, `자신의emailid`, `OTP보낸메일주소`와 같이 설정하면 됩니다.

```
$ export MAILHOST=imap.gmail.com
$ export MAILUSER=myname
$ export MAILSENDER=otpsenderemail
```

* 이후 `mail-otp.py` 파일 안에서 자신의 OTP 메일 포맷에 맞게 파싱해줍니다.

```
            # 본인 설정에 맞게 변경 필요 --------------------------
            # 현재는 제목에 OTP가 들어 있는 경우 추출
            m = re.search('OTP: (.+?)', msg['Subject'])
            if m:
                found = m.group(1)
                print(found)
                break
            # -----------------------------------------------
```

* 사용할 스크립트를 옮겨줍니다.

```
$ cp mail-otp.py /usr/local/bin/
```

* 이후 아래의 환경변수들과 함께 vpn.applescript를 사용하면 됩니다.

```
$ export MAILHOST=imap.gmail.com
$ export MAILUSER=myname
$ export MAILSENDER=otpsenderemail
$ /usr/local/bin/vpn.applescript
```

### iphone sms OTP 사용시

* 아래를 참고해서 성공하면 icloud로 연동된 mac으로 SMS가 잘 전송되도록 세팅 합니다.

https://support.apple.com/ko-kr/HT208386

* `보안 및 개인 정보 보호` -> `전체 디스크 접근 권한` -> `개인 정보 보호` -> `iTerm or terminal app` 에서 terminal에서 문자를 읽을 `"$HOME/Library/Messages/chat.db"` 와 같은 디렉토리를 접근 가능하도록 권한을 줘야 합니다.

* `OPT가 전송될 전화 번호`를 아래와 같이 등록합니다.

```
$ export SMS_PHONE_NUMBER=+820702222222
```

* OTP의 내용을 알맞게 정제할 부분을 수정해야 합니다.

```
                    # 본인 설정에 맞게 변경 필요 --------------------------
                    tail -n1)
                    # -----------------------------------------------
```

* 사용할 스크립트를 옮겨줍니다.

```
$ cp sms-otp.sh /usr/local/bin/
```

* 이후 아래의 환경변수들과 함께 vpn.applescript를 사용하면 됩니다.

```
$ export SMS_PHONE_NUMBER=+820702222222
$ /usr/local/bin/vpn.applescript
```

## vpn.applescript 에서 본인에 맞는 수정이 필요하다면

[UIElementInspector](https://forum.keyboardmaestro.com/t/os-x-accessibility-inspector-uielementinspector-tool-for-ui-scripting/3443)툴을 받아서 자신의 GUI의 element 구성들을 파악하면 도움이 됩니다.

어떤식으로 이런 메뉴를 자동화 하는지 [이 도큐먼트](https://apple.stackexchange.com/a/311494)를 참고하면 도움이 될것입니다.

## 마무리

다시 한번 강조하지만 사용하는 환경 마다 상황이 다를 것이기 때문에 **결국 가이드를 보고 진행하더라도 결국 각자 환경에 맞게 임기응변하는 부분들이 아마 크게 필요 할것입니다.**
