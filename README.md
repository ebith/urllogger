# url-logger?

## 説明
URLをPOSTするとページのタイトルや本文ともに保存して後から検索できるようにするやつ

## 必要なの
- Node.js
- PhantomJS
- Elasticsearch

## 使い方
``` sh
npm install
npm start
curl -X POST http://localhost:9200/url-logger -d @scheme.json
```

## 気になるところ
- PhantomJSのServerにPOSTでJSONを投げるとなんか挙動がおかしい時があってよくわからんのでヘッダにURL入れてる
