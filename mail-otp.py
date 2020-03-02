#!/usr/bin/env python
#-*- coding: utf-8 -*-

import imaplib
import email
import os
import re
import sys
from subprocess import check_output, STDOUT


def main():
    host = os.getenv("MAILHOST", 'imap.gmail.com')
    username = os.getenv("MAILUSER")
    sender = os.getenv("MAILSENDER")

    if not username:
        sys.exit(1)

    if not sender:
        sys.exit(1)

    cmd = [
        'security', 'find-internet-password', '-s', host, '-a', 'imap', '-w'
    ]
    password = check_output(cmd, stderr=STDOUT)
    mail = imaplib.IMAP4_SSL(host)
    mail.login(username, password)
    mail.select('inbox')
    result, messages = mail.search(None, '(UNSEEN FROM "{}")'.format(sender))
    if result == 'OK' and messages[0] != '':
        mails = []
        if ' ' in messages[0]:
            mails = sorted(messages[0].split(' '),
                           key=lambda i: (int(i)),
                           reverse=True)
        else:
            mails = messages
        for num in mails:
            _, data = mail.fetch(num, '(RFC822)')
            msg = email.message_from_string(data[0][1])
            # 본인 설정에 맞게 변경 필요 --------------------------
            # 현재는 제목에 OTP가 들어 있는 경우 추출
            m = re.search('OTP: (.+?)', msg['Subject'])
            if m:
                found = m.group(1)
                print(found)
                break
            # -----------------------------------------------

    mail.close()
    mail.logout()


if __name__ == "__main__":
    main()
