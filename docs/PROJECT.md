# Project Overview (In Depth) — Lung Cancer Risk Predictor (Flask + MySQL)

| Field | Value |
|---|---|
| Document ID | LUNGU-PROJECT |
| Project | Lung Cancer Risk Predictor (Flask + MySQL) |
| Repository | [`vansh070605/LUNG-CANCER-PREDICTOR`](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR) |
| Version | 1.0 |
| Status | Approved — living document |
| Owner | Hirav Kadikar |
| Classification | Public |
| Last updated | 2026-09-25 |

> **Purpose:** The complete, plain-English explanation of this project: why it exists, what it does, how every part works, how it evolved, its quality, security, risks and vocabulary.


## 1. The project in one paragraph

**LUNG CANCER PREDICTOR** is a Flask 3 web application backed by MySQL 8, built in May 2025 as a database-management-
systems (DBMS) project. Users register and log in, fill a short form (age, gender, smoking, cough, chest pain, fatigue,
shortness of breath) and receive a **risk band — Low, Moderate or High — with a numeric score**. Every prediction is
stored and linked to the user so they can review their history; the schema also covers medical history, a symptom
library, recommendations and feedback.

The project's main teaching focus is the **database layer**: explicit transactions with rollback, a custom
`lock_management` table (an exclusive "one prediction at a time" lock), optimistic `version_control`, a
`transaction_log`, triggers that audit user changes and deleted predictions, stored procedures for backups,
point-in-time recovery, deadlock detection and bulk risk recalculation.

Important: the web app uses a **hand-written scoring rule**, not machine learning. A Random-Forest model script
(`model/dummy_model.py`, trained on the public "survey lung cancer" dataset) exists but is not wired into the app. This
tool is **not a medical device** and must not be used for diagnosis.


## 2. Background and why it exists

Early awareness of lung-cancer risk factors (smoking, persistent cough, chest pain, breathlessness) encourages people to
see a doctor sooner. The course also required demonstrating advanced DBMS concepts — ACID transactions, concurrency
control, recovery and auditing — inside a working application.


## 3. Fact sheet

|  |  |
|---|---|
| Repository | Public — `vansh070605/LUNG-CANCER-PREDICTOR` |
| Status | Academic project (May 2025) — complete for coursework, not for clinical use |
| Live URL | — |
| Hosting | Not deployed — runs locally with MySQL |
| Primary language | Python + SQL |
| Default branch | `master` |
| History | 13 commits from 2025-05-05 to 2025-05-07 |
| Contributors | Vansh Agrawal (12 commits), Hirav Kadikar (1 commits) |
| Upstream / related | Original repository by Vansh Agrawal (team includes Hirav Kadikar). A fork exists at HiravK/LUNG-CANCER-PREDICTOR. |


## 4. Features explained


### Accounts

Register (hashed passwords via Werkzeug) and session login; logout


### Risk assessment

Rule-based score - age band 1–4, male +2 / female +1, smoking +5, cough +2, chest pain +3, fatigue +1, breathlessness +3 → Low (<6), Moderate (6–9), High (≥10)


### Prediction history

`/user/predictions` shows a user's past results; `/predictions` lists all


### Medical data

Medical history, symptom library, recommendations and feedback routes | Partly built — four templates are missing


### Transactions

`transaction_required` decorator wraps a request in START TRANSACTION / COMMIT / ROLLBACK


### Concurrency control

Exclusive row in `lock_management` so only one prediction runs at a time; optimistic `version_control` table


### Auditing and recovery (SQL)

Triggers log user changes and deleted predictions; procedures create_backup, point_in_time_recovery, detect_deadlocks, update_all_risk_scores


### ML experiment

`model/dummy_model.py` trains a Random Forest and saves model/model.pkl | Not used by the app


### Project report

`PROJECT REPORT.docx` and a generator script `generate_document.py`


## 5. How it works end to end

A classic server-rendered Flask app (`app.py`, ~500 lines) with Jinja templates and one stylesheet. Each request that
writes data opens a fresh `mysql.connector` connection with autocommit off; the `transaction_required` decorator starts a
transaction, runs the view, and commits or rolls back. Prediction requests insert a row in `lock_management` (unique on
table + record) to take an exclusive global lock, compute the rule-based score, insert into `predictions` and
`user_predictions`, bump `version_control`, and release the lock. The database script `database/lung_cancer_db.sql`
creates 13 tables plus backup tables, triggers and stored procedures.


### Get a risk estimate

1. Open http://127.0.0.1:5000 → intro page → Register → Login
1. Dashboard → Predict
1. Enter age, gender and yes/no for smoking, cough, chest pain, fatigue, shortness of breath
1. The app locks, scores, saves the prediction and link, releases the lock, commits
1. Result page shows the band and score; History lists previous results

Diagrams and component detail: [ARCHITECTURE.md](ARCHITECTURE.md).


## 6. Technology choices

| Layer | Technology | Why it is used |
|---|---|---|
| Web | Flask 3.0.2, Jinja2, Flask-CORS | Server-rendered app |
| Security | Werkzeug password hashing, sessions; PyJWT (unused decorator) | Auth |
| Database | MySQL 8 + mysql-connector-python 8.3 | Data, transactions, triggers, procedures |
| ML (experiment) | scikit-learn 1.4 RandomForest, pandas, numpy | Model training script |
| UI | Custom CSS (glassmorphism) | Look and feel |


## 7. Codebase tour

```text
LUNG-CANCER-PREDICTOR/
├── app.py                    # Flask app
├── config.py                 # unused Config class
├── database/lung_cancer_db.sql
├── model/dummy_model.py, model.pkl
├── templates/                # 9 templates
├── static/styles.css
├── generate_document.py, PROJECT REPORT.docx, Sample Document.docx
├── requirements.txt
└── .venv/                    # Windows virtualenv (should not be committed)
```

