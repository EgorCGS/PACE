<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TaskDetail.aspx.cs" Inherits="PACE.TaskDetail" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Task Detail</title>
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
        .nav-badge { font-size:11px; font-weight:700; background:rgba(255,255,255,0.22); color:#fff; padding:1px 7px; border-radius:20px; }
        .nav-badge.overdue { background:rgba(212,136,42,0.85); }
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

        /* No hero - compact subheader */
        .page-subheader { background:var(--white); border-bottom:1px solid var(--border); padding:16px 28px; display:flex; align-items:center; gap:14px; }
        .page-subheader-icon { width:42px; height:42px; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:21px; flex-shrink:0; }
        .page-subheader-title { font-size:18px; font-weight:700; color:var(--text-dark); line-height:1.2; }
        .page-subheader-sub { font-size:12.5px; color:var(--text-muted); margin-top:2px; }

        .content { padding:24px 28px 40px; max-width:760px; }
        .card { background:var(--white); border:1px solid var(--border); border-radius:12px; box-shadow:var(--shadow); }

        .detail-header { padding:24px 28px 20px; border-bottom:1px solid var(--border); }
        .detail-title { font-size:22px; font-weight:700; color:var(--text-dark); margin-bottom:12px; }
        .detail-meta { display:flex; align-items:center; gap:10px; flex-wrap:wrap; }

        .badge { display:inline-flex; align-items:center; gap:4px; padding:3px 10px; border-radius:20px; font-size:12px; font-weight:500; border:1px solid; white-space:nowrap; }
        .badge-high     { color:var(--red);    background:var(--red-bg);    border-color:var(--red-border); }
        .badge-med      { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .badge-low      { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .badge-complete { color:var(--green);  background:var(--green-bg);  border-color:var(--green-border); }
        .badge-pending  { color:var(--orange); background:var(--orange-bg); border-color:var(--orange-border); }
        .meta-pill { display:inline-flex; align-items:center; gap:5px; padding:3px 10px; border-radius:20px; font-size:12px; font-weight:500; background:rgba(74,111,165,0.10); color:#3a5a8c; border:1px solid #b8cde8; }
        .meta-pill i { font-size:13px; }

        .detail-body { padding:24px 28px; display:flex; flex-direction:column; gap:20px; }
        .field-label { font-size:11px; font-weight:600; letter-spacing:0.7px; text-transform:uppercase; color:var(--text-muted); margin-bottom:6px; }
        .field-value { font-size:14px; color:var(--text-dark); line-height:1.6; }
        .field-value.desc { background:var(--bg); border:1px solid var(--border); border-radius:8px; padding:14px 16px; line-height:1.7; }

        .detail-footer { padding:16px 28px; border-top:1px solid var(--border); background:#f8fbff; border-radius:0 0 12px 12px; }
        .btn-back { display:inline-flex; align-items:center; gap:6px; padding:9px 18px; border-radius:8px; background:var(--topbar); color:#fff; font-size:13.5px; font-weight:600; text-decoration:none; transition:background 0.15s; }
        .btn-back:hover { background:var(--hero-dark); }
        .not-found { padding:60px 28px; text-align:center; color:var(--text-muted); }
    </style>
</head>
<body>
    <form id="frmTaskDetail" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Main</div>
                <a class="nav-item" href="StudentDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">My Dashboard</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class="nav-item" href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-book"></i>
                            <span class="nav-item-label"><%# Eval("ClassName") %></span>
                            <%# Convert.ToInt32(Eval("PendingCount")) > 0
                                ? "<span class='nav-badge" + (Convert.ToInt32(Eval("OverdueCount")) > 0 ? " overdue" : "") + "'>" + Eval("PendingCount") + "</span>"
                                : "" %>
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
                    <i class="ti ti-chevron-right sep"></i>
                    <a href="StudentDashboard.aspx">My Dashboard</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current">Task Detail</span>
                </div>
            </header>

            <%-- Compact subheader replaces the hero - task detail does not need hero-level prominence --%>
            <div class="page-subheader">
                <div class="page-subheader-icon" style="background:#e8f0fa;"><i class="ti ti-file-description" style="color:#3a5a8c;"></i></div>
                <div>
                    <div class="page-subheader-title">Task Detail</div>
                    <div class="page-subheader-sub">Full details for this homework task.</div>
                </div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlTask" runat="server" Visible="false">
                    <div class="card">
                        <div class="detail-header">
                            <div class="detail-title"><asp:Label ID="lblTitle" runat="server" /></div>
                            <div class="detail-meta">
                                <asp:Label ID="lblPriorityBadge" runat="server" />
                                <asp:Label ID="lblStatusBadge"   runat="server" />
                                <span class="meta-pill"><i class="ti ti-book"></i><asp:Label ID="lblSubject" runat="server" /></span>
                                <span class="meta-pill"><i class="ti ti-school"></i><asp:Label ID="lblClass" runat="server" /></span>
                            </div>
                        </div>
                        <div class="detail-body">
                            <div>
                                <div class="field-label">Due Date</div>
                                <div class="field-value"><asp:Label ID="lblDueDate" runat="server" /></div>
                            </div>
                            <div>
                                <div class="field-label">Description</div>
                                <div class="field-value desc"><asp:Label ID="lblDescription" runat="server" /></div>
                            </div>
                        </div>
                        <div class="detail-footer">
                            <a class="btn-back" href="StudentDashboard.aspx"><i class="ti ti-arrow-left"></i> Back to Dashboard</a>
                        </div>
                    </div>
                </asp:Panel>

                <asp:Panel ID="pnlNotFound" runat="server" Visible="false">
                    <div class="card">
                        <div class="not-found">
                            Task not found or you do not have access to it.<br /><br />
                            <a href="StudentDashboard.aspx" style="color:var(--topbar);">Back to Dashboard</a>
                        </div>
                    </div>
                </asp:Panel>

            </div>
        </div>

    </form>
</body>
</html>