<%@ Page Language="C#" AutoEventWireup="true" MaintainScrollPositionOnPostBack="true" CodeBehind="MarkCompletions.aspx.cs" Inherits="PACE.MarkCompletions" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Mark Completions</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/MarkCompletions.css" />
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

                <%-- Step indicator: uses selected state (not done checkmark) until a student is actually marked.
                     btnChangeClass sits alongside it so the teacher can back out to step 1 from step 2 or 3
                     without browser back navigation, its own Visible is toggled server side in Page_PreRender. --%>
                <div style="display:flex;align-items:center;gap:12px;">
                    <div class="steps-bar" style="flex:1;">
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
                    <asp:LinkButton ID="btnChangeClass" runat="server" CssClass="btn-select" Visible="false" OnClick="btnChangeClass_Click">
                        <i class="ti ti-arrow-back-up"></i> Change Class
                    </asp:LinkButton>
                </div>

                <asp:Panel ID="pnlSuccess" runat="server" CssClass="alert-success-wrap alert-hidden" Visible="false">
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
                                        <tr><th>Task</th><th>Due Date</th><th>Priority</th><th style="width:100px;">Completed</th><th style="text-align:right;padding-right:16px;"></th></tr>
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
                                        <tr><th>Student</th><th style="width:110px;">Status</th><th style="text-align:right;padding-right:20px;">Action</th></tr>
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
