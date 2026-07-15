#!/bin/bash

echo "SETTING UP AUTO LOGIN"

if [ -f ~/bin/iiser-login.sh ]; then
    read -p "~/bin/iiser-login.sh already exists. Overwrite? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi


mkdir -p ~/bin


echo '#!/bin/bash

LOG="$HOME/.iiser-login.log"

MAXLINES=500

# Truncate log
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAXLINES" ]; then
    tail -n "$((MAXLINES / 2))" "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
fi

"$HOME/bin/iiser-login.sh" >> "$LOG" 2>&1' > ~/bin/check-internet.sh



read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo




cat > ~/bin/iiser-login.sh << EOF
#!/bin/bash

USERNAME="$USERNAME"
PASSWORD="$PASSWORD"

curl -sk \\
  -H "Origin: https://gateway.iisertvm.ac.in:8090" \\
  -H "Referer: https://gateway.iisertvm.ac.in:8090/httpclient.html" \\
  -H "Content-Type: application/x-www-form-urlencoded" \\
  --data "mode=191&username=\${USERNAME}&password=\${PASSWORD}&a=\$(date +%s%3N)&producttype=0" \\
  "https://gateway.iisertvm.ac.in:8090/login.xml"
EOF


chmod 700 ~/bin/iiser-login.sh
chmod 755 ~/bin/check-internet.sh


mkdir -p ~/.config/systemd/user

touch ~/.config/systemd/user/iiser-login.service
echo '[Unit]
Description=Check internet and login to IISER captive portal

[Service]
Type=oneshot
ExecStart=%h/bin/check-internet.sh' > ~/.config/systemd/user/iiser-login.service


touch ~/.config/systemd/user/iiser-login.timer

echo '[Unit]
Description=Run IISER login check every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target' > ~/.config/systemd/user/iiser-login.timer


systemctl --user daemon-reload

systemctl --user enable --now iiser-login.timer



echo "Setup complete. Timer status:"
systemctl --user status iiser-login.timer --no-pager



