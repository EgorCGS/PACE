<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TaskDetail.aspx.cs" Inherits="PACE.TaskDetail" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Task Detail</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/TaskDetail.css" />
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
