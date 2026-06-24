<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ManageTasks.aspx.cs" Inherits="PACE.ManageTasks" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Manage Tasks</title>
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

        /* Edit form */
        .form-body {
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 16px;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .form-label {
            font-size: 12.5px;
            font-weight: 600;
        }

        .form-input, .form-select, .form-textarea {
            width: 100%;
            padding: 9px 12px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            background: var(--input-bg);
            font-family: 'DM Sans',sans-serif;
            font-size: 13.5px;
            color: var(--text-dark);
            outline: none;
            transition: border-color 0.15s;
        }

        .form-select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%237a9fbe' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 10px center;
            padding-right: 34px;
        }

        .form-textarea {
            resize: vertical;
            min-height: 90px;
        }

            .form-input:focus, .form-select:focus, .form-textarea:focus {
                border-color: var(--topbar);
                background: #fff;
            }

        .form-footer {
            padding: 14px 20px;
            border-top: 1px solid var(--border);
            display: flex;
            align-items: center;
            gap: 10px;
            background: #f8fbff;
            border-radius: 0 0 12px 12px;
        }

        .btn-primary {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 9px 20px;
            border-radius: 8px;
            background: var(--topbar);
            color: #fff;
            font-size: 13.5px;
            font-weight: 600;
            font-family: 'DM Sans',sans-serif;
            border: none;
            cursor: pointer;
            transition: background 0.15s;
        }

            .btn-primary:hover {
                background: var(--hero-dark);
            }

        .btn-ghost {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 9px 16px;
            border-radius: 8px;
            background: transparent;
            color: var(--text-muted);
            font-size: 13.5px;
            font-weight: 500;
            font-family: 'DM Sans',sans-serif;
            border: 1.5px solid var(--border);
            cursor: pointer;
            transition: all 0.15s;
            text-decoration: none;
        }

            .btn-ghost:hover {
                background: var(--bg);
                color: var(--text-dark);
            }

        .edit-panel-title {
            font-size: 13px;
            color: var(--text-muted);
            margin-left: 4px;
        }

        .error-msg {
            font-size: 12px;
            color: var(--red);
            margin-top: 2px;
        }

        /* Task table */
        .table-card {
            overflow: hidden;
        }

        .task-table {
            width: 100%;
            border-collapse: collapse;
        }

            .task-table thead th {
                padding: 11px 14px;
                text-align: left;
                font-size: 11px;
                font-weight: 600;
                letter-spacing: 0.7px;
                text-transform: uppercase;
                color: var(--text-muted);
                background: var(--bg);
                border-bottom: 1px solid var(--border);
            }

                .task-table thead th:first-child {
                    padding-left: 18px;
                }

            .task-table tbody tr {
                border-bottom: 1px solid var(--border);
                transition: background 0.12s;
            }

                .task-table tbody tr:last-child {
                    border-bottom: none;
                }

                .task-table tbody tr:nth-child(even) {
                    background: #f7f9fd;
                }

                .task-table tbody tr:hover {
                    background: #eef3fb;
                }

            .task-table td {
                padding: 11px 14px;
                vertical-align: middle;
            }

                .task-table td:first-child {
                    padding-left: 18px;
                }

        .task-name {
            font-size: 13.5px;
            font-weight: 600;
        }

        .task-sub {
            font-size: 12px;
            color: var(--text-muted);
            margin-top: 1px;
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

        .badge-high {
            color: var(--red);
            background: var(--red-bg);
            border-color: var(--red-border);
        }

        .badge-med {
            color: var(--orange);
            background: var(--orange-bg);
            border-color: var(--orange-border);
        }

        .badge-low {
            color: var(--green);
            background: var(--green-bg);
            border-color: var(--green-border);
        }

        .btn-edit {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 5px 12px;
            border-radius: 7px;
            background: #e8f0fa;
            color: #3a5a8c;
            font-size: 12px;
            font-weight: 500;
            font-family: 'DM Sans',sans-serif;
            border: 1px solid #b8cde8;
            cursor: pointer;
            text-decoration: none;
            transition: background 0.15s;
        }

            .btn-edit:hover {
                background: #cddcee;
            }

        .btn-delete {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 5px 12px;
            border-radius: 7px;
            background: var(--red-bg);
            color: var(--red);
            font-size: 12px;
            font-weight: 500;
            font-family: 'DM Sans',sans-serif;
            border: 1px solid var(--red-border);
            cursor: pointer;
            text-decoration: none;
            transition: background 0.15s;
        }

            .btn-delete:hover {
                background: #f8e0e0;
            }

        .actions-cell {
            display: flex;
            gap: 6px;
            justify-content: flex-end;
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

        .alert-error {
            background: var(--red-bg);
            border: 1px solid var(--red-border);
            border-radius: 8px;
            padding: 12px 16px;
            color: var(--red);
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .empty-state {
            padding: 48px 20px;
            text-align: center;
            color: var(--text-muted);
        }
    </style>
</head>
<body>
    <form id="frmManageTasks" runat="server">

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
                <a class="nav-item active" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
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
                    <a href="TeacherDashboard.aspx">PACE</a>&nbsp;&rsaquo;&nbsp;<span class="current">Manage Tasks</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Manage Tasks</div>
                <div class="hero-sub">Edit or delete homework tasks you have created.</div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                    <div class="alert-success"><i class="ti ti-circle-check" style="font-size: 18px;"></i>
                        <asp:Label ID="lblSuccess" runat="server" /></div>
                </asp:Panel>
                <asp:Panel ID="pnlError" runat="server" Visible="false">
                    <div class="alert-error"><i class="ti ti-alert-circle" style="font-size: 18px;"></i>
                        <asp:Label ID="lblError" runat="server" /></div>
                </asp:Panel>

                <%-- Edit form, hidden until teacher clicks Edit on a task --%>
                <asp:Panel ID="pnlEditForm" runat="server" Visible="false">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background: #e8f0fa;"><i class="ti ti-pencil" style="color: #3a5a8c; font-size: 17px;"></i></div>
                            <span class="card-header-title">Edit Task</span>
                            <span class="edit-panel-title">
                                <asp:Label ID="lblEditTitle" runat="server" /></span>
                        </div>
                        <asp:HiddenField ID="hdnEditTaskID" runat="server" />
                        <div class="form-body">
                            <div class="form-row">
                                <div class="form-group">
                                    <label class="form-label">Task Title</label>
                                    <asp:TextBox ID="txtEditTitle" runat="server" CssClass="form-input" MaxLength="150" />
                                    <asp:Label ID="lblEditTitleError" runat="server" CssClass="error-msg" Visible="false">Title is required.</asp:Label>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Subject</label>
                                    <asp:TextBox ID="txtEditSubject" runat="server" CssClass="form-input" MaxLength="100" />
                                    <asp:Label ID="lblEditSubjectError" runat="server" CssClass="error-msg" Visible="false">Subject is required.</asp:Label>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="form-label">Description</label>
                                <asp:TextBox ID="txtEditDescription" runat="server" TextMode="MultiLine" CssClass="form-textarea" />
                                <asp:Label ID="lblEditDescError" runat="server" CssClass="error-msg" Visible="false">Description is required.</asp:Label>
                            </div>
                            <div class="form-row">
                                <div class="form-group">
                                    <label class="form-label">Due Date (DD/MM/YYYY)</label>
                                    <asp:TextBox ID="txtEditDueDate" runat="server" CssClass="form-input" placeholder="DD/MM/YYYY" MaxLength="10" />
                                    <asp:Label ID="lblEditDateError" runat="server" CssClass="error-msg" Visible="false">Must be a valid date in DD/MM/YYYY format.</asp:Label>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Priority</label>
                                    <asp:DropDownList ID="ddlEditPriority" runat="server" CssClass="form-select">
                                        <asp:ListItem Value="3">High</asp:ListItem>
                                        <asp:ListItem Value="2" Selected="True">Medium</asp:ListItem>
                                        <asp:ListItem Value="1">Low</asp:ListItem>
                                    </asp:DropDownList>
                                </div>
                            </div>
                        </div>
                        <div class="form-footer">
                            <asp:LinkButton ID="btnSaveEdit" runat="server" CssClass="btn-primary" OnClick="btnSaveEdit_Click"><i class="ti ti-device-floppy"></i> Save Changes</asp:LinkButton>
                            <asp:LinkButton ID="btnCancelEdit" runat="server" CssClass="btn-ghost" OnClick="btnCancelEdit_Click">Cancel</asp:LinkButton>
                        </div>
                    </div>
                </asp:Panel>

                <%-- Task list --%>
                <div class="card table-card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background: #e8f0fa;"><i class="ti ti-list" style="color: #3a5a8c; font-size: 17px;"></i></div>
                        <span class="card-header-title">All Tasks</span>
                        <span style="font-size: 13px; color: var(--text-muted); margin-left: auto;">
                            <asp:Label ID="lblTaskCount" runat="server" />
                            tasks</span>
                    </div>

                    <asp:Repeater ID="rptTasks" runat="server">
                        <HeaderTemplate>
                            <table class="task-table">
                                <thead>
                                    <tr>
                                        <th>Task</th>
                                        <th>Class</th>
                                        <th>Due Date</th>
                                        <th>Priority</th>
                                        <th style="text-align: right; padding-right: 18px;">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr>
                                <td>
                                    <div class="task-name"><%# Eval("Title") %></div>
                                    <div class="task-sub"><%# Eval("Subject") %></div>
                                </td>
                                <td><%# Eval("ClassName") %></td>
                                <td><%# Convert.ToDateTime(Eval("DueDate")).ToString("d MMM yyyy") %></td>
                                <td><%# GetPriorityBadge(Eval("PriorityLevel")) %></td>
                                <td>
                                    <div class="actions-cell">
                                        <asp:LinkButton runat="server" CssClass="btn-edit" CommandName="Edit" CommandArgument='<%# Eval("TaskID") %>' OnCommand="TaskCommand"><i class="ti ti-pencil"></i> Edit</asp:LinkButton>
                                        <asp:LinkButton runat="server" CssClass="btn-delete" CommandName="Delete" CommandArgument='<%# Eval("TaskID") %>' OnCommand="TaskCommand" OnClientClick="return confirm('Delete this task and all its completion records?');"><i class="ti ti-trash"></i> Delete</asp:LinkButton>
                                    </div>
                                </td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                        <div class="empty-state">No tasks yet. <a href="CreateTask.aspx">Create one.</a></div>
                    </asp:Panel>
                </div>

            </div>
        </div>
    </form>
</body>
</html>
