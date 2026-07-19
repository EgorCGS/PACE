<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TeacherClassPage.aspx.cs" Inherits="PACE.TeacherClassPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Class Overview</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/TeacherClassPage.css" />
</head>
<body>
    <form id="frmClassPage" runat="server">

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
                <a class="nav-item" href="MarkCompletions.aspx"><i class="ti ti-clipboard-check"></i><span class="nav-item-label">Mark Completions</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class='<%# GetNavClass(Eval("ClassID")) %>' href='TeacherClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
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
                    <a href="TeacherDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current"><asp:Label ID="lblBreadcrumb" runat="server" /></span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title"><asp:Label ID="lblHeroTitle" runat="server" /></div>
                <div class="hero-sub">Completion statistics and enrolled students for this class.</div>
            </div>

            <div class="content">

                <div class="actions-row">
                    <a class="btn-action" href='CreateTask.aspx?ClassID=<%= Request.QueryString["ClassID"] %>'><i class="ti ti-plus"></i> Create Task</a>
                    <a class="btn-action secondary" href='MarkCompletions.aspx?ClassID=<%= Request.QueryString["ClassID"] %>'><i class="ti ti-clipboard-check"></i> Mark Completions</a>
                </div>

                <div class="summary-strip">
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblTotalStudents" runat="server" /></div>
                        <div class="summary-label">Students enrolled</div>
                    </div>
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblTotalTasks" runat="server" /></div>
                        <div class="summary-label">Tasks assigned</div>
                    </div>
                    <div class="summary-card">
                        <div class="summary-number"><asp:Label ID="lblOverallPct" runat="server" /></div>
                        <div class="summary-label">Overall completion</div>
                    </div>
                </div>

                <div class="stats-grid">

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#eef2fb;"><i class="ti ti-chart-bar" style="color:#4a6fa5;font-size:17px;"></i></div>
                            <span class="card-header-title">Student Distribution</span>
                        </div>
                        <div class="graph-card-body">
                            <asp:Panel ID="pnlDistributionChart" runat="server">
                                <div class="dist-bar">
                                    <asp:Panel ID="pnlOnTrackSeg" runat="server" CssClass="dist-seg dist-seg-green" />
                                    <asp:Panel ID="pnlAtRiskSeg" runat="server" CssClass="dist-seg dist-seg-orange" />
                                    <asp:Panel ID="pnlBehindSeg" runat="server" CssClass="dist-seg dist-seg-red" />
                                </div>
                                <div class="dist-legend">
                                    <div class="dist-legend-item"><span class="dist-dot dist-dot-green"></span>On Track (75%+): <span class="dist-count"><asp:Label ID="lblOnTrackCount" runat="server" /></span></div>
                                    <div class="dist-legend-item"><span class="dist-dot dist-dot-orange"></span>At Risk (40-74%): <span class="dist-count"><asp:Label ID="lblAtRiskCount" runat="server" /></span></div>
                                    <div class="dist-legend-item"><span class="dist-dot dist-dot-red"></span>Behind (under 40%): <span class="dist-count"><asp:Label ID="lblBehindCount" runat="server" /></span></div>
                                </div>
                            </asp:Panel>
                            <asp:Panel ID="pnlDistributionEmpty" runat="server" Visible="false">
                                <div class="empty-state">No tasks assigned yet. Add a task to see how students are tracking.</div>
                            </asp:Panel>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-trending-up" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">Completion Trend (Last 30 Days)</span>
                        </div>
                        <div class="graph-card-body">
                            <asp:Panel ID="pnlTrendChart" runat="server">
                                <div class="trend-chart-scroll">
                                    <div class="trend-chart">
                                        <asp:Repeater ID="rptCompletionTrend" runat="server">
                                            <ItemTemplate>
                                                <div class="trend-bar-col">
                                                    <div class="trend-bar" style='height:<%# GetTrendBarHeight(Eval("CompletionCount")) %>%' title='<%# GetTrendTooltip(Eval("CompletionDate"), Eval("CompletionCount")) %>'></div>
                                                    <div class="trend-date-label"><%# GetTrendDateLabel(Eval("CompletionDate")) %></div>
                                                </div>
                                            </ItemTemplate>
                                        </asp:Repeater>
                                    </div>
                                </div>
                            </asp:Panel>
                            <asp:Panel ID="pnlTrendEmpty" runat="server" Visible="false">
                                <div class="empty-state">No completions marked yet in the last 30 days.</div>
                            </asp:Panel>
                        </div>
                    </div>

                </div>

                <div class="stats-grid">

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">By Task</span>
                        </div>
                        <asp:Repeater ID="rptTaskStats" runat="server">
                            <HeaderTemplate>
                                <table class="stats-table">
                                    <thead><tr><th>Task</th><th>Done</th><th class="pct-cell">Progress</th></tr></thead>
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
                                                <div class="pct-fill <%# GetPctClass(Eval("Percentage")) %>" style="width:<%# string.Format("{0:0}", Eval("Percentage")) %>%"></div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </ItemTemplate>
                            <FooterTemplate></tbody></table></FooterTemplate>
                        </asp:Repeater>
                        <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                            <div class="empty-state">No tasks yet. <a href='CreateTask.aspx?ClassID=<%= Request.QueryString["ClassID"] %>' style="color:var(--topbar);">Create one.</a></div>
                        </asp:Panel>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-users" style="color:#3a9e6e;font-size:17px;"></i></div>
                            <span class="card-header-title">By Student</span>
                        </div>
                        <asp:Repeater ID="rptStudentStats" runat="server">
                            <HeaderTemplate>
                                <table class="stats-table">
                                    <thead><tr><th>Student</th><th>Done</th><th class="pct-cell">Progress</th></tr></thead>
                                    <tbody>
                            </HeaderTemplate>
                            <ItemTemplate>
                                <tr>
                                    <td>
                                        <div class="student-name-cell">
                                            <span class="student-avatar <%# GetStudentRowClass(Eval("TasksCompleted"), Eval("TotalTasks")) %>"><%# GetStudentInitials(Eval("FullName")) %></span>
                                            <span class="<%# GetStudentRowClass(Eval("TasksCompleted"), Eval("TotalTasks")) %>"><%# Eval("FullName") %></span>
                                        </div>
                                    </td>
                                    <td><span class="fraction"><%# Eval("TasksCompleted") %> / <%# Eval("TotalTasks") %></span></td>
                                    <td class="pct-cell">
                                        <div class="pct-row">
                                            <span class="pct-label"><%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%</span>
                                            <div class="pct-track">
                                                <div class="pct-fill <%# GetPctClass(GetStudentPctRaw(Eval("TasksCompleted"), Eval("TotalTasks"))) %>"
                                                     style="width:<%# GetStudentPct(Eval("TasksCompleted"), Eval("TotalTasks")) %>%"></div>
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
            </div>
        </div>

    </form>
</body>
</html>
