<%@ Page Language="C#" AutoEventWireup="true" MaintainScrollPositionOnPostBack="true" CodeBehind="ManageTasks.aspx.cs" Inherits="PACE.ManageTasks" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Manage Tasks</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/ManageTasks.css" />
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
                <a class="nav-item active" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
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
                    <a href="TeacherDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current">Manage Tasks</span>
                </div>
            </header>

            <div class="page-subheader">
                <div class="page-subheader-icon" style="background:#fef7ee;"><i class="ti ti-list" style="color:#d4882a;"></i></div>
                <div>
                    <div class="page-subheader-title">Manage Tasks</div>
                    <div class="page-subheader-sub">Edit or delete homework tasks you have created.</div>
                </div>
            </div>

            <div class="content">

                <div class="alert-area">
                    <asp:Panel ID="pnlSuccess" runat="server" CssClass="alert-success-wrap alert-hidden">
                        <div class="alert-success"><i class="ti ti-circle-check" style="font-size:18px;"></i><asp:Label ID="lblSuccess" runat="server" /></div>
                    </asp:Panel>
                    <asp:Panel ID="pnlError" runat="server" CssClass="alert-error-wrap alert-hidden">
                        <div class="alert-error"><i class="ti ti-alert-circle" style="font-size:18px;"></i><asp:Label ID="lblError" runat="server" /></div>
                    </asp:Panel>
                </div>

                <%-- pnlEditForm is a large card, not a small banner. Reserving its full height
                     permanently would leave a large empty gap on a page that is mostly just
                     browsing the task list, so unlike pnlSuccess/pnlError above it keeps using
                     the server Visible property as the real open/closed switch (a jump is
                     accepted at the moment a row's edit genuinely opens or closes). What it
                     avoids is jumping AGAIN while already open: switching the edit target to a
                     different row, or a failed Save, never toggles Visible, only refills the
                     same still-open panel, so those interactions cause no additional jump. See
                     ManageTasks.aspx.cs LoadEditForm / btnSaveEdit_Click for where this is enforced. --%>
                <asp:Panel ID="pnlEditForm" runat="server" Visible="false">
                    <div class="card">
                        <div class="card-header">
                            <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-pencil" style="color:#3a5a8c;font-size:17px;"></i></div>
                            <span class="card-header-title">Edit Task</span>
                            <span class="edit-panel-title"><asp:Label ID="lblEditTitle" runat="server" /></span>
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
                                <asp:TextBox ID="txtEditDescription" runat="server" TextMode="MultiLine" CssClass="form-textarea" MaxLength="1000" />
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

                <div class="card table-card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-list" style="color:#3a5a8c;font-size:17px;"></i></div>
                        <span class="card-header-title">All Tasks</span>
                        <span style="font-size:13px;color:var(--text-muted);margin-left:auto;"><asp:Label ID="lblTaskCount" runat="server" /> tasks</span>
                    </div>
                    <asp:Repeater ID="rptTasks" runat="server">
                        <HeaderTemplate>
                            <table class="task-table">
                                <thead>
                                    <tr>
                                        <th>Task</th><th>Class</th><th>Due Date</th><th style="width:90px;">Priority</th>
                                        <th style="text-align:right;padding-right:18px;">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr>
                                <td><div class="task-name"><%# Eval("Title") %></div><div class="task-sub"><%# Eval("Subject") %></div></td>
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
                        <div class="empty-state">No tasks yet. <a href="CreateTask.aspx" style="color:var(--topbar);">Create one.</a></div>
                    </asp:Panel>
                </div>

            </div>
        </div>
    </form>
</body>
</html>
