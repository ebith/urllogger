# URL Logger

## 説明
URLをPOSTするとページのタイトルや本文ともに保存して後から検索できるようにするやつ

## 必要なの
- Node.js
- Elasticsearch

## 使い方
``` sh
npm install
npm start
curl -X POST http://localhost:9200/url-logger -d @scheme.json

curl -X POST http://localhost:3000 -H 'Content-Type: application/json' -d '{ "url": "http://google.com/"}'
```
