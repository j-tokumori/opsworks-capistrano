```
$ ls config/deploy/XXXXX-*.rb | sed -e "s/config\/deploy\/\([a-zA-Z0-9\-]*\)\.rb/\1/" | xargs -I@ sh -c 'A=@; bundle exec cap @ ssh_config > ~/.ssh/conf.d/hosts/${A}'
```

