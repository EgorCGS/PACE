<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TeacherDashboard.aspx.cs" Inherits="PACE.TeacherDashboard" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Teacher Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <style>
        :root {
            --bg:#ddeaf7; --sidebar:#4a6fa5; --topbar:#5b7db8; --hero-dark:#3a5a8c;
            --text-dark:#1a2d42; --text-muted:#7a9fbe; --white:#ffffff; --border:#c5daf0;
            --red:#d95c5c; --red-bg:#fdf0f0; --red-border:#f0b8b8;
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
        .breadcrumb { font-size:13px; color:rgba(255,255,255,0.65); display:flex; align-items:center; gap:6px; }
        .breadcrumb .sep { opacity:0.45; font-size:12px; }
        .breadcrumb .current { color:#fff; font-weight:500; }
        .hero { background:linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%); padding:30px 28px 28px; }
        .hero-title { font-size:28px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .hero-sub { font-size:14px; color:rgba(255,255,255,0.62); margin-top:4px; }

        .content { padding:28px 28px 48px; display:flex; flex-direction:column; gap:28px; }

        .summary-strip { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; }
        .summary-card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); padding:20px 22px 18px; display:flex; flex-direction:column; gap:6px; }
        .summary-card-icon { width:36px; height:36px; border-radius:9px; display:flex; align-items:center; justify-content:center; font-size:18px; margin-bottom:2px; }
        .summary-number { font-size:30px; font-weight:700; color:var(--topbar); line-height:1; }
        .summary-label { font-size:12px; color:var(--text-muted); font-weight:500; }

        .section-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:14px; }
        .section-title { font-size:16px; font-weight:700; color:var(--text-dark); }
        .section-hint { font-size:12.5px; color:var(--text-muted); }

        .classes-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(280px,1fr)); gap:16px; }
        .class-card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); overflow:hidden; display:flex; flex-direction:column; transition:box-shadow 0.15s; }
        .class-card:hover { box-shadow:0 4px 16px rgba(74,111,165,0.16); }
        .class-card-accent { height:4px; background:linear-gradient(90deg,var(--sidebar),var(--topbar)); }
        .class-card-accent.green  { background:linear-gradient(90deg,#2d8a5f,var(--green)); }
        .class-card-accent.orange { background:linear-gradient(90deg,#b86e10,var(--orange)); }
        .class-card-accent.red    { background:linear-gradient(90deg,#b03a3a,var(--red)); }
        .class-card-body { padding:18px 20px 14px; flex:1; display:flex; flex-direction:column; gap:12px; }
        .class-card-name { font-size:16px; font-weight:700; color:var(--text-dark); }
        .class-card-meta { display:flex; gap:14px; font-size:12.5px; color:var(--text-muted); }
        .class-card-meta span { display:flex; align-items:center; gap:4px; }
        .class-card-meta i { font-size:14px; }
        .class-pct-row { display:flex; align-items:center; gap:10px; }
        .class-pct-label { font-size:13px; font-weight:700; min-width:38px; }
        .class-pct-track { flex:1; height:7px; background:var(--bg); border:1px solid var(--border); border-radius:10px; overflow:hidden; }
        .class-pct-fill { height:100%; border-radius:10px; background:linear-gradient(90deg,var(--sidebar),var(--topbar)); }
        .class-pct-fill.green  { background:linear-gradient(90deg,#2d8a5f,var(--green)); }
        .class-pct-fill.orange { background:linear-gradient(90deg,#b86e10,var(--orange)); }
        .class-pct-fill.zero   { background:var(--border); }
        .class-card-footer { padding:12px 20px; border-top:1px solid var(--border); background:#f8fbff; display:flex; align-items:center; gap:8px; }
        .btn-card { display:inline-flex; align-items:center; gap:5px; padding:7px 14px; border-radius:7px; background:var(--topbar); color:#fff; font-size:12.5px; font-weight:600; font-family:'DM Sans',sans-serif; border:none; cursor:pointer; text-decoration:none; transition:background 0.15s; }
        .btn-card:hover { background:var(--hero-dark); }
        .btn-card.secondary { background:transparent; color:var(--topbar); border:1.5px solid var(--border); }
        .btn-card.secondary:hover { background:var(--bg); }
        .overdue-tag { display:inline-flex; align-items:center; gap:4px; font-size:11.5px; font-weight:600; color:var(--red); margin-left:auto; }
        .overdue-tag i { font-size:13px; }

        .quick-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:16px; }
        .quick-card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); padding:20px; display:flex; align-items:center; gap:16px; text-decoration:none; color:var(--text-dark); transition:box-shadow 0.15s,background 0.15s; }
        .quick-card:hover { box-shadow:0 4px 16px rgba(74,111,165,0.14); background:#f8fbff; }
        .quick-icon { width:44px; height:44px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:22px; flex-shrink:0; }
        .quick-label { font-size:14px; font-weight:600; }
        .quick-hint { font-size:12px; color:var(--text-muted); margin-top:2px; }

        /* First-run empty state */
        .first-run { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); padding:64px 40px; text-align:center; }
        .first-run-icon { width:72px; height:72px; border-radius:20px; background:#e8f0fa; display:flex; align-items:center; justify-content:center; margin:0 auto 20px; font-size:36px; color:#3a5a8c; }
        .first-run-title { font-size:20px; font-weight:700; color:var(--text-dark); margin-bottom:8px; }
        .first-run-body { font-size:14px; color:var(--text-muted); max-width:420px; margin:0 auto; line-height:1.7; }
    </style>
</head>
<body>
    <form id="frmTeacherDashboard" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Overview</div>
                <a class="nav-item active" href="TeacherDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">Dashboard</span></a>
                <div class="nav-section-label">Tasks</div>
                <a class="nav-item" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
                <a class="nav-item" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
                <a class="nav-item" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
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
                    <span class="current">PACE</span>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current">Dashboard</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Teacher Dashboard</div>
                <div class="hero-sub">Welcome back, <asp:Label ID="lblHeroName" runat="server" />. Here is an overview of your classes.</div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlNoClasses" runat="server" Visible="false">
                    <div class="first-run">
                        <div class="first-run-icon"><i class="ti ti-school-off"></i></div>
                        <div class="first-run-title">No classes assigned yet</div>
                        <div class="first-run-body">You have not been assigned to any classes. Contact your school administrator to have classes linked to your account. Once classes are assigned, they will appear here along with your tasks and completion statistics.</div>
                    </div>
                </asp:Panel>

                <asp:Panel ID="pnlDashboard" runat="server">

                    <div class="summary-strip">
                        <div class="summary-card">
                            <div class="summary-card-icon" style="background:#e8f0fa;"><i class="ti ti-school" style="color:#3a5a8c;"></i></div>
                            <div class="summary-number"><asp:Label ID="lblTotalClasses" runat="server" /></div>
                            <div class="summary-label">Classes</div>
                        </div>
                        <div class="summary-card">
                            <div class="summary-card-icon" style="background:#eef8f3;"><i class="ti ti-users" style="color:#3a9e6e;"></i></div>
                            <div class="summary-number"><asp:Label ID="lblTotalStudents" runat="server" /></div>
                            <div class="summary-label">Students enrolled</div>
                        </div>
                        <div class="summary-card">
                            <div class="summary-card-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;"></i></div>
                            <div class="summary-number"><asp:Label ID="lblTotalTasks" runat="server" /></div>
                            <div class="summary-label">Tasks assigned</div>
                        </div>
                        <div class="summary-card">
                            <div class="summary-card-icon" style="background:#fef7ee;"><i class="ti ti-chart-bar" style="color:#d4882a;"></i></div>
                            <div class="summary-number"><asp:Label ID="lblOverallPct" runat="server" /></div>
                            <div class="summary-label">Overall completion</div>
                        </div>
                    </div>

                    <div>
                        <div class="section-header">
                            <span class="section-title">Your Classes</span>
                            <span class="section-hint">Click a class to view detailed stats</span>
                        </div>
                        <div class="classes-grid">
                            <asp:Repeater ID="rptClasses" runat="server">
                                <ItemTemplate>
                                    <div class="class-card">
                                        <div class="class-card-accent <%# Eval("AccentClass") %>"></div>
                                        <div class="class-card-body">
                                            <div class="class-card-name"><%# Eval("ClassName") %></div>
                                            <div class="class-card-meta">
                                                <span><i class="ti ti-users"></i> <%# Eval("StudentCount") %> students</span>
                                                <span><i class="ti ti-clipboard-list"></i> <%# Eval("TaskCount") %> tasks</span>
                                            </div>
                                            <div class="class-pct-row">
                                                <span class="class-pct-label" style="color:<%# Eval("PctColor") %>"><%# Eval("PctDisplay") %></span>
                                                <div class="class-pct-track">
                                                    <div class="class-pct-fill <%# Eval("PctClass") %>" style="width:<%# Eval("PctWidth") %>%"></div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="class-card-footer">
                                            <a class="btn-card" href='TeacherClassPage.aspx?ClassID=<%# Eval("ClassID") %>'><i class="ti ti-arrow-right"></i> View Class</a>
                                            <a class="btn-card secondary" href='CreateTask.aspx?ClassID=<%# Eval("ClassID") %>'><i class="ti ti-plus"></i> Add Task</a>
                                            <%# Convert.ToInt32(Eval("OverdueTasks")) > 0 ? "<span class='overdue-tag'><i class='ti ti-alert-triangle'></i>" + Eval("OverdueTasks") + " overdue</span>" : "" %>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                    </div>

                    <div>
                        <div class="section-header">
                            <span class="section-title">Quick Actions</span>
                        </div>
                        <div class="quick-grid">
                            <a class="quick-card" href="ManageTasks.aspx">
                                <div class="quick-icon" style="background:#fef7ee;"><i class="ti ti-pencil" style="color:#d4882a;"></i></div>
                                <div><div class="quick-label">Manage Tasks</div><div class="quick-hint">Edit or delete existing tasks</div></div>
                            </a>
                            <a class="quick-card" href="CreateTask.aspx">
                                <div class="quick-icon" style="background:#e8f0fa;"><i class="ti ti-plus" style="color:#3a5a8c;"></i></div>
                                <div><div class="quick-label">Create Task</div><div class="quick-hint">Add a new homework task to a class</div></div>
                            </a>
                            <a class="quick-card" href="MarkCompletions.aspx">
                                <div class="quick-icon" style="background:#eef8f3;"><i class="ti ti-clipboard-check" style="color:#3a9e6e;"></i></div>
                                <div><div class="quick-label">Mark Completions</div><div class="quick-hint">Record which students completed tasks</div></div>
                            </a>
                        </div>
                    </div>

                </asp:Panel>

            </div>
        </div>
    </form>
</body>
</html>