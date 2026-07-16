<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TeacherClassPage.aspx.cs" Inherits="PACE.TeacherClassPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Class Overview</title>
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
        .hero { background:linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%); padding:30px 28px 28px; }
        .hero-title { font-size:28px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .hero-sub { font-size:14px; color:rgba(255,255,255,0.62); margin-top:4px; }

        .content { padding:28px 28px 48px; display:flex; flex-direction:column; gap:28px; }
        .summary-strip { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
        .summary-card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); padding:22px 24px 20px; }
        .summary-number { font-size:36px; font-weight:700; color:var(--topbar); line-height:1; margin-bottom:8px; }
        .summary-label { font-size:12.5px; color:var(--text-muted); font-weight:500; }
        .actions-row { display:flex; gap:12px; }
        .btn-action { display:inline-flex; align-items:center; gap:6px; padding:9px 18px; border-radius:8px; background:var(--topbar); color:#fff; font-size:13.5px; font-weight:600; font-family:'DM Sans',sans-serif; border:none; cursor:pointer; text-decoration:none; transition:background 0.15s; }
        .btn-action:hover { background:var(--hero-dark); }
        .btn-action.secondary { background:var(--white); color:var(--topbar); border:1.5px solid var(--border); }
        .btn-action.secondary:hover { background:var(--bg); }
        .btn-action i { font-size:16px; }
        .stats-grid { display:grid; grid-template-columns:1fr 1fr; gap:20px; }
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }
        .card-header { display:flex; align-items:center; gap:10px; padding:16px 20px 14px; border-bottom:1px solid var(--border); }
        .card-header-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .card-header-title { font-size:15px; font-weight:600; flex:1; }
        .stats-table { width:100%; border-collapse:collapse; }
        .stats-table thead th { padding:10px 16px; text-align:left; font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); background:var(--bg); border-bottom:1px solid var(--border); }
        .stats-table thead th:first-child { padding-left:20px; }
        .stats-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.12s; }
        .stats-table tbody tr:last-child { border-bottom:none; }
        .stats-table tbody tr:hover { background:#f7f9fd; }
        .stats-table td { padding:12px 16px; vertical-align:middle; font-size:13.5px; }
        .stats-table td:first-child { padding-left:20px; font-weight:600; }
        .pct-cell { min-width:150px; }
        .pct-row { display:flex; align-items:center; gap:10px; }
        .pct-label { font-size:12.5px; font-weight:600; color:var(--text-dark); min-width:38px; text-align:right; }
        .pct-track { flex:1; height:7px; border-radius:10px; background:var(--bg); border:1px solid var(--border); overflow:hidden; }
        .pct-fill { height:100%; border-radius:10px; background:linear-gradient(90deg,var(--sidebar),var(--topbar)); }
        .pct-fill.green  { background:linear-gradient(90deg,#2d8a5f,var(--green)); }
        .pct-fill.orange { background:linear-gradient(90deg,#b86e10,var(--orange)); }
        .pct-fill.zero   { background:var(--border); }
        .fraction { font-size:12px; color:var(--text-muted); }
        .student-avatar { width:30px; height:30px; border-radius:50%; background:rgba(74,111,165,0.12); color:#3a5a8c; font-size:11.5px; font-weight:700; display:inline-flex; align-items:center; justify-content:center; border:1px solid #b8cde8; margin-right:8px; }
        .student-name-cell { display:flex; align-items:center; }
        .student-behind { color:var(--red); }
        .empty-state { padding:40px 20px; text-align:center; color:var(--text-muted); font-size:13px; }
    </style>
</head>
<body>
    <form id="frmClassPage" runat="server">

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
                <a class="nav-item" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class='<%# GetNavClass(Eval("ClassID")) %>' href='TeacherClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-school"></i>
                            <span class="nav-item-label"><%# Eval("ClassName") %></span>
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
                    <span class="current"><asp:Label ID="lblBreadcrumb" runat="server" /></span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title"><asp:Label ID="lblHeroTitle" runat="server" /></div>
                <div class="hero-sub">Completion statistics and enrolled students for this class.</div>
            </div>

            <div class="content">

                <div class="actions-row">
                    <a class="btn-action" href='CreateTask.aspx?ClassID=<%= Request.QueryString["ClassID"] %>'><i class="ti ti-plus"></i> Create Task</a>
                    <a class="btn-action secondary" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i> Mark Completions</a>
                </div>

                <div class="summary-strip">
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblTotalStudents" runat="server" /></div>
                        <div class="summary-label">Students enrolled</div>
                    </div>
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblTotalTasks" runat="server" /></div>
                        <div class="summary-label">Tasks assigned</div>
                    </div>
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblOverallPct" runat="server" /></div>
                        <div class="summary-label">Overall completion</div>
                    </div>
                </div>

                <div class="stats-grid">

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">By Task</span>
                        </div>
                        <asp:Repeater ID="rptTaskStats" runat="server">
                            <HeaderTemplate>
                                <table class="stats-table">
                                    <thead><tr><th>Task</th><th>Done</th><th class="pct-cell">Progress</th></tr></thead>
                                    <tbody>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr>
                                    <td><%# Eval("Title") %></td>
                                    <td><span class="fraction"><%# Eval("CompletionCount") %> / <%# Eval("TotalStudents") %></span></td>
                                    <td class="pct-cell">
                                        <div class="pct-row">
                                            <span class="pct-label"><%# string.Format("{0:0}", Eval("Percentage")) %>%</span>
                                            <div class="pct-track">
                                                <div class="pct-fill <%# GetPctClass(Eval("Percentage")) %>" style="width:<%# string.Format("{0:0}", Eval("Percentage")) %>%"></div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </ItemTemplate>
                            <FooterTemplate></tbody></table></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                            <div class="empty-state">No tasks yet. <a href='CreateTask.aspx?ClassID=<%= Request.QueryString["ClassID"] %>' style="color:var(--topbar);">Create one.</a></div>
                        </asp:Panel>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-users" style="color:#3a9e6e;font-size:17px;"></i></div>
                            <span class="card-header-title">By Student</span>
                        </div>
                        <asp:Repeater ID="rptStudentStats" runat="server">
                            <HeaderTemplate>
                                <table class="stats-table">
                                    <thead><tr><th>Student</th><th>Done</th><th class="pct-cell">Progress</th></tr></thead>
                                    <tbody>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr>
                                    <td>
                                        <div class="student-name-cell">
                                            <span class="student-avatar <%# GetStudentRowClass(Eval("TasksCompleted"), Eval("TotalTasks")) %>"><%# GetStudentInitials(Eval("FullName")) %></span>
                                            <span class="<%# GetStudentRowClass(Eval("TasksCompleted"), Eval("TotalTasks")) %>"><%# Eval("FullName") %></span>
                                        </div>
                                    </td>
                                    <td><span class="fraction"><%# Eval("TasksCompleted") %> / <%# Eval("TotalTasks") %></span></td>
                                    <td class="pct-cell">
                                        <div class="pct-row">
                                            <span class="pct-label"><%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%</span>
                                            <div class="pct-track">
                                                <div class="pct-fill <%# GetPctClass(GetStudentPctRaw(Eval("TasksCompleted"), Eval("TotalTasks"))) %>"
                                                     style="width:<%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%"></div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </ItemTemplate>
                            <FooterTemplate></tbody></table></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlNoStudents" runat="server" Visible="false">
                            <div class="empty-state">No students enrolled yet.</div>
                        </asp:Panel>
                    </div>

                </div>
            </div>
        </div>

    </form>
</body>
</html>