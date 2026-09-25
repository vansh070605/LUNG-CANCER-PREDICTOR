# Product Requirements Document (PRD) — Lung Cancer Risk Predictor (Flask + MySQL)

| Field | Value |
|---|---|
| Document ID | LUNGU-PRD |
| Project | Lung Cancer Risk Predictor (Flask + MySQL) |
| Repository | [`vansh070605/LUNG-CANCER-PREDICTOR`](https://github.com/vansh070605/LUNG-CANCER-PREDICTOR) |
| Version | 1.0 |
| Status | Approved — living document |
| Owner | Hirav Kadikar |
| Classification | Public |
| Last updated | 2026-09-25 |

> **Purpose:** Defines what the product must do, for whom, and how success is measured. It is the single source of truth for scope.


## 1. Revision history

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 2026-09-25 | Hirav Kadikar | Full documentation suite generated from a complete review of the repository. |


## 2. Executive summary

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


## 3. Problem statement

Early awareness of lung-cancer risk factors (smoking, persistent cough, chest pain, breathlessness) encourages people to
see a doctor sooner. The course also required demonstrating advanced DBMS concepts — ACID transactions, concurrency
control, recovery and auditing — inside a working application.


## 4. Goals and non-goals


### 4.1 Goals

- Let a user estimate their risk band from common symptoms in under a minute.
- Store predictions per user with full history.
- Demonstrate transactions, locking, versioning, triggers, backup and recovery in MySQL.


### 4.2 Non-goals (explicitly out of scope)

- Clinical accuracy or medical advice.
- Production hosting or multi-tenant scale.


## 5. Stakeholders (RACI)

| Stakeholder | Role | R/A/C/I | Interest |
|---|---|---|---|
| Vansh Agrawal | Lead developer, repository owner (upstream) | R/A | Project delivery and grade |
| Hirav Kadikar | Team member; fork owner | C | Portfolio |
| Course faculty | Evaluators | I | DBMS concepts demonstrated |
| Users | End users (demo) | I | Simple risk estimate |


_R = Responsible, A = Accountable, C = Consulted, I = Informed._


## 6. Users and personas


### Health-curious adult

Smoker with a persistent cough wondering whether to see a doctor.
needs[]: Short form ;; Clear risk band ;; Past results


### DBMS evaluator

Checks database concepts.
needs[]: Visible transactions, locks, triggers, procedures ;; Clean schema


## 7. User stories

| ID | As a… | I want to… | So that… | Priority |
|---|---|---|---|---|
| US-01 | user | to register and log in | my results are private to me | Must |
| US-02 | user | to enter my symptoms and get a risk band | I know whether to seek advice | Must |
| US-03 | user | to see my past predictions | I can track changes | Should |
| US-04 | user | to record my medical history | the assessment has context | Could |
| US-05 | evaluator | to see transactions and rollback on failure | ACID behaviour is demonstrated | Must |
| US-06 | evaluator | to see backup and recovery procedures | recovery is demonstrated | Must |


## 8. Functional requirements

| ID | Area | Requirement | MoSCoW | Status |
|---|---|---|---|---|
| FR-01 | Auth | Register with name, email, password; unique email | Must | Done |
| FR-02 | Auth | Login with session; protected routes redirect to /login | Must | Done |
| FR-03 | Predict | Validate form, compute score, save prediction + link to user in one transaction | Must | Done |
| FR-04 | Predict | Only one prediction processed at a time (global lock) | Should | Done |
| FR-05 | History | Show current user's predictions | Should | Done |
| FR-06 | Medical history / symptoms / recommendations / feedback | CRUD pages | Could | Routes exist; templates missing |
| FR-07 | Database | Transaction log, versioning, locks, triggers, backup and recovery procedures | Must | Done (SQL script) |
| FR-08 | ML | Use trained model for predictions | Could | Not wired |


## 9. Non-functional requirements

| ID | Category | Requirement | Current status |
|---|---|---|---|
| NFR-01 | Consistency | All multi-table writes atomic | Met |
| NFR-02 | Concurrency | No conflicting writes | Met (via global lock — limits throughput to one prediction at a time) |
| NFR-03 | Security | Passwords hashed; secrets from environment | Partly met — hard-coded DB root/root and session secret |
| NFR-04 | Privacy | Health-related answers protected | Partly met — stored unencrypted, `/predictions` lists everyone's results |
| NFR-05 | Usability | Glassmorphism dark UI, responsive | Met |


## 10. User experience and key flows


### Get a risk estimate

1. Open http://127.0.0.1:5000 → intro page → Register → Login
1. Dashboard → Predict
1. Enter age, gender and yes/no for smoking, cough, chest pain, fatigue, shortness of breath
1. The app locks, scores, saves the prediction and link, releases the lock, commits
1. Result page shows the band and score; History lists previous results


## 11. Success metrics (KPIs)

| Metric | Target | How it is measured |
|---|---|---|
| Prediction round-trip | < 1 s locally | Manual timing |
| Transaction rollbacks leave no partial rows | 100% | Force an error and inspect tables |


## 12. Assumptions, constraints and dependencies


### Assumptions

- A local MySQL 8 server with user root / password root (as hard-coded).


### Constraints

- Academic timeline; Windows development (a Windows `.venv` was committed).


### External dependencies

| Dependency | Used for | Risk if unavailable |
|---|---|---|
| MySQL 8 | All data, triggers, procedures | App cannot start without it |
| Flask 3, Werkzeug | Web app, password hashing | — |
| scikit-learn, pandas, numpy | ML experiment | Not used at runtime |
| PyJWT, Flask-CORS | Token decorator, CORS | JWT path unused by the web pages |


## 13. Release plan and roadmap

| Phase | Scope | Status |
|---|---|---|
| v1 (May 2025) | Flask app, MySQL schema with DBMS features, report | Done |
| v1.1 | Missing templates, wire the ML model, remove secrets, per-user access on /predictions | Proposed |


## 14. Open questions

- Should the Random-Forest model replace the rule-based score (and how is it validated)?
- Should the Windows .venv and .docx reports be removed from the repository?


## 15. Acceptance and sign-off

| Role | Name | Decision | Date |
|---|---|---|---|
| Product owner | Hirav Kadikar | Approved (baseline of current build) | 2026-09-25 |
