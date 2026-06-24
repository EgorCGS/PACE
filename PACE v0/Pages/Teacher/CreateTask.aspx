<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="CreateTask.aspx.cs" Inherits="PACE.CreateTask" %>

<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>PACE - Create Task</title>
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

            .breadcrumb a {
                color: rgba(255,255,255,0.65);
                text-decoration: none;
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
            padding: 24px 28px 40px;
        }

        .content-layout {
            display: flex;
            gap: 20px;
            align-items: flex-start;
        }

        .form-column {
            flex: 1;
            min-width: 0;
        }

        .panel-column {
            width: 290px;
            flex-shrink: 0;
            display: flex;
            flex-direction: column;
            gap: 16px;
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
            justify-content: space-between;
            padding: 16px 20px 14px;
            border-bottom: 1px solid var(--border);
        }

        .card-header-left {
            display: flex;
            align-items: center;
            gap: 10px;
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
        }

        .required-note {
            font-size: 12px;
            color: var(--text-muted);
            font-style: italic;
        }

            .required-note span {
                color: var(--red);
                font-style: normal;
            }

        .form-body {
            padding: 20px;
            display: flex;
            flex-direction: column;
            gap: 18px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }

        .form-label {
            font-size: 12.5px;
            font-weight: 600;
            color: var(--text-dark);
        }

            .form-label .req {
                color: var(--red);
                margin-left: 2px;
            }

        .form-hint {
            font-size: 11.5px;
            color: var(--text-muted);
        }

        .form-select, .form-input {
            width: 100%;
            padding: 9px 12px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            background: var(--input-bg);
            font-family: 'DM Sans', sans-serif;
            font-size: 13.5px;
            color: var(--text-dark);
            outline: none;
            transition: border-color 0.15s, box-shadow 0.15s;
            appearance: none;
        }

        .form-select {
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%237a9fbe' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 10px center;
            padding-right: 34px;
        }

            .form-select:focus, .form-input:focus {
                border-color: var(--topbar);
                box-shadow: 0 0 0 3px rgba(91,125,184,0.14);
                background: #fff;
            }

        .form-input::placeholder {
            color: var(--text-muted);
        }

        .form-input.error {
            border-color: var(--red);
            background: var(--red-bg);
        }

        .form-textarea {
            width: 100%;
            padding: 9px 12px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            background: var(--input-bg);
            font-family: 'DM Sans', sans-serif;
            font-size: 13.5px;
            color: var(--text-dark);
            outline: none;
            resize: vertical;
            min-height: 100px;
            transition: border-color 0.15s, box-shadow 0.15s;
        }

            .form-textarea:focus {
                border-color: var(--topbar);
                box-shadow: 0 0 0 3px rgba(91,125,184,0.14);
                background: #fff;
            }

        .error-msg {
            font-size: 12px;
            color: var(--red);
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 4px;
            margin-top: 2px;
        }

            .error-msg i {
                font-size: 14px;
            }

        .priority-toggle {
            display: grid;
            grid-template-columns: 1fr 1fr 1fr;
            gap: 0;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
        }

        .prio-btn {
            padding: 9px 0;
            text-align: center;
            font-size: 13px;
            font-weight: 500;
            cursor: pointer;
            background: var(--input-bg);
            color: var(--text-muted);
            border: none;
            border-right: 1px solid var(--border);
            font-family: 'DM Sans', sans-serif;
            transition: background 0.15s, color 0.15s;
        }

            .prio-btn:last-child {
                border-right: none;
            }

            .prio-btn:hover {
                background: #e4edf9;
                color: var(--text-dark);
            }

            .prio-btn.sel-high {
                background: var(--red-bg);
                color: var(--red);
                font-weight: 600;
            }

            .prio-btn.sel-med {
                background: var(--orange-bg);
                color: var(--orange);
                font-weight: 600;
            }

            .prio-btn.sel-low {
                background: var(--green-bg);
                color: var(--green);
                font-weight: 600;
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
            font-family: 'DM Sans', sans-serif;
            border: none;
            cursor: pointer;
            transition: background 0.15s;
        }

            .btn-primary:hover {
                background: var(--hero-dark);
            }

            .btn-primary i {
                font-size: 16px;
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
            font-family: 'DM Sans', sans-serif;
            border: 1.5px solid var(--border);
            cursor: pointer;
            transition: all 0.15s;
            text-decoration: none;
        }

            .btn-ghost:hover {
                background: var(--bg);
                color: var(--text-dark);
                border-color: var(--topbar);
            }

        .alert-success {
            background: var(--green-bg);
            border: 1px solid var(--green-border);
            border-radius: 8px;
            padding: 12px 16px;
            color: var(--green);
            margin-bottom: 16px;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Right panel */
        .panel-card-header {
            display: flex;
            align-items: center;
            gap: 9px;
            padding: 14px 16px 12px;
            border-bottom: 1px solid var(--border);
        }

        .panel-card-icon {
            width: 30px;
            height: 30px;
            border-radius: 7px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 15px;
            flex-shrink: 0;
        }

        .panel-card-title {
            font-size: 13.5px;
            font-weight: 600;
        }

        .val-list {
            padding: 10px 16px 14px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        }

        .val-rule {
            display: flex;
            gap: 10px;
            align-items: flex-start;
        }

        .val-rule-text {
            font-size: 12.5px;
            color: var(--text-dark);
            line-height: 1.45;
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
            flex-shrink: 0;
        }

        .badge-existence {
            color: #3a5a8c;
            background: #e8f0fa;
            border-color: #b8cde8;
        }

        .badge-type {
            color: #6b3db0;
            background: #f1ecfa;
            border-color: #cdb0e8;
        }

        .badge-range {
            color: var(--green);
            background: var(--green-bg);
            border-color: var(--green-border);
        }
    </style>
</head>
<body>
    <form id="frmCreateTask" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Overview</div>
                <a class="nav-item" href="TeacherDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">Dashboard</span></a>
                <div class="nav-section-label">Tasks</div>
                <a class="nav-item active" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
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
                    <a href="TeacherDashboard.aspx">PACE</a>&nbsp;&rsaquo;&nbsp;
                    <a href="TeacherDashboard.aspx">Tasks</a>&nbsp;&rsaquo;&nbsp;
                    <span class="current">Create Task</span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title">Create Task</div>
                <div class="hero-sub">Add a new homework task and assign it to one of your classes.</div>
            </div>

            <div class="content">

                <%-- Success message, shown after a task is created successfully --%>
                <asp:Panel ID="pnlSuccess" runat="server" Visible="false">
                    <div class="alert-success">
                        <i class="ti ti-circle-check" style="font-size: 18px;"></i>
                        <asp:Label ID="lblSuccess" runat="server" />
                    </div>
                </asp:Panel>

                <div class="content-layout">

                    <%-- Left: form card --%>
                    <div class="form-column">
                        <div class="card">
                            <div class="card-header">
                                <div class="card-header-left">
                                    <div class="card-header-icon" style="background: #e8f0fa;">
                                        <i class="ti ti-pencil-plus" style="color: #3a5a8c; font-size: 17px;"></i>
                                    </div>
                                    <span class="card-header-title">Task Details</span>
                                </div>
                                <span class="required-note">Fields marked with <span>*</span> are required</span>
                            </div>

                            <div class="form-body">

                                <%-- Assign to class dropdown, populated by SchoolClass.GetClassesByTeacher() --%>
                                <div class="form-group">
                                    <label class="form-label">Assign to Class <span class="req">*</span></label>
                                    <asp:DropDownList ID="ddlClass" runat="server" CssClass="form-select" />
                                    <span class="form-hint">Only your own classes are shown.</span>
                                    <asp:Label ID="lblClassError" runat="server" CssClass="error-msg" Visible="false"><i class="ti ti-alert-circle"></i> Please select a class.</asp:Label>
                                </div>

                                <%-- Title and Subject side by side --%>
                                <div class="form-row">
                                    <div class="form-group">
                                        <label class="form-label">Task Title <span class="req">*</span></label>
                                        <asp:TextBox ID="txtTitle" runat="server" CssClass="form-input" placeholder="e.g. Exercises 4A" MaxLength="150" />
                                        <asp:Label ID="lblTitleError" runat="server" CssClass="error-msg" Visible="false"><i class="ti ti-alert-circle"></i> Title is required.</asp:Label>
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">Subject <span class="req">*</span></label>
                                        <asp:TextBox ID="txtSubject" runat="server" CssClass="form-input" placeholder="e.g. Mathematics" MaxLength="100" />
                                        <asp:Label ID="lblSubjectError" runat="server" CssClass="error-msg" Visible="false"><i class="ti ti-alert-circle"></i> Subject is required.</asp:Label>
                                    </div>
                                </div>

                                <%-- Description --%>
                                <div class="form-group">
                                    <label class="form-label">Description <span class="req">*</span></label>
                                    <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="form-textarea" placeholder="Describe the task in detail..." />
                                    <asp:Label ID="lblDescError" runat="server" CssClass="error-msg" Visible="false"><i class="ti ti-alert-circle"></i> Description is required.</asp:Label>
                                </div>

                                <%-- Due date and priority side by side --%>
                                <div class="form-row">
                                    <div class="form-group">
                                        <label class="form-label">Due Date <span class="req">*</span></label>
                                        <asp:TextBox ID="txtDueDate" runat="server" CssClass="form-input" placeholder="DD/MM/YYYY" MaxLength="10" />
                                        <asp:Label ID="lblDateError" runat="server" CssClass="error-msg" Visible="false"><i class="ti ti-alert-circle"></i> Must be a valid date in DD/MM/YYYY format.</asp:Label>
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">Priority <span class="req">*</span></label>
                                        <%-- Three-button toggle. JavaScript sets the hidden field value. --%>
                                        <div class="priority-toggle">
                                            <button type="button" class="prio-btn" id="btnHigh" onclick="setPriority(3, 'sel-high')">High</button>
                                            <button type="button" class="prio-btn sel-med" id="btnMed" onclick="setPriority(2, 'sel-med')">Med</button>
                                            <button type="button" class="prio-btn" id="btnLow" onclick="setPriority(1, 'sel-low')">Low</button>
                                        </div>
                                        <asp:HiddenField ID="hdnPriority" runat="server" Value="2" />
                                    </div>
                                </div>

                            </div>

                            <div class="form-footer">
                                <asp:LinkButton ID="btnCreateTask" runat="server" CssClass="btn-primary" OnClick="btnCreateTask_Click">
                                    <i class="ti ti-plus"></i> Create Task
                                </asp:LinkButton>
                                <a class="btn-ghost" href="TeacherDashboard.aspx">Cancel</a>
                            </div>
                        </div>
                    </div>

                    <%-- Right: validation rules card --%>
                    <div class="panel-column">
                        <div class="card">
                            <div class="panel-card-header">
                                <div class="panel-card-icon" style="background: #f1ecfa;">
                                    <i class="ti ti-shield-check" style="color: #6b3db0;"></i>
                                </div>
                                <span class="panel-card-title">Validation Rules</span>
                            </div>
                            <div class="val-list">
                                <div class="val-rule">
                                    <span class="badge badge-existence">Existence</span>
                                    <span class="val-rule-text">All fields must be filled in before the task can be created.</span>
                                </div>
                                <div class="val-rule">
                                    <span class="badge badge-type">Type</span>
                                    <span class="val-rule-text">Due date must be a real calendar date in DD/MM/YYYY format.</span>
                                </div>
                                <div class="val-rule">
                                    <span class="badge badge-range">Range</span>
                                    <span class="val-rule-text">Priority must be one of three values: High, Med, or Low.</span>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </div>

    </form>

    <script>
        function setPriority(value, selectedClass) {
            document.getElementById('<%= hdnPriority.ClientID %>').value = value;
            document.querySelectorAll('.prio-btn').forEach(function (b) {
                b.classList.remove('sel-high', 'sel-med', 'sel-low');
            });
            var ids = { 3: 'btnHigh', 2: 'btnMed', 1: 'btnLow' };
            document.getElementById(ids[value]).classList.add(selectedClass);
        }

        // Restore the toggle visual state after a postback
        (function () {
            var val = parseInt(document.getElementById('<%= hdnPriority.ClientID %>').value);
            var map = { 3: ['btnHigh', 'sel-high'], 2: ['btnMed', 'sel-med'], 1: ['btnLow', 'sel-low'] };
            if (map[val]) document.getElementById(map[val][0]).classList.add(map[val][1]);
        }());
    </script>
</body>
</html>
