[Unit]
Description=Bitfocus Companion
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=companion
Environment=COMPANION_IN_SYSTEMD=1
ExecStart={{INSTALL_FOLDER}}/node-runtime/bin/node {{INSTALL_FOLDER}}/main.js --extra-module-path {{EXTRA_MODULE_PATH}} --admin-address {{ADMIN_ADDRESS}} --admin-port {{ADMIN_PORT}}
Restart=on-failure
KillSignal=SIGINT
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target