| Component | Location | What it does |
|---|---|---|
| Flask app | `app.py` | Routes, decorators, lock/version helpers, rule-based scoring |
| Config | `config.py` | Config class (secret keys, DB settings) — not imported by app.py |
| Database script | `database/lung_cancer_db.sql` | Tables, triggers, stored procedures, isolation level |
| Templates | `templates/*.html` | base, intro, login, register, dashboard, predict, result, history, index |
| Styles | `static/styles.css` | Glassmorphism dark theme |
| ML experiment | `model/dummy_model.py, model/model.pkl` | Random Forest on "survey lung cancer.csv" |
| Report tooling | `generate_document.py, PROJECT REPORT.docx, Sample Document.docx` | Course report |


## 8. Project timeline

| Phase | Scope | Status |
|---|---|---|
| v1 (May 2025) | Flask app, MySQL schema with DBMS features, report | Done |
| v1.1 | Missing templates, wire the ML model, remove secrets, per-user access on /predictions | Proposed |

Recent commits:

```text
2025-05-07  Merge pull request #2 from vansh070605/main
2025-05-07  Project Report Updated
2025-05-07  Deletd 2 files
2025-05-07  Documentations added
2025-05-06  Merge pull request #1 from vansh070605/main
2025-05-06  Initial commit: Lung Cancer Predictor web application
2025-05-06  Added Concurrency control
2025-05-05  Merge branch 'master' of https://github.com/vansh070605/LUNG-CANCER-PREDICTOR
2025-05-05  Did some changes in the frontend and backend
2025-05-05  Update README.md
2025-05-05  Updated README.md
2025-05-05  Updated Readme FIle
```


## 9. Team and ownership

| Person / group | Role | Interest |
|---|---|---|
| Vansh Agrawal | Lead developer, repository owner (upstream) | Project delivery and grade |
| Hirav Kadikar | Team member; fork owner | Portfolio |
| Course faculty | Evaluators | DBMS concepts demonstrated |
| Users | End users (demo) | Simple risk estimate |


## Quality and testing

No automated tests. Behaviour was demonstrated manually for the course.

Acceptance checks to run before every release:

| # | Area | Check | Expected result |
|---|---|---|---|
| 1 | Auth | Register same email twice | "Email already registered" |
| 2 | Auth | Visit /dashboard logged out | Redirect to /login |
| 3 | Predict | Age 65, male, smoker, cough, chest pain | High risk (score ≥ 10) |
| 4 | Predict | Age 30, female, no symptoms | Low risk |
| 5 | Concurrency | Insert a lock row manually, then predict | "System is busy" |
| 6 | Rollback | Stop MySQL mid-request | No partial prediction rows |
| 7 | Missing pages | Open /medical_history | Currently errors (template missing) |


## Security and privacy

| Area | Current state |
|---|---|
| Authentication | Session login with Werkzeug password hashes; a JWT decorator exists but is unused. |
| Authorisation | Login required for app pages; no roles. |
| Data handled | Health-related answers (symptoms, smoking, medical history) — sensitive personal data. |
| Secrets | Hard-coded - MySQL root/root and Flask session secret in app.py; placeholder secrets in config.py. |
| Transport | HTTPS via the hosting provider. |

| Threat | Scenario | Mitigation | Status |
|---|---|---|---|
| Information disclosure | Any user views all predictions via /predictions | Admin-only | Open |
| Spoofing | Forged sessions via known hard-coded secret | Random secret from env | Open |
| Tampering | SQL injection | Parameterised queries used throughout | Mitigated |
| Denial of service | Stale global lock blocks predictions | Timeouts/cleanup | Open |

Findings from this review:

| Finding | Severity | Recommendation |
|---|---|---|
| Hard-coded session secret and DB root credentials | High (if deployed) | Env vars |
| /predictions exposes all users' health answers | High | Restrict |
| No medical disclaimer | Medium | Add |
| CORS enabled for all origins | Low | Restrict |

Health data is sensitive under India's DPDP Act 2023 and GDPR. This demo must not store real patients' data; if ever used by the public, add consent, encryption at rest, access controls and deletion.


## Risks and technical debt

| ID | Category | Risk | Score (L×I) | Mitigation |
|---|---|---|---|---|
| R-01 | Safety | Users treat the score as a diagnosis | 15 (High) | Disclaimer; advise seeing a doctor |
| R-02 | Privacy | Health data exposure | 12 (Medium) | Access control |
| R-03 | Maintainability | Repo contains binaries and a venv | 8 (Medium) | Clean up |

| Tech debt | Severity | Fix |
|---|---|---|
| Unused config.py and JWT decorator | Low | Remove or use |
| Model not wired | Medium | Integrate or delete |
| Committed .venv | Medium | Remove |


## How to use it


### Check your risk (demo)

1. Register and log in
1. Click Predict, answer the questions and submit
1. Read your risk band — this is an educational estimate, not a diagnosis; see a doctor if you have symptoms
1. Open History to see past results


## Glossary

| Term | Meaning |
|---|---|
| **DPDP Act** | India's Digital Personal Data Protection Act, 2023 |
| **Optimistic locking** | Detecting conflicting edits by comparing version numbers |
| **Random Forest** | Ensemble of decision trees used for classification |
| **Risk band** | Low / Moderate / High category from the score |
| **Stored procedure** | Named SQL routine stored in the database |
| **Transaction** | A group of DB operations that all succeed or all roll back |
| **Trigger** | SQL code that runs automatically on insert/update/delete |
