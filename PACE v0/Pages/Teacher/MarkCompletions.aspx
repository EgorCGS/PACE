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
        }

        .selector-label {
            font-size: 12.5px;
            font-weight: 600;
            color: var(--text-dark);
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

        /* Student completion list */
        .student-list {
            padding: 8px 0 4px;
        }

        .student-row {
            display: flex;
            align-items: center;
            gap: 16px;
            padding: 12px 20px;
            border-bottom: 1px solid var(--border);
            transition: background 0.12s;
        }

            .student-row:last-child {
                border-bottom: none;
            }

            .student-row:hover {
                background: #f7f9fd;
            }

        .student-name {
            flex: 1;
            font-size: 14px;
            font-weight: 500;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            padding: 2px 8px;
            border-radius: 20px;
            font-size: 11.5px;
            font-weight: 500;
            border: 1px solid;
            white-space: nowrap;
        }

        .badge-complete {
            color: var(--green);
            background: var(--green-bg);
            border-color: var(--green-border);
        }

        .badge-pending {
            color: var(--orange);
            background: var(--orange-bg);
            border-color: var(--orange-border);
        }

        .btn-mark {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 6px 14px;
            border-radius: 7px;
            background: var(--green-bg);
            color: var(--green);
            font-size: 12.5px;
            font-weight: 600;
            font-family: 'DM Sans',sans-serif;
            border: 1px solid var(--green-border);
            cursor: pointer;
            text-decoration: none;
            transition: background 0.15s;
        }

            .btn-mark:hover {
                background: #d4f0e0;
            }

        .btn-unmark {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 6px 14px;
            border-radius: 7px;
            background: var(--red-bg);
            color: var(--red);
            font-size: 12.5px;
            font-weight: 600;
            font-family: 'DM Sans',sans-serif;
            border: 1px solid var(--red-border);
            cursor: pointer;
            text-decoration: none;
            transition: background 0.15s;
        }

            .btn-unmark:hover {
                background: #f8e0e0;
            }

        .empty-state {
            padding: 40px 20px;
            text-align: center;
            color: var(--text-muted);
        }

        .hint-state {
            padding: 40px 20px;
            text-align: center;
            color: var(--text-muted);
            font-size: 13px;
        }

        .alert-success {
            background: var(--green-bg);
            border: 1px solid var(--green-border);
            border-radius: 8px;
            padding: 12px 16px;
            color: var(--green);
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
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
                <a class="nav-item" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
                <a class="nav-item" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
                <a class="nav-item active" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
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
                    <a href="TeacherDashboard.aspx">PACE</a>&nbsp;&rsaquo;&nbsp;<span class="current">Mark Completions</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Mark Completions</div>
                <div class="hero-sub">Select a class and task to mark which students have completed it.</div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                    <div class="alert-success"><i class="ti ti-circle-check" style="font-size: 18px;"></i>
                        <asp:Label ID="lblSuccess" runat="server" /></div>
                </asp:Panel>

                <%-- Step 1: select class and task --%>
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background: #e8f0fa;"><i class="ti ti-filter" style="color: #3a5a8c; font-size: 17px;"></i></div>
                        <span class="card-header-title">Select Class and Task</span>
                    </div>
                    <div class="selector-body">
                        <div class="selector-group">
                            <label class="selector-label">Class</label>
                            <%-- AutoPostBack populates the task dropdown when class changes --%>
                            <asp:DropDownList ID="ddlClass" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="ddlClass_SelectedIndexChanged" />
                        </div>
                        <div class="selector-group">
                            <label class="selector-label">Task</label>
                            <%-- AutoPostBack loads the student list when task changes --%>
                            <asp:DropDownList ID="ddlTask" runat="server" CssClass="form-select" AutoPostBack="true" OnSelectedIndexChanged="ddlTask_SelectedIndexChanged" />
                        </div>
                    </div>
                </div>

                <%-- Step 2: student completion list --%>
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background: #eef8f3;"><i class="ti ti-users" style="color: #3a9e6e; font-size: 17px;"></i></div>
                        <span class="card-header-title">Student Completions</span>
                        <span style="font-size: 13px; color: var(--text-muted); margin-left: auto;">
                            <asp:Label ID="lblCompletionSummary" runat="server" /></span>
                    </div>

                    <%-- Shown before a task is selected --%>
                    <asp:Panel ID="pnlHint" runat="server">
                        <div class="hint-state">Select a class and task above to see the student completion list.</div>
                    </asp:Panel>

                    <%-- Student list, shown when a task is selected --%>
                    <asp:Panel ID="pnlStudents" runat="server" Visible="false">
                        <div class="student-list">
                            <asp:Repeater ID="rptStudents" runat="server">
                                <ItemTemplate>
                                    <div class="student-row">
                                        <span class="student-name"><%# Eval("FullName") %></span>
                                        <%# GetStatusBadge(Eval("MarkedComplete")) %>
                                        <%-- Mark/Unmark button uses CommandName to tell the handler what to do --%>
                                        <asp:LinkButton runat="server"
                                            CssClass='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "btn-unmark" : "btn-mark" %>'
                                            CommandName='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "Unmark" : "Mark" %>'
                                            CommandArgument='<%# Eval("StudentID") %>'
                                            OnCommand="StudentCommand">
                                            <%# Convert.ToBoolean(Eval("MarkedComplete")) ? "Unmark" : "Mark Complete" %>
                                        </asp:LinkButton>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>
                        </div>
                        <asp:Panel ID="pnlNoStudents" runat="server" Visible="false">
                            <div class="empty-state">No students enrolled in this class.</div>
                        </asp:Panel>
                    </asp:Panel>

                </div>

            </div>
        </div>

    </form>
</body>
</html>
