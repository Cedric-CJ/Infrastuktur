
0. Voraussetzungen

Lokale Tools: Git, Node.js ≥ 20, AWS CLI, Terraform ≥ 1.6 (nur für lokale Tests).
AWS Konto mit IAM-User der die Services verwalten darf (mindestens: S3, IAM, Lambda, API Gateway, DynamoDB, EC2, ELB, Auto Scaling, CloudWatch, CloudWatch Logs, CodeBuild, CodePipeline, SSM). Für produktive Accounts lieber einzelne, minimal berechtigte Rollen.
1. Remote-State-Backend vorbereiten (einmalig)

Lege eine S3‑Bucket + DynamoDB-Tabelle für Terraform-States an (oder nutze make backend, das tf-state-streamflix-itinfra2025 und tf-locks-streamflix erzeugt).
Prüfe in terraform/envs/dev/backend.tf und terraform/envs/prod/backend.tf, dass Bucket, Key, Region, Tabelle stimmen. Ohne korrektes Backend riskierst du Divergenzen zwischen lokal und AWS.
2. Repository konfigurieren

Passe terraform/envs/dev/terraform.tfvars.example an, kopiere nach terraform.tfvars. Wichtige Punkte:
admin_cidr unbedingt auf deine öffentliche IP/32 begrenzen, damit SSH (Port 22) nur dir offen steht.
Setze instance_key_name, falls du dich per SSH auf die EC2s verbinden möchtest (Key Pair vorher in EC2-Konsole erzeugen).
Optional: video_object_key ändern, falls das Demo-Video nicht demo-video.mp4 heißen soll.
Dasselbe für prod, ggf. mit anderen CIDRs oder Instanzgrößen.
3. Secrets festlegen

Erzeuge TF_VAR_jwt_secret mit openssl rand -base64 32.
Lege dieses Secret lokal als Environment-Variable und in CodeBuild als verschlüsseltes Environment-Secret an. Gib es niemals in Dateien oder Logs aus.
Falls du langfristig arbeiten willst, speichere das Secret künftig in AWS Secrets Manager und mappe es als TF_VAR_jwt_secret.
4. Lambda-Dependencies installieren

Lokal: make install-deps (installiert node_modules in jedem Lambda-Verzeichnis). Das gleiche macht später der CodeBuild-Job automatisch.
5. Manuelle Erstvalidierung (optional aber empfohlen)

terraform -chdir=terraform/envs/dev init
terraform -chdir=terraform/envs/dev plan
Prüfe, dass keine destruktiven Änderungen geplant sind und alle neuen Module (VPC/ALB/ASG) angezeigt werden.
Noch nicht apply ausführen, wenn du alles in CodePipeline deployen willst; ansonsten terraform ... apply erlaubt dir erste Smoke-Tests.
6. Demo-Video bereitstellen

Lade dein Testvideo (max. ~5 GB für Free Tier) in frontend/ oder an anderer Stelle hoch. Nach dem ersten Terraform-Apply liefert dir terraform output -raw video_bucket den Namen des S3-Buckets. aws s3 cp demo-video.mp4s3://BUCKET/demo-video.mp4.
Jede Änderung am Video musst du weiterhin manuell hochladen; die Timer-Synchronisation kopiert, löscht und ersetzt nur Dateien aus frontend/.
7. CodeStar-Verbindung zu GitHub

AWS Console → Developer Tools → Connections.
„Create connection“, Provider „GitHub“, authentifizieren, Repository auswählen.
Namen merken (z. B. streamflix-github).
8. CodeBuild-Projekt anlegen

