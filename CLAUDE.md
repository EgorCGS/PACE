# PACE - Project Context for Claude Code

## What this is
PACE is a homework management web app, built as a VCE Applied Computing: Software Development SAT (Year 11, Casey Grammar School). Client is Mrs Bright (maths teacher). Marking is against VCAA Criteria 6, 7, 8 (Unit 4 Outcome 1). Target: 9-10 marks on each.

The app is functionally complete. Current work is bug fixing plus C6/C7/C8 polish (internal documentation depth, validation completeness, testing evidence). Do not add new features unless asked.

## Tech stack (fixed, teacher-mandated, non-negotiable)
- ASP.NET WebForms, C# code-behind (.aspx + .aspx.cs)
- .NET Framework 4.8
- SQL Server LocalDB, PACE.mdf in App_Data
- Data access: SqlConnection/SqlCommand/SqlDataReader/SqlDataAdapter only, in code-behind. NEVER SqlDataSource controls.
- Inline CSS and JS only, no external JS frameworks
- DM Sans (Google Fonts CDN), Tabler Icons (jsDelivr CDN)
- HTTPS disabled

## Project structure
- Project folder: "PACE v0" (has a space in it), nested one level inside the repo root (also "PACE v0")
- Namespace: PACE (no space) throughout every file
- Connection string key: PACEConnectionString, read via ConfigurationManager.ConnectionStrings
- Root pages: Login.aspx, Setup.aspx (test data seeder, keep for folio evidence, not for production)
- Pages/Student/: StudentDashboard.aspx, StudentClassPage.aspx, TaskDetail.aspx
- Pages/Teacher/: TeacherDashboard.aspx, CreateTask.aspx, ManageTasks.aspx, MarkCompletions.aspx, TeacherClassPage.aspx (Statistics.aspx removed, stats now shown as graphs on TeacherClassPage)
- App_Code/: five class files (User.cs, HomeworkTask.cs, SchoolClass.cs, CompletionRecord.cs, StatisticsReport.cs), Build Action MUST be Compile (not Content) or the compiler cannot find them, confirmed set correctly in PACE v0.csproj

## Database (five tables)
Users (UserID PK, Username, PasswordHash VARBINARY(64), Salt VARBINARY(32), Role {Teacher,Student}, FullName)
Classes (ClassID PK, ClassName, TeacherID FK -> Users)
ClassEnrolments (EnrolmentID PK, StudentID FK, ClassID FK, unique StudentID+ClassID)
HomeworkTasks (TaskID PK, ClassID FK, Title, Subject, Description, DueDate DATE, PriorityLevel INT {1=Low,2=Medium,3=High}, CreatedDate DATETIME)
CompletionRecords (CompletionID PK, TaskID FK, StudentID FK, MarkedComplete BIT, MarkedDate DATETIME NULL, unique TaskID+StudentID)

Note: table schema lives in the PACE.mdf file itself, not in a CREATE TABLE script in the codebase. Setup.aspx.cs only INSERTs seed data (it assumes the tables already exist).

Test accounts (seeded by Setup.aspx.cs): egor/admin123 (Teacher), felix/student123, neil/student123, bucknell/student123 (Students)

