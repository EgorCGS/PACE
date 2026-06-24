<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Statistics.aspx.cs" Inherits="PACE.Statistics" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Statistics</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <style>
        :root {
            --bg: #ddeaf7;
            --sidebar: #4a6fa5;
            --topbar: #5b7db8;
            --hero-dark: #3a5a8c;
            --text-dark: #1a2d42;
            --text-muted: #7a9fbe;
            --white: #ffffff;
            --border: #c5daf0;
            --input-bg: #f0f5fb;
            --red: #d95c5c;
            --red-bg: #fdf0f0;
            --red-border: #f0b8b8;
            --orange: #d4882a;
            --orange-bg: #fef7ee;
            --orange-border: #f0d0a0;
            --green: #3a9e6e;
            --green-bg: #eef8f3;
            --green-border: #a8d9c0;
            --sidebar-w: 258px;
            --topbar-h: 58px;
            --shadow: 0 2px 8px rgba(74,111,165,0.10);
        }

        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        html, body {
            font-family: 'DM Sans',sans-serif;
            background: var(--bg);
            color: var(--text-dark);
            font-size: 14px;
        }

        .sidebar {
            position: fixed;
            left: 0;
            top: 0;
            bottom: 0;
            width: var(--sidebar-w);
            background: var(--sidebar);
            display: flex;
            flex-direction: column;
            z-index: 300;
            overflow-y: auto;
        }

        .sidebar-logo {
            padding: 24px 20px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.12);
        }

        .logo-title {
            font-size: 22px;
            font-weight: 700;
            color: #fff;
            letter-spacing: -0.5px;
        }

        .logo-sub {
            font-size: 11px;
            color: rgba(255,255,255,0.55);
            margin-top: 2px;
        }

        .sidebar-nav {
            flex: 1;
            padding: 12px 0;
        }

        .nav-section-label {
            padding: 14px 20px 5px;
            font-size: 10.5px;
            font-weight: 600;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            color: rgba(255,255,255,0.38);
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 9px 16px 9px 20px;
            margin: 1px 8px;
            border-radius: 8px;
            color: rgba(255,255,255,0.70);
            font-size: 13.5px;
            text-decoration: none;
            transition: background 0.15s,color 0.15s;
        }

            .nav-item:hover {
                background: rgba(255,255,255,0.12);
                color: #fff;
            }

            .nav-item.active {
                background: rgba(255,255,255,0.18);
                color: #fff;
                font-weight: 600;
            }

            .nav-item i {
                font-size: 17px;
                flex-shrink: 0;
            }

        .nav-item-label {
            flex: 1;
        }

        .sidebar-user {
            padding: 14px 16px;
            border-top: 1px solid rgba(255,255,255,0.12);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .user-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: rgba(255,255,255,0.22);
            color: #fff;
            font-size: 13px;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .user-info {
            flex: 1;
            min-width: 0;
        }

        .user-name {
            font-size: 13px;
            font-weight: 600;
            color: #fff;
        }

        .user-role {
            font-size: 11px;
            color: rgba(255,255,255,0.50);
        }

        .btn-logout {
            background: none;
            border: none;
            color: rgba(255,255,255,0.45);
            cursor: pointer;
            padding: 4px;
            border-radius: 6px;
            transition: color 0.15s,background 0.15s;
            text-decoration: none;
        }

            .btn-logout:hover {
                color: #fff;
                background: rgba(255,255,255,0.12);
            }

            .btn-logout i {
                font-size: 18px;
                display: block;
            }

        .main {
            margin-left: var(--sidebar-w);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .topbar {
            position: sticky;
            top: 0;
            z-index: 200;
            height: var(--topbar-h);
            background: var(--topbar);
            display: flex;
            align-items: center;
            padding: 0 28px;
            box-shadow: 0 2px 10px rgba(58,90,140,0.18);
        }

        .breadcrumb {
            font-size: 13px;
            color: rgba(255,255,255,0.65);
        }

            .breadcrumb a {
                color: rgba(255,255,255,0.65);
                text-decoration: none;
            }

            .breadcrumb .current {
                color: #fff;
                font-weight: 500;
            }

        .hero {
            background: linear-gradient(130deg,var(--hero-dark) 0%,var(--topbar) 100%);
            padding: 30px 28px 28px;
        }

        .hero-title {
            font-size: 28px;
            font-weight: 700;
            color: #fff;
            letter-spacing: -0.5px;
        }

        .hero-sub {
            font-size: 14px;
            color: rgba(255,255,255,0.62);
            margin-top: 4px;
        }

        .content {
            padding: 24px 28px 40px;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        /* Selector card */
        .card {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: 12px;
            box-shadow: var(--shadow);
        }

        .card-header {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 16px 20px 14px;
            border-bottom: 1px solid var(--border);
        }

        .card-header-icon {
            width: 34px;
            height: 34px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }

        .card-header-title {
            font-size: 15px;
            font-weight: 600;
            flex: 1;
        }

        .selector-body {
            padding: 20px;
            display: flex;
            gap: 16px;
            align-items: flex-end;
        }

        .selector-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
            max-width: 340px;
        }

        .selector-label {
            font-size: 12.5px;
            font-weight: 600;
        }

        .form-select {
            width: 100%;
            padding: 9px 34px 9px 12px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            background: var(--input-bg) url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%237a9fbe' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E") no-repeat right 10px center;
            font-family: 'DM Sans',sans-serif;
            font-size: 13.5px;
            color: var(--text-dark);
            outline: none;
            appearance: none;
            transition: border-color 0.15s;
        }

            .form-select:focus {
                border-color: var(--topbar);
                background-color: #fff;
            }

        /* Summary numbers */
        .summary-strip {
            display: grid;
            grid-template-columns: repeat(3,1fr);
            gap: 16px;
        }

        .summary-card {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: 12px;
            box-shadow: var(--shadow);
            padding: 20px 24px;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .summary-number {
            font-size: 32px;
            font-weight: 700;
            color: var(--topbar);
            line-height: 1;
        }

        .summary-label {
            font-size: 12.5px;
            color: var(--text-muted);
            font-weight: 500;
        }

        /* Two column layout for task and student tables */
        .stats-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        /* Task stats table */
        .stats-table {
            width: 100%;
            border-collapse: collapse;
        }

            .stats-table thead th {
                padding: 10px 16px;
                text-align: left;
                font-size: 11px;
                font-weight: 600;
                letter-spacing: 0.7px;
                text-transform: uppercase;
                color: var(--text-muted);
                background: var(--bg);
                border-bottom: 1px solid var(--border);
            }

                .stats-table thead th:first-child {
                    padding-left: 20px;
                }

            .stats-table tbody tr {
                border-bottom: 1px solid var(--border);
                transition: background 0.12s;
            }

                .stats-table tbody tr:last-child {
                    border-bottom: none;
                }

                .stats-table tbody tr:hover {
                    background: #f7f9fd;
                }

            .stats-table td {
                padding: 12px 16px;
                vertical-align: middle;
                font-size: 13.5px;
            }

                .stats-table td:first-child {
                    padding-left: 20px;
                    font-weight: 600;
                }

        /* Inline progress bar */
        .pct-cell {
            min-width: 160px;
        }

        .pct-row {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .pct-label {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-dark);
            min-width: 36px;
            text-align: right;
        }

        .pct-track {
            flex: 1;
            height: 7px;
            border-radius: 10px;
            background: var(--bg);
            border: 1px solid var(--border);
            overflow: hidden;
        }

        .pct-fill {
            height: 100%;
            border-radius: 10px;
            background: linear-gradient(90deg,var(--sidebar) 0%,var(--topbar) 100%);
            transition: width 0.6s ease;
        }

            .pct-fill.green {
                background: linear-gradient(90deg,#2d8a5f 0%,var(--green) 100%);
            }

            .pct-fill.orange {
                background: linear-gradient(90deg,#b86e10 0%,var(--orange) 100%);
            }

            .pct-fill.zero {
                background: var(--border);
            }

        /* Fraction display */
        .fraction {
            font-size: 12px;
            color: var(--text-muted);
        }

        .hint-state {
            padding: 40px 20px;
            text-align: center;
            color: var(--text-muted);
            font-size: 13px;
        }

        .empty-state {
            padding: 40px 20px;
            text-align: center;
            color: var(--text-muted);
        }
    </style>
</head>
<body>
    <form id="frmStatistics" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Overview</div>
                <a class="nav-item" href="TeacherDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">Dashboard</span></a>
                <a class="nav-item active" href="Statistics.aspx"><i class="ti ti-chart-bar"></i><span class="nav-item-label">Statistics</span></a>
                <div class="nav-section-label">Tasks</div>
                <a class="nav-item" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
                <a class="nav-item" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
                <a class="nav-item" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class="nav-item" href='TeacherClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
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
                    <a href="TeacherDashboard.aspx">PACE</a>&nbsp;&rsaquo;&nbsp;<span class="current">Statistics</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Statistics</div>
                <div class="hero-sub">View class-wide and per-student homework completion rates.</div>
            </div>

            <div class="content">

                <%-- Class selector --%>
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background: #e8f0fa;"><i class="ti ti-filter" style="color: #3a5a8c; font-size: 17px;"></i></div>
                        <span class="card-header-title">Select Class</span>
                    </div>
                    <div class="selector-body">
                        <div class="selector-group">
                            <label class="selector-label">Class</label>
                            <asp:DropDownList ID="ddlClass" runat="server" CssClass="form-select"
                                AutoPostBack="true" OnSelectedIndexChanged="ddlClass_SelectedIndexChanged" />
                        </div>
                    </div>
                </div>

                <%-- Shown before a class is selected --%>
                <asp:Panel ID="pnlHint" runat="server">
                    <div class="card">
                        <div class="hint-state">Select a class above to load its completion statistics.</div>
                    </div>
                </asp:Panel>

                <%-- Stats area, shown after class is selected --%>
                <asp:Panel ID="pnlStats" runat="server" Visible="false">

                    <%-- Three summary numbers across the top --%>
                    <div class="summary-strip">
                        <div class="summary-card">
                            <div class="summary-number">
                                <asp:Label ID="lblTotalStudents" runat="server" /></div>
                            <div class="summary-label">Students enrolled</div>
                        </div>
                        <div class="summary-card">
                            <div class="summary-number">
                                <asp:Label ID="lblTotalTasks" runat="server" /></div>
                            <div class="summary-label">Tasks assigned</div>
                        </div>
                        <div class="summary-card">
                            <div class="summary-number">
                                <asp:Label ID="lblOverallPct" runat="server" /></div>
                            <div class="summary-label">Overall completion rate</div>
                        </div>
                    </div>

                    <%-- Task and student tables side by side --%>
                    <div class="stats-grid">

                        <%-- Left: task completion rates --%>
                        <div class="card">
                            <div class="card-header">
                                <div class="card-header-icon" style="background: #e8f0fa;"><i class="ti ti-checklist" style="color: #3a5a8c; font-size: 17px;"></i></div>
                                <span class="card-header-title">By Task</span>
                            </div>
                            <asp:Repeater ID="rptTaskStats" runat="server">
                                <HeaderTemplate>
                                    <table class="stats-table">
                                        <thead>
                                            <tr>
                                                <th>Task</th>
                                                <th>Completed</th>
                                                <th class="pct-cell">Progress</th>
                                            </tr>
                                        </thead>
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
                                                    <div class="pct-fill <%# GetPctClass(Eval("Percentage")) %>"
                                                        style="width: <%# string.Format("{0:0}", Eval("Percentage")) %>%">
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                                <FooterTemplate></tbody></table></FooterTemplate>
                            </asp:Repeater>
                            <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                                <div class="empty-state">No tasks assigned yet.</div>
                            </asp:Panel>
                        </div>

                        <%-- Right: per-student breakdown --%>
                        <div class="card">
                            <div class="card-header">
                                <div class="card-header-icon" style="background: #eef8f3;"><i class="ti ti-users" style="color: #3a9e6e; font-size: 17px;"></i></div>
                                <span class="card-header-title">By Student</span>
                            </div>
                            <asp:Repeater ID="rptStudentStats" runat="server">
                                <HeaderTemplate>
                                    <table class="stats-table">
                                        <thead>
                                            <tr>
                                                <th>Student</th>
                                                <th>Completed</th>
                                                <th class="pct-cell">Progress</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                </HeaderTemplate>
                                <ItemTemplate>
                                    <tr>
                                        <td><%# Eval("FullName") %></td>
                                        <td><span class="fraction"><%# Eval("TasksCompleted") %> / <%# Eval("TotalTasks") %></span></td>
                                        <td class="pct-cell">
                                            <div class="pct-row">
                                                <span class="pct-label"><%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%</span>
                                                <div class="pct-track">
                                                    <div class="pct-fill <%# GetPctClass(GetStudentPctRaw(Eval("TasksCompleted"), Eval("TotalTasks"))) %>"
                                                        style="width: <%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%">
                                                    </div>
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
                </asp:Panel>

            </div>
        </div>

    </form>
</body>
</html>
