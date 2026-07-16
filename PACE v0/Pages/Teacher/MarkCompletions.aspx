<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="MarkCompletions.aspx.cs" Inherits="PACE.MarkCompletions" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Mark Completions</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <style>
        :root {
            --bg:#ddeaf7; --sidebar:#4a6fa5; --topbar:#5b7db8; --hero-dark:#3a5a8c;
            --text-dark:#1a2d42; --text-muted:#7a9fbe; --white:#ffffff; --border:#c5daf0;
            --input-bg:#f0f5fb; --red:#d95c5c; --red-bg:#fdf0f0; --red-border:#f0b8b8;
            --orange:#d4882a; --orange-bg:#fef7ee; --orange-border:#f0d0a0;
            --green:#3a9e6e; --green-bg:#eef8f3; --green-border:#a8d9c0;
            --sidebar-w:258px; --topbar-h:58px; --shadow:0 2px 8px rgba(74,111,165,0.10);
        }
        *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
        a { text-decoration:none; }
        html, body { font-family:'DM Sans',sans-serif; background:var(--bg); color:var(--text-dark); font-size:14px; }

        .sidebar { position:fixed; left:0; top:0; bottom:0; width:var(--sidebar-w); background:var(--sidebar); display:flex; flex-direction:column; z-index:300; overflow-y:auto; }
        .sidebar-logo { padding:24px 20px 20px; border-bottom:1px solid rgba(255,255,255,0.12); }
        .logo-title { font-size:22px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .logo-sub { font-size:11px; color:rgba(255,255,255,0.55); margin-top:2px; }
        .sidebar-nav { flex:1; padding:12px 0; }
        .nav-section-label { padding:14px 20px 5px; font-size:10.5px; font-weight:600; letter-spacing:0.8px; text-transform:uppercase; color:rgba(255,255,255,0.38); }
        .nav-item { display:flex; align-items:center; gap:10px; padding:9px 16px 9px 20px; margin:1px 8px; border-radius:8px; color:rgba(255,255,255,0.70); font-size:13.5px; text-decoration:none; transition:background 0.15s,color 0.15s; }
        .nav-item:hover { background:rgba(255,255,255,0.12); color:#fff; }
        .nav-item.active { background:rgba(255,255,255,0.18); color:#fff; font-weight:600; }
        .nav-item i { font-size:17px; flex-shrink:0; }
        .nav-item-label { flex:1; }
        .sidebar-user { padding:14px 16px; border-top:1px solid rgba(255,255,255,0.12); display:flex; align-items:center; gap:10px; }
        .user-avatar { width:36px; height:36px; border-radius:50%; background:rgba(255,255,255,0.22); color:#fff; font-size:13px; font-weight:600; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .user-info { flex:1; min-width:0; }
        .user-name { font-size:13px; font-weight:600; color:#fff; }
        .user-role { font-size:11px; color:rgba(255,255,255,0.50); }
        .btn-logout { background:none; border:none; color:rgba(255,255,255,0.45); cursor:pointer; padding:4px; border-radius:6px; transition:color 0.15s,background 0.15s; text-decoration:none; }
        .btn-logout:hover { color:#fff; background:rgba(255,255,255,0.12); }
        .btn-logout i { font-size:18px; display:block; }

        .main { margin-left:var(--sidebar-w); min-height:100vh; display:flex; flex-direction:column; }
        .topbar { position:sticky; top:0; z-index:200; height:var(--topbar-h); background:var(--topbar); display:flex; align-items:center; padding:0 28px; box-shadow:0 2px 10px rgba(58,90,140,0.18); }
        .breadcrumb { display:flex; align-items:center; gap:6px; font-size:13px; color:rgba(255,255,255,0.65); }
        .breadcrumb a { color:rgba(255,255,255,0.65); }
        .breadcrumb .sep { opacity:0.45; font-size:12px; }
        .breadcrumb .current { color:#fff; font-weight:500; }

        .page-subheader { background:var(--white); border-bottom:1px solid var(--border); padding:16px 28px; display:flex; align-items:center; gap:14px; }
        .page-subheader-icon { width:42px; height:42px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:21px; flex-shrink:0; }
        .page-subheader-title { font-size:18px; font-weight:700; color:var(--text-dark); line-height:1.2; }
        .page-subheader-sub { font-size:12.5px; color:var(--text-muted); margin-top:2px; }

        .content { padding:24px 28px 48px; display:flex; flex-direction:column; gap:20px; }

        /* Step indicator */
        .steps-bar { display:flex; align-items:stretch; background:var(--white); border:1px solid var(--border); border-radius:12px; overflow:hidden; box-shadow:var(--shadow); }
        .step { flex:1; padding:14px 20px; display:flex; align-items:center; gap:10px; border-right:1px solid var(--border); font-size:13.5px; font-weight:500; color:var(--text-muted); background:var(--white); }
        .step:last-child { border-right:none; }

        /* Active: currently needs action */
        .step.active { background:var(--topbar); color:#fff; font-weight:600; }
        .step.active .step-num { background:rgba(255,255,255,0.25); color:#fff; }

        /* Selected: completed but shown as chosen, not done checkmark */
        .step.selected { background:rgba(91,125,184,0.10); color:var(--topbar); }
        .step.selected .step-num { background:var(--topbar); color:#fff; }

        .step-num { width:24px; height:24px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:700; background:rgba(0,0,0,0.08); flex-shrink:0; }

        /* Cards */
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }
        .card-header { display:flex; align-items:center; gap:10px; padding:16px 20px 14px; border-bottom:1px solid var(--border); }
        .card-header-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .card-header-title { font-size:15px; font-weight:600; flex:1; }
        .card-header-meta { font-size:13px; color:var(--text-muted); }

        /* Class grid */
        .class-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); gap:12px; padding:18px; }
        .class-btn { background:var(--bg); border:2px solid var(--border); border-radius:10px; padding:16px; text-align:left; cursor:pointer; font-family:'DM Sans',sans-serif; transition:all 0.15s; }
        .class-btn:hover { border-color:var(--topbar); background:#eef3fb; }
        .class-btn.selected { border-color:var(--topbar); background:rgba(91,125,184,0.10); }
        .class-btn-name { font-size:14px; font-weight:600; color:var(--text-dark); margin-bottom:4px; }
        .class-btn-meta { font-size:12px; color:var(--text-muted); }

        /* Task table */
        .task-table { width:100%; border-collapse:collapse; }
        .task-table thead th { padding:10px 16px; text-align:left; font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); background:var(--bg); border-bottom:1px solid var(--border); }
        .task-table thead th:first-child { padding-left:20px; }
        .task-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.12s; }
        .task-table tbody tr:last-child { border-bottom:none; }
        .task-table tbody tr:hover { background:#eef3fb; }
        .task-table tbody tr.selected { background:rgba(91,125,184,0.08); }
        .task-table td { padding:12px 16px; vertical-align:middle; }
        .task-table td:first-child { padding-left:20px; }
        .task-name-cell { font-size:13.5px; font-weight:600; color:var(--text-dark); }
        .task-sub-cell  { font-size:12px; color:var(--text-muted); margin-top:1px; }

        /* Student table */
        .student-table { width:100%; border-collapse:collapse; }
        .student-table thead th { padding:10px 16px; text-align:left; font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); background:var(--bg); border-bottom:1px solid var(--border); }
        .student-table thead th:first-child { padding-left:20px; }
        .student-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.12s; }
        .student-table tbody tr:last-child { border-bottom:none; }
        .student-table tbody tr:hover { background:#f7f9fd; }
        .student-table td { padding:12px 16px; vertical-align:middle; }
        .student-table td:first-child { padding-left:20px; }
        .student-avatar { width:30px; height:30px; border-radius:50%; background:rgba(74,111,165,0.12); color:#3a5a8c; font-size:11.5px; font-weight:700; display:inline-flex; align-items:center; justify-content:center; border:1px solid #b8cde8; margin-right:8px; flex-shrink:0; }
        .student-name-cell { display:flex; align-items:center; }

        .badge { display:inline-flex; align-items:center; padding:2px 8px; border-radius:20px; font-size:11.5px; font-weight:500; border:1px solid; white-space:nowrap; }
        .badge-high { color:var(--red);    background:var(--red-bg);    border-color:var(--red-border); }
        .badge-med  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-low  { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .badge-sel  { color:var(--topbar); background:#e8f0fa; border-color:#b8cde8; font-size:11px; }

        .btn-mark   { display:inline-flex; align-items:center; gap:5px; padding:6px 14px; border-radius:7px; background:var(--green-bg); color:var(--green); font-size:12.5px; font-weight:600; font-family:'DM Sans',sans-serif; border:1px solid var(--green-border); cursor:pointer; text-decoration:none; transition:background 0.15s; }
        .btn-mark:hover { background:#c8eedd; }
        .btn-unmark { display:inline-flex; align-items:center; gap:5px; padding:6px 14px; border-radius:7px; background:var(--red-bg); color:var(--red); font-size:12.5px; font-weight:600; font-family:'DM Sans',sans-serif; border:1px solid var(--red-border); cursor:pointer; text-decoration:none; transition:background 0.15s; }
        .btn-unmark:hover { background:#f8e0e0; }
        .btn-select { display:inline-flex; align-items:center; gap:4px; padding:6px 14px; border-radius:7px; background:#e8f0fa; color:#3a5a8c; font-size:12px; font-weight:600; font-family:'DM Sans',sans-serif; border:1px solid #b8cde8; cursor:pointer; text-decoration:none; transition:background 0.15s; }
        .btn-select:hover { background:#cddcee; }
        .btn-selected { display:inline-flex; align-items:center; gap:4px; padding:6px 14px; border-radius:7px; background:var(--topbar); color:#fff; font-size:12px; font-weight:600; font-family:'DM Sans',sans-serif; border:1px solid var(--topbar); cursor:pointer; text-decoration:none; }

        .completion-bar-wrap { display:flex; align-items:center; gap:12px; padding:14px 20px; border-top:1px solid var(--border); background:#f8fbff; border-radius:0 0 12px 12px; }
        .completion-bar-label { font-size:13px; font-weight:600; color:var(--text-dark); white-space:nowrap; }
        .completion-track { flex:1; height:8px; background:var(--bg); border:1px solid var(--border); border-radius:10px; overflow:hidden; }
        .completion-fill { height:100%; border-radius:10px; background:linear-gradient(90deg,#2d8a5f,var(--green)); transition:width 0.4s ease; }
        .completion-pct { font-size:13px; font-weight:700; color:var(--green); white-space:nowrap; }

        .alert-success { background:var(--green-bg); border:1px solid var(--green-border); border-radius:8px; padding:12px 16px; color:var(--green); font-size:13px; display:flex; align-items:center; gap:8px; }
        .hint-state { padding:36px 20px; text-align:center; color:var(--text-muted); font-size:13px; }
        .empty-state { padding:36px 20px; text-align:center; color:var(--text-muted); }
    </style>
</head>
<body>
    <form id="frmMarkCompletions" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Overview</div>
                <a class="nav-item" href="TeacherDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">Dashboard</span></a>
                <div class="nav-section-label">Tasks</div>
                <a class="nav-item" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
                <a class="nav-item" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
                <a class="nav-item active" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class="nav-item" href='TeacherClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-school"></i><span class="nav-item-label"><%# Eval("ClassName") %></span>
                        </a>
                    </ItemTemplate>
                </asp:Repeater>
            </nav>
            <div class="sidebar-user">
                <div class="user-avatar"><%= GetInitials() %></div>
                <div class="user-info">
                    <div class="user-name"><%= Session["FullName"] %></div>
                    <div class="user-role">Teacher</div>
                </div>
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn-logout" OnClick="btnLogout_Click"><i class="ti ti-logout"></i></asp:LinkButton>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="breadcrumb">
                    <a href="TeacherDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current">Mark Completions</span>
                </div>
            </header>

            <div class="page-subheader">
                <div class="page-subheader-icon" style="background:#eef8f3;"><i class="ti ti-clipboard-check" style="color:#3a9e6e;"></i></div>
                <div>
                    <div class="page-subheader-title">Mark Completions</div>
                    <div class="page-subheader-sub">Select a class, then a task, then mark which students have completed it.</div>
                </div>
            </div>

            <div class="content">

                <%-- Step indicator: uses selected state (not done checkmark) until a student is actually marked --%>
                <div class="steps-bar">
                    <div class="step <%= GetStepClass(1) %>">
                        <span class="step-num">1</span>
                        <span>Choose Class</span>
                    </div>
                    <div class="step <%= GetStepClass(2) %>">
                        <span class="step-num">2</span>
                        <span>Choose Task</span>
                    </div>
                    <div class="step <%= GetStepClass(3) %>">
                        <span class="step-num">3</span>
                        <span>Mark Students</span>
                    </div>
                </div>

                <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                    <div class="alert-success"><i class="ti ti-circle-check" style="font-size:18px;"></i><asp:Label ID="lblSuccess" runat="server" /></div>
                </asp:Panel>

                <%-- Step 1: class grid --%>
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-school" style="color:#3a5a8c;font-size:17px;"></i></div>
                        <span class="card-header-title">Step 1: Select a Class</span>
                        <asp:Label ID="lblSelectedClass" runat="server" CssClass="card-header-meta" />
                    </div>
                    <div class="class-grid">
                        <asp:Repeater ID="rptClasses" runat="server">
                            <ItemTemplate>
                                <asp:LinkButton runat="server"
                                    CssClass='<%# Convert.ToInt32(Eval("ClassID")) == SelectedClassID ? "class-btn selected" : "class-btn" %>'
                                    CommandName="SelectClass"
                                    CommandArgument='<%# Eval("ClassID") %>'
                                    OnCommand="ClassCommand">
                                    <div class="class-btn-name"><%# Eval("ClassName") %></div>
                                    <div class="class-btn-meta"><i class="ti ti-users"></i> <%# Eval("StudentCount") %> students &middot; <%# Eval("TaskCount") %> tasks</div>
                                </asp:LinkButton>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>

                <%-- Step 2: task table --%>
                <asp:Panel ID="pnlTaskSelector" runat="server" Visible="false">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#fef7ee;"><i class="ti ti-clipboard-list" style="color:#d4882a;font-size:17px;"></i></div>
                            <span class="card-header-title">Step 2: Select a Task</span>
                            <asp:Label ID="lblSelectedTask" runat="server" CssClass="card-header-meta" />
                        </div>
                        <asp:Repeater ID="rptTasks" runat="server">
                            <HeaderTemplate>
                                <table class="task-table">
                                    <thead>
                                        <tr><th>Task</th><th>Due Date</th><th>Priority</th><th>Completed</th><th style="text-align:right;padding-right:16px;"></th></tr>
                                    </thead>
                                    <tbody>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr class='<%# Convert.ToInt32(Eval("TaskID")) == SelectedTaskID ? "selected" : "" %>'>
                                    <td>
                                        <div class="task-name-cell"><%# Eval("Title") %></div>
                                        <div class="task-sub-cell"><%# Eval("Subject") %></div>
                                    </td>
                                    <td><%# Convert.ToDateTime(Eval("DueDate")).ToString("d MMM yyyy") %></td>
                                    <td><%# GetPriorityBadge(Eval("PriorityLevel")) %></td>
                                    <td><span class="badge badge-sel"><%# Eval("CompletionCount") %> / <%# Eval("TotalStudents") %></span></td>
                                    <td style="text-align:right;padding-right:16px;">
                                        <asp:LinkButton runat="server"
                                            CssClass='<%# Convert.ToInt32(Eval("TaskID")) == SelectedTaskID ? "btn-selected" : "btn-select" %>'
                                            CommandName="SelectTask"
                                            CommandArgument='<%# Eval("TaskID") %>'
                                            OnCommand="TaskCommand">
                                            <%# Convert.ToInt32(Eval("TaskID")) == SelectedTaskID ? "<i class='ti ti-check'></i> Selected" : "Select" %>
                                        </asp:LinkButton>
                                    </td>
                                </tr>
                            </ItemTemplate>
                            <FooterTemplate></tbody></table></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                            <div class="hint-state">No tasks assigned to this class yet. <a href="CreateTask.aspx" style="color:var(--topbar);">Create one.</a></div>
                        </asp:Panel>
                    </div>
                </asp:Panel>

                <%-- Step 3: student list --%>
                <asp:Panel ID="pnlStudents" runat="server" Visible="false">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-users" style="color:#3a9e6e;font-size:17px;"></i></div>
                            <span class="card-header-title">Step 3: Mark Students</span>
                            <span class="card-header-meta"><asp:Label ID="lblCompletionSummary" runat="server" /></span>
                        </div>
                        <asp:Repeater ID="rptStudents" runat="server">
                            <HeaderTemplate>
                                <table class="student-table">
                                    <thead>
                                        <tr><th>Student</th><th>Status</th><th style="text-align:right;padding-right:20px;">Action</th></tr>
                                    </thead>
                                    <tbody>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr>
                                    <td>
                                        <div class="student-name-cell">
                                            <span class="student-avatar"><%# GetStudentInitials(Eval("FullName")) %></span>
                                            <%# Eval("FullName") %>
                                        </div>
                                    </td>
                                    <td><%# GetStatusBadge(Eval("MarkedComplete")) %></td>
                                    <td style="text-align:right;padding-right:20px;">
                                        <asp:LinkButton runat="server"
                                            CssClass='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "btn-unmark" : "btn-mark" %>'
                                            CommandName='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "Unmark" : "Mark" %>'
                                            CommandArgument='<%# Eval("StudentID") %>'
                                            OnCommand="StudentCommand">
                                            <%# Convert.ToBoolean(Eval("MarkedComplete")) ? "<i class='ti ti-x'></i> Unmark" : "<i class='ti ti-check'></i> Mark Complete" %>
                                        </asp:LinkButton>
                                    </td>
                                </tr>
                            </ItemTemplate>
                            <FooterTemplate></tbody></table></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlNoStudents" runat="server" Visible="false">
                            <div class="empty-state">No students enrolled in this class.</div>
                        </asp:Panel>
                        <div class="completion-bar-wrap">
                            <span class="completion-bar-label">Class completion</span>
                            <div class="completion-track">
                                <div class="completion-fill" style="width:<%= CompletionPct.ToString("0") %>%"></div>
                            </div>
                            <span class="completion-pct"><%= CompletionPct.ToString("0") %>%</span>
                        </div>
                    </div>
                </asp:Panel>

            </div>
        </div>
    </form>
</body>
</html>