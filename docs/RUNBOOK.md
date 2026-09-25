# Operations Runbook — Lung Cancer Risk Predictor (Flask + MySQL)

| Field | Value |
|---|---|
| Document ID | LUNGU-RUNBOOK |
| Project | Lung Cancer Risk Predictor (Flask + MySQL) |
| Repository | [`vansh070605/LUNG-CANCER-PREDICTOR`](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR) |
| Version | 1.0 |
| Status | Approved — living document |
| Owner | Hirav Kadikar |
| Classification | Public |
| Last updated | 2026-09-25 |

> **Purpose:** Step-by-step instructions to set up, deploy, operate, monitor, recover and support the system.


## 1. Service overview

| Item | Detail |
|---|---|
| Service | Lung Cancer Risk Predictor (Flask + MySQL) |
| Hosting | Not deployed — runs locally with MySQL |
| Live URL | — |
| Owner / on-call | Hirav Kadikar |
| Criticality | Low — non-revenue critical |
| Target availability | Best effort (no contractual SLA) |


## 2. Environments

| Environment | Where | Notes |
|---|---|---|
| Local | http://127.0.0.1:5000 | MySQL on localhost with root/root |


## 3. Local setup


### Prerequisites

- Python 3.10–3.12
- MySQL 8 server


### Steps

```bash
git clone https://github.com/HiravK/LUNG-CANCER-PREDICTOR.git
cd LUNG-CANCER-PREDICTOR
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
mysql -u root -p < database/lung_cancer_db.sql      # creates lung_cancer_db
# edit the MySQL user/password in create_connection() in app.py if not root/root
python app.py                                        # http://127.0.0.1:5000
```


## 4. Configuration and secrets

| Variable | Required | Purpose | Where to set in production |
|---|---|---|---|
| `SECRET_KEY` | Recommended | Flask session secret (app.py currently hard-codes one) | Hosting provider environment settings |
| `DB host/user/password` | Yes | Hard-coded in app.py (root/root) — should move to env vars | Hosting provider environment settings |


## 5. Build and release

_Not deployed._


## 6. Rollback

1. Revert the offending commit on the default branch (`git revert <sha>`) and push; the host redeploys the previous good state.
1. If the host keeps previous deployments (e.g. Vercel/Netlify), promote the last good deployment from the dashboard for an instant rollback.


## 7. Monitoring and logging

No monitoring is configured. Minimum recommendation: an uptime check on the live URL and error alerts from the host.


## 8. Backup and disaster recovery

Use `CALL create_backup();` for the demo; for real use, `mysqldump lung_cancer_db > backup.sql`.

| Metric | Target |
|---|---|
| RPO (max data loss) | 0 — code is in Git |
| RTO (max downtime) | < 1 hour — redeploy from Git |


## 9. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "Error connecting to MySQL" | Server not running or wrong credentials | Start MySQL; update create_connection() |
| TemplateNotFound medical_history.html (and 3 others) | Templates never added | Create templates or remove routes |
| "System is busy" forever | Stale lock row after a crash | DELETE FROM lock_management WHERE table_name='predictions' |
| dummy_model.py fails | Dataset CSV not in repo | Download "survey lung cancer.csv" (Kaggle) |


## 10. Incident response

1. **Detect** — alert, user report or failed check.
1. **Triage** — confirm impact; classify: SEV1 (site down / data exposed), SEV2 (major feature broken), SEV3 (minor).
1. **Mitigate** — roll back (section 6) before debugging if users are affected.
1. **Fix** — reproduce locally, patch on a branch, test, deploy.
1. **Review** — write a short blameless post-mortem: timeline, root cause, actions; add new risks to the risk register.


## 11. Routine maintenance

- Monthly: update dependencies and re-run the test plan.
- Quarterly: rotate secrets and review access.
- Per release: update CHANGELOG.md and the session handover.
