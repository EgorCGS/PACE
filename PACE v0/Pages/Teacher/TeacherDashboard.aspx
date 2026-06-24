<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TeacherDashboard.aspx.cs" Inherits="PACE.TeacherDashboard" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>PACE - Teacher Dashboard</title>
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
            font-family: 'DM Sans', sans-serif;
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
            transition: background 0.15s, color 0.15s;
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
            transition: color 0.15s, background 0.15s;
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

            .breadcrumb .current {
                color: #fff;
                font-weight: 500;
            }

        .hero {
            background: linear-gradient(130deg, var(--hero-dark) 0%, var(--topbar) 100%);
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
            padding: 32px 28px 40px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .action-card {
            background: var(--white);
            border: 1px solid var(--border);
            border-radius: 12px;
            box-shadow: var(--shadow);
            padding: 28px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        .action-card-icon {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
        }

        .action-card h3 {
            font-size: 16px;
            font-weight: 600;
        }

        .action-card p {
            font-size: 13px;
            color: var(--text-muted);
            line-height: 1.5;
        }

        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 9px 18px;
            border-radius: 8px;
            background: var(--topbar);
            color: #fff;
            font-size: 13.5px;
            font-weight: 600;
            font-family: 'DM Sans', sans-serif;
            border: none;
            cursor: pointer;
            text-decoration: none;
            margin-top: 4px;
            transition: background 0.15s;
        }

            .btn-action:hover {
                background: var(--hero-dark);
            }

            .btn-action i {
                font-size: 16px;
            }
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
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn-logout" OnClick="btnLogout_Click">
                    <i class="ti ti-logout"></i>
                </asp:LinkButton>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="breadcrumb">
                    <span>PACE</span>&nbsp;&rsaquo;&nbsp;<span class="current">Teacher Dashboard</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Teacher Dashboard</div>
                <div class="hero-sub">
                    Welcome back,
                    <asp:Label ID="lblHeroName" runat="server" />. What would you like to do?
                </div>
            </div>

            <div class="content">

                <div class="action-card">
                    <div class="action-card-icon" style="background: #e8f0fa;">
                        <i class="ti ti-plus" style="color: #3a5a8c;"></i>
                    </div>
                    <h3>Create a Task</h3>
                    <p>Add a new homework task and assign it to one of your classes. Set the title, subject, description, due date, and priority level.</p>
                    <a class="btn-action" href="CreateTask.aspx">
                        <i class="ti ti-plus"></i>Create Task
                    </a>
                </div>

                <div class="action-card">
                    <div class="action-card-icon" style="background: #eef8f3;">
                        <i class="ti ti-chart-bar" style="color: #3a9e6e;"></i>
                    </div>
                    <h3>View Statistics</h3>
                    <p>See class-wide and per-student completion rates for all assigned tasks. Coming in the next build.</p>
                    <a class="btn-action" href="#" style="background: #aac4dc;">
                        <i class="ti ti-chart-bar"></i>Coming Soon
                    </a>
                </div>

            </div>
        </div>

    </form>
</body>
</html>
