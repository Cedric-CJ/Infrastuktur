# 🚀 AWS FREE TIER SETUP GUIDE

## 1. AWS Account erstellen (kostenlos)

Gehe zu: https://aws.amazon.com/free/
- Klicke "Create a free account"
- Folge den Schritten
- Bestätige mit Kreditkarte (wird nicht belastet bei Free Tier)

## 2. AWS Credentials bekommen

### Option A: AWS Console (empfohlen für Anfänger)
1. Gehe zu: https://console.aws.amazon.com/iam/
2. Klicke "Users" → "Create user"
3. Username: `streamflix-deploy`
4. Aktiviere "Provide user access to the AWS Management Console"
5. Setze ein starkes Passwort
6. Klicke "Next"
7. Wähle "Attach policies directly"
8. Suche und wähle:
   - `AmazonS3FullAccess`
   - `AWSLambda_FullAccess`
   - `AmazonDynamoDBFullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`
9. Erstelle User
10. Gehe zu "Security credentials" → "Create access key"
11. Wähle "Command Line Interface (CLI)"
12. Erstelle Access Key → **Speichere die Credentials sicher!**

### Option B: AWS CLI (für Entwickler)
```bash
# Installiere AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Konfiguriere
aws configure
# Eingabe:
# AWS Access Key ID: [dein-access-key]
# AWS Secret Access Key: [dein-secret-key]
# Default region name: eu-central-1
# Default output format: json
```

## 3. Free Tier Limits beachten

### ✅ Deine Konfiguration bleibt kostenlos:
- **S3**: 5GB Speicher + 20.000 GET + 2.000 PUT Requests
- **Lambda**: 1M Requests + 400.000 GB-Sekunden
- **API Gateway**: 1M Requests
- **DynamoDB**: 25GB + 200M Requests
- **CloudWatch Logs**: 5GB

### ⚠️ Kosten vermeiden:
- **Keine Videos > 5GB** hochladen
- **Keine 1000+ Requests** pro Monat
- **Keine Provisioned Throughput** in DynamoDB
- **Keine zusätzlichen Services** (CloudFront, etc.)

## 4. Deployment (kostenlos)

```bash
# 1. Backend erstellen (kostenlos)
make backend

# 2. JWT Secret setzen
export TF_VAR_jwt_secret=$(openssl rand -base64 32)

# 3. Deployen (kostenlos)
make deploy-dev

# 4. Testen (kostenlos)
make outputs-dev
```

## 5. Kosten überwachen

Gehe zu: https://console.aws.amazon.com/billing/
- Aktiviere "Free Tier Usage Alerts"
- Setze Budget-Alerts für 0.01$ (wird dich warnen)

## 6. Cleanup (wichtig!)

Wenn fertig:
```bash
make destroy-dev
```

Das löscht alles und verhindert unerwartete Kosten.

## 💡 Tipps für kostenlos bleiben:

1. **Teste nur kurz** - Deploye nicht dauerhaft
2. **Überwache Billing** täglich in der ersten Woche
3. **Verwende kleine Dateien** (< 100MB Videos)
4. **Mache regelmäßige Cleanups**
5. **Aktiviere Cost Allocation Tags** in AWS Console

## 🔍 Wo du die Infos findest:

- **AWS Account**: https://aws.amazon.com/free/
- **IAM Users**: https://console.aws.amazon.com/iam/
- **Access Keys**: Security Credentials → Access Keys
- **Billing**: https://console.aws.amazon.com/billing/
- **Free Tier**: https://aws.amazon.com/free/free-tier-limits/

## 🚨 Wichtig:

- **Speichere Credentials sicher** (nie in Git!)
- **Teile sie nicht** mit anderen
- **Rotiere sie regelmäßig** (IAM → Security Credentials)
- **Überwache Kosten** immer

Bei Fragen: Schaue in AWS Dokumentation oder Free Tier FAQ!