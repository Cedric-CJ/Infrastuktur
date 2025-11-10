# Streaming MVP – Extended Starter

Deckt euren Projektscope ab:
- **Basic Frontend (HTML/JS)**
- **Kommentare serverless**: API Gateway → Lambda → DynamoDB
- **Datenbank ausgelagert**: DynamoDB (keine DB auf EC2)
- **Login-Bereich (Stub)** [Außerhalb des Skripts] – später ersetzen
- **Video**: Abspielen per EC2 (Apache) *oder* S3

## Was jetzt zu tun ist

### 1) Lambda + API (laut PDF)
1. **Lambda** erstellen (Python/Node) und `key1` aus `queryStringParameters` lesen, `statusCode` + `body` zurückgeben.
2. **API Gateway (REST)** als Trigger (GET) hinzufügen, Stage setzen.
3. **CORS** aktivieren: Header in Lambda (`Access-Control-Allow-Origin: *`) + CORS in API Gateway Settings.
4. **CloudWatch Logs** nutzen (Lambda → Monitoring → View Logs) fürs Debugging.

**Beispiel (Python, gekürzt, an PDF angelehnt):**
```python
import json, boto3, time
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('<<YOUR_TABLE>>')

def lambda_handler(event, context):
    q = event.get("queryStringParameters", {}) or {}
    key1 = q.get("key1", "")  # z.B. "user: kommentar"
    if not key1:
        return {"statusCode": 400, "body": "missing key1"}
    item = {"key": f"cmt-{int(time.time()*1000)}", "text": key1}
    table.put_item(Item=item)  # Rolle braucht dynamodb:PutItem
    return {"statusCode": 200, "body": f"stored: {item['key']}"}
```

> **IAM-Hinweis**: Rolle der Lambda um eine Policy mit `dynamodb:PutItem` auf eure Tabelle ergänzen.

### 2) DynamoDB
- Tabelle anlegen, z. B. **PK: key (String)**.
- Lambda mit `boto3.resource('dynamodb')` verbinden und `put_item` wie oben.

### 3) Frontend konfigurieren
- In `app.js` `COMMENTS_API_URL` auf eure **REST-URL** setzen (Format `https://.../stage/service`).
- Optional `COMMENTS_LIST_API_URL` eintragen, falls ihr einen GET-Endpoint zum Listen baut.
- Lokal öffnen (Doppelklick `index.html`) – CORS muss serverseitig korrekt sein.

### 4) Hosten
**Variante A – EC2 (Apache):**
- EC2 starten, `httpd` installieren und **Port 80** in der Security Group öffnen.
- Dateien nach `/var/www/html/` kopieren.
- **Video hochladen** (z. B. `video.mp4`) an denselben Pfad und im UI setzen.

**Variante B – S3 Static Website:**
- S3-Bucket → Static website hosting aktivieren, `index.html` + `app.js` hochladen.
- Bucket-Policy für öffentliches GET (nur für Demo) setzen.

### 5) Video testen
- Oben im UI die **Video-URL** eintragen (z. B. `http://<EC2-IP>/video.mp4`) → **Video setzen** → Abspielen.

### 6) (Optional) Kommentare listen
- Zweites Lambda (GET `/comments`) bauen, das Items als JSON zurückgibt.
- `COMMENTS_LIST_API_URL` setzen → „Neu laden“ zeigt Kommentare.

### 7) Login
- Der Login ist nur ein **Stub** (localStorage). Für echten Login später Authorizer/IDP ergänzen.

Viel Erfolg! 🚀