AWS Console → CodeBuild → „Create build project“.
Source: GitHub (über Connection), Branch main (oder was ihr nutzt).
Environment:
Image: aws/codebuild/standard:7.0.
Compute type: BUILD_GENERAL1_SMALL reicht.
Service Role: neue Rolle mit folgenden Richtlinien (oder maßgeschneidert): AmazonS3FullAccess, AWSLambda_FullAccess, AmazonDynamoDBFullAccess, AmazonAPIGatewayAdministrator, AmazonEC2FullAccess, ElasticLoadBalancingFullAccess, AutoScalingFullAccess, CloudWatchLogsFullAccess. Zusätzlich muss dieselbe Rolle iam:PassRole auf die Lambda-Execution-Role (streamflix-*-lambda-role) sowie die EC2 Instance Profile Rolle besitzen. Für Feingranularität lieber eigene Policies anlegen.
Environment Variables:
TF_VAR_jwt_secret (SecureString/Sensitive).
AWS_REGION=eu-central-1.
Buildspec: „Use a buildspec file“ (das neue buildspec.yml im Repo).
Output artifacts nicht nötig (Terraform state wird im Backend gehalten).
Encryption: Standard KMS alias aws/s3 reicht; optional eigenes KMS.
Logs: CloudWatch Logs aktivieren für Audits.
9. CodePipeline erstellen

AWS Console → CodePipeline → „Create pipeline“.
Pipeline settings: Name, Service role (neu oder bestehend).
Source stage: GitHub (selbe Connection), Branch.
Build stage: wähle das oben erstellte CodeBuild-Projekt.
Deploy stage brauchst du nicht, weil CodeBuild via Terraform alles provisioniert und aws s3 sync aufruft.
Pipeline starten → löst Build aus. Beobachte Logs:
Installationsphase: Terraform wird heruntergeladen, Node-Module installiert.
terraform apply läuft in terraform/envs/dev.
Danach werden video_bucket, api_base_url, load_balancer_dns ausgelesen und S3-Sync durchgeführt.
10. Outputs prüfen / Smoke-Test

Nach erfolgreichem Run findest du in den Build-Logs:
Frontend bucket.
API URL.
Load balancer.
Load balancer DNS in Browser öffnen → UI sollte laden (denk an TTL von bis zu 5 min wegen Sync-Timer).
Testablauf:
Signup → notiere user_id.
Login → prüfe, dass Token zurückkommt; Browser speichert JWT im LocalStorage.
Kommentar senden (content_id frei wählen) → checke Antwort + DynamoDB comments Tabelle.
CloudWatch Logs der Lambdas (& DynamoDB Tables) prüfen, ob Fehler auftreten.
11. Sicherheitshärtung

IAM Least Privilege: Erstelle dedizierte Policies für CodeBuild statt der FullAccess-Vorlagen. Erlaube nur die Ressourcen/Actions aus Terraform (z. B. S3 nur für deinen Bucket, iam:PassRole nur auf die spezifischen Rollen).
Admin-Zugriff: admin_cidr immer auf konkrete IPs setzen. Lass Port 22 im ALB-SG geschlossen (nur EC2-SG erlaubt SSH, also auch nur wenn du es brauchst). Entferne SSH komplett, sobald SSM Session Manager ausreicht.
Secrets: Nutze AWS Secrets Manager oder SSM Parameter Store für TF_VAR_jwt_secret und injiziere ihn in CodeBuild via Parameter.
Logging: Aktivere CloudWatch Log-Group Retention (Standard 30 Tage) und DynamoDB Streams, wenn ihr Audits braucht.
Budgets/Alarme: Setze ein AWS Budget (0,01 USD) und Free-Tier-Usage Alert, damit ihr Unikosten im Blick behaltet.
Lifecycle: Wenn Ressourcen nicht gebraucht werden, terraform -chdir=terraform/envs/dev destroy oder Pipeline deaktivieren, damit Auto Scaling nicht weiter läuft.
12. Produktionsumgebung

Wiederhole Schritte 8–11 mit terraform/envs/prod:
Eigene VPC CIDRs (z. B. 10.31.0.0/16), höhere Instanzgröße (t3.small).
Getrennte Backend-Pfade (streamflix/prod/terraform.tfstate).
Eigene CodeBuild-Variante plus Pipeline, oder Parameterisiere Buildspec, falls du Deployments per TF_VAR_env=prod steuern willst.
Mit dieser Anleitung hast du alle Bausteine: Terraform modelliert S3, DynamoDB, API Gateway, Lambda, VPC, ALB und Auto Scaling; CodePipeline/CodeBuild handeln das automatische Ausrollen und S3-Sync; Security bleibt durch State-Backend, least privilege, IP-Restriktionen und Secret-Handling sauber. Wenn du einzelne Schritte angepasst haben willst (z. B. CloudFront/Route53 vor die ALB), sag Bescheid.