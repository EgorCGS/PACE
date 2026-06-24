<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="StudentClassPage.aspx.cs" Inherits="PACE.StudentClassPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Class Tasks</title>
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
        .breadcrumb a { color:rgba(255,255,255,0.65); text-decoration:none; }
        .breadcrumb .current { color:#fff; font-weight:500; }
        .hero { background:linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%); padding:30px 28px 28px; }
        .hero-title { font-size:28px; font-weight:700; color:#fff; letter-spacing:-0.5px; }
        .hero-sub { font-size:14px; color:rgba(255,255,255,0.62); margin-top:4px; }

        .content { padding:24px 28px 40px; display:flex; flex-direction:column; gap:20px; }
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }
        .card-header { display:flex; align-items:center; gap:10px; padding:16px 20px 14px; border-bottom:1px solid var(--border); }
        .card-header-icon { width:34px; height:34px; border-radius:8px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
        .card-header-title { font-size:15px; font-weight:600; flex:1; }
        .card-header-count { font-size:13px; color:var(--text-muted); }

        .table-card { overflow:hidden; }
        .task-table { width:100%; border-collapse:collapse; }
        .task-table thead th { padding:11px 14px; text-align:left; font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); background:var(--bg); border-bottom:1px solid var(--border); }
        .task-table thead th:first-child { padding-left:18px; }
        .task-table tbody tr { border-bottom:1px solid var(--border); transition:background 0.12s; }
        .task-table tbody tr:last-child { border-bottom:none; }
        .task-table tbody tr:nth-child(even) { background:#f7f9fd; }
        .task-table tbody tr:hover { background:#eef3fb; }
        .task-table td { padding:11px 14px; vertical-align:middle; }
        .task-table td:first-child { padding-left:18px; }
        .task-name { font-size:13.5px; font-weight:600; }
        .task-desc { font-size:12px; color:var(--text-muted); margin-top:2px; display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden; }
        .due-main { font-size:13px; font-weight:500; }
        .due-urgency { font-size:11px; font-weight:500; margin-top:1px; }
        .due-red { color:var(--red); } .due-orange { color:var(--orange); } .due-green { color:var(--green); } .due-muted { color:var(--text-muted); }
        .badge { display:inline-flex; align-items:center; padding:2px 8px; border-radius:20px; font-size:11.5px; font-weight:500; border:1px solid; white-space:nowrap; }
        .badge-high { color:var(--red); background:var(--red-bg); border-color:var(--red-border); }
        .badge-med  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-low  { color:var(--green); background:var(--green-bg); border-color:var(--green-border); }
        .badge-pending  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-complete { color:var(--green); background:var(--green-bg); border-color:var(--green-border); }
        .btn-view { display:inline-flex; align-items:center; gap:4px; padding:5px 12px; border-radius:7px; background:var(--topbar); color:#fff; font-size:12px; font-weight:500; text-decoration:none; transition:background 0.15s; }
        .btn-view:hover { background:var(--hero-dark); }
        .btn-view i { font-size:14px; }
        .empty-state { padding:48px 20px; text-align:center; color:var(--text-muted); }
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
                <div class="nav-section-label">Main</div>
                <a class="nav-item" href="StudentDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">My Dashboard</span></a>
                <div class="nav-section-label">Classes</div>
                <%-- Active class is highlighted by the code-behind helper --%>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class='<%# GetNavClass(Eval("ClassID")) %>' href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-book"></i>
                            <span class="nav-item-label"><%# Eval("ClassName") %></span>
                        </a>
                    </ItemTemplate>
                </asp:Repeater>
            </nav>
            <div class="sidebar-user">
                <div class="user-avatar"><%= GetInitials() %></div>
                <div class="user-info">
                    <div class="user-name"><%= Session["FullName"] %></div>
                    <div class="user-role">Student</div>
                </div>
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn-logout" OnClick="btnLogout_Click"><i class="ti ti-logout"></i></asp:LinkButton>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="breadcrumb">
                    <a href="StudentDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right" style="opacity:0.45;"></i>
                    <a href="StudentDashboard.aspx">My Dashboard</a>
                    <i class="ti ti-chevron-right" style="opacity:0.45;"></i>
                    <span class="current"><asp:Label ID="lblBreadcrumb" runat="server" /></span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title"><asp:Label ID="lblHeroTitle" runat="server" /></div>
                <div class="hero-sub">All homework tasks assigned to this class, ordered by due date.</div>
            </div>

            <div class="content">
                <div class="card table-card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                        <span class="card-header-title">Tasks</span>
                        <span class="card-header-count"><asp:Label ID="lblTaskCount" runat="server" /> tasks</span>
                    </div>

                    <asp:Repeater ID="rptTasks" runat="server">
                        <HeaderTemplate>
                            <table class="task-table">
                                <thead>
                                    <tr>
                                        <th>Task</th>
                                        <th>Due Date</th>
                                        <th>Priority</th>
                                        <th>Status</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr>
                                <td>
                                    <div class="task-name"><%# Eval("Title") %></div>
                                    <div class="task-desc"><%# Eval("Description") %></div>
                                </td>
                                <td>
                                    <div class="due-main"><%# Convert.ToDateTime(Eval("DueDate")).ToString("d MMM yyyy") %></div>
                                    <div class="due-urgency <%# GetUrgencyClass(Eval("DueDate")) %>"><%# GetUrgencyText(Eval("DueDate")) %></div>
                                </td>
                                <td><%# GetPriorityBadge(Eval("PriorityLevel")) %></td>
                                <td><%# GetStatusBadge(Eval("MarkedComplete")) %></td>
                                <td>
                                    <a class="btn-view" href="TaskDetail.aspx?TaskID=<%# Eval("TaskID") %>">
                                        <i class="ti ti-eye"></i> View
                                    </a>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                        <div class="empty-state">No tasks assigned to this class yet.</div>
                    </asp:Panel>
                </div>
            </div>
        </div>

    </form>
</body>
</html>