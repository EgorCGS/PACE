<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TeacherDashboard.aspx.cs" Inherits="PACE.TeacherDashboard" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Teacher Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/TeacherDashboard.css" />
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
                                            <%# Convert.ToInt32(Eval("OverdueTasks")) > 0 ? "<span class='overdue-tag'><span class='overdue-tag-count'><i class='ti ti-alert-triangle'></i>" + Eval("OverdueTasks") + "</span><span class='overdue-tag-label'>overdue</span></span>" : "" %>
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
