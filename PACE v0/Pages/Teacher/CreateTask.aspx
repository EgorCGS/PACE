<%@ Page Language="C#" AutoEventWireup="true" MaintainScrollPositionOnPostBack="true" CodeBehind="CreateTask.aspx.cs" Inherits="PACE.CreateTask" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Create Task</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/CreateTask.css" />
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
                <a class="nav-item" href="ManageTasks.aspx"><i class="ti ti-list"></i><span class="nav-item-label">Manage Tasks</span></a>
                <a class="nav-item active" href="CreateTask.aspx"><i class="ti ti-plus"></i><span class="nav-item-label">Create Task</span></a>
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
                    <span class="current">Create Task</span>
                </div>
            </header>

            <div class="page-subheader">
                <div class="page-subheader-icon" style="background:#e8f0fa;"><i class="ti ti-pencil-plus" style="color:#3a5a8c;"></i></div>
                <div>
                    <div class="page-subheader-title">Create Task</div>
                    <div class="page-subheader-sub">Add a new homework task and assign it to one of your classes.</div>
                </div>
            </div>

            <div class="content">

                <asp:Panel ID="pnlSuccess" runat="server" CssClass="alert-success-wrap alert-hidden">
                    <div class="alert-success">
                        <i class="ti ti-circle-check" style="font-size:18px;"></i>
                        <asp:Label ID="lblSuccess" runat="server" />
                    </div>
                </asp:Panel>

                <div class="content-layout">

                    <div class="form-column">
                        <div class="card">
                            <div class="card-header">
                                <div class="card-header-left">
                                    <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-pencil-plus" style="color:#3a5a8c;font-size:17px;"></i></div>
                                    <span class="card-header-title">Task Details</span>
                                </div>
                                <span class="required-note">Fields marked with <span>*</span> are required</span>
                            </div>

                            <div class="form-body">
                                <div class="form-group">
                                    <label class="form-label">Assign to Class <span class="req">*</span></label>
                                    <asp:DropDownList ID="ddlClass" runat="server" CssClass="form-select" />
                                    <span class="form-hint">Only your own classes are shown.</span>
                                    <asp:Label ID="lblClassError" runat="server" CssClass="error-msg" Visible="false">Please select a class.</asp:Label>
                                </div>
                                <div class="form-row">
                                    <div class="form-group">
                                        <label class="form-label">Task Title <span class="req">*</span></label>
                                        <asp:TextBox ID="txtTitle" runat="server" CssClass="form-input" placeholder="e.g. Exercises 4A" MaxLength="150" />
                                        <asp:Label ID="lblTitleError" runat="server" CssClass="error-msg" Visible="false">Title is required.</asp:Label>
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">Subject <span class="req">*</span></label>
                                        <asp:TextBox ID="txtSubject" runat="server" CssClass="form-input" placeholder="e.g. Mathematics" MaxLength="100" />
                                        <asp:Label ID="lblSubjectError" runat="server" CssClass="error-msg" Visible="false">Subject is required.</asp:Label>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <label class="form-label">Description <span class="req">*</span></label>
                                    <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="form-textarea" placeholder="Describe the task in detail..." MaxLength="1000" />
                                    <asp:Label ID="lblDescError" runat="server" CssClass="error-msg" Visible="false">Description is required.</asp:Label>
                                </div>
                                <div class="form-row">
                                    <div class="form-group">
                                        <label class="form-label">Due Date <span class="req">*</span></label>
                                        <asp:TextBox ID="txtDueDate" runat="server" CssClass="form-input" placeholder="DD/MM/YYYY" MaxLength="10" />
                                        <asp:Label ID="lblDateError" runat="server" CssClass="error-msg" Visible="false">Must be a valid date in DD/MM/YYYY format.</asp:Label>
                                    </div>
                                    <div class="form-group">
                                        <label class="form-label">Priority <span class="req">*</span></label>
                                        <div class="priority-toggle">
                                            <button type="button" class="prio-btn" id="btnHigh" onclick="setPriority(3,'sel-high')">High</button>
                                            <button type="button" class="prio-btn sel-med" id="btnMed" onclick="setPriority(2,'sel-med')">Med</button>
                                            <button type="button" class="prio-btn" id="btnLow" onclick="setPriority(1,'sel-low')">Low</button>
                                        </div>
                                        <asp:HiddenField ID="hdnPriority" runat="server" Value="2" />
                                    </div>
                                </div>
                            </div>

                            <div class="form-footer">
                                <asp:LinkButton ID="btnCreateTask" runat="server" CssClass="btn-primary" OnClick="btnCreateTask_Click"><i class="ti ti-plus"></i> Create Task</asp:LinkButton>
                                <a class="btn-ghost" href="TeacherDashboard.aspx">Cancel</a>
                            </div>
                        </div>
                    </div>

                    <div class="panel-column">
                        <div class="card">
                            <div class="panel-card-header">
                                <div class="panel-card-icon" style="background:#f1ecfa;"><i class="ti ti-shield-check" style="color:#6b3db0;"></i></div>
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
        /**
         * Sets the hidden priority field and updates the selected visual state
         * of the priority toggle buttons.
         * @param {number} value - The priority level to store (3=High, 2=Med, 1=Low).
         * @param {string} selectedClass - The CSS class to apply to the newly selected button.
         */
        function setPriority(value, selectedClass) {
            document.getElementById('<%= hdnPriority.ClientID %>').value = value;
            document.querySelectorAll('.prio-btn').forEach(function(b) {
                b.classList.remove('sel-high', 'sel-med', 'sel-low');
            });
            var ids = { 3: 'btnHigh', 2: 'btnMed', 1: 'btnLow' };
            document.getElementById(ids[value]).classList.add(selectedClass);
        }

        /**
         * Restores the priority toggle's selected visual state after postback, since the
         * hidden field's value survives ViewState but the button CSS classes do not.
         */
        (function () {
            var val = parseInt(document.getElementById('<%= hdnPriority.ClientID %>').value);
            var map = { 3: ['btnHigh', 'sel-high'], 2: ['btnMed', 'sel-med'], 1: ['btnLow', 'sel-low'] };
            if (map[val]) document.getElementById(map[val][0]).classList.add(map[val][1]);
        }());
    </script>
</body>
</html>
