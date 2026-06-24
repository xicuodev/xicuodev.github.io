---
date: '{{ .Date }}'
drafe: true
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
---
