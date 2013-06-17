pingweb
=======

This script determines whether a given webpage is available.

usage: $0 [-hdv] [-e eml1,eml2] [-c eml3,eml4] [-b eml5,eml6] [-f from_eml] [-n name] [-p pattern] [-s tmpfile] [-t timeout] url

-h              : this (help) message
-d              : debug output
-v              : verbose output
-e eml1,eml2    : comma-separated list of To: addresses for email alert
                  (email alerts are enabled iff this is provided)
-c eml3,eml4    : comma-separated list of Cc: addresses for email alert
-b eml5,eml6    : comma-separated list of Bcc: addresses for email alert
-f from_eml     : From: address for email alert
-n name         : friendly name of webpage, used in email alerts
-p pattern      : pattern (regex) to match on valid webpage
-s tmpfile      : unique temporary file used to track page status between runs
-t timeout      : timeout (in seconds) to wait for an HTTP response

example: $0 -p "[Ww]elcome \\w+ Example\\.com" -e support\@example.com -c boss\@example.com,qa\@example.com -f monitor\@example.com http://www.example.com/

