#!/bin/bash
TMP=/tmp
/usr/bin/gpg-agent --daemon --enable-ssh-support --write-env-file /root/.gnupg/.gpg-agent-info
GPG_AGENT=`find $TMP/gpg-* -name S.gpg-agent`
/bin/rm -rf /root/.gnupg/S.gpg-agent
/bin/ln -s $GPG_AGENT /root/.gnupg/S.gpg-agent
