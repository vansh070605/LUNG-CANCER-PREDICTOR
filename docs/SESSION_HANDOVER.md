# Session Handover — Lung Cancer Risk Predictor (Flask + MySQL)

| Field | Value |
|---|---|
| Document ID | LUNGU-HANDOVER |
| Project | Lung Cancer Risk Predictor (Flask + MySQL) |
| Repository | [`vansh070605/LUNG-CANCER-PREDICTOR`](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR) |
| Version | 1.0 |
| Status | Approved — living document |
| Owner | Hirav Kadikar |
| Classification | Public |
| Last updated | 2026-09-25 |

> **Purpose:** Lets the next person (or AI session) pick up the work cold: what exists, what state it is in, what is unfinished, and exactly what to do next.


## 1. Handover summary

| Item | Detail |
|---|---|
| Handover date | 2026-09-25 |
| Handed over by | Hirav Kadikar |
| Repository state | `master` @ `4821428` — 13 commits, last change 2025-05-07 |
| Overall status | Academic project (May 2025) — complete for coursework, not for clinical use |
| Live URL | — |
| Health | Amber — core flow works locally; several pages incomplete |


## 2. Current state (plain English)

A completed DBMS course project (May 2025) by Vansh Agrawal with Hirav Kadikar. The core register → predict → history
flow works locally with MySQL. Medical history, symptoms, recommendations and feedback routes lack templates, the ML
model is not connected, and credentials are hard-coded. The fork (HiravK) is identical to the upstream (vansh070605).


## 3. What is done

- Auth, prediction, history
- MySQL schema with transactions, locking, versioning, triggers, backup/recovery procedures
- Project report


## 4. In progress / partially done

- Nothing.


## 5. Known issues and bugs

| # | Issue | Impact | Suggested fix |
|---|---|---|---|
| 1 | Web app uses a rule-based score; README implies ML | Misleading | State clearly or wire the model |
| 2 | Hard-coded MySQL root/root and session secret in app.py | Unsafe if deployed | Environment variables |
| 3 | /predictions returns every user's results to any logged-in user | Health-data exposure | Restrict to admins or remove |
| 4 | Four templates missing | 500 errors on those pages | Add templates |
| 5 | Global lock serialises all predictions; stale lock if a crash occurs | Throughput and availability | Use DB row locks / timeouts |
| 6 | Windows .venv and Word documents committed | Repo bloat | Remove and .gitignore |
| 7 | No medical disclaimer on the result page | Users may over-trust the result | Add a disclaimer |


## 6. Next steps (prioritised)

1. Move secrets to environment variables.
1. Restrict /predictions; add a disclaimer.
1. Add missing templates or remove routes.
1. Decide whether to wire the Random Forest model.


## 7. How to resume work in 10 minutes

```bash
git clone https://github.com/HiravK/LUNG-CANCER-PREDICTOR.git
cd LUNG-CANCER-PREDICTOR
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
mysql -u root -p < database/lung_cancer_db.sql      # creates lung_cancer_db
# edit the MySQL user/password in create_connection() in app.py if not root/root
python app.py                                        # http://127.0.0.1:5000
```


## 8. Access, accounts and secrets

Secrets are **never** stored in this repository. The table lists where each credential lives, not its value.

| System | What you need | Where it lives |
|---|---|---|
| GitHub vansh070605/LUNG-CANCER-PREDICTOR | Owner: Vansh Agrawal | GitHub |
| GitHub HiravK/LUNG-CANCER-PREDICTOR | Fork owner | GitHub |


## 9. Gotchas and tribal knowledge

- app.py ignores config.py; edit create_connection() directly.
- Column-name case differs in queries (`Email`, `ID`, `Name` vs schema lowercase) — works on MySQL because column names are case-insensitive.


## 10. Key files to read first

| File | Why |
|---|---|
| `app.py` | All routes and logic |
| `database/lung_cancer_db.sql` | DBMS features |


## 11. Recent history

```text
2025-05-07  4821428  Merge pull request #2 from vansh070605/main
2025-05-07  deb651d  Project Report Updated
2025-05-07  b25caba  Deletd 2 files
2025-05-07  1d2943d  Documentations added
2025-05-06  c425939  Merge pull request #1 from vansh070605/main
2025-05-06  1489d47  Initial commit: Lung Cancer Predictor web application
2025-05-06  84d40ce  Added Concurrency control
2025-05-05  9c04124  Merge branch 'master' of https://github.com/vansh070605/LUNG-CANCER-PREDICTOR
2025-05-05  d267d99  Did some changes in the frontend and backend
2025-05-05  eb31f2d  Update README.md
2025-05-05  7211aa0  Updated README.md
2025-05-05  6e272d4  Updated Readme FIle
2025-05-05  ee519e7  Initial commit: LUNG CANCER PREDICTOR project
```


## 12. Handover checklist

- [ ] Repository builds from a clean clone using the README steps
- [ ] Environment variables documented in the README / runbook
- [ ] Open risks recorded in the risk register
- [ ] Next steps above agreed with the product owner
- [ ] Access to hosting / third-party accounts transferred or shared