## App_Code classes (naming conflicts, important)
- User.cs contains class PaceUser (not User, conflicts with ASP.NET's IPrincipal User). Key methods: PaceUser.Authenticate(username, password), PaceUser.CreateUser(username, plainTextPassword, role, fullName), PaceUser.GenerateSalt(), PaceUser.HashPassword(plainText, salt)
- HomeworkTask.cs contains class PaceTask (not HomeworkTask, conflicts with an imported type)
- SchoolClass.cs, CompletionRecord.cs, StatisticsReport.cs keep their natural names
- SQL table for tasks is HomeworkTasks (not PaceTasks, this was a bug that got fixed once already, do not reintroduce).
- Passwords: PBKDF2 (Rfc2898DeriveBytes), 100,000 SHA-256 iterations, 32-byte salt, 64-byte hash, both byte[], constant-time comparison in PaceUser.CompareHashes() used by Authenticate()

## Session pattern (every page must do this at the top of Page_Load)
Session["UserID"], Session["Role"] ("Teacher" or "Student"), Session["FullName"] are set on login.
Every page checks Session["Role"] first. If it is null, redirect to ~/Login.aspx. If it does not match the page's expected role, redirect to the other role's dashboard (Teacher pages redirect students to StudentDashboard.aspx and vice versa). This must happen before rendering anything else.

## Coding conventions (strict, non-negotiable)
- No em dashes anywhere, in code, comments, or strings
- No double dashes mid-sentence in comments, use commas instead
- Comment section headings use the format: // - Methods -
- camelCase for local variables and parameters
- PascalCase for methods, classes, properties
- Control ID prefixes: txt, btn, ddl, lbl, pnl, rpt, hdn
- ASPX page filenames: PascalCase
- Every method needs a comment block above it: what it does, and WHY the data types/structures/sources chosen (this is graded under C6/C7, treat it as required, not optional)
- Every C# method (public and private, in App_Code and in .aspx.cs code-behind files) must have a proper XML documentation comment block directly above its signature, using /// <summary>, /// <param name="x">, and /// <returns> tags as applicable. The <summary> holds a concise statement of what the method does. Existing WHY-level reasoning (design rationale, data type/structure justification) is preserved as regular // comments either continuing within the summary or immediately below the XML block, whichever reads more cleanly, not deleted or shortened. Inline JavaScript functions use the equivalent JSDoc /** */ block comment style above the function, same content expectations, since /// is not valid JS syntax.
- Full file rewrites preferred over partial diffs when a file changes substantially, but for small targeted fixes a clear diff is fine, ask if unsure

## Design system
Colour palette (CSS custom properties, defined inline per page):
--bg:#ddeaf7 --sidebar:#4a6fa5 --topbar:#5b7db8 --hero-dark:#3a5a8c --text-dark:#1a2d42 --text-muted:#7a9fbe --white:#ffffff --border:#c5daf0 --red:#d95c5c (High priority/errors) --orange:#d4882a (Medium priority/warnings) --green:#3a9e6e (Low priority/success)
Each of red/orange/green also has a matching -bg and -border tint variable (e.g. --red-bg, --red-border) for status chip backgrounds.

Layout conventions:
- Hero gradient strip appears only on dashboard and class overview pages
- Action pages (CreateTask, ManageTasks, MarkCompletions, TaskDetail) use a compact white page-subheader instead of the hero
- Breadcrumbs use ti-chevron-right icon consistently
- Teacher sidebar nav order: Manage Tasks above Create Task
- Student sidebar class badges turn orange when a pending task in that class is overdue

## Known resolved bugs (do not reintroduce)
- HomeworkTasks table name was written as PaceTasks in some SQL, fixed
- StatisticsReport GROUP BY needed ht.DueDate added or it throws SqlException (confirmed present: App_Code/StatisticsReport.cs GROUP BY ht.TaskID, ht.Title, ht.DueDate)
- Duplicate btnLogout control ID on StudentDashboard, fixed (only one btnLogout control exists now)
- CSS class name mismatches between .aspx markup and .aspx.cs error-state code have caused bugs before, double check these match when editing validation code
- HomeworkTask.cs's ValidateInputs() had a comment claiming CreateTask.aspx.cs and ManageTasks.aspx.cs called it, they don't (each implements validation inline because their reasonableness-check requirements differ page to page). Comment corrected to reflect this, method is confirmed unused dead code, left in place as it still documents the validation rules and matches the surrounding C6/C7 commentary.
- TaskDetail.aspx.cs's GetPriorityBadge was private while the equivalent helper methods on StudentDashboard.aspx.cs, StudentClassPage.aspx.cs, MarkCompletions.aspx.cs and ManageTasks.aspx.cs are all protected. Standardized to protected for consistency (behaviour-neutral, confirmed via build), it was the only private outlier project-wide.

## Current focus
Bug fixing and polish pass is DONE: compile error fixes, MarkCompletions lifecycle bug, scroll preservation sitewide, layout-shift fixes sitewide, Statistics.aspx removal plus TeacherClassPage graphs, deep-link auto-select, native button appearance fixes, C7 reasonableness check (due date not in past) on CreateTask.aspx.cs and ManageTasks.aspx.cs, C6/C7 WHY comments across App_Code, and the full /// XML doc comment pass across every code-behind file and inline JS function.

Remaining work (documentation deliverables, being handled outside Claude Code, not code changes):
1. C8 formal testing table (Word doc) covering valid/invalid/boundary/erroneous cases
2. C8 contingencies and design-modification documentation

## What not to do
- Do not introduce SqlDataSource controls
- Do not introduce external JS/CSS frameworks or CDN libraries beyond DM Sans and Tabler Icons
- Do not rename PaceUser or PaceTask back to User/HomeworkTask
- Do not remove the Session role-check pattern from any page
- Do not add features outside what is already scoped without checking first, this is a graded VCE SAT with a fixed rubric
