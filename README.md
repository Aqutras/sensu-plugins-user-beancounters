# インストール前に

visudoにて以下を追記

```
Defaults:sensu !requiretty
sensu ALL=NOPASSWD: /bin/cat /proc/user_beancounters
```

# アラートをリセットするには

`cat /proc/user_beancounters > /tmp/user_beancounters`